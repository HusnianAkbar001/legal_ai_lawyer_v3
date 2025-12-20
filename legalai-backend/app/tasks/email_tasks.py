from datetime import datetime, timedelta
import secrets
from flask import current_app
from .celery_app import celery
from ..extensions import db
from ..models.user import User, EmailVerificationToken, PasswordResetToken
from ..services.email_service import EmailService

_flask_app = None

def _get_app():
    global _flask_app
    if _flask_app is None:
        from .. import create_app 
        _flask_app = create_app()
    return _flask_app


@celery.task
def send_verification_email_task(user_id: int):
    """
    Celery task to send verification email.
    Safe to run outside request thread.
    """
    app = _get_app()
    with app.app_context():
        user = User.query.get(user_id)
        if not user:
            return

        token = secrets.token_urlsafe(48)
        expires = datetime.utcnow() + timedelta(hours=24)

        vt = EmailVerificationToken(
            user_id=user.id,
            token=token,
            expires_at=expires,
        )
        db.session.add(vt)
        db.session.commit()

        verify_url = (
            f"{current_app.config.get('FRONTEND_VERIFY_URL')}"
            f"/verify-email?token={token}"
        )

        html = f"""
        <p>Please verify your email by clicking the link below:</p>
        <p><a href="{verify_url}">Verify Email</a></p>
        <p>This link expires in 24 hours.</p>
        """

        try:
            cfg = current_app.config
            smtp_ready = all([
                cfg.get("SMTP_HOST"),
                cfg.get("SMTP_PORT"),
                cfg.get("SMTP_USER"),
                cfg.get("SMTP_PASS"),
                cfg.get("EMAIL_FROM"),
            ])
            if not smtp_ready:
                current_app.logger.warning(
                    "SMTP not configured; skipping verification email for %s",
                    user.email,
                )
                return

            EmailService.send(user.email, "Verify your email", html)
        except Exception as e:
            current_app.logger.exception(
                "Failed to send verification email to %s: %s",
                user.email, str(e)
            )

@celery.task
def send_password_reset_email_task(user_id: int):
    """
    Celery task to send password reset email.
    """
    app = _get_app()
    with app.app_context():
        user = User.query.get(user_id)
        if not user:
            return

        token = secrets.token_urlsafe(48)
        expires = datetime.utcnow() + timedelta(hours=1)

        rt = PasswordResetToken(
            user_id=user.id,
            token=token,
            expires_at=expires,
        )
        db.session.add(rt)
        db.session.commit()

        reset_url = (
            f"{current_app.config.get('FRONTEND_RESET_URL')}"
            f"/reset-password?token={token}"
        )

        html = f"""
        <p>Reset your password by clicking the link below:</p>
        <p><a href="{reset_url}">Reset Password</a></p>
        <p>This link expires in 1 hour.</p>
        """

        try:
            cfg = current_app.config
            smtp_ready = all([
                cfg.get("SMTP_HOST"),
                cfg.get("SMTP_PORT"),
                cfg.get("SMTP_USER"),
                cfg.get("SMTP_PASS"),
                cfg.get("EMAIL_FROM"),
            ])
            if not smtp_ready:
                current_app.logger.warning(
                    "SMTP not configured; skipping reset email for %s",
                    user.email,
                )
                return

            EmailService.send(user.email, "Reset password", html)
        except Exception as e:
            current_app.logger.exception(
                "Failed to send reset email to %s: %s",
                user.email, str(e)
            )


@celery.task
def send_password_changed_email_task(user_id: int):
    """
    Notify the user that their password was changed.
    """
    app = _get_app()
    with app.app_context():
        user = User.query.get(user_id)
        if not user:
            return

        html = """
        <p>Your password was changed successfully.</p>
        <p>If this wasn't you, please reset your password immediately or contact support.</p>
        """

        try:
            cfg = current_app.config
            smtp_ready = all([
                cfg.get("SMTP_HOST"),
                cfg.get("SMTP_PORT"),
                cfg.get("SMTP_USER"),
                cfg.get("SMTP_PASS"),
                cfg.get("EMAIL_FROM"),
            ])
            if not smtp_ready:
                current_app.logger.warning(
                    "SMTP not configured; skipping password-changed email for %s",
                    user.email,
                )
                return

            EmailService.send(user.email, "Your password was changed", html)
        except Exception as e:
            current_app.logger.exception(
                "Failed to send password-changed email to %s: %s",
                user.email, str(e)
            )
