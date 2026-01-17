import hashlib

from flask import Blueprint, jsonify, request, g
from werkzeug.exceptions import BadRequest, NotFound, Conflict
from werkzeug.utils import secure_filename
from ..models.rag_evaluation import RAGEvaluationLog
from ..models.user import User
from ..models.activity import ActivityEvent
from app.models.lawyer import Lawyer
from app.models.contact_message import ContactMessage
from app.models.feedback import Feedback
from ..utils.security import validate_password, hash_password
from ..tasks.email_tasks import send_verification_email_task
from ..utils.pagination import paginate
from ..extensions import db, limiter
from sqlalchemy.exc import IntegrityError
from datetime import datetime
from ._auth_guard import require_auth
from ..models.rag import KnowledgeSource
from ..services.storage_service import StorageService
from ..tasks.ingestion_tasks import ingest_source
from ..extensions import db

bp = Blueprint("admin", __name__)

import json
from flask import current_app

def _default_lawyer_categories() -> list[str]:
    return [
        "Family Law",
        "Divorce / Khula",
        "Child Custody & Guardianship",
        "Criminal Law",
        "Bail Matters",
        "Civil Litigation",
        "Property Law",
        "Real Estate & Conveyancing",
        "Land Revenue Matters",
        "Rent / Tenancy Law",
        "Consumer Protection",
        "Cyber Crime",
        "Banking & Finance",
        "Money Recovery",
        "Debt Recovery",
        "Corporate Law",
        "Company Law",
        "Commercial Contracts",
        "Mergers & Acquisitions",
        "Partnership / LLP Matters",
        "SECP / Regulatory Matters",
        "Tax Law",
        "FBR / Tax Appeals",
        "Customs & Excise",
        "Labour & Employment",
        "Service Matters",
        "Immigration",
        "Intellectual Property",
        "Trademark",
        "Copyright",
        "Patent",
        "Arbitration",
        "Mediation",
        "ADR / Dispute Resolution",
        "Constitutional Law",
        "Human Rights",
        "Public Interest Litigation",
        "Administrative Law",
        "NAB / Accountability Matters",
        "FIA / Investigation Matters",
        "Anti-Corruption",
        "Islamic / Shariah Law",
        "Inheritance / Succession",
        "Wills & Probate",
        "Personal Injury",
        "Medical Negligence",
        "Insurance Law",
        "Environmental Law",
        "Education Law",
        "Media / Defamation",
        "Telecom / IT Law",
        "Energy / Power",
        "Oil & Gas",
        "Construction Law",
        "Infrastructure / PPP",
        "International Law",
        "International Trade",
    ]

def _lawyer_categories() -> list[str]:
    raw = current_app.config.get("LAWYER_CATEGORIES_JSON")
    if not raw:
        return _default_lawyer_categories()
    try:
        data = json.loads(raw)
        if isinstance(data, list) and all(isinstance(x, str) and x.strip() for x in data):
            return [x.strip() for x in data]
    except Exception:
        pass
    return _default_lawyer_categories()

@bp.get("/users")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_list_users():
    q = User.query.order_by(User.created_at.desc())
    return jsonify(
        paginate(
            q,
            lambda u: {
                "id": u.id,
                "name": u.name,
                "email": u.email,
                "phone": u.phone,
                "cnic": u.cnic,
                "isAdmin": bool(u.is_admin),
                "isEmailVerified": bool(u.is_email_verified),
                "isDeleted": bool(getattr(u, "is_deleted", False)),
                "createdAt": u.created_at.isoformat() if u.created_at else None,
            },
        )
    )


@bp.post("/users")
@require_auth(admin=True)
@limiter.limit("20 per minute")
def admin_create_user():
    d = request.get_json() or {}

    name = (d.get("name") or "").strip()
    email = (d.get("email") or "").strip().lower()
    phone = (d.get("phone") or "").strip()
    cnic = (d.get("cnic") or "").strip()
    password = d.get("password")

    if not name or not email or not phone or not cnic or not password:
        raise BadRequest("name, email, phone, cnic, password are required")

    validate_password(password)

    u = User(
        name=name,
        email=email,
        phone=phone,
        cnic=cnic,
        is_admin=bool(d.get("isAdmin", False)),
        is_email_verified=False,
        password_hash=hash_password(password),
    )

    db.session.add(u)

    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="USER_CREATED",
            payload={"targetUserId": None}, 
        )
    )

    try:
        db.session.flush()

        db.session.add(u)

        evt = ActivityEvent(
            user_id=g.user.id,
            event_type="USER_CREATED",
            payload={"targetUserId": None},
        )
        db.session.add(evt)

        try:
            db.session.flush()
            evt.payload = {"targetUserId": u.id}
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            raise Conflict("User already exists (email or CNIC).")

        current_app.logger.info(
            "Admin created user: admin_user_id=%s target_user_id=%s",
            g.user.id,
            u.id,
        )
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        raise Conflict("User already exists (email or CNIC).")

    send_verification_email_task.delay(u.id)

    return jsonify({"id": u.id}), 201


