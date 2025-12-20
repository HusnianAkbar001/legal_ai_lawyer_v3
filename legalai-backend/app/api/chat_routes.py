from flask import Blueprint, request, jsonify, g, current_app
from werkzeug.exceptions import BadRequest, Forbidden, NotFound
from ._auth_guard import require_auth, safe_mode_on
from ..services.rag_service import RAGService
from ..services.llm_service import LLMService
from ..models.chat import ChatMessage, ChatConversation
from ..extensions import db

bp = Blueprint("chat", __name__)

DISCLAIMER_BY_LANG = {
    "en": (
        "Note: This information is provided only to explain your legal rights. "
        "If you want to take legal action, please contact a lawyer from our provided list "
        "or consult a lawyer in person. For urgent help, use the Helpline."
    ),
    "ur": (
        "نوٹ: یہ معلومات صرف آپ کے قانونی حقوق کی وضاحت کے لیے فراہم کی جاتی ہیں۔ "
        "اگر آپ قانونی کارروائی کرنا چاہتے ہیں تو براہِ کرم ہماری فراہم کردہ فہرست میں سے کسی وکیل سے رابطہ کریں "
        "یا ذاتی طور پر کسی وکیل سے مشورہ کریں۔ فوری مدد کے لیے ہیلپ لائن استعمال کریں۔"
    ),
}


def _summarize_title(question: str, max_len: int = 80) -> str:
    q = " ".join((question or "").split())
    if len(q) <= max_len:
        return q or "Chat"
    cut = q[:max_len].rsplit(" ", 1)[0]
    return cut if cut else q[:max_len]


def _get_conversation_or_404(cid: int, user_id: int) -> ChatConversation:
    conv = ChatConversation.query.get(cid)
    if not conv:
        raise NotFound("Conversation not found")
    if conv.user_id != user_id:
        raise Forbidden("Not yours")
    return conv


def _recent_conversation_messages(cid: int, limit: int = 10) -> list[dict]:
    """
    Return last N messages (chronological) from this conversation only.
    This provides true 'resume chat' memory without leaking other chats.
    """
    rows = (
        ChatMessage.query
        .filter_by(conversation_id=cid, user_id=g.user.id)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
        .all()
    )
    rows = list(reversed(rows))
    return [{"role": r.role, "content": r.content} for r in rows]


@bp.post("/ask")
@require_auth()
def ask():
    data = request.get_json() or {}
    q = (data.get("question") or "").strip()
    if not q:
        raise BadRequest("Question required")
    if len(q) > 2000:
        raise BadRequest("Question too long")

    language = (getattr(g.user, "language", None) or "en")

    conv_id = data.get("conversationId")

    # Safe mode: no DB writes & no conversation memory
    if safe_mode_on():
        emb = LLMService.embed(q)

        hits = RAGService.search_similar_with_scores(emb, language=language)
        contexts = [h["chunk_text"] for h in hits]

        threshold = RAGService.get_distance_threshold()
        best_distance = hits[0]["distance"] if hits else None
        in_domain = bool(hits) and (best_distance <= threshold)

        current_app.logger.info(
            "ChatRAG routing safe_mode=1 user_id=%s lang=%s hits=%s best_dist=%s threshold=%.4f in_domain=%s",
            getattr(g.user, "id", None),
            language,
            len(hits),
            None if best_distance is None else round(best_distance, 4),
            threshold,
            in_domain,
        )

        if not hits:
            # No KB results at all -> ask user to rephrase in-scope legal question
            msg = (
                "I could not find relevant information in the uploaded legal documents. "
                "Please ask a specific legal question or rephrase."
                if language != "ur"
                else
                "مجھے اپ لوڈ کیے گئے قانونی دستاویزات میں اس سوال سے متعلق معلومات نہیں ملیں۔ "
                "براہِ کرم اپنا قانونی سوال واضح انداز میں دوبارہ لکھیں۔"
            )
            disclaimer = DISCLAIMER_BY_LANG.get(language, DISCLAIMER_BY_LANG["en"])
            final = f"{msg}\n\n{disclaimer}"

            return jsonify({"answer": final, "conversationId": None, "contextsUsed": 0})

        if not in_domain:
            # Out-of-domain/meta/smalltalk -> capability/scope message (user language)
            msg = (
                "I can only help with legal awareness related to Pakistan’s laws. "
                "Please ask a legal question."
                if language != "ur"
                else
                "میں صرف پاکستان کے قوانین اور قانونی آگاہی کے بارے میں مدد کر سکتا ہوں۔ "
                "براہِ کرم کوئی قانونی سوال کریں۔"
            )
            disclaimer = DISCLAIMER_BY_LANG.get(language, DISCLAIMER_BY_LANG["en"])
            final = f"{msg}\n\n{disclaimer}"
            return jsonify({"answer": final, "conversationId": None, "contextsUsed": 0})

        answer = LLMService.chat_rag(
            question=q,
            contexts=contexts,
            language=language,
            history=[],
        )
        final = f"{answer}\n\n{DISCLAIMER_BY_LANG}"
        return jsonify({"answer": final, "conversationId": None, "contextsUsed": len(contexts)})

    # Conversation handling
    if conv_id is not None:
        try:
            conv_id = int(conv_id)
        except (TypeError, ValueError):
            raise BadRequest("conversationId must be an integer")
        conv = _get_conversation_or_404(conv_id, g.user.id)
    else:
        # Requirement: new conversation every time if no id supplied
        conv = ChatConversation(
            user_id=g.user.id,
            title=_summarize_title(q),
        )
        db.session.add(conv)
        db.session.commit()
        conv_id = conv.id

    # Conversation memory (last 10 messages only)
    history = _recent_conversation_messages(conv_id, limit=10)

    # Knowledge RAG
    emb = LLMService.embed(q)

    hits = RAGService.search_similar_with_scores(emb, language=language)
    contexts = [h["chunk_text"] for h in hits]

    threshold = RAGService.get_distance_threshold()
    best_distance = hits[0]["distance"] if hits else None
    in_domain = bool(hits) and (best_distance <= threshold)

    current_app.logger.info(
        "ChatRAG routing safe_mode=0 user_id=%s conv_id=%s lang=%s hits=%s best_dist=%s threshold=%.4f in_domain=%s",
        getattr(g.user, "id", None),
        conv_id,
        language,
        len(hits),
        None if best_distance is None else round(best_distance, 4),
        threshold,
        in_domain,
    )

    if not hits:
        msg = (
            "I could not find relevant information in the uploaded legal documents. "
            "Please ask a specific legal question or rephrase."
            if language != "ur"
            else
            "مجھے اپ لوڈ کیے گئے قانونی دستاویزات میں اس سوال سے متعلق معلومات نہیں ملیں۔ "
            "براہِ کرم اپنا قانونی سوال واضح انداز میں دوبارہ لکھیں۔"
        )
        disclaimer = DISCLAIMER_BY_LANG.get(language, DISCLAIMER_BY_LANG["en"])
        final = f"{msg}\n\n{disclaimer}"


        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="user",
            content=q,
            max_messages=100,
            commit=False,
        )
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="assistant",
            content=final,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        return jsonify({"answer": final, "conversationId": conv_id, "contextsUsed": 0})

    if not in_domain:
        msg = (
            "I can only help with legal awareness related to Pakistan’s laws. "
            "Please ask a legal question."
            if language != "ur"
            else
                "منتخب زبان میں مواد دستیاب نہیں ہے۔"
        )
        disclaimer = DISCLAIMER_BY_LANG.get(language, DISCLAIMER_BY_LANG["en"])
        final = f"{msg}\n\n{disclaimer}"

        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="user",
            content=q,
            max_messages=100,
            commit=False,
        )
        ChatMessage.add_and_trim(
            user_id=g.user.id,
            conversation_id=conv_id,
            role="assistant",
            content=final,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        return jsonify({"answer": final, "conversationId": conv_id, "contextsUsed": 0})

    answer = LLMService.chat_rag(
        question=q,
        contexts=contexts,
        language=language,
        history=history,
    )
    final = f"{answer}\n\n{DISCLAIMER_BY_LANG}"

    # Atomic write: add both messages then single commit
    ChatMessage.add_and_trim(
        user_id=g.user.id,
        conversation_id=conv_id,
        role="user",
        content=q,
        max_messages=100,
        commit=False,
    )
    ChatMessage.add_and_trim(
        user_id=g.user.id,
        conversation_id=conv_id,
        role="assistant",
        content=final,
        max_messages=100,
        commit=False,
    )
    db.session.commit()

    return jsonify({
        "answer": final,
        "conversationId": conv_id,
        "contextsUsed": len(contexts),
    })


@bp.get("/conversations")
@require_auth()
def list_conversations():
    try:
        page = int(request.args.get("page", 1))
        limit = int(request.args.get("limit", 20))
    except ValueError:
        raise BadRequest("page and limit must be integers")

    page = max(page, 1)
    limit = min(max(limit, 1), 100)

    q = (
        ChatConversation.query
        .filter_by(user_id=g.user.id)
        .order_by(ChatConversation.updated_at.desc())
    )
    items = q.offset((page - 1) * limit).limit(limit).all()

    result = []
    for c in items:
        last_msg = (
            ChatMessage.query
            .filter_by(conversation_id=c.id, user_id=g.user.id)
            .order_by(ChatMessage.created_at.desc())
            .first()
        )
        last_snip = (last_msg.content[:120] + "…") if last_msg else ""
        result.append({
            "id": c.id,
            "title": c.title,
            "createdAt": c.created_at.isoformat(),
            "updatedAt": c.updated_at.isoformat(),
            "lastMessageSnippet": last_snip,
        })

    return jsonify({"page": page, "limit": limit, "items": result})


@bp.get("/conversations/<int:cid>/messages")
@require_auth()
def get_conversation_messages(cid: int):
    conv = _get_conversation_or_404(cid, g.user.id)

    try:
        page = int(request.args.get("page", 1))
        limit = int(request.args.get("limit", 30))
    except ValueError:
        raise BadRequest("page and limit must be integers")

    page = max(page, 1)
    limit = min(max(limit, 1), 100)

    q = (
        ChatMessage.query
        .filter_by(conversation_id=conv.id, user_id=g.user.id)
        .order_by(ChatMessage.created_at.desc())
    )
    msgs_desc = q.offset((page - 1) * limit).limit(limit).all()
    msgs = list(reversed(msgs_desc))

    return jsonify({
        "conversationId": conv.id,
        "title": conv.title,
        "page": page,
        "limit": limit,
        "items": [
            {
                "id": m.id,
                "role": m.role,
                "content": m.content,
                "createdAt": m.created_at.isoformat(),
            } for m in msgs
        ],
    })


@bp.put("/conversations/<int:cid>")
@require_auth()
def rename_conversation(cid: int):
    conv = _get_conversation_or_404(cid, g.user.id)
    data = request.get_json() or {}
    title = (data.get("title") or "").strip()
    if not title:
        raise BadRequest("title required")
    if len(title) > 200:
        raise BadRequest("title too long (max 200 chars)")

    conv.title = title
    db.session.commit()
    return jsonify({"ok": True})


@bp.delete("/conversations/<int:cid>")
@require_auth()
def delete_conversation(cid: int):
    conv = _get_conversation_or_404(cid, g.user.id)

    ChatMessage.query.filter_by(conversation_id=conv.id).delete()
    ChatConversation.query.filter_by(id=conv.id).delete()
    db.session.commit()

    return jsonify({"ok": True})