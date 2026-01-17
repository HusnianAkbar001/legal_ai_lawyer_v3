"""
Async evaluation tasks for RAG monitoring.

Runs in background to avoid blocking chat responses.
"""
from .celery_app import celery
from ..services.rag_evaluation_service import RAGEvaluationService
from flask import current_app

_flask_app = None


def _get_app():
    global _flask_app
    if _flask_app is None:
        from .. import create_app
        _flask_app = create_app()
    return _flask_app


@celery.task(bind=True, max_retries=2)
def log_rag_evaluation_async(self, **kwargs):
    """
    Async task for logging RAG evaluations.
    
    Retries up to 2 times on failure to ensure metrics are captured.
    """
    app = _get_app()
    with app.app_context():
        try:
            RAGEvaluationService.log_evaluation(**kwargs)
        except Exception as exc:
            current_app.logger.warning(
                "RAG evaluation task failed (attempt %s): %s",
                self.request.retries + 1,
                str(exc),
            )
            raise self.retry(exc=exc, countdown=2 ** self.request.retries)