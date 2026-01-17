from flask import Blueprint, request, jsonify, g, current_app
from werkzeug.exceptions import BadRequest, Forbidden, NotFound
from ._auth_guard import require_auth, safe_mode_on
from ..services.rag_service import RAGService
from ..services.llm_service import LLMService
from ..models.chat import ChatMessage, ChatConversation
from ..extensions import db
from ..tasks.evaluation_tasks import log_rag_evaluation_async
import time

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

def _detect_emergency_fast(q: str) -> bool:
    ql = (q or "").lower()
    hints = [
        "kill", "murder", "suicide", "self harm", "self-harm", "i will die",
        "threaten to kill", "threat to kill", "he will kill me", "she will kill me",
        "rape", "kidnap", "abduct",
        "قتل", "خودکشی", "جان سے مار", "مار دوں گا", "مار دوں گی", "ماردے", "مر جاؤں",
        "زیادتی", "اغوا"
    ]
    return any(h in ql for h in hints)

@bp.post("/ask")
@require_auth()
def ask():
    data = request.get_json() or {}
    request_start_time = time.perf_counter()

    q = (data.get("question") or "").strip()
    if not q:
        raise BadRequest("Question required")
    if len(q) > 2000:
        raise BadRequest("Question too long")

    language = (getattr(g.user, "language", None) or "en")
    province = getattr(g.user, "province", None)
    conv_id = data.get("conversationId")
    memory_limit = current_app.config.get("CHAT_MEMORY_LIMIT", 10)

    if safe_mode_on():
        if _detect_emergency_fast(q):
            route = {"category": "EMERGENCY", "confidence": 1.0, "topic": "emergency"}
        else:
            route = LLMService.classify_query(question=q, language=language)

        category = route.get("category")
        topic = route.get("topic") or "other"

        current_app.logger.info(
            "Chat classify: safe_mode=1 user_id=%s lang=%s category=%s topic=%s conf=%s",
            getattr(g.user, "id", None),
            language,
            category,
            topic,
            route.get("confidence"),
        )

        if category == "GREETING_OR_APP_HELP":
            msg = (
                "Hello! I can help with legal awareness for women in Pakistan (workplace harassment, domestic violence, family matters, cyber harassment). "
                "Please describe your situation and I will guide you."
                if language != "ur"
                else
                "السلام علیکم! میں پاکستان میں خواتین کے لیے قانونی آگاہی میں مدد کر سکتی ہوں (کام کی جگہ ہراسانی، گھریلو تشدد، خاندانی معاملات، سائبر ہراسانی)۔ "
                "براہِ کرم اپنا مسئلہ بتائیں، میں رہنمائی کروں گی۔"
            )
            return jsonify({"answer": msg, "conversationId": None, "contextsUsed": 0})

        if category == "EMERGENCY":
            emergency_msg = LLMService.emergency_response(language=language, province=province)
            total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
            try:
                log_rag_evaluation_async.delay(
                    user_id=g.user.id,
                    conversation_id=None,
                    language=language,
                    safe_mode=True,
                    is_new_conversation=True,
                    question=q,
                    answer=emergency_msg,
                    threshold=None,
                    best_distance=None,
                    contexts_found=0,
                    contexts_used=0,
                    in_domain=True,
                    decision="EMERGENCY",
                    chunk_ids=[],
                    embedding_time_ms=0,
                    llm_time_ms=0,
                    total_time_ms=total_time_ms,
                    embedding_model=current_app.config["EMBEDDING_MODEL"],
                    embedding_dimension=current_app.config.get("EMBEDDING_DIMENSION"),
                    chat_model=current_app.config.get("CHAT_MODEL"),
                    prompt_messages=None,
                    completion_text=emergency_msg,
                )
            except Exception as e:
                current_app.logger.warning("Failed to queue evaluation task: %s", str(e))

            return jsonify({"answer": emergency_msg, "conversationId": None, "contextsUsed": 0})

        if category in {"OUT_OF_DOMAIN", "PROMPT_INJECTION_OR_MISUSE"}:
            refusal = (
                "I am an AI legal lawyer assistant. I can only help you with legal awareness. "
                "I'm not able to process this query."
                if language != "ur"
                else
                "میں ایک اے آئی لیگل اسسٹنٹ ہوں۔ میں صرف قانونی آگاہی میں مدد کر سکتی ہوں۔ میں اس سوال پر مدد نہیں کر سکتی۔"
            )
            total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
            try:
                log_rag_evaluation_async.delay(
                    user_id=g.user.id,
                    conversation_id=None,
                    language=language,
                    safe_mode=True,
                    is_new_conversation=True,
                    question=q,
                    answer=refusal,
                    threshold=None,
                    best_distance=None,
                    contexts_found=0,
                    contexts_used=0,
                    in_domain=False,
                    decision="REFUSE_OUT_OF_DOMAIN",
                    chunk_ids=[],
                    embedding_time_ms=0,
                    llm_time_ms=0,
                    total_time_ms=total_time_ms,
                    embedding_model=current_app.config["EMBEDDING_MODEL"],
                    embedding_dimension=current_app.config.get("EMBEDDING_DIMENSION"),
                    chat_model=current_app.config.get("CHAT_MODEL"),
                    prompt_messages=None,
                    completion_text=refusal,
                )
            except Exception as e:
                current_app.logger.warning("Failed to queue evaluation task: %s", str(e))

            return jsonify({"answer": refusal, "conversationId": None, "contextsUsed": 0})

        embedding_start = time.perf_counter()
        emb = LLMService.embed(q)
        embedding_time_ms = int((time.perf_counter() - embedding_start) * 1000)

        hits = RAGService.search_similar_with_scores(emb, language=language)
        chunk_ids = [h.get("chunk_id") for h in hits if h.get("chunk_id")]

        threshold = RAGService.get_distance_threshold()
        best_distance = hits[0]["distance"] if hits else None

        has_verified_sources = bool(hits) and (best_distance is not None) and (best_distance <= threshold)
        contexts = [h["chunk_text"] for h in hits] if has_verified_sources else []

        llm_start = time.perf_counter()
        answer, prompt_messages, _ = LLMService.chat_legal_awareness(
            question=q,
            contexts=contexts,
            language=language,
            province=province,
            history=[],
        )
        llm_time_ms = int((time.perf_counter() - llm_start) * 1000)

        total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
        decision = "ANSWER_WITH_SOURCES" if has_verified_sources else "ANSWER_NO_SOURCES"

        try:
            log_rag_evaluation_async.delay(
                user_id=g.user.id,
                conversation_id=None,
                language=language,
                safe_mode=True,
                is_new_conversation=True,
                question=q,
                answer=answer,
                threshold=threshold,
                best_distance=best_distance,
                contexts_found=len(hits),
                contexts_used=len(contexts),
                in_domain=True,
                decision=decision,
                chunk_ids=chunk_ids,
                embedding_time_ms=embedding_time_ms,
                llm_time_ms=llm_time_ms,
                total_time_ms=total_time_ms,
                embedding_model=current_app.config["EMBEDDING_MODEL"],
                embedding_dimension=current_app.config.get("EMBEDDING_DIMENSION"),
                chat_model=current_app.config.get("CHAT_MODEL"),
                prompt_messages=prompt_messages,
                completion_text=answer,
            )
        except Exception as e:
            current_app.logger.warning("Failed to queue evaluation task: %s", str(e))

        return jsonify({"answer": answer, "conversationId": None, "contextsUsed": len(contexts)})


    is_new_conversation = conv_id is None

    if conv_id is not None:
        try:
            conv_id = int(conv_id)
        except (TypeError, ValueError):
            raise BadRequest("conversationId must be an integer")
        conv = _get_conversation_or_404(conv_id, g.user.id)
    else:
        conv = ChatConversation(
            user_id=g.user.id,
            title=_summarize_title(q),
        )
        db.session.add(conv)
        db.session.commit()
        conv_id = conv.id

    history = _recent_conversation_messages(conv_id, limit=memory_limit)

    if _detect_emergency_fast(q):
        route = {"category": "EMERGENCY", "confidence": 1.0, "topic": "emergency"}
    else:
        route = LLMService.classify_query(question=q, language=language)

    category = route.get("category")
    topic = route.get("topic") or "other"

    current_app.logger.info(
        "Chat classify: safe_mode=0 user_id=%s conv_id=%s lang=%s category=%s topic=%s conf=%s",
        getattr(g.user, "id", None),
        conv_id,
        language,
        category,
        topic,
        route.get("confidence"),
    )

    if category == "GREETING_OR_APP_HELP":
        msg = (
            "Hello! I can help with legal awareness for women in Pakistan (workplace harassment, domestic violence, family matters, cyber harassment). "
            "Please describe your situation and I will guide you."
            if language != "ur"
            else
            "السلام علیکم! میں پاکستان میں خواتین کے لیے قانونی آگاہی میں مدد کر سکتی ہوں (کام کی جگہ ہراسانی، گھریلو تشدد، خاندانی معاملات، سائبر ہراسانی)۔ "
            "براہِ کرم اپنا مسئلہ بتائیں، میں رہنمائی کروں گی۔"
        )

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
            content=msg,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        return jsonify({"answer": msg, "conversationId": conv_id, "contextsUsed": 0})

    if category == "EMERGENCY":
        emergency_msg = LLMService.emergency_response(language=language, province=province)

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
            content=emergency_msg,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
        try:
            log_rag_evaluation_async.delay(
                user_id=g.user.id,
                conversation_id=conv_id,
                language=language,
                safe_mode=False,
                is_new_conversation=is_new_conversation,
                question=q,
                answer=emergency_msg,
                threshold=None,
                best_distance=None,
                contexts_found=0,
                contexts_used=0,
                in_domain=True,
                decision="EMERGENCY",
                chunk_ids=[],
                embedding_time_ms=0,
                llm_time_ms=0,
                total_time_ms=total_time_ms,
                embedding_model=current_app.config["EMBEDDING_MODEL"],
                embedding_dimension=current_app.config.get("EMBEDDING_DIMENSION"),
                chat_model=current_app.config.get("CHAT_MODEL"),
                prompt_messages=None,
                completion_text=emergency_msg,
            )
        except Exception as e:
            current_app.logger.warning("Failed to queue evaluation task: %s", str(e))

        return jsonify({"answer": emergency_msg, "conversationId": conv_id, "contextsUsed": 0})

    if category in {"OUT_OF_DOMAIN", "PROMPT_INJECTION_OR_MISUSE"}:
        refusal = (
            "I am an AI legal lawyer assistant. I can only help you with legal awareness. "
            "I'm not able to process this query."
            if language != "ur"
            else
            "میں ایک اے آئی لیگل اسسٹنٹ ہوں۔ میں صرف قانونی آگاہی میں مدد کر سکتی ہوں۔ میں اس سوال پر مدد نہیں کر سکتی۔"
        )

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
            content=refusal,
            max_messages=100,
            commit=False,
        )
        db.session.commit()

        total_time_ms = int((time.perf_counter() - request_start_time) * 1000)
        try:
            log_rag_evaluation_async.delay(
                user_id=g.user.id,
                conversation_id=conv_id,
                language=language,
                safe_mode=False,
                is_new_conversation=is_new_conversation,
                question=q,
                answer=refusal,
                threshold=None,
                best_distance=None,
                contexts_found=0,
                contexts_used=0,
                in_domain=False,
                decision="REFUSE_OUT_OF_DOMAIN",
                chunk_ids=[],
                embedding_time_ms=0,
                llm_time_ms=0,
                total_time_ms=total_time_ms,
                embedding_model=current_app.config["EMBEDDING_MODEL"],
                embedding_dimension=current_app.config.get("EMBEDDING_DIMENSION"),
                chat_model=current_app.config.get("CHAT_MODEL"),
                prompt_messages=None,
                completion_text=refusal,
            )
        except Exception as e:
            current_app.logger.warning("Failed to queue evaluation task: %s", str(e))

        return jsonify({"answer": refusal, "conversationId": conv_id, "contextsUsed": 0})

    embedding_start = time.perf_counter()
    emb = LLMService.embed(q)
    embedding_time_ms = int((time.perf_counter() - embedding_start) * 1000)

    hits = RAGService.search_similar_with_scores(emb, language=language)
    chunk_ids = [h.get("chunk_id") for h in hits if h.get("chunk_id")]

    threshold = RAGService.get_distance_threshold()
    best_distance = hits[0]["distance"] if hits else None

    has_verified_sources = bool(hits) and (best_distance is not None) and (best_distance <= threshold)
    contexts = [h["chunk_text"] for h in hits] if has_verified_sources else []
    decision = "ANSWER_WITH_SOURCES" if has_verified_sources else "ANSWER_NO_SOURCES"

    llm_start = time.perf_counter()
    answer, prompt_messages, _ = LLMService.chat_legal_awareness(
        question=q,
        contexts=contexts,
        language=language,
        province=province,
        history=history,
    )
    llm_time_ms = int((time.perf_counter() - llm_start) * 1000)

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
        content=answer,
        max_messages=100,
        commit=False,
    )
    db.session.commit()

    total_time_ms = int((time.perf_counter() - request_start_time) * 1000)

    try:
        log_rag_evaluation_async.delay(
            user_id=g.user.id,
            conversation_id=conv_id,
            language=language,
            safe_mode=False,
            is_new_conversation=is_new_conversation,
            question=q,
            answer=answer,
            threshold=threshold,
            best_distance=best_distance,
            contexts_found=len(hits),
            contexts_used=len(contexts),
            in_domain=True,
            decision=decision,
            chunk_ids=chunk_ids,
            embedding_time_ms=embedding_time_ms,
            llm_time_ms=llm_time_ms,
            total_time_ms=total_time_ms,
            embedding_model=current_app.config["EMBEDDING_MODEL"],
            embedding_dimension=current_app.config.get("EMBEDDING_DIMENSION"),
            chat_model=current_app.config.get("CHAT_MODEL"),
            prompt_messages=prompt_messages,
            completion_text=answer,
        )
    except Exception as e:
        current_app.logger.warning("Failed to queue evaluation task: %s", str(e))

    return jsonify({"answer": answer, "conversationId": conv_id, "contextsUsed": len(contexts)})

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