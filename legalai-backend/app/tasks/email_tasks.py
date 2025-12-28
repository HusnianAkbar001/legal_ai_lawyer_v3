from datetime import datetime, timedelta
import secrets
from flask import current_app
from .celery_app import celery
from ..extensions import db
from ..models.user import User, EmailVerificationToken, PasswordResetToken
from ..services.email_service import EmailService


@celery.task(bind=True)  # ✅ Use .task instead of .shared_task
def send_verification_email_task(self, user_id: int) -> None:
    """
    Celery task to send verification email.
    Runs inside Flask application context via ContextTask.
    """
    current_app.logger.info(f"[TASK START] send_verification_email for user_id={user_id}")
    
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
        raise


@celery.task(bind=True)  # ✅ Use .task with bind=True
def send_password_reset_email_task(self, user_id: int) -> None:
    """
    Celery task to send password reset email.
    Runs inside Flask application context via ContextTask.
    """
    current_app.logger.info(f"[TASK START] send_password_reset_email for user_id={user_id}")
    
    user = User.query.get(user_id)
    if not user:
        current_app.logger.error(f"[TASK ABORT] User {user_id} not found")
        return
    
    current_app.logger.info(f"User found: {user.email}")

    token = secrets.token_urlsafe(48)
    expires = datetime.utcnow() + timedelta(hours=1)

    rt = PasswordResetToken(
        user_id=user.id,
        token=token,
        expires_at=expires,
    )
    db.session.add(rt)
    db.session.commit()
    
    current_app.logger.info(f"Reset token created and saved")

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
                "[TASK ABORT] SMTP not configured; skipping reset email for user_id=%s",
                user.id,
            )
            current_app.logger.warning(f"SMTP Config: HOST={cfg.get('SMTP_HOST')}, PORT={cfg.get('SMTP_PORT')}, USER={cfg.get('SMTP_USER')}")
            return

        current_app.logger.info(f"Attempting to send email to {user.email}")
        EmailService.send(user.email, "Reset password", html)
        current_app.logger.info(f"[TASK SUCCESS] Password reset email sent to {user.email}")

    except Exception as e:
        current_app.logger.error(
            "[TASK ERROR] Email send failed for user_id=%s | Error: %s",
            user_id,
            str(e),
            exc_info=True
        )
        raise


@celery.task(bind=True)  # ✅ Use .task with bind=True
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
    
# from datetime import datetime, timedelta
# import secrets

# from flask import current_app

# from .celery_app import celery
# from ..extensions import db
# from ..models.user import User, EmailVerificationToken, PasswordResetToken
# from ..services.email_service import EmailService


# @celery.task
# def send_verification_email_task(user_id: int) -> None:
#     """
#     Celery task to send verification email.
#     Runs inside Flask application context via ContextTask.
#     """
#     user = User.query.get(user_id)
#     if not user:
#         return

#     token = secrets.token_urlsafe(48)
#     expires = datetime.utcnow() + timedelta(hours=24)

#     vt = EmailVerificationToken(
#         user_id=user.id,
#         token=token,
#         expires_at=expires,
#     )
#     db.session.add(vt)
#     db.session.commit()

#     verify_url = (
#         f"{current_app.config.get('FRONTEND_VERIFY_URL')}"
#         f"/verify-email?token={token}"
#     )

#     html = f"""
#     <p>Please verify your email by clicking the link below:</p>
#     <p><a href="{verify_url}">Verify Email</a></p>
#     <p>This link expires in 24 hours.</p>
#     """

#     try:
#         cfg = current_app.config
#         smtp_ready = all([
#             cfg.get("SMTP_HOST"),
#             cfg.get("SMTP_PORT"),
#             cfg.get("SMTP_USER"),
#             cfg.get("SMTP_PASS"),
#             cfg.get("EMAIL_FROM"),
#         ])

#         if not smtp_ready:
#             current_app.logger.warning(
#                 "SMTP not configured; skipping verification email for user_id=%s",
#                 user.id,
#             )
#             return

#         EmailService.send(user.email, "Verify your email", html)

#     except Exception:
#         # Avoid logging email or token to prevent sensitive leakage.
#         current_app.logger.exception(
#             "Failed to send verification email for user_id=%s",
#             user.id,
#         )


# @celery.task
# def send_password_reset_email_task(user_id: int) -> None:
#     """
#     Celery task to send password reset email.
#     Runs inside Flask application context via ContextTask.
#     """
#     user = User.query.get(user_id)
#     if not user:
#         return
#     current_app.logger.info(
#         "Password reset task started for user_id=%s",
#         user_id,
#     )

#     token = secrets.token_urlsafe(48)
#     expires = datetime.utcnow() + timedelta(hours=1)

#     rt = PasswordResetToken(
#         user_id=user.id,
#         token=token,
#         expires_at=expires,
#     )
#     db.session.add(rt)
#     db.session.commit()

#     reset_url = (
#         f"{current_app.config.get('FRONTEND_RESET_URL')}"
#         f"/reset-password?token={token}"
#     )

#     html = f"""
#     <p>Reset your password by clicking the link below:</p>
#     <p><a href="{reset_url}">Reset Password</a></p>
#     <p>This link expires in 1 hour.</p>
#     """

#     try:
#         cfg = current_app.config
#         smtp_ready = all([
#             cfg.get("SMTP_HOST"),
#             cfg.get("SMTP_PORT"),
#             cfg.get("SMTP_USER"),
#             cfg.get("SMTP_PASS"),
#             cfg.get("EMAIL_FROM"),
#         ])

#         if not smtp_ready:
#             current_app.logger.warning(
#                 "SMTP not configured; skipping reset email for user_id=%s",
#                 user.id,
#             )
#             return

#         EmailService.send(user.email, "Reset password", html)
#         current_app.logger.info(
#             "Password reset email dispatched for user_id=%s",
#             user_id,
#         )

#     except Exception as e:
#         current_app.logger.error(
#             "Email send failed for user_id=%s | Error: %s",
#             user_id,
#             str(e),
#             exc_info=True  # Includes traceback, no sensitive data
#         )


# @celery.task
# def send_password_changed_email_task(user_id: int) -> None:
#     """
#     Notify the user that their password was changed.
#     Runs inside Flask application context via ContextTask.
#     """
#     user = User.query.get(user_id)
#     if not user:
#         return

#     html = """
#     <p>Your password was changed successfully.</p>
#     <p>If this wasn't you, please reset your password immediately or contact support.</p>
#     """

#     try:
#         cfg = current_app.config
#         smtp_ready = all([
#             cfg.get("SMTP_HOST"),
#             cfg.get("SMTP_PORT"),
#             cfg.get("SMTP_USER"),
#             cfg.get("SMTP_PASS"),
#             cfg.get("EMAIL_FROM"),
#         ])

#         if not smtp_ready:
#             current_app.logger.warning(
#                 "SMTP not configured; skipping password-changed email for user_id=%s",
#                 user.id,
#             )
#             return

#         EmailService.send(user.email, "Your password was changed", html)

#     except Exception:
#         current_app.logger.exception(
#             "Failed to send password changed email for user_id=%s",
#             user.id,
#         )