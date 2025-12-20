import smtplib
from email.mime.text import MIMEText
from flask import current_app

class EmailService:
    @staticmethod
    def send(to_email: str, subject: str, html: str):
        cfg = current_app.config
        msg = MIMEText(html, "html", "utf-8")
        msg["Subject"] = subject
        msg["From"] = cfg["EMAIL_FROM"]
        msg["To"] = to_email

        with smtplib.SMTP(cfg["SMTP_HOST"], cfg["SMTP_PORT"]) as server:
            server.starttls()
            server.login(cfg["SMTP_USER"], cfg["SMTP_PASS"])
            server.send_message(msg)
