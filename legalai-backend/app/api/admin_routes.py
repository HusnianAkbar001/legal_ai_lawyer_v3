import hashlib

from flask import Blueprint, jsonify, request, g
from werkzeug.exceptions import BadRequest, NotFound, Conflict
from werkzeug.utils import secure_filename
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
    # Broad practice-area taxonomy commonly used across Pakistan firms/directories.
    # Can be overridden via LAWYER_CATEGORIES_JSON in env.
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
    # Fallback if env is invalid
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

    # Admin sets password (confirmed)
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

    # Add audit event in the same transaction (no PII in payload)
    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="USER_CREATED",
            payload={"targetUserId": None},  # fill after flush
        )
    )

    try:
        # Ensure u.id exists before commit so payload can store targetUserId
        db.session.flush()

        # Update the last added ActivityEvent payload now that u.id exists
        # (keeps a single atomic commit)
        db.session.query(ActivityEvent).order_by(ActivityEvent.id.desc()).limit(1).update(
            {ActivityEvent.payload: {"targetUserId": u.id}}
        )

        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        raise Conflict("User already exists (email or CNIC).")

    # Send verification email so user can login after verifying
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

    # Optional password reset by admin
    if "password" in d and d["password"]:
        validate_password(d["password"])
        u.password_hash = hash_password(d["password"])
        # invalidate old tokens
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
        return jsonify({"ok": True})  # idempotent

    u.is_deleted = True
    u.deleted_at = datetime.utcnow()
    u.deleted_by = g.user.id

    # force logout everywhere
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
    # multipart/form-data required: file + fields
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

    # Mandatory picture; store relative DB-safe path
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

    # Safe audit log (no PII)
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

    # accept multipart (optional file) OR JSON
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

    # Basic required fields must remain non-empty
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
        return jsonify({"ok": True})  # idempotent

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
                # description intentionally excluded from list view
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
                # comment excluded from list view
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

    f = request.files["file"]
    if not f.filename:
        raise BadRequest("Missing file name")

    ext = (f.filename or "").rsplit(".", 1)[-1].lower()
    if ext == "doc":
        ext = "docx"

    # Only these types are supported for ingestion
    supported = {
        "txt", "csv", "tsv", "json",
        "pdf", "docx",
        "xlsx",
        "png", "jpg", "jpeg", "svg",
    }
    if ext not in supported:
        raise BadRequest("Unsupported document type for ingestion")

    # Compute content hash for deduplication and empty-file detection
    stream = f.stream
    stream.seek(0)
    hasher = hashlib.sha256()
    total_bytes = 0

    for chunk in iter(lambda: stream.read(8192), b""):
        if not chunk:
            break
        hasher.update(chunk)
        total_bytes += len(chunk)

    # Reset stream so StorageService can read it normally
    stream.seek(0)

    if total_bytes == 0:
        raise BadRequest("File is empty. Please upload a non-empty document.")

    content_hash = hasher.hexdigest()


    # Reject duplicates (same content already ingested or attempted)
    existing = KnowledgeSource.query.filter_by(content_hash=content_hash).first()
    if existing is not None:
        raise BadRequest("A document with the same content has already been uploaded.")

    # Save file to storage (size, extension, and content checks happen inside)
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

    # Only allow manual retry for queued/failed (matches UI + avoids inconsistent states)
    if src.status not in ("queued", "failed"):
        raise BadRequest("Retry is only allowed when status is queued or failed.")

    # Enforce same retry limit as watchdog
    if (src.retry_count or 0) >= MAX_INGEST_RETRIES:
        raise BadRequest(f"Retry limit reached ({MAX_INGEST_RETRIES}).")

    # Put back into queued state for the next ingestion attempt
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