@bp.put("/users/<int:user_id>")
@require_auth(admin=True)
@limiter.limit("30 per minute")
def admin_update_user(user_id: int):
    u = User.query.get(user_id)
    if not u:
        raise NotFound("User not found")

    if getattr(u, "is_deleted", False):
        raise BadRequest("Cannot update a deleted user")

    d = request.get_json() or {}

    if "name" in d:
        u.name = (d.get("name") or "").strip()

    if "phone" in d:
        u.phone = (d.get("phone") or "").strip()

    if "isAdmin" in d:
        u.is_admin = bool(d.get("isAdmin"))

    if "password" in d and d["password"]:
        validate_password(d["password"])
        u.password_hash = hash_password(d["password"])
        u.token_version = (u.token_version or 0) + 1

    db.session.commit()

    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="USER_UPDATED",
            payload={"targetUserId": u.id},
        )
    )
    db.session.commit()

    return jsonify({"ok": True})


@bp.delete("/users/<int:user_id>")
@require_auth(admin=True)
@limiter.limit("20 per minute")
def admin_soft_delete_user(user_id: int):
    u = User.query.get(user_id)
    if not u:
        raise NotFound("User not found")

    if getattr(u, "is_deleted", False):
        return jsonify({"ok": True}) 

    u.is_deleted = True
    u.deleted_at = datetime.utcnow()
    u.deleted_by = g.user.id

    u.token_version = (u.token_version or 0) + 1

    db.session.commit()

    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="USER_DELETED",
            payload={"targetUserId": u.id},
        )
    )
    db.session.commit()

    return jsonify({"ok": True})

MAX_INGEST_RETRIES = 10

@bp.get("/lawyers/categories")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_lawyer_categories():
    return jsonify({"items": _lawyer_categories()})


@bp.get("/lawyers")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_list_lawyers():
    q = Lawyer.query.order_by(Lawyer.created_at.desc())
    return jsonify(
        paginate(
            q,
            lambda l: {
                "id": l.id,
                "fullName": l.full_name,
                "email": l.email,
                "phone": l.phone,
                "category": l.category,
                "profilePicturePath": l.profile_picture_path,
                "isActive": bool(l.is_active),
                "createdAt": l.created_at.isoformat() if l.created_at else None,
                "updatedAt": l.updated_at.isoformat() if l.updated_at else None,
            },
        )
    )


@bp.get("/lawyers/<int:lawyer_id>")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_get_lawyer(lawyer_id: int):
    l = Lawyer.query.get(lawyer_id)
    if not l:
        raise NotFound("Lawyer not found")
    return jsonify({
        "id": l.id,
        "fullName": l.full_name,
        "email": l.email,
        "phone": l.phone,
        "category": l.category,
        "profilePicturePath": l.profile_picture_path,
        "isActive": bool(l.is_active),
        "createdAt": l.created_at.isoformat() if l.created_at else None,
        "updatedAt": l.updated_at.isoformat() if l.updated_at else None,
    })


@bp.post("/lawyers")
@require_auth(admin=True)
@limiter.limit("20 per minute")
def admin_create_lawyer():
    if "file" not in request.files:
        raise BadRequest("Missing profile picture file")
    f = request.files["file"]
    if not f or not f.filename:
        raise BadRequest("Missing profile picture file name")

    full_name = (request.form.get("fullName") or "").strip()
    email = (request.form.get("email") or "").strip().lower()
    phone = (request.form.get("phone") or "").strip()
    category = (request.form.get("category") or "").strip()

    if not full_name or not email or not phone or not category:
        raise BadRequest("fullName, email, phone, category are required")

    allowed = set(_lawyer_categories())
    if category not in allowed:
        raise BadRequest("Invalid category")

    abs_path = StorageService.save_avatar(f, "lawyers")
    rel_path = StorageService.public_path(abs_path)

    l = Lawyer(
        full_name=full_name,
        email=email,
        phone=phone,
        category=category,
        profile_picture_path=rel_path,
        is_active=True,
    )
    db.session.add(l)
    db.session.commit()

    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="LAWYER_CREATED",
            payload={"lawyerId": l.id},
        )
    )
    db.session.commit()

    return jsonify({"id": l.id}), 201


@bp.put("/lawyers/<int:lawyer_id>")
@require_auth(admin=True)
@limiter.limit("30 per minute")
def admin_update_lawyer(lawyer_id: int):
    l = Lawyer.query.get(lawyer_id)
    if not l:
        raise NotFound("Lawyer not found")

    if request.content_type and request.content_type.startswith("multipart/form-data"):
        full_name = request.form.get("fullName")
        email = request.form.get("email")
        phone = request.form.get("phone")
        category = request.form.get("category")

        if full_name is not None:
            l.full_name = (full_name or "").strip()
        if email is not None:
            l.email = (email or "").strip().lower()
        if phone is not None:
            l.phone = (phone or "").strip()
        if category is not None:
            cat = (category or "").strip()
            if cat not in set(_lawyer_categories()):
                raise BadRequest("Invalid category")
            l.category = cat

        if "file" in request.files and request.files["file"] and request.files["file"].filename:
            abs_path = StorageService.save_avatar(request.files["file"], "lawyers")
            l.profile_picture_path = StorageService.public_path(abs_path)

    else:
        d = request.get_json() or {}
        if "fullName" in d:
            l.full_name = (d.get("fullName") or "").strip()
        if "email" in d:
            l.email = (d.get("email") or "").strip().lower()
        if "phone" in d:
            l.phone = (d.get("phone") or "").strip()
        if "category" in d:
            cat = (d.get("category") or "").strip()
            if cat not in set(_lawyer_categories()):
                raise BadRequest("Invalid category")
            l.category = cat
        if "isActive" in d:
            l.is_active = bool(d.get("isActive"))

    if not l.full_name or not l.email or not l.phone or not l.category or not l.profile_picture_path:
        raise BadRequest("fullName, email, phone, category, profile picture are required")

    db.session.commit()

    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="LAWYER_UPDATED",
            payload={"lawyerId": l.id},
        )
    )
    db.session.commit()

    return jsonify({"ok": True})


@bp.delete("/lawyers/<int:lawyer_id>")
@require_auth(admin=True)
@limiter.limit("20 per minute")
def admin_deactivate_lawyer(lawyer_id: int):
    l = Lawyer.query.get(lawyer_id)
    if not l:
        raise NotFound("Lawyer not found")

    if not l.is_active:
        return jsonify({"ok": True}) 

    l.is_active = False
    db.session.commit()

    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="LAWYER_DEACTIVATED",
            payload={"lawyerId": l.id},
        )
    )
    db.session.commit()

    return jsonify({"ok": True})

@bp.get("/contact-messages")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_list_contact_messages():
    q = ContactMessage.query.order_by(ContactMessage.created_at.desc())
    return jsonify(
        paginate(
            q,
            lambda m: {
                "id": m.id,
                "userId": m.user_id,
                "fullName": m.full_name,
                "email": m.email,
                "phone": m.phone,
                "subject": m.subject,
                "createdAt": m.created_at.isoformat() if m.created_at else None,
            },
        )
    )


@bp.get("/contact-messages/<int:msg_id>")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_get_contact_message(msg_id: int):
    m = ContactMessage.query.get(msg_id)
    if not m:
        raise NotFound("Contact message not found")
    return jsonify({
        "id": m.id,
        "userId": m.user_id,
        "fullName": m.full_name,
        "email": m.email,
        "phone": m.phone,
        "subject": m.subject,
        "description": m.description,
        "createdAt": m.created_at.isoformat() if m.created_at else None,
    })


@bp.get("/feedback")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_list_feedback():
    q = Feedback.query.order_by(Feedback.created_at.desc())
    return jsonify(
        paginate(
            q,
            lambda f: {
                "id": f.id,
                "userId": f.user_id,
                "rating": f.rating,
                "createdAt": f.created_at.isoformat() if f.created_at else None,
            },
        )
    )


@bp.get("/feedback/<int:fb_id>")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def admin_get_feedback(fb_id: int):
    f = Feedback.query.get(fb_id)
    if not f:
        raise NotFound("Feedback not found")
    return jsonify({
        "id": f.id,
        "userId": f.user_id,
        "rating": f.rating,
        "comment": f.comment,
        "createdAt": f.created_at.isoformat() if f.created_at else None,
    })

@bp.post("/knowledge/upload")
@require_auth(admin=True)
def upload_knowledge():
    if "file" not in request.files:
        raise BadRequest("Missing file")

    expected_dim = current_app.config.get("EMBEDDING_DIMENSION")
    model_name = current_app.config.get("EMBEDDING_MODEL_NAME")
    
    if not expected_dim or not model_name:
        current_app.logger.error(
            "Embedding configuration incomplete: dim=%s model=%s",
            expected_dim,
            model_name,
        )
        raise BadRequest(
            "Embedding configuration is incomplete. Please set EMBEDDING_DIMENSION "
            "and EMBEDDING_MODEL in environment variables."
        )

    f = request.files["file"]
    if not f.filename:
        raise BadRequest("Missing file name")

    ext = (f.filename or "").rsplit(".", 1)[-1].lower()
    if ext == "doc":
        ext = "docx"

    supported = {
        "txt", "csv", "tsv", "json",
        "pdf", "docx",
        "xlsx",
        "png", "jpg", "jpeg", "svg",
    }
    if ext not in supported:
        raise BadRequest("Unsupported document type for ingestion")

    stream = f.stream
    stream.seek(0)
    hasher = hashlib.sha256()
    total_bytes = 0

    for chunk in iter(lambda: stream.read(8192), b""):
        if not chunk:
            break
        hasher.update(chunk)
        total_bytes += len(chunk)

    stream.seek(0)

    if total_bytes == 0:
        raise BadRequest("File is empty. Please upload a non-empty document.")

    content_hash = hasher.hexdigest()


    existing = KnowledgeSource.query.filter_by(content_hash=content_hash).first()
    if existing is not None:
        raise BadRequest("A document with the same content has already been uploaded.")

    path = StorageService.save_file(f, "knowledge")

    src = KnowledgeSource(
        title=f.filename,
        source_type=ext,
        file_path=path,
        language=request.form.get("language", "en"),
        status="queued",
        error_message=None,
        content_hash=content_hash,
        retry_count=0,
    )
    db.session.add(src)
    db.session.commit()

    ingest_source.delay(src.id)
    return jsonify({"id": src.id}), 201

@bp.post("/knowledge/url")
@require_auth(admin=True)
def ingest_url():
    d = request.get_json() or {}
    if not d.get("url") or not d.get("title"):
        raise BadRequest("url and title required")

    src = KnowledgeSource(
        title=d["title"],
        source_type="url",
        url=d["url"],
        language=d.get("language","en")
    )
    db.session.add(src); db.session.commit()
    ingest_source.delay(src.id)
    return jsonify({"id": src.id}), 201

@bp.get("/knowledge/sources")
@require_auth(admin=True)
def list_sources():
    q = KnowledgeSource.query.order_by(KnowledgeSource.created_at.desc()).all()
    return jsonify([{
        "id": s.id,
        "title": s.title,
        "type": s.source_type,
        "language": s.language,
        "status": s.status,
        "errorMessage": s.error_message,
        "createdAt": s.created_at.isoformat(),
        "updatedAt": s.updated_at.isoformat(),
    } for s in q])

@bp.post("/knowledge/sources/<int:sid>/retry")
@require_auth(admin=True)
def retry_source(sid: int):
    """
    Manually trigger re-ingestion for a knowledge source.

    Rules:
      - status == "invalid": cannot be retried (permanent input problem)
      - status == "done": nothing to do
      - otherwise (queued / failed / processing / other): allow retry
      - automatic watchdog still respects retry_count < 10
      - admin can click retry any number of times; each attempt will be counted
    """
    src = KnowledgeSource.query.get(sid)
    if not src:
        raise NotFound("Knowledge source not found")

    if src.status == "invalid":
        raise BadRequest("This source is invalid and cannot be retried.")

    if src.status == "done":
        raise BadRequest("This source is already ingested (done) and cannot be retried.")

    if src.status not in ("queued", "failed"):
        raise BadRequest("Retry is only allowed when status is queued or failed.")

    if (src.retry_count or 0) >= MAX_INGEST_RETRIES:
        raise BadRequest(f"Retry limit reached ({MAX_INGEST_RETRIES}).")

    src.status = "queued"
    db.session.commit()

    ingest_source.delay(src.id)
    return jsonify({"ok": True})

