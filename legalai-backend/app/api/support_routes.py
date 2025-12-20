from flask import Blueprint, jsonify, current_app, request, g
from werkzeug.exceptions import BadRequest, ServiceUnavailable
from markupsafe import escape

from ._auth_guard import require_auth, safe_mode_on
from ..extensions import db, limiter
from ..services.email_service import EmailService
from ..schemas.support import ContactUsSchema, FeedbackSchema
from ..models.contact_message import ContactMessage
from ..models.feedback import Feedback


bp = Blueprint("support", __name__)

def _as_safe_html(text: str) -> str:
    """
    Escape user-controlled text for HTML and preserve newlines safely.
    Avoids f-string backslash issues and prevents HTML injection.
    """
    if not text:
        return ""
    # Normalize newlines and preserve formatting in HTML
    safe = escape(text).replace("\r\n", "\n").replace("\r", "\n")
    return safe.replace("\n", "<br/>")


def _safe_subject(text: str, max_len: int = 160) -> str:
    """
    Prevent CR/LF injection in email subject and keep it reasonably short.
    """
    if not text:
        return ""
    s = " ".join(str(text).replace("\r", " ").replace("\n", " ").split())
    return s[:max_len]

def _smtp_ready(cfg) -> bool:
    return all([
        cfg.get("SMTP_HOST"),
        cfg.get("SMTP_PORT"),
        cfg.get("SMTP_USER"),
        cfg.get("SMTP_PASS"),
        cfg.get("EMAIL_FROM"),
        cfg.get("SUPPORT_INBOX_EMAIL"),
    ])

@bp.post("/contact")
@limiter.limit("10 per minute")
@require_auth()
def contact_us():
    if safe_mode_on():
        return jsonify({"ok": False, "reason": "Safe mode"}), 403

    data = ContactUsSchema().load((request.get_json() or {}))

    msg = ContactMessage(
        user_id=__import__("flask").g.user.id,
        full_name=data["fullName"].strip(),
        email=data["email"].strip().lower(),
        phone=data["phone"].strip(),
        subject=data["subject"].strip(),
        description=data["description"].strip(),
    )
    db.session.add(msg)
    db.session.commit()

    cfg = current_app.config
    if not _smtp_ready(cfg):
        # Message is saved in admin panel; email sending is optional but requested.
        # Return 503 so frontend can show a "try again later" message if needed.
        current_app.logger.warning("ContactUs email skipped (SMTP not configured). msgId=%s userId=%s", msg.id, msg.user_id)
        raise ServiceUnavailable("Support email is not configured")

    # Do NOT log subject/description (sensitive)
    safe_full_name = _as_safe_html(msg.full_name)
    safe_email = _as_safe_html(msg.email)
    safe_phone = _as_safe_html(msg.phone)
    safe_subject = _as_safe_html(msg.subject)
    safe_description = _as_safe_html(msg.description)

    html = f"""
    <h3>Contact Us</h3>
    <p><b>Full Name:</b> {safe_full_name}</p>
    <p><b>Email:</b> {safe_email}</p>
    <p><b>Phone:</b> {safe_phone}</p>
    <p><b>Subject:</b> {safe_subject}</p>
    <p><b>Description:</b><br/>{safe_description}</p>
    <hr/>
    <p><b>Message ID:</b> {msg.id}</p>
    <p><b>User ID:</b> {msg.user_id}</p>
    """


    try:
        EmailService.send(
            cfg["SUPPORT_INBOX_EMAIL"],
            f"Contact Us: {_safe_subject(msg.subject)}",
            html,
        )

        current_app.logger.info("ContactUs email sent. msgId=%s userId=%s", msg.id, msg.user_id)
    except Exception:
        # Keep logs safe: do not include body contents
        current_app.logger.exception("ContactUs email failed. msgId=%s userId=%s", msg.id, msg.user_id)
        raise ServiceUnavailable("Failed to send support email")

    return jsonify({"ok": True, "id": msg.id}), 201


@bp.post("/feedback")
@limiter.limit("10 per minute")
@require_auth()
def submit_feedback():
    if safe_mode_on():
        return jsonify({"ok": False, "reason": "Safe mode"}), 403

    data = FeedbackSchema().load((__import__("flask").request.get_json() or {}))

    fb = Feedback(
        user_id=g.user.id,
        rating=int(data["rating"]),
        comment=data["comment"].strip(),
    )
    db.session.add(fb)
    db.session.commit()

    cfg = current_app.config
    if not _smtp_ready(cfg):
        current_app.logger.warning("Feedback email skipped (SMTP not configured). feedbackId=%s userId=%s", fb.id, fb.user_id)
        raise ServiceUnavailable("Support email is not configured")

    safe_comment = _as_safe_html(fb.comment)

    html = f"""
    <h3>Feedback</h3>
    <p><b>Rating:</b> {fb.rating} / 5</p>
    <p><b>Comment:</b><br/>{safe_comment}</p>
    <hr/>
    <p><b>Feedback ID:</b> {fb.id}</p>
    <p><b>User ID:</b> {fb.user_id}</p>
    """

    try:
        EmailService.send(
            cfg["SUPPORT_INBOX_EMAIL"],
            f"Feedback: {fb.rating}/5",
            html,
        )
        current_app.logger.info("Feedback email sent. feedbackId=%s userId=%s", fb.id, fb.user_id)
    except Exception:
        current_app.logger.exception("Feedback email failed. feedbackId=%s userId=%s", fb.id, fb.user_id)
        raise ServiceUnavailable("Failed to send support email")

    return jsonify({"ok": True, "id": fb.id}), 201
