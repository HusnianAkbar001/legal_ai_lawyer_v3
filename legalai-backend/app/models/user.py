from datetime import datetime
from sqlalchemy import func
from ..extensions import db

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.BigInteger, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(255), nullable=False, unique=True, index=True)
    phone = db.Column(db.String(30), nullable=False)
    cnic = db.Column(db.String(30), nullable=False, unique=True, index=True)

    father_name = db.Column(db.String(120))
    father_cnic = db.Column(db.String(30))
    mother_name = db.Column(db.String(120))
    mother_cnic = db.Column(db.String(30))

    city = db.Column(db.String(120))
    gender = db.Column(db.String(30))
    age = db.Column(db.Integer)
    province = db.Column(db.String(30), nullable=False, index=True)
    total_siblings = db.Column(db.Integer, default=0)
    brothers = db.Column(db.Integer, default=0)
    sisters = db.Column(db.Integer, default=0)

    password_hash = db.Column(db.String(255), nullable=False)
    is_admin = db.Column(db.Boolean, default=False)
    is_email_verified = db.Column(db.Boolean, default=False)
    token_version = db.Column(db.Integer, nullable=False, default=0, server_default="0")

    # Soft delete
    is_deleted = db.Column(db.Boolean, nullable=False, default=False, server_default="false", index=True)
    deleted_at = db.Column(db.DateTime)
    deleted_by = db.Column(db.BigInteger, db.ForeignKey("users.id"))
    
    avatar_path = db.Column(db.String(512))
    timezone = db.Column(db.String(64), default="UTC")
    language = db.Column(db.String(16), nullable=False, default="en", server_default="en")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, server_default=func.now(), onupdate=func.now())

class EmailVerificationToken(db.Model):
    __tablename__ = "email_verification_tokens"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = db.Column(db.String(512), nullable=False, unique=True, index=True)
    expires_at = db.Column(db.DateTime, nullable=False)
    used = db.Column(db.Boolean, default=False)

class PasswordResetToken(db.Model):
    __tablename__ = "password_reset_tokens"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = db.Column(db.String(512), nullable=False, unique=True, index=True)
    expires_at = db.Column(db.DateTime, nullable=False)
    used = db.Column(db.Boolean, default=False)
