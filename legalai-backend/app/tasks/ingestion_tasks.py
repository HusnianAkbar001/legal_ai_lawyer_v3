import time
from .celery_app import celery
from ..extensions import db
from ..models.rag import KnowledgeSource, KnowledgeChunk
from ..services.llm_service import LLMService
from ..utils.text_extract import extract_text_from_source, chunk_text
from flask import current_app

_TASK_APP = None


def _get_task_app():
    """
    Return a Flask app instance usable inside Celery worker tasks.

    - If a Flask app context is already active, reuse it.
    - Otherwise, create the app once via create_app() and cache it.
    """
    global _TASK_APP
    if _TASK_APP is not None:
        return _TASK_APP

    try:
        _TASK_APP = current_app._get_current_object()
        return _TASK_APP
    except Exception:
        from .. import create_app

        _TASK_APP = create_app()
        return _TASK_APP
def _retry_sleep(attempt: int):
    time.sleep(min(2 ** attempt, 20))


@celery.task
def ingest_source(source_id: int):
    app = _get_task_app()
    with app.app_context():
        src = KnowledgeSource.query.get(source_id)
        if not src:
            return

        try:
            src.retry_count = (src.retry_count or 0) + 1
            src.status = "processing"
            src.error_message = None
            db.session.commit()

            text = extract_text_from_source(src)
            if not text or len(text.strip()) < 20:
                src.status = "invalid"
                src.error_message = "Extraction returned empty or too little text."
                db.session.commit()
                return

            chunks = chunk_text(text)
            chunks = [c for c in chunks if c and len(c.strip()) >= 5]

            if not chunks:
                src.status = "invalid"
                src.error_message = "No valid chunks produced from extracted text."
                db.session.commit()
                return

            batch_size = 32 
            model_name = current_app.config["EMBEDDING_MODEL_NAME"]
            expected_dim = current_app.config["EMBEDDING_DIMENSION"]
            for i in range(0, len(chunks), batch_size):
                batch = chunks[i:i + batch_size]

                for attempt in range(3):
                    try:
                        embs = LLMService.embed(batch) 
                        break
                    except Exception as e:
                        if attempt == 2:
                            raise e
                        _retry_sleep(attempt + 1)

                for ch, emb in zip(batch, embs):
                    db.session.add(
                        KnowledgeChunk(
                            source_id=src.id,
                            chunk_text=ch,
                            embedding=emb,
                            embedding_model=model_name,
                            embedding_dimension=expected_dim,
                        )
                    )
                db.session.flush()

            db.session.commit()
            src.status = "done"
            src.error_message = None
            src.embedding_model = model_name
            src.embedding_dimension = expected_dim
            db.session.commit()

        except Exception as e:
            db.session.rollback()
            src.status = "failed"
            src.error_message = str(e)
            db.session.commit()

@celery.task
def retry_stale_knowledge_sources():
    """
    Periodic watchdog task that retries knowledge sources that are still
    not ingested successfully.

    Rules:
      - Only status in ("queued", "failed") are auto-retired.
      - status == "invalid" is never auto-retired (permanent input problem).
      - Automatic retries stop when retry_count >= 10.
      - Manual admin retries are still allowed beyond 10.
    """
    stale = KnowledgeSource.query.filter(
        KnowledgeSource.status.in_(("queued", "failed")),
        KnowledgeSource.retry_count < 10,
    ).all()

    for src in stale:
        ingest_source.delay(src.id)


@celery.on_after_configure.connect
def setup_periodic_ingestion_retry(sender, **kwargs):
    """
    Register periodic execution for retrying stale knowledge sources.

    This uses a 24-hour interval based on the system time of the environment
    where Celery is running, avoiding time-zone assumptions.
    """
    sender.add_periodic_task(
        24 * 60 * 60,
        retry_stale_knowledge_sources.s(),
        name="retry_stale_knowledge_sources_every_24h",
    )
