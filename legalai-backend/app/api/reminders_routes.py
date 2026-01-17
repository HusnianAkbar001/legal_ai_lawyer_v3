from flask import Blueprint, request, jsonify, g
from werkzeug.exceptions import BadRequest, Forbidden
from ._auth_guard import require_auth, safe_mode_on
from ..models.reminders import Reminder, DeviceToken
from ..extensions import db
from datetime import datetime
import dateutil.parser

bp = Blueprint("reminders", __name__)

@bp.post("")
@require_auth()
def create_reminder():
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")
    d = request.get_json() or {}
    if not d.get("title") or not d.get("scheduledAt"):
        raise BadRequest("title and scheduledAt required")

    scheduled = dateutil.parser.isoparse(d["scheduledAt"])
    r = Reminder(
        user_id=g.user.id,
        title=d["title"],
        notes=d.get("notes"),
        scheduled_at=scheduled,
        timezone=d.get("timezone") or g.user.timezone
    )
    db.session.add(r); db.session.commit()
    return jsonify({"id": r.id}), 201

@bp.get("")
@require_auth()
def list_reminders():
    q = Reminder.query.filter_by(user_id=g.user.id).order_by(Reminder.scheduled_at.asc()).all()
    return jsonify([{
        "id": r.id, "title": r.title, "notes": r.notes,
        "scheduledAt": r.scheduled_at.isoformat(),
        "timezone": r.timezone, "isDone": r.is_done
    } for r in q])

@bp.put("/<int:rid>")
@require_auth()
def update_reminder(rid):
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")
    r = Reminder.query.get_or_404(rid)
    if r.user_id != g.user.id:
        raise Forbidden("Not yours")
    d = request.get_json() or {}
    if "title" in d: r.title = d["title"]
    if "notes" in d: r.notes = d["notes"]
    if "scheduledAt" in d: r.scheduled_at = dateutil.parser.isoparse(d["scheduledAt"])
    if "timezone" in d: r.timezone = d["timezone"]
    if "isDone" in d: r.is_done = bool(d["isDone"])
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/<int:rid>")
@require_auth()
def delete_reminder(rid):
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")
    Reminder.query.filter_by(id=rid, user_id=g.user.id).delete()
    db.session.commit()
    return jsonify({"ok": True})

@bp.post("/register-device-token")
@require_auth()
def register_device():
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")
    d = request.get_json() or {}
    if d.get("platform") not in {"android","ios"} or not d.get("token"):
        raise BadRequest("platform and token required")

    DeviceToken.query.filter_by(token=d["token"]).delete()
    dt = DeviceToken(user_id=g.user.id, platform=d["platform"], token=d["token"])
    db.session.add(dt); db.session.commit()
    return jsonify({"ok": True})
