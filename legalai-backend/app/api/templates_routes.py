from flask import Blueprint, request, jsonify, g
from ._auth_guard import require_auth
from werkzeug.exceptions import BadRequest
from ..models.content import Template
from ..extensions import db

bp = Blueprint("templates", __name__)

@bp.get("")
@require_auth()
def list_templates():
    category = request.args.get("category")
    lang = (getattr(g.user, "language", None) or "en")

    q = Template.query.filter_by(language=lang)
    if category:
        q = q.filter_by(category=category)

    items = q.order_by(Template.updated_at.desc()).all()
    data = [{
        "id": t.id, "title": t.title, "description": t.description,
        "body": t.body, "category": t.category,
        "language": t.language, "tags": t.tags
    } for t in items]

    if not data:
        return jsonify({"data": [], "message": "Content not available in selected language"})
    return jsonify({"data": data, "message": None})

@bp.get("/<int:tid>")
@require_auth()
def get_template(tid):
    lang = (getattr(g.user, "language", None) or "en")
    t = Template.query.filter_by(id=tid, language=lang).first()
    if not t:
        return jsonify({"data": None, "message": "Content not available in selected language"}), 404

    return jsonify({
        "data": {
            "id": t.id, "title": t.title, "description": t.description,
            "body": t.body, "category": t.category,
            "language": t.language, "tags": t.tags
        },
        "message": None
    })

@bp.post("")
@require_auth(admin=True)
def create_template():
    d = request.get_json() or {}
    if not d.get("title") or not d.get("body"):
        raise BadRequest("title and body required")
    t = Template(
        title=d["title"], description=d.get("description"),
        body=d["body"], category=d.get("category"),
        language=d.get("language","en"), tags=d.get("tags",[])
    )
    db.session.add(t); db.session.commit()
    return jsonify({"id": t.id}), 201

@bp.put("/<int:tid>")
@require_auth(admin=True)
def update_template(tid):
    t = Template.query.get_or_404(tid)
    d = request.get_json() or {}
    for k in ["title","description","body","category","language","tags"]:
        if k in d:
            setattr(t, k, d[k])
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/<int:tid>")
@require_auth(admin=True)
def delete_template(tid):
    Template.query.filter_by(id=tid).delete()
    db.session.commit()
    return jsonify({"ok": True})
