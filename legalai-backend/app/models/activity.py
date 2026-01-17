from datetime import datetime
from ..extensions import db
from sqlalchemy import JSON
from sqlalchemy.dialects.postgresql import JSONB

class Bookmark(db.Model):
    __tablename__ = "bookmarks"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True)
    item_type = db.Column(db.String(20), nullable=False)
    item_id = db.Column(db.BigInteger, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class ActivityEvent(db.Model):
    __tablename__ = "activity_events"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True)
    event_type = db.Column(db.String(30), nullable=False)
    payload = db.Column(JSON().with_variant(JSONB, "postgresql"), default=dict)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