@bp.delete("/knowledge/sources/<int:sid>")
@require_auth(admin=True)
def delete_source(sid):
    KnowledgeSource.query.filter_by(id=sid).delete()
    db.session.commit()
    return jsonify({"ok": True})

@bp.get("/rag/metrics/summary")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def rag_metrics_summary():
    """
    Get high-level RAG performance summary.
    
    Returns aggregated metrics for dashboard view.
    """
    from sqlalchemy import func
    
    try:
        days = int(request.args.get("days", 7))
        days = max(1, min(days, 90)) 
    except ValueError:
        days = 7
    
    from datetime import datetime, timedelta
    cutoff = datetime.utcnow() - timedelta(days=days)
    
    q = RAGEvaluationLog.query.filter(RAGEvaluationLog.created_at >= cutoff)
    
    total_queries = q.count()
    
    if total_queries == 0:
        return jsonify({
            "period": f"Last {days} days",
            "totalQueries": 0,
            "summary": "No data available for this period"
        })
    
    decisions = (
        db.session.query(
            RAGEvaluationLog.decision,
            func.count(RAGEvaluationLog.id).label("count")
        )
        .filter(RAGEvaluationLog.created_at >= cutoff)
        .group_by(RAGEvaluationLog.decision)
        .all()
    )
    
    decision_stats = {d.decision: d.count for d in decisions}
    
    avg_total_time = (
        db.session.query(func.avg(RAGEvaluationLog.total_time_ms))
        .filter(RAGEvaluationLog.created_at >= cutoff)
        .scalar() or 0
    )
    
    avg_embedding_time = (
        db.session.query(func.avg(RAGEvaluationLog.embedding_time_ms))
        .filter(RAGEvaluationLog.created_at >= cutoff)
        .scalar() or 0
    )
    
    avg_llm_time = (
        db.session.query(func.avg(RAGEvaluationLog.llm_time_ms))
        .filter(
            RAGEvaluationLog.created_at >= cutoff,
            RAGEvaluationLog.llm_time_ms.isnot(None)
        )
        .scalar() or 0
    )
    
    total_tokens_used = (
        db.session.query(func.sum(RAGEvaluationLog.total_tokens))
        .filter(
            RAGEvaluationLog.created_at >= cutoff,
            RAGEvaluationLog.total_tokens.isnot(None)
        )
        .scalar() or 0
    )
    
    avg_tokens_per_query = (
        db.session.query(func.avg(RAGEvaluationLog.total_tokens))
        .filter(
            RAGEvaluationLog.created_at >= cutoff,
            RAGEvaluationLog.total_tokens.isnot(None)
        )
        .scalar() or 0
    )
    
    in_domain_count = q.filter_by(in_domain=True).count()
    fallback_count = q.filter_by(used_fallback=True).count()
    error_count = q.filter_by(error_occurred=True).count()
    
    avg_distance = (
        db.session.query(func.avg(RAGEvaluationLog.best_distance))
        .filter(
            RAGEvaluationLog.created_at >= cutoff,
            RAGEvaluationLog.in_domain == True,
            RAGEvaluationLog.best_distance.isnot(None)
        )
        .scalar() or 0
    )
    
    avg_contexts = (
        db.session.query(func.avg(RAGEvaluationLog.contexts_used))
        .filter(RAGEvaluationLog.created_at >= cutoff)
        .scalar() or 0
    )
    
    return jsonify({
        "period": f"Last {days} days",
        "totalQueries": total_queries,
        
        "decisions": {
            "answer": decision_stats.get("ANSWER", 0),
            "outOfDomain": decision_stats.get("OUT_OF_DOMAIN", 0),
            "noHits": decision_stats.get("NO_HITS", 0),
        },
        
        "quality": {
            "inDomainRate": round(in_domain_count / total_queries * 100, 2),
            "fallbackRate": round(fallback_count / total_queries * 100, 2),
            "errorRate": round(error_count / total_queries * 100, 2),
            "avgDistance": round(avg_distance, 4),
            "avgContextsUsed": round(avg_contexts, 2),
        },
        
        "performance": {
            "avgTotalTimeMs": round(avg_total_time, 0),
            "avgEmbeddingTimeMs": round(avg_embedding_time, 0),
            "avgLlmTimeMs": round(avg_llm_time, 0),
        },
        
        "tokens": {
            "totalUsed": int(total_tokens_used),
            "avgPerQuery": round(avg_tokens_per_query, 0),
        },
    })


@bp.get("/rag/metrics/queries")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def rag_metrics_queries():
    """
    Get detailed query logs with pagination.
    
    Query params:
    - page: page number (default 1)
    - perPage: items per page (default 20, max 100)
    - decision: filter by decision type (ANSWER|OUT_OF_DOMAIN|NO_HITS)
    - inDomain: filter by in_domain (true|false)
    - minTime: filter by minimum total_time_ms
    - days: time range in days (default 7)
    """
    from datetime import datetime, timedelta
    
    try:
        days = int(request.args.get("days", 7))
        days = max(1, min(days, 90))
    except ValueError:
        days = 7
    
    cutoff = datetime.utcnow() - timedelta(days=days)
    
    q = RAGEvaluationLog.query.filter(RAGEvaluationLog.created_at >= cutoff)
    
    decision = request.args.get("decision")
    if decision in {"ANSWER", "OUT_OF_DOMAIN", "NO_HITS"}:
        q = q.filter_by(decision=decision)
    
    in_domain = request.args.get("inDomain")
    if in_domain in {"true", "false"}:
        q = q.filter_by(in_domain=(in_domain == "true"))
    
    min_time = request.args.get("minTime")
    if min_time:
        try:
            q = q.filter(RAGEvaluationLog.total_time_ms >= int(min_time))
        except ValueError:
            pass
    
    q = q.order_by(RAGEvaluationLog.created_at.desc())
    
    return jsonify(
        paginate(
            q,
            lambda log: {
                "id": log.id,
                "userId": log.user_id,
                "conversationId": log.conversation_id,
                "language": log.language,
                "safeMode": log.safe_mode,
                
                "question": log.question_text[:200] + "..." if len(log.question_text) > 200 else log.question_text,
                "questionLength": log.question_length,
                
                "decision": log.decision,
                "inDomain": log.in_domain,
                "usedFallback": log.used_fallback,
                
                "contextsFound": log.contexts_found,
                "contextsUsed": log.contexts_used,
                "threshold": round(log.threshold_used, 4),
                "bestDistance": round(log.best_distance, 4) if log.best_distance else None,
                
                "totalTimeMs": log.total_time_ms,
                "embeddingTimeMs": log.embedding_time_ms,
                "llmTimeMs": log.llm_time_ms,
                
                "totalTokens": log.total_tokens,
                
                "errorOccurred": log.error_occurred,
                "errorType": log.error_type,
                
                "createdAt": log.created_at.isoformat(),
            },
        )
    )


@bp.get("/rag/metrics/queries/<int:query_id>")
@require_auth(admin=True)
@limiter.limit("60 per minute")
def rag_metrics_query_detail(query_id: int):
    """
    Get full details of a specific query evaluation.
    
    Includes full question, answer, and source attribution.
    """
    log = RAGEvaluationLog.query.get(query_id)
    if not log:
        raise NotFound("Query log not found")
    
    return jsonify({
        "id": log.id,
        "userId": log.user_id,
        "conversationId": log.conversation_id,
        "language": log.language,
        "safeMode": log.safe_mode,
        "isNewConversation": log.is_new_conversation,
        
        "question": {
            "text": log.question_text,
            "length": log.question_length,
        },
        
        "answer": {
            "text": log.answer_text,
            "length": log.answer_length,
            "usedFallback": log.used_fallback,
            "disclaimerAdded": log.disclaimer_added,
        },
        
        "rag": {
            "threshold": log.threshold_used,
            "bestDistance": log.best_distance,
            "contextsFound": log.contexts_found,
            "contextsUsed": log.contexts_used,
            "inDomain": log.in_domain,
            "decision": log.decision,
        },
        
        "sources": {
            "chunkIds": log.source_chunk_ids or [],
            "titles": log.source_titles or [],
        },
        
        "performance": {
            "embeddingTimeMs": log.embedding_time_ms,
            "llmTimeMs": log.llm_time_ms,
            "totalTimeMs": log.total_time_ms,
        },
        
        "tokens": {
            "prompt": log.prompt_tokens,
            "completion": log.completion_tokens,
            "total": log.total_tokens,
        },
        
        "models": {
            "embedding": log.embedding_model,
            "embeddingDimension": log.embedding_dimension,
            "chat": log.chat_model,
        },
        
        "error": {
            "occurred": log.error_occurred,
            "type": log.error_type,
            "message": log.error_message,
        } if log.error_occurred else None,
        
        "createdAt": log.created_at.isoformat(),
    })