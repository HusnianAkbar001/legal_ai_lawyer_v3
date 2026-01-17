from datetime import datetime, timedelta
import secrets
from flask import current_app
from .celery_app import celery
from ..extensions import db
from ..models.user import User, EmailVerificationToken, PasswordResetToken
from ..services.email_service import EmailService


@celery.task(bind=True, max_retries=3) 
def send_verification_email_task(self, user_id: int) -> None:
    """
    Celery task to send verification email.
    Runs inside Flask application context via ContextTask.
    """
    current_app.logger.info(
        f"[TASK START] send_verification_email | "
        f"task_id={self.request.id} | user_id={user_id}"
    )
    user = User.query.get(user_id)
    if not user:
        current_app.logger.error(f"[TASK ABORT] User {user_id} not found")
        return

    current_app.logger.info(f"User found: {user.email}")

    token = secrets.token_urlsafe(48)
    expires = datetime.utcnow() + timedelta(hours=24)

    vt = EmailVerificationToken(
        user_id=user.id,
        token=token,
        expires_at=expires,
    )
    db.session.add(vt)
    db.session.commit()
    
    current_app.logger.info(f"Verification token created and saved")

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
                "[TASK ABORT] SMTP not configured; skipping verification email for user_id=%s",
                user.id,
            )
            current_app.logger.warning(f"SMTP Config: HOST={cfg.get('SMTP_HOST')}, PORT={cfg.get('SMTP_PORT')}, USER={cfg.get('SMTP_USER')}")
            return

        current_app.logger.info(f"Attempting to send email to {user.email}")
        EmailService.send(user.email, "Verify your email", html)
        current_app.logger.info(f"[TASK SUCCESS] Verification email sent to {user.email}")

    except Exception as e:
        current_app.logger.exception(
            "[TASK ERROR] Failed to send verification email for user_id=%s | Error: %s",
            user.id,
            str(e),
        )
        raise self.retry(exc=e, countdown=2 ** self.request.retries)

@celery.task(bind=True, max_retries=3)
def send_password_reset_email_task(self, user_id: int) -> None:
    """
    Celery task to send password reset email with comprehensive logging.
    Runs inside Flask application context via ContextTask.
    """
    current_app.logger.info(
        f"[TASK START] send_password_reset_email | "
        f"task_id={self.request.id} | user_id={user_id}"
    )
    
    user = User.query.get(user_id)
    if not user:
        current_app.logger.error(
            f"[TASK ABORT] User not found | user_id={user_id}"
        )
        return
    
    masked_email = user.email[:2] + "***@" + user.email.split('@')[1] if '@' in user.email else "invalid"
    current_app.logger.info(f"[TASK] User found: {masked_email}")

    token = secrets.token_urlsafe(48)
    expires = datetime.utcnow() + timedelta(hours=1)

    rt = PasswordResetToken(
        user_id=user.id,
        token=token,
        expires_at=expires,
    )
    db.session.add(rt)
    
    try:
        db.session.commit()
        current_app.logger.info(
            f"[TASK] Reset token created | expires_in=1h"
        )
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(
            f"[TASK ERROR] Failed to save token | user_id={user_id} | error={str(e)}",
            exc_info=True
        )
        raise

    reset_url = (
        f"{current_app.config.get('FRONTEND_RESET_URL')}"
        f"/reset-password?token={token}"
    )

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #2c3e50;">Password Reset Request</h2>
            <p>You requested to reset your password. Click the button below to proceed:</p>
            <div style="text-align: center; margin: 30px 0;">
                <a href="{reset_url}" 
                   style="background-color: #3498db; color: white; padding: 12px 30px; 
                          text-decoration: none; border-radius: 5px; display: inline-block;">
                    Reset Password
                </a>
            </div>
            <p style="color: #7f8c8d; font-size: 14px;">
                This link expires in <strong>1 hour</strong>.
            </p>
            <p style="color: #7f8c8d; font-size: 14px;">
                If you didn't request this, please ignore this email.
            </p>
        </div>
    </body>
    </html>
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
            current_app.logger.error(
                f"[TASK ABORT] SMTP not configured | user_id={user_id} | "
                f"HOST={bool(cfg.get('SMTP_HOST'))} | PORT={bool(cfg.get('SMTP_PORT'))} | "
                f"USER={bool(cfg.get('SMTP_USER'))} | PASS={bool(cfg.get('SMTP_PASS'))} | "
                f"FROM={bool(cfg.get('EMAIL_FROM'))}"
            )
            return

        current_app.logger.info(
            f"[TASK] Attempting to send email | to={masked_email} | "
            f"smtp={cfg.get('SMTP_HOST')}:{cfg.get('SMTP_PORT')}"
        )
        
        success = EmailService.send(user.email, "Reset Your Password", html)
        
        if success:
            current_app.logger.info(
                f"[TASK SUCCESS] Password reset email sent | "
                f"user_id={user_id} | to={masked_email}"
            )
        else:
            current_app.logger.error(
                f"[TASK FAILED] Email service returned False | user_id={user_id}"
            )
            raise self.retry(exc=Exception("Email sending failed"), countdown=2 ** self.request.retries)

    except Exception as e:
        current_app.logger.error(
            f"[TASK ERROR] Email send exception | user_id={user_id} | "
            f"error={str(e)}",
            exc_info=True
        )
        raise self.retry(exc=e, countdown=2 ** self.request.retries)

@celery.task(bind=True) 
def send_password_changed_email_task(self, user_id: int) -> None:
    """
    Notify the user that their password was changed.
    Runs inside Flask application context via ContextTask.
    """
    current_app.logger.info(f"[TASK START] send_password_changed_email for user_id={user_id}")
    
    user = User.query.get(user_id)
    if not user:
        current_app.logger.error(f"[TASK ABORT] User {user_id} not found")
        return
    
    current_app.logger.info(f"User found: {user.email}")

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
                "[TASK ABORT] SMTP not configured; skipping password-changed email for user_id=%s",
                user.id,
            )
            return

        current_app.logger.info(f"Attempting to send email to {user.email}")
        EmailService.send(user.email, "Your password was changed", html)
        current_app.logger.info(f"[TASK SUCCESS] Password changed email sent to {user.email}")

    except Exception as e:
        current_app.logger.exception(
            "[TASK ERROR] Failed to send password changed email for user_id=%s | Error: %s",
            user.id,
            str(e),
        )
        raise