from celery import Celery
from flask import Flask
from ..config import Config

celery = Celery(
    __name__,
    broker=Config.CELERY_BROKER_URL,
    backend=Config.CELERY_RESULT_BACKEND,
)

def init_celery(app: Flask):
    """
    Bind Celery to Flask app and ensure every task runs
    inside Flask application context.

    IMPORTANT: Do not push old CELERY_* keys into celery.conf,
    Celery 5+ forbids mixing old/new setting names.
    """
    broker = app.config.get("CELERY_BROKER_URL") or app.config.get("broker_url")
    backend = app.config.get("CELERY_RESULT_BACKEND") or app.config.get("result_backend")

    celery.conf.update(
        broker_url=broker,
        result_backend=backend,
        timezone="UTC",
        enable_utc=True,

        # --- CRITICAL: force async execution ---
        task_always_eager=False,
        task_eager_propagates=False,

        # Reliability
        task_acks_late=True,
        worker_prefetch_multiplier=1,

        # Serialization safety
        accept_content=["json"],
        task_serializer="json",
        result_serializer="json",
    )

    # celery.conf.update(
    #     broker_url=broker,
    #     result_backend=backend,
    #     timezone="UTC",
    #     enable_utc=True,
    # )

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask

