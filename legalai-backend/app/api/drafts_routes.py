from flask import Blueprint, request, jsonify, g, send_file
from werkzeug.exceptions import BadRequest, Forbidden
from ._auth_guard import require_auth, safe_mode_on
from ..services.docify_service import DocifyService
from ..services.export_service import ExportService
from ..models.drafts import Draft
from ..extensions import db
import os
from flask import current_app

bp = Blueprint("drafts", __name__)

@bp.post("/generate")
@require_auth()
def generate():
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")
    d = request.get_json() or {}
    if not d.get("templateId") or not isinstance(d.get("answers"), dict):
        raise BadRequest("templateId and answers required")
    if not isinstance(d.get("userSnapshot"), dict):
        raise BadRequest("userSnapshot required")

    draft = DocifyService.generate(g.user, int(d["templateId"]), d["answers"], d["userSnapshot"])
    return jsonify({
        "id": draft.id, "title": draft.title, "contentText": draft.content_text,
        "createdAt": draft.created_at.isoformat()
    }), 201

@bp.get("")
@require_auth()
def list_drafts():
    q = Draft.query.filter_by(user_id=g.user.id).order_by(Draft.created_at.desc()).all()
    return jsonify([{
        "id": dr.id, "title": dr.title, "createdAt": dr.created_at.isoformat()
    } for dr in q])

@bp.get("/<int:did>")
@require_auth()
def get_draft(did):
    dr = Draft.query.get_or_404(did)
    if dr.user_id != g.user.id:
        raise Forbidden("Not yours")
    return jsonify({
        "id": dr.id, "title": dr.title, "contentText": dr.content_text,
        "answers": dr.answers, "userSnapshot": dr.user_snapshot,
        "createdAt": dr.created_at.isoformat()
    })

@bp.get("/<int:did>/export")
@require_auth()
def export_draft(did):
    dr = Draft.query.get_or_404(did)
    if dr.user_id != g.user.id:
        raise Forbidden("Not yours")

    fmt = request.args.get("format","txt")
    base = current_app.config["STORAGE_BASE"]

    if fmt == "txt":
        return jsonify({"text": ExportService.export_txt(dr)})

    if fmt == "pdf":
        path = ExportService.export_pdf(dr)
        return send_file(path, as_attachment=True, download_name=f"{dr.title}.pdf")

    if fmt == "docx":
        path = ExportService.export_docx(dr)
        return send_file(path, as_attachment=True, download_name=f"{dr.title}.docx")

    raise BadRequest("Invalid format")

@bp.delete("/<int:did>")
@require_auth()
def delete_draft(did):
    if safe_mode_on():
        raise Forbidden("Safe mode enabled")
    Draft.query.filter_by(id=did, user_id=g.user.id).delete()
    db.session.commit()
    return jsonify({"ok": True})
