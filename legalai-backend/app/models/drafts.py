from datetime import datetime
from ..extensions import db
from sqlalchemy import JSON
from sqlalchemy.dialects.postgresql import JSONB

class Draft(db.Model):
    __tablename__ = "drafts"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True)
    template_id = db.Column(db.BigInteger, db.ForeignKey("templates.id"), index=True)

    title = db.Column(db.String(200), nullable=False)
    content_text = db.Column(db.Text, nullable=False)

    # export paths (created on demand)
    pdf_path = db.Column(db.String(512))
    docx_path = db.Column(db.String(512))

    # answers snapshot (option B)
    answers = db.Column(JSON().with_variant(JSONB, "postgresql"), nullable=False)
    user_snapshot = db.Column(JSON().with_variant(JSONB, "postgresql"), nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
