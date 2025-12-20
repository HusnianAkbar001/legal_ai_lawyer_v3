from datetime import datetime
from app.extensions import db


class ContactMessage(db.Model):
    __tablename__ = "contact_messages"

    id = db.Column(db.BigInteger, primary_key=True)

    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )

    full_name = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(50), nullable=False)
    subject = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
