from datetime import datetime
from app.extensions import db


class Feedback(db.Model):
    __tablename__ = "feedback"

    id = db.Column(db.BigInteger, primary_key=True)

    user_id = db.Column(
        db.BigInteger,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    rating = db.Column(db.Integer, nullable=False)  # 1..5
    comment = db.Column(db.Text, nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
