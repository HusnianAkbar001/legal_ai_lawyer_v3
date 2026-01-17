"""
Celery entrypoint for worker/beat processes.

This module creates the Flask app and binds Celery to it,
ensuring all tasks run inside Flask application context.

Usage:
    celery -A app.celery_worker:celery worker --loglevel=info --pool=solo
    celery -A app.celery_worker:celery beat --loglevel=info
"""

from __future__ import annotations

import logging

from . import create_app
from .tasks.celery_app import celery, init_celery

logger = logging.getLogger(__name__)

try:
    flask_app = create_app()
    init_celery(flask_app)
    
    logger.info("Celery worker initialized with Flask app context")
    logger.info(f"Flask app config loaded: DB={bool(flask_app.config.get('SQLALCHEMY_DATABASE_URI'))}")
    logger.info(f"SMTP configured: {bool(flask_app.config.get('SMTP_HOST'))}")
    
except Exception as e:
    logger.exception("CRITICAL: Failed to initialize Flask app for Celery worker")
    raise