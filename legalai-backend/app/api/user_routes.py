from flask import Blueprint, request, jsonify, g
from werkzeug.exceptions import BadRequest
from ._auth_guard import require_auth, safe_mode_on
from ..models.user import User
from ..models.activity import Bookmark, ActivityEvent
from ..services.storage_service import StorageService
from ..extensions import db, limiter

bp = Blueprint("users", __name__)

@bp.get("/me")
@require_auth()
def me():
    u: User = g.user
    return jsonify({
        "id": u.id, "name": u.name, "email": u.email, "phone": u.phone, "cnic": u.cnic,
        "fatherName": u.father_name, "fatherCnic": u.father_cnic,
        "motherName": u.mother_name, "motherCnic": u.mother_cnic,
        "city": u.city, "gender": u.gender, "age": u.age,
        "totalSiblings": u.total_siblings, "brothers": u.brothers, "sisters": u.sisters,
        "avatarPath": u.avatar_path, "timezone": u.timezone, "language": u.language,
        "isAdmin": u.is_admin, "isEmailVerified": u.is_email_verified
    })

@bp.put("/me")
@require_auth()
@limiter.limit("30 per minute")
def update_me():
    if safe_mode_on():
        return jsonify({"ok": False, "reason": "Safe mode"}), 403

    data = request.get_json() or {}
    u: User = g.user

    for k, attr in [
        ("name","name"),("phone","phone"),("cnic","cnic"),
        ("fatherName","father_name"),("fatherCnic","father_cnic"),
        ("motherName","mother_name"),("motherCnic","mother_cnic"),
        ("city","city"),("gender","gender"),("age","age"),
        ("totalSiblings","total_siblings"),("brothers","brothers"),("sisters","sisters"),
        ("timezone","timezone"), ("language","language")
    ]:
        if k in data:
            setattr(u, attr, data[k])
    if "language" in data:
        lang = str(data.get("language") or "").strip().lower()
        if lang not in {"en", "ur"}:
            raise BadRequest("Invalid language")
        u.language = lang
    db.session.commit()
    return jsonify({"ok": True})

@bp.post("/me/avatar")
@limiter.limit("10 per minute")
@require_auth()
def upload_avatar():
    if safe_mode_on():
        return jsonify({"ok": False, "reason": "Safe mode"}), 403

    if "file" not in request.files:
        raise BadRequest("Missing file")
    path = StorageService.save_file(request.files["file"], "avatars")
    g.user.avatar_path = StorageService.public_path(path)
    db.session.commit()
    db.session.add(
        ActivityEvent(
            user_id=g.user.id,
            event_type="PROFILE_IMAGE_UPDATED",
            payload={},
        )
    )
    db.session.commit()
    return jsonify({"avatarPath": g.user.avatar_path})

@bp.post("/me/bookmarks")
@require_auth()
def add_bookmark():
    if safe_mode_on():
        return jsonify({"ok": False, "reason": "Safe mode"}), 403

    d = request.get_json() or {}
    if d.get("itemType") not in {"right","template","pathway"}:
        raise BadRequest("Invalid itemType")

    bm = Bookmark(user_id=g.user.id, item_type=d["itemType"], item_id=int(d["itemId"]))
    db.session.add(bm); db.session.commit()
    return jsonify({"id": bm.id}), 201

@bp.get("/me/bookmarks")
@require_auth()
def list_bookmarks():
    q = Bookmark.query.filter_by(user_id=g.user.id).order_by(Bookmark.created_at.desc()).all()
    return jsonify([{"id": b.id, "itemType": b.item_type, "itemId": b.item_id} for b in q])

@bp.delete("/me/bookmarks/<int:bid>")
@require_auth()
def delete_bookmark(bid):
    if safe_mode_on():
        return jsonify({"ok": False, "reason": "Safe mode"}), 403
    Bookmark.query.filter_by(id=bid, user_id=g.user.id).delete()
    db.session.commit()
    return jsonify({"ok": True})

@bp.post("/me/activity")
@require_auth()
def log_activity():
    if safe_mode_on():
        return jsonify({"ok": True}) 
    d = request.get_json() or {}
    ev = ActivityEvent(user_id=g.user.id, event_type=d.get("eventType","unknown"), payload=d.get("payload",{}))
    db.session.add(ev); db.session.commit()
    return jsonify({"ok": True})

@bp.get("/me/activity")
@require_auth()
def get_activity():
    q = (ActivityEvent.query.filter_by(user_id=g.user.id)
         .order_by(ActivityEvent.created_at.desc()).limit(50).all())
    return jsonify([{"type": e.event_type, "payload": e.payload, "createdAt": e.created_at.isoformat()} for e in q])
