from dotenv import load_dotenv
import os
from datetime import timedelta

load_dotenv()

class Config:
    ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = ENV == "development"

    SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
    DATABASE_URL = os.getenv("DATABASE_URL") or os.getenv("SQLALCHEMY_DATABASE_URI")
    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    JWT_ACCESS_EXPIRES = timedelta(minutes=int(os.getenv("JWT_ACCESS_MIN", "15")))
    JWT_REFRESH_EXPIRES = timedelta(days=int(os.getenv("JWT_REFRESH_DAYS", "30")))
    JWT_ALGORITHM = "HS256"

    SMTP_HOST = os.getenv("SMTP_HOST")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "True").lower() == "true"
    SMTP_USER = os.getenv("SMTP_USER")
    SMTP_PASS = os.getenv("SMTP_PASS")
    EMAIL_FROM = os.getenv("EMAIL_FROM")
    FRONTEND_VERIFY_URL = os.getenv("FRONTEND_VERIFY_URL")
    FRONTEND_RESET_URL = os.getenv("FRONTEND_RESET_URL")
    SUPPORT_INBOX_EMAIL = os.getenv("SUPPORT_INBOX_EMAIL")
    LAWYER_CATEGORIES_JSON = os.getenv("LAWYER_CATEGORIES_JSON")
    
    SUPERADMIN_EMAIL = os.getenv("SUPERADMIN_EMAIL")
    SUPERADMIN_PASSWORD = os.getenv("SUPERADMIN_PASSWORD")

    STORAGE_BASE = os.getenv("STORAGE_BASE", os.path.abspath("storage/uploads"))
    MAX_UPLOAD_MB = int(os.getenv("MAX_UPLOAD_MB", "30"))
    ALLOWED_EXTS = {
        "txt", "csv", "tsv", "json",
        "pdf", "docx",
        "xlsx",
        "png", "jpg", "jpeg", "svg",
    }


    EMBEDDING_PROVIDER = os.getenv("EMBEDDING_PROVIDER", "openai") 
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "text-embedding-3-large")
    CHAT_PROVIDER = os.getenv("CHAT_PROVIDER", "openai")
    CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o-mini")
    RAG_TOP_K = int(os.getenv("RAG_TOP_K", "5"))

    FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY")
    APNS_KEY_ID = os.getenv("APNS_KEY_ID")
    APNS_TEAM_ID = os.getenv("APNS_TEAM_ID")
    APNS_BUNDLE_ID = os.getenv("APNS_BUNDLE_ID")
    APNS_AUTH_KEY_PATH = os.getenv("APNS_AUTH_KEY_PATH")

    REDIS_URL = os.getenv("REDIS_URL")
    CELERY_BROKER_URL = REDIS_URL
    CELERY_RESULT_BACKEND = REDIS_URL

    RATELIMIT_STORAGE_URI = os.getenv("RATELIMIT_STORAGE_URI") or REDIS_URL
    RATELIMIT_DEFAULT = os.getenv("RATELIMIT_DEFAULT", "120 per minute")
    RATELIMIT_HEADERS_ENABLED = True
    CHAT_MEMORY_LIMIT = int(os.getenv("CHAT_MEMORY_LIMIT", "10"))
    
    EMBEDDING_DIMENSION = int(os.getenv("EMBEDDING_DIMENSION", "3072"))
    EMBEDDING_MODEL_NAME = os.getenv("EMBEDDING_MODEL", "text-embedding-3-large")