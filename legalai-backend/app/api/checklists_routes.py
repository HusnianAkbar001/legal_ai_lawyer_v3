from flask import Blueprint, request, jsonify, g
from ._auth_guard import require_auth
from werkzeug.exceptions import BadRequest
from ..models.content import ChecklistCategory, ChecklistItem
from ..extensions import db

bp = Blueprint("checklists", __name__)

@bp.get("/categories")
def list_categories():
    cats = ChecklistCategory.query.order_by(ChecklistCategory.order.asc()).all()
    return jsonify([{"id": c.id, "title": c.title, "icon": c.icon, "order": c.order} for c in cats])

@bp.get("/items")
def list_items():
    cid = request.args.get("categoryId")
    q = ChecklistItem.query
    if cid:
        q = q.filter_by(category_id=int(cid))
    q = q.order_by(ChecklistItem.order.asc()).all()
    return jsonify([{
        "id": i.id, "categoryId": i.category_id,
        "text": i.text, "required": i.required, "order": i.order
    } for i in q])

@bp.post("/categories")
@require_auth(admin=True)
def create_category():
    d = request.get_json() or {}
    if not d.get("title"):
        raise BadRequest("title required")
    c = ChecklistCategory(title=d["title"], icon=d.get("icon"), order=d.get("order",0))
    db.session.add(c); db.session.commit()
    return jsonify({"id": c.id}), 201

@bp.put("/categories/<int:cid>")
@require_auth(admin=True)
def update_category(cid):
    c = ChecklistCategory.query.get_or_404(cid)
    d = request.get_json() or {}
    for k in ["title","icon","order"]:
        if k in d:
            setattr(c, k, d[k])
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/categories/<int:cid>")
@require_auth(admin=True)
def delete_category(cid):
    ChecklistCategory.query.filter_by(id=cid).delete()
    db.session.commit()
    return jsonify({"ok": True})

@bp.post("/items")
@require_auth(admin=True)
def create_item():
    d = request.get_json() or {}
    if not d.get("categoryId") or not d.get("text"):
        raise BadRequest("categoryId and text required")
    i = ChecklistItem(
        category_id=int(d["categoryId"]), text=d["text"],
        required=bool(d.get("required",False)), order=d.get("order",0)
    )
    db.session.add(i); db.session.commit()
    return jsonify({"id": i.id}), 201

@bp.put("/items/<int:iid>")
@require_auth(admin=True)
def update_item(iid):
    i = ChecklistItem.query.get_or_404(iid)
    d = request.get_json() or {}
    for k, attr in [("text","text"),("required","required"),("order","order"),("categoryId","category_id")]:
        if k in d:
            setattr(i, attr, d[k])
    db.session.commit()
    return jsonify({"ok": True})

@bp.delete("/items/<int:iid>")
@require_auth(admin=True)
def delete_item(iid):
    ChecklistItem.query.filter_by(id=iid).delete()
    db.session.commit()
    return jsonify({"ok": True})
