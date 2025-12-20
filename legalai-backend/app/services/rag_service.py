import os
import statistics
from flask import current_app
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import func

from ..extensions import db
from ..models.rag import KnowledgeChunk, KnowledgeSource

class RAGService:
    _distance_threshold: float | None = None

    @staticmethod
    def get_distance_threshold() -> float:
        """
        Data-driven, self-calibrated threshold for deciding whether a query is in-domain (legal)
        relative to the uploaded knowledge base.

        Override via env:
          RAG_DISTANCE_THRESHOLD=<float>
        """
        override = os.getenv("RAG_DISTANCE_THRESHOLD")
        if override:
            try:
                return float(override)
            except ValueError:
                current_app.logger.warning("Invalid RAG_DISTANCE_THRESHOLD override; ignoring.")

        if RAGService._distance_threshold is not None:
            return RAGService._distance_threshold

        # Calibrate once per process (fast enough for your dataset size).
        RAGService._distance_threshold = RAGService._calibrate_distance_threshold()
        return RAGService._distance_threshold

    @staticmethod
    def _calibrate_distance_threshold(sample_size: int = 60) -> float:
        """
        Compute a robust threshold from the dataset itself:
        - sample embeddings
        - for each, compute nearest neighbor distance (excluding itself)
        - threshold = p95 + 0.5 * IQR (robust to outliers)

        This avoids hard-coded magic numbers.
        """
        try:
            samples = (
                db.session.query(KnowledgeChunk.id, KnowledgeChunk.embedding)
                .filter(KnowledgeChunk.embedding.isnot(None))
                .order_by(func.random())
                .limit(sample_size)
                .all()
            )

            distances: list[float] = []
            for chunk_id, emb in samples:
                if emb is None:
                    continue

                d = (
                    db.session.query(KnowledgeChunk.embedding.l2_distance(emb).label("d"))
                    .filter(KnowledgeChunk.embedding.isnot(None))
                    .filter(KnowledgeChunk.id != chunk_id)
                    .order_by("d")
                    .limit(1)
                    .scalar()
                )

                if d is not None:
                    distances.append(float(d))

            # Fallback if calibration couldn't collect enough values
            if len(distances) < 10:
                current_app.logger.warning(
                    "RAG threshold calibration had insufficient samples (n=%s). Using safe fallback.",
                    len(distances),
                )
                return 1.25  # safe fallback (can be overridden by env)

            distances.sort()
            p95 = distances[int(0.95 * (len(distances) - 1))]
            q1 = distances[int(0.25 * (len(distances) - 1))]
            q3 = distances[int(0.75 * (len(distances) - 1))]
            iqr = max(0.0, q3 - q1)

            threshold = float(p95 + 0.5 * iqr)

            current_app.logger.info(
                "RAG threshold calibrated sample_n=%s p95=%.4f iqr=%.4f threshold=%.4f",
                len(distances),
                p95,
                iqr,
                threshold,
            )
            return threshold

        except SQLAlchemyError:
            current_app.logger.exception("RAG threshold calibration failed. Using safe fallback.")
            return 1.25
    @staticmethod
    def search_similar_with_scores(embedding, top_k=None, language: str | None = None):
        """
        Returns: list of dicts: {"chunk_text": str, "distance": float}
        Distance is L2 distance (smaller = more similar).
        """
        top_k = top_k or current_app.config["RAG_TOP_K"]

        distance_col = KnowledgeChunk.embedding.l2_distance(embedding).label("distance")

        q = db.session.query(KnowledgeChunk.chunk_text, distance_col).filter(
            KnowledgeChunk.embedding.isnot(None)
        )

        if language:
            q = (
                q.join(KnowledgeSource, KnowledgeChunk.source_id == KnowledgeSource.id)
                 .filter(KnowledgeSource.language == language)
            )

        rows = (
            q.order_by(distance_col.asc())
             .limit(top_k)
             .all()
        )

        return [{"chunk_text": r.chunk_text, "distance": float(r.distance)} for r in rows]
