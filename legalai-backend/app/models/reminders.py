from datetime import datetime
from ..extensions import db

class Reminder(db.Model):
    __tablename__ = "reminders"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True)
    title = db.Column(db.String(200), nullable=False)
    notes = db.Column(db.Text)
    scheduled_at = db.Column(db.DateTime, nullable=False)
    timezone = db.Column(db.String(64), nullable=False)

    is_done = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class DeviceToken(db.Model):
    __tablename__ = "device_tokens"
    id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey("users.id", ondelete="CASCADE"), index=True)
    platform = db.Column(db.String(10), nullable=False) # android/ios
    token = db.Column(db.String(512), nullable=False, unique=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
