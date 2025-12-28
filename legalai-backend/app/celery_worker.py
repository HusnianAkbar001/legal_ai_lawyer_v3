"""
Celery entrypoint for worker/beat processes.

This module creates the Flask app and binds Celery to it,
without causing circular imports during Flask startup.

Usage:
    celery -A app.celery_worker.celery worker --loglevel=info
    celery -A app.celery_worker.celery beat --loglevel=info
"""

from __future__ import annotations

import logging

from . import create_app
from .tasks.celery_app import celery, init_celery

logger = logging.getLogger(__name__)

try:
    flask_app = create_app()
    init_celery(flask_app)
except Exception:
    # Do not include secrets in logs. Keep this generic.
    logger.exception("Failed to initialize Flask app for Celery worker.")
    raise
