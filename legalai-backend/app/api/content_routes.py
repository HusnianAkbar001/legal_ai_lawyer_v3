from flask import Blueprint, jsonify, current_app
from ..models.content import Right, Template  # adjust if your model names differ
from ..extensions import db

bp = Blueprint("content", __name__)

@bp.get("/manifest")
def manifest():
    """
    Manifest format expected by ContentSyncService:
    {
      "version": <int>,
      "files": {
        "rights": {"url": "..."},
        "templates": {"url": "..."}
      }
    }
    """
    version = current_app.config.get("CONTENT_VERSION", 1)
    return jsonify({
        "version": int(version),
        "files": {
            "rights": {"url": "/api/v1/content/rights.json"},
            "templates": {"url": "/api/v1/content/templates.json"}
        }
    })

@bp.get("/rights.json")
def rights_json():
    rights = Right.query.order_by(Right.updated_at.desc()).all()
    return jsonify([{
        "id": r.id,
        "topic": r.topic,
        "body": r.body,
        "category": r.category,
        "language": r.language,
        "tags": r.tags
    } for r in rights])

@bp.get("/templates.json")
def templates_json():
    templates = Template.query.order_by(Template.updated_at.desc()).all()
    return jsonify([{
        "id": t.id,
        "title": t.title,
        "category": t.category,
        "summary": t.summary,
        "body": t.body
    } for t in templates])
