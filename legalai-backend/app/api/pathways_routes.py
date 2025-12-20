from flask import Blueprint, request, jsonify, g
from ._auth_guard import require_auth
from werkzeug.exceptions import BadRequest
from ..models.content import Pathway
from ..extensions import db

bp = Blueprint("pathways", __name__)

@bp.get("")
@require_auth()
def list_pathways():
    category = request.args.get("category")
    lang = (getattr(g.user, "language", None) or "en")

    q = Pathway.query.filter_by(language=lang)
    if category:
        q = q.filter_by(category=category)

    items = q.order_by(Pathway.id.desc()).all()
    data = [{
        "id": p.id, "title": p.title, "summary": p.summary,
        "steps": p.steps, "category": p.category,
        "language": p.language, "tags": p.tags
    } for p in items]

    if not data:
        return jsonify({"data": [], "message": "Content not available in selected language"})
    return jsonify({"data": data, "message": None})

@bp.get("/<int:pid>")
@require_auth()
def get_pathway(pid):
    lang = (getattr(g.user, "language", None) or "en")
    p = Pathway.query.filter_by(id=pid, language=lang).first()
    if not p:
        return jsonify({"data": None, "message": "Content not available in selected language"}), 404

    return jsonify({
        "data": {
            "id": p.id, "title": p.title, "summary": p.summary,
            "steps": p.steps, "category": p.category,
            "language": p.language, "tags": p.tags
        },
        "message": None
    })

@bp.post("")
@require_auth(admin=True)
def create_pathway():
    d = request.get_json() or {}
    if not d.get("title") or not isinstance(d.get("steps"), list):
        raise BadRequest("title and steps(list) required")
    p = Pathway(
        title=d["title"], summary=d.get("summary"),
        steps=d["steps"], category=d.get("category"),
        language=d.get("language","en"), tags=d.get("tags",[])
    )
    db.session.add(p); db.session.commit()
    return jsonify({"id": p.id}), 201

@bp.put("/<int:pid>")
@require_auth(admin=True)
def update_pathway(pid):
    p = Pathway.query.get_or_404(pid)
    d = request.get_json() or {}
    for k in ["title","summary","steps","category","language","tags"]:
        if k in d:
            setattr(p, k, d[k])
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/<int:pid>")
@require_auth(admin=True)
def delete_pathway(pid):
    Pathway.query.filter_by(id=pid).delete()
    db.session.commit()
    return jsonify({"ok": True})
