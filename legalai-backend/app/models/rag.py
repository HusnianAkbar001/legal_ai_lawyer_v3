from datetime import datetime
from pgvector.sqlalchemy import Vector
from ..extensions import db
from sqlalchemy import func

class KnowledgeSource(db.Model):
    __tablename__ = "knowledge_sources"
    id = db.Column(db.BigInteger, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    source_type = db.Column(db.String(20), nullable=False)
    file_path = db.Column(db.String(512))
    url = db.Column(db.Text)
    language = db.Column(db.String(10), default="en")
    content_hash = db.Column(db.String(64), unique=True, nullable=True)
    embedding_model = db.Column(db.String(100))
    embedding_dimension = db.Column(db.Integer)
    status = db.Column(db.String(20), default="queued", nullable=False)
    error_message = db.Column(db.Text)
    retry_count = db.Column(db.Integer, nullable=False, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(
        db.DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class KnowledgeChunk(db.Model):
    __tablename__ = "knowledge_chunks"
    id = db.Column(db.BigInteger, primary_key=True)
    source_id = db.Column(db.BigInteger, db.ForeignKey("knowledge_sources.id", ondelete="CASCADE"))
    chunk_text = db.Column(db.Text, nullable=False)
    embedding = db.Column(Vector())
    embedding_model = db.Column(db.String(100))
    embedding_dimension = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
