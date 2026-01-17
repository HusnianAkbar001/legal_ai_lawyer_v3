from celery import Celery, Task
from flask import Flask, current_app, has_app_context
from ..config import Config

celery = Celery(__name__)


class ContextTask(Task):
    """
    Custom task class that ensures Flask application context.
    
    CRITICAL: All tasks inherit this to access Flask features
    like current_app, db.session, etc.
    """
    def __call__(self, *args, **kwargs):
        """
        Wrap task execution in Flask app context.
        This allows access to current_app, db, etc.
        """
        flask_app = celery.flask_app
        
        if not flask_app:
            raise RuntimeError(
                "Flask app not bound to Celery. "
                "Call init_celery(app) before starting worker."
            )
        
        with flask_app.app_context():
            return self.run(*args, **kwargs)


def init_celery(app: Flask):
    """
    Bind Celery to Flask app and ensure every task runs
    inside Flask application context.
    
    CRITICAL: Must be called AFTER Flask app is fully configured.
    """
    broker = app.config.get("CELERY_BROKER_URL") or app.config.get("broker_url")
    backend = app.config.get("CELERY_RESULT_BACKEND") or app.config.get("result_backend")

    celery.conf.update(
        broker_url=broker,
        result_backend=backend,
        broker_connection_retry_on_startup=True,
        timezone="UTC",
        enable_utc=True,
        
        task_always_eager=False,
        task_eager_propagates=False,
        
        task_acks_late=True,
        worker_prefetch_multiplier=1,
        
        accept_content=["json"],
        task_serializer="json",
        result_serializer="json",
        
        broker_pool_limit=10,
        broker_connection_max_retries=10,
        broker_connection_retry=True,
    )
    
    celery.flask_app = app
    
    celery.Task = ContextTask
    
    try:
        celery.connection().ensure_connection(max_retries=3)
        app.logger.info("Celery connected to Redis successfully")
    except Exception as e:
        app.logger.error(f"Celery failed to connect to Redis: {e}")
        raise
