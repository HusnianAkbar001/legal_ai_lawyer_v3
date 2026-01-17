from datetime import datetime
from sqlalchemy.dialects.postgresql import ARRAY
from ..extensions import db


class RAGEvaluationLog(db.Model):
    """
    Production-grade RAG evaluation and monitoring.
    
    Tracks every RAG interaction for:
    - Quality analysis
    - Performance monitoring
    - Source attribution
    - Token usage tracking
    - Error diagnostics
    
    Access: Admin only (contains user questions/answers)
    """
    
    __tablename__ = "rag_evaluation_logs"
    
    id = db.Column(db.BigInteger, primary_key=True)
    
    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
    )
    conversation_id = db.Column(
        db.BigInteger,
        db.ForeignKey("chat_conversations.id", ondelete="SET NULL"),
        index=True,
    )
    language = db.Column(db.String(10), nullable=False)
    safe_mode = db.Column(db.Boolean, nullable=False)
    
    question_text = db.Column(db.Text, nullable=False)
    question_length = db.Column(db.Integer, nullable=False)
    answer_text = db.Column(db.Text, nullable=False)
    answer_length = db.Column(db.Integer, nullable=False)
    
    threshold_used = db.Column(db.Float, nullable=False)
    best_distance = db.Column(db.Float)
    contexts_found = db.Column(db.Integer, nullable=False)
    contexts_used = db.Column(db.Integer, nullable=False)
    in_domain = db.Column(db.Boolean, nullable=False)
    decision = db.Column(db.String(20), nullable=False)  
    
    source_chunk_ids = db.Column(ARRAY(db.BigInteger))
    source_titles = db.Column(ARRAY(db.Text))
    
    embedding_time_ms = db.Column(db.Integer, nullable=False)
    llm_time_ms = db.Column(db.Integer)
    total_time_ms = db.Column(db.Integer, nullable=False)
    
    prompt_tokens = db.Column(db.Integer)
    completion_tokens = db.Column(db.Integer)
    total_tokens = db.Column(db.Integer)
    
    embedding_model = db.Column(db.String(100), nullable=False)
    embedding_dimension = db.Column(db.Integer)
    chat_model = db.Column(db.String(100))
    
    used_fallback = db.Column(db.Boolean, nullable=False)
    disclaimer_added = db.Column(db.Boolean, nullable=False)
    is_new_conversation = db.Column(db.Boolean)
    
    error_occurred = db.Column(db.Boolean, nullable=False, default=False)
    error_type = db.Column(db.String(100))
    error_message = db.Column(db.Text)
    
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)