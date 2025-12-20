from datetime import datetime
from ..extensions import db
from sqlalchemy import JSON
from sqlalchemy.dialects.postgresql import JSONB

class Right(db.Model):
    __tablename__ = "rights"
    id = db.Column(db.BigInteger, primary_key=True)
    topic = db.Column(db.String(200), nullable=False, index=True)
    body = db.Column(db.Text, nullable=False)
    category = db.Column(db.String(120), index=True)
    language = db.Column(db.String(10), default="en")  # en/ur
    tags = db.Column(db.ARRAY(db.String), default=[])

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)

class Template(db.Model):
    __tablename__ = "templates"
    id = db.Column(db.BigInteger, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    body = db.Column(db.Text, nullable=False)  # with placeholders
    category = db.Column(db.String(120), index=True)
    language = db.Column(db.String(10), default="en")
    tags = db.Column(db.ARRAY(db.String), default=[])

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)

class Pathway(db.Model):
    __tablename__ = "pathways"
    id = db.Column(db.BigInteger, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    summary = db.Column(db.Text)
    steps = db.Column(JSON().with_variant(JSONB, "postgresql"), nullable=False)  # list of steps, decisions etc.
    category = db.Column(db.String(120), index=True)
    language = db.Column(db.String(10), default="en")
    tags = db.Column(db.ARRAY(db.String), default=[])

class ChecklistCategory(db.Model):
    __tablename__ = "checklist_categories"
    id = db.Column(db.BigInteger, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    icon = db.Column(db.String(80))
    order = db.Column(db.Integer, default=0)

class ChecklistItem(db.Model):
    __tablename__ = "checklist_items"
    id = db.Column(db.BigInteger, primary_key=True)
    category_id = db.Column(db.BigInteger, db.ForeignKey("checklist_categories.id", ondelete="CASCADE"))
    text = db.Column(db.String(300), nullable=False)
    required = db.Column(db.Boolean, default=False)
    order = db.Column(db.Integer, default=0)
