from datetime import datetime
from sqlalchemy import func
from app.extensions import db

class Lawyer(db.Model):
    __tablename__ = "lawyers"

    id = db.Column(db.BigInteger, primary_key=True)

    full_name = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(255), nullable=False, index=True)
    phone = db.Column(db.String(50), nullable=False)
    category = db.Column(db.String(120), nullable=False)

    profile_picture_path = db.Column(db.String(512), nullable=False)

    is_active = db.Column(db.Boolean, nullable=False, default=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(
        db.DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
