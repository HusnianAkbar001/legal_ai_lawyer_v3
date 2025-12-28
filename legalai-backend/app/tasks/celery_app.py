from celery import Celery, Task
from flask import Flask, current_app, has_app_context
from ..config import Config

# Create Celery instance WITHOUT immediate configuration
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
        # Get the Flask app from Celery's flask_app attribute
        flask_app = celery.flask_app
        
        if not flask_app:
            raise RuntimeError(
                "Flask app not bound to Celery. "
                "Call init_celery(app) before starting worker."
            )
        
        # Execute task inside Flask app context
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

    # CRITICAL: Configure Celery with explicit connection settings
    celery.conf.update(
        broker_url=broker,
        result_backend=backend,
        broker_connection_retry_on_startup=True,
        timezone="UTC",
        enable_utc=True,
        
        # CRITICAL: Force async execution
        task_always_eager=False,
        task_eager_propagates=False,
        
        # Reliability
        task_acks_late=True,
        worker_prefetch_multiplier=1,
        
        # Serialization safety
        accept_content=["json"],
        task_serializer="json",
        result_serializer="json",
        
        # Connection pool settings
        broker_pool_limit=10,
        broker_connection_max_retries=10,
        broker_connection_retry=True,
    )
    
    # Store Flask app reference for ContextTask
    celery.flask_app = app
    
    # Set custom task class
    celery.Task = ContextTask
    
    # Test connection on init
    try:
        celery.connection().ensure_connection(max_retries=3)
        app.logger.info("✅ Celery connected to Redis successfully")
    except Exception as e:
        app.logger.error(f"❌ Celery failed to connect to Redis: {e}")
        raise

###############################################################################################################

# 2
# from celery import Celery
# from flask import Flask
# from ..config import Config

# # Create Celery instance WITHOUT immediate configuration
# celery = Celery(__name__)


# def init_celery(app: Flask):
#     """
#     Bind Celery to Flask app and ensure every task runs
#     inside Flask application context.
    
#     CRITICAL: Must be called AFTER Flask app is fully configured.
#     """
#     broker = app.config.get("CELERY_BROKER_URL") or app.config.get("broker_url")
#     backend = app.config.get("CELERY_RESULT_BACKEND") or app.config.get("result_backend")

#     # CRITICAL: Configure Celery with explicit connection settings
#     celery.conf.update(
#         broker_url=broker,
#         result_backend=backend,
#         broker_connection_retry_on_startup=True,  # ✅ NEW: Auto-retry on startup
#         timezone="UTC",
#         enable_utc=True,
        
#         # CRITICAL: Force async execution
#         task_always_eager=False,
#         task_eager_propagates=False,
        
#         # Reliability
#         task_acks_late=True,
#         worker_prefetch_multiplier=1,
        
#         # Serialization safety
#         accept_content=["json"],
#         task_serializer="json",
#         result_serializer="json",
        
#         # ✅ NEW: Connection pool settings for robustness
#         broker_pool_limit=10,
#         broker_connection_max_retries=10,
#         broker_connection_retry=True,
#     )
    
#     # ✅ NEW: Test connection on init
#     try:
#         celery.connection().ensure_connection(max_retries=3)
#         app.logger.info("✅ Celery connected to Redis successfully")
#     except Exception as e:
#         app.logger.error(f"❌ Celery failed to connect to Redis: {e}")
#         raise

#     class ContextTask(celery.Task):
#         def __call__(self, *args, **kwargs):
#             with app.app_context():
#                 return self.run(*args, **kwargs)

#     celery.Task = ContextTask
    
###############################################################################################################
# from celery import Celery
# from flask import Flask
# from ..config import Config

# celery = Celery(
#     __name__,
#     broker=Config.CELERY_BROKER_URL,
#     backend=Config.CELERY_RESULT_BACKEND,
# )

# def init_celery(app: Flask):
#     """
#     Bind Celery to Flask app and ensure every task runs
#     inside Flask application context.

#     IMPORTANT: Do not push old CELERY_* keys into celery.conf,
#     Celery 5+ forbids mixing old/new setting names.
#     """
#     broker = app.config.get("CELERY_BROKER_URL") or app.config.get("broker_url")
#     backend = app.config.get("CELERY_RESULT_BACKEND") or app.config.get("result_backend")

#     celery.conf.update(
#         broker_url=broker,
#         result_backend=backend,
#         timezone="UTC",
#         enable_utc=True,

#         # --- CRITICAL: force async execution ---
#         task_always_eager=False,
#         task_eager_propagates=False,

#         # Reliability
#         task_acks_late=True,
#         worker_prefetch_multiplier=1,

#         # Serialization safety
#         accept_content=["json"],
#         task_serializer="json",
#         result_serializer="json",
#     )

#     # celery.conf.update(
#     #     broker_url=broker,
#     #     result_backend=backend,
#     #     timezone="UTC",
#     #     enable_utc=True,
#     # )

#     class ContextTask(celery.Task):
#         def __call__(self, *args, **kwargs):
#             with app.app_context():
#                 return self.run(*args, **kwargs)

#     celery.Task = ContextTask

