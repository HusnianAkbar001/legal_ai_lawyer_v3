from datetime import datetime, timedelta
import secrets
import jwt
from flask import current_app
from ..extensions import db
from sqlalchemy.exc import IntegrityError
from ..models.user import User, EmailVerificationToken, PasswordResetToken
from ..utils.security import hash_password, verify_password
from .email_service import EmailService
from ..tasks.email_tasks import (
    send_verification_email_task,
    send_password_reset_email_task,
    send_password_changed_email_task,
)

class AuthService:
    @staticmethod
    def create_user(data):
        """
        Create new user account.
        
        Assumes data is already validated by schema (format, types, password strength).
        Performs business logic validation (uniqueness checks).
        
        Args:
            data: Validated user data from schema
            
        Returns:
            User: Created user object
            
        Raises:
            ValueError: If business logic validation fails (duplicate email/CNIC)
        """
        # ✅ Normalize email (industry standard: lowercase, trimmed)
        email = (data["email"] or "").strip().lower()

        # ✅ Check email uniqueness (business logic validation)
        existing_email = User.query.filter_by(email=email).first()
        if existing_email:
            raise ValueError("Email already exists. Please login instead.")

        # ✅ Normalize CNIC (keep dashes for user-friendly format)
        cnic = (data.get("cnic") or "").strip()
        if not cnic:
            raise ValueError("CNIC is required.")

        # ✅ Check CNIC uniqueness (business logic validation)
        existing_cnic = User.query.filter_by(cnic=cnic).first()
        if existing_cnic:
            raise ValueError("CNIC already exists. Please login instead.")

        # ✅ Language validation with default fallback
        lang = str(data.get("language") or "en").strip().lower()
        if lang not in {"en", "ur"}:
            lang = "en"

        # ✅ Create user with validated data
        user = User(
            language=lang,
            name=data["name"],
            email=email,
            phone=data["phone"],
            cnic=cnic,
            father_name=data.get("fatherName"),
            father_cnic=data.get("fatherCnic"),
            mother_name=data.get("motherName"),
            mother_cnic=data.get("motherCnic"),
            city=data.get("city"),
            gender=data.get("gender"),
            age=data.get("age"),
            total_siblings=data.get("totalSiblings", 0),
            brothers=data.get("brothers", 0),
            sisters=data.get("sisters", 0),
            timezone=data.get("timezone", "UTC"),
            password_hash=hash_password(data["password"]),
        )

        db.session.add(user)

        try:
            db.session.commit()
        except IntegrityError:
            # ✅ Handle race condition (simultaneous signups)
            db.session.rollback()
            raise ValueError("Account already exists. Please login instead.")

        # ✅ Async email sending (non-blocking)
        try:
            task = send_verification_email_task.delay(user.id)
            current_app.logger.info(
                f"✅ Verification email task queued: task_id={task.id} user_id={user.id}"
            )
        except Exception as e:
            current_app.logger.error(
                f"❌ CRITICAL: Failed to queue verification email task for user_id={user.id}: {e}",
                exc_info=True
            )
            # Don't fail signup if email queueing fails - user can resend later
        
        return user
        # # ✅ Async email sending (non-blocking)
        # send_verification_email_task.delay(user.id)
        # return user

    @staticmethod
    def send_verification_email(user: User):
        """Send email verification link to user"""
        token = secrets.token_urlsafe(48)
        expires = datetime.utcnow() + timedelta(hours=24)
        vt = EmailVerificationToken(user_id=user.id, token=token, expires_at=expires)
        db.session.add(vt)
        db.session.commit()

        verify_url = f"{current_app.config.get('FRONTEND_VERIFY_URL')}/verify-email?token={token}"
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
            if smtp_ready:
                EmailService.send(user.email, "Verify your email", html)
            else:
                current_app.logger.warning(
                    "SMTP not configured; skipping verification email for user_id=%s",
                    user.id,
                )
        except Exception as e:
            current_app.logger.exception(
                "Failed to send verification email user_id=%s",
                user.id,
            )

    @staticmethod
    def verify_email(token: str):
        """Verify user email with token"""
        vt = EmailVerificationToken.query.filter_by(token=token, used=False).first()
        if not vt or vt.expires_at < datetime.utcnow():
            return False
        user = User.query.get(vt.user_id)
        user.is_email_verified = True
        vt.used = True
        db.session.commit()
        return True

    @staticmethod
    def authenticate(email: str, password: str):
        """Authenticate user with email and password"""
        user = User.query.filter_by(email=email.lower()).first()
        if not user or not verify_password(password, user.password_hash):
            return None
        return user

    @staticmethod
    def _encode(payload, exp_delta):
        """Encode JWT token with expiration"""
        payload = {**payload, "exp": datetime.utcnow() + exp_delta}
        return jwt.encode(payload, current_app.config["SECRET_KEY"], algorithm="HS256")

    @staticmethod
    def issue_tokens(user: User):
        """Issue access and refresh tokens for user"""
        version = user.token_version or 0
        access = AuthService._encode(
            {"sub": user.id, "type": "access", "v": version},
            current_app.config["JWT_ACCESS_EXPIRES"],
        )
        refresh = AuthService._encode(
            {"sub": user.id, "type": "refresh", "v": version},
            current_app.config["JWT_REFRESH_EXPIRES"],
        )
        return access, refresh

    @staticmethod
    def refresh_tokens(refresh_token: str):
        """Refresh access token using refresh token"""
        try:
            payload = jwt.decode(refresh_token, current_app.config["SECRET_KEY"], algorithms=["HS256"])
            if payload.get("type") != "refresh":
                return None
        except jwt.PyJWTError:
            return None
        user = User.query.get(payload["sub"])
        token_version = payload.get("v", 0)
        if not user or token_version != (user.token_version or 0):
            return None
        return AuthService.issue_tokens(user)

    @staticmethod
    def request_password_reset(email: str):
        """Send password reset email"""
        user = User.query.filter_by(email=email.lower()).first()
        if not user:
            return

        try:
            task = send_password_reset_email_task.delay(user.id)
            current_app.logger.info(
                f"✅ Password reset email task queued: task_id={task.id} user_id={user.id}"
            )
        except Exception as e:
            current_app.logger.error(
                f"❌ CRITICAL: Failed to queue password reset task for user_id={user.id}: {e}",
                exc_info=True
            )
    # @staticmethod
    # def request_password_reset(email: str):
    #     """Send password reset email"""
    #     user = User.query.filter_by(email=email.lower()).first()
    #     if not user:
    #         return

    #     send_password_reset_email_task.delay(user.id)

    @staticmethod
    def reset_password(token: str, new_password: str):
        """
        Reset user password with token.
        
        Note: Password validation happens in ResetPasswordSchema.
        """
        rt = PasswordResetToken.query.filter_by(token=token, used=False).first()
        if not rt or rt.expires_at < datetime.utcnow():
            return False
        user = User.query.get(rt.user_id)
        user.password_hash = hash_password(new_password)
        user.token_version = (user.token_version or 0) + 1
        rt.used = True
        db.session.commit()
        send_password_changed_email_task.delay(user.id)
        return True

    @staticmethod
    def change_password(user: User, current_password: str, new_password: str):
        """
        Change user password.
        
        Note: Password validation happens in ChangePasswordSchema.
        """
        if not verify_password(current_password, user.password_hash):
            return False, "Current password is incorrect."
        if current_password == new_password:
            return False, "New password must be different from the current password."

        user.password_hash = hash_password(new_password)
        user.token_version = (user.token_version or 0) + 1
        db.session.commit()
        send_password_changed_email_task.delay(user.id)

        return True, None
    
# from datetime import datetime, timedelta
# import secrets
# import jwt
# from flask import current_app
# from ..extensions import db
# from sqlalchemy.exc import IntegrityError
# from ..models.user import User, EmailVerificationToken, PasswordResetToken
# from ..utils.security import validate_password, hash_password, verify_password
# from .email_service import EmailService
# from ..tasks.email_tasks import (
#     send_verification_email_task,
#     send_password_reset_email_task,
#     send_password_changed_email_task,
# )

# class AuthService:
#     @staticmethod
#     def create_user(data):
#         validate_password(data["password"])

#         email = (data["email"] or "").strip().lower()

#         existing = User.query.filter_by(email=email).first()
#         if existing:
#             raise ValueError("Email already exists. Please login instead.")

#         cnic = (data.get("cnic") or "").strip()
#         if not cnic:
#             raise ValueError("CNIC is required.")

#         existing_cnic = User.query.filter_by(cnic=cnic).first()
#         if existing_cnic:
#             raise ValueError("CNIC already exists. Please login instead.")

#         lang = str(data.get("language") or "en").strip().lower()
#         if lang not in {"en", "ur"}:
#             lang = "en"

#         user = User(
#             language=lang,
#             name=data["name"],
#             email=email,
#             phone=data["phone"],
#             cnic=cnic,
#             father_name=data.get("fatherName"),
#             father_cnic=data.get("fatherCnic"),
#             mother_name=data.get("motherName"),
#             mother_cnic=data.get("motherCnic"),
#             city=data.get("city"),
#             gender=data.get("gender"),
#             age=data.get("age"),
#             total_siblings=data.get("totalSiblings", 0),
#             brothers=data.get("brothers", 0),
#             sisters=data.get("sisters", 0),
#             timezone=data.get("timezone", "UTC"),
#             password_hash=hash_password(data["password"]),
#         )

#         db.session.add(user)

#         try:
#             db.session.commit()
#         except IntegrityError:
#             # ---- Race-condition / DB-constraint fallback ----
#             db.session.rollback()
#             raise ValueError("Account already exists. Please login instead.")

#         send_verification_email_task.delay(user.id)
#         return user

#     @staticmethod
#     def send_verification_email(user: User):
#         token = secrets.token_urlsafe(48)
#         expires = datetime.utcnow() + timedelta(hours=24)
#         vt = EmailVerificationToken(user_id=user.id, token=token, expires_at=expires)
#         db.session.add(vt); db.session.commit()

#         verify_url = f"{current_app.config.get('FRONTEND_VERIFY_URL')}/verify-email?token={token}"
#         html = f"""
#         <p>Please verify your email by clicking the link below:</p>
#         <p><a href="{verify_url}">Verify Email</a></p>
#         <p>This link expires in 24 hours.</p>
#         """
#         try:
#             cfg = current_app.config
#             smtp_ready = all([
#                 cfg.get("SMTP_HOST"),
#                 cfg.get("SMTP_PORT"),
#                 cfg.get("SMTP_USER"),
#                 cfg.get("SMTP_PASS"),
#                 cfg.get("EMAIL_FROM"),
#             ])
#             if smtp_ready:
#                 EmailService.send(user.email, "Verify your email", html)
#             else:
#                 current_app.logger.warning(
#                     "SMTP not configured; skipping verification email for user_id=%s",
#                     user.id,
#                 )
#         except Exception as e:
#             current_app.logger.exception(
#                 "Failed to send verification email user_id=%s",
#                 user.id,
#             )

#     @staticmethod
#     def verify_email(token: str):
#         vt = EmailVerificationToken.query.filter_by(token=token, used=False).first()
#         if not vt or vt.expires_at < datetime.utcnow():
#             return False
#         user = User.query.get(vt.user_id)
#         user.is_email_verified = True
#         vt.used = True
#         db.session.commit()
#         return True

#     @staticmethod
#     def authenticate(email: str, password: str):
#         user = User.query.filter_by(email=email.lower()).first()
#         if not user or not verify_password(password, user.password_hash):
#             return None
#         return user

#     @staticmethod
#     def _encode(payload, exp_delta):
#         payload = {**payload, "exp": datetime.utcnow() + exp_delta}
#         return jwt.encode(payload, current_app.config["SECRET_KEY"], algorithm="HS256")

#     @staticmethod
#     def issue_tokens(user: User):
#         version = user.token_version or 0
#         access = AuthService._encode(
#             {"sub": user.id, "type": "access", "v": version},
#             current_app.config["JWT_ACCESS_EXPIRES"],
#         )
#         refresh = AuthService._encode(
#             {"sub": user.id, "type": "refresh", "v": version},
#             current_app.config["JWT_REFRESH_EXPIRES"],
#         )
#         return access, refresh

#     @staticmethod
#     def refresh_tokens(refresh_token: str):
#         try:
#             payload = jwt.decode(refresh_token, current_app.config["SECRET_KEY"], algorithms=["HS256"])
#             if payload.get("type") != "refresh":
#                 return None
#         except jwt.PyJWTError:
#             return None
#         user = User.query.get(payload["sub"])
#         token_version = payload.get("v", 0)
#         if not user or token_version != (user.token_version or 0):
#             return None
#         return AuthService.issue_tokens(user)

#     @staticmethod
#     def request_password_reset(email: str):
#         user = User.query.filter_by(email=email.lower()).first()
#         if not user:
#             return

#         send_password_reset_email_task.delay(user.id)

#     @staticmethod
#     def reset_password(token: str, new_password: str):
#         validate_password(new_password)
#         rt = PasswordResetToken.query.filter_by(token=token, used=False).first()
#         if not rt or rt.expires_at < datetime.utcnow():
#             return False
#         user = User.query.get(rt.user_id)
#         user.password_hash = hash_password(new_password)
#         user.token_version = (user.token_version or 0) + 1
#         rt.used = True
#         db.session.commit()
#         send_password_changed_email_task.delay(user.id)
#         return True

#     @staticmethod
#     def change_password(user: User, current_password: str, new_password: str):
#         if not verify_password(current_password, user.password_hash):
#             return False, "Current password is incorrect."
#         if current_password == new_password:
#             return False, "New password must be different from the current password."

#         validate_password(new_password)
#         user.password_hash = hash_password(new_password)
#         user.token_version = (user.token_version or 0) + 1
#         db.session.commit()
#         send_password_changed_email_task.delay(user.id)

#         return True, None
