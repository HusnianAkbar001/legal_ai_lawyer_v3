from flask import Blueprint, request, jsonify, g
from ._auth_guard import require_auth
from werkzeug.exceptions import BadRequest
from ..models.content import Right
from ..extensions import db

bp = Blueprint("rights", __name__)

@bp.get("")
@require_auth()
def list_rights():
    category = request.args.get("category")
    lang = (getattr(g.user, "language", None) or "en")

    q = Right.query.filter_by(language=lang)
    if category:
        q = q.filter_by(category=category)

    items = q.order_by(Right.updated_at.desc()).all()
    data = [{
        "id": r.id, "topic": r.topic, "body": r.body,
        "category": r.category, "language": r.language, "tags": r.tags
    } for r in items]

    if not data:
        return jsonify({"data": [], "message": "Content not available in selected language"})
    return jsonify({"data": data, "message": None})

@bp.get("/<int:rid>")
@require_auth()
def get_right(rid):
    lang = (getattr(g.user, "language", None) or "en")
    r = Right.query.filter_by(id=rid, language=lang).first()
    if not r:
        return jsonify({"data": None, "message": "Content not available in selected language"}), 404

    return jsonify({
        "data": {
            "id": r.id, "topic": r.topic, "body": r.body,
            "category": r.category, "language": r.language, "tags": r.tags
        },
        "message": None
    })

@bp.post("")
@require_auth(admin=True)
def create_right():
    d = request.get_json() or {}
    if not d.get("topic") or not d.get("body"):
        raise BadRequest("topic and body required")
    r = Right(
        topic=d["topic"], body=d["body"],
        category=d.get("category"), language=d.get("language","en"),
        tags=d.get("tags",[])
    )
    db.session.add(r); db.session.commit()
    return jsonify({"id": r.id}), 201

@bp.put("/<int:rid>")
@require_auth(admin=True)
def update_right(rid):
    r = Right.query.get_or_404(rid)
    d = request.get_json() or {}
    for k in ["topic","body","category","language","tags"]:
        if k in d:
            setattr(r, k, d[k])
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/<int:rid>")
@require_auth(admin=True)
def delete_right(rid):
    Right.query.filter_by(id=rid).delete()
    db.session.commit()
    return jsonify({"ok": True})
