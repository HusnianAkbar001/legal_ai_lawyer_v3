from datetime import datetime
from sqlalchemy import func
from ..extensions import db


class ChatConversation(db.Model):
    __tablename__ = "chat_conversations"

    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    title = db.Column(db.String(200), nullable=False, default="Chat")
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(
        db.DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    messages = db.relationship(
        "ChatMessage",
        backref="conversation",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="ChatMessage.created_at.asc()",
    )


class ChatMessage(db.Model):
    __tablename__ = "chat_messages"

    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    conversation_id = db.Column(
        db.BigInteger,
        db.ForeignKey("chat_conversations.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    role = db.Column(db.String(10), nullable=False) 
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    @staticmethod
    def add_and_trim(
        *,
        user_id: int,
        conversation_id: int,
        role: str,
        content: str,
        max_messages: int = 100,
        commit: bool = False,
    ):
        """
        Append message and keep only latest N per conversation.
        commit=False lets caller commit once for atomicity.
        """
        db.session.add(
            ChatMessage(
                user_id=user_id,
                conversation_id=conversation_id,
                role=role,
                content=content,
            )
        )
        db.session.flush()

        subq = (
            ChatMessage.query
            .filter_by(user_id=user_id, conversation_id=conversation_id)
            .order_by(ChatMessage.created_at.desc())
            .offset(max_messages)
            .with_entities(ChatMessage.id)
            .subquery()
        )
        ChatMessage.query.filter(ChatMessage.id.in_(subq)).delete(
            synchronize_session=False
        )

        ChatConversation.query.filter_by(id=conversation_id).update(
            {"updated_at": datetime.utcnow()}
        )

        if commit:
            db.session.commit()