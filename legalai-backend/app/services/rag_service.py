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
        Get distance threshold with environment variable override support.
        
        Priority order:
        1. RAG_DISTANCE_THRESHOLD env var (manual override)
        2. Cached calibrated threshold
        3. Fresh calibration
        
        Returns:
            float: Distance threshold for in-domain detection
        """
        # Check for manual override first (production tuning)
        override = os.getenv("RAG_DISTANCE_THRESHOLD")
        if override:
            try:
                threshold = float(override)
                if 0.5 <= threshold <= 3.0:  # Sanity check
                    current_app.logger.info(
                        "Using manual RAG threshold override: %.4f", threshold
                    )
                    return threshold
                else:
                    current_app.logger.warning(
                        "Invalid RAG_DISTANCE_THRESHOLD override (%.4f). Must be between 0.5 and 3.0. Using calibration.",
                        threshold,
                    )
            except (ValueError, TypeError):
                current_app.logger.warning(
                    "Invalid RAG_DISTANCE_THRESHOLD format: %s. Using calibration.",
                    override,
                )

        # Use cached threshold if available
        if RAGService._distance_threshold is not None:
            return RAGService._distance_threshold

        # Calibrate and cache
        RAGService._distance_threshold = RAGService._calibrate_distance_threshold()
        return RAGService._distance_threshold
    
    # @staticmethod
    # def get_distance_threshold() -> float:
    #     """
    #     Data-driven, self-calibrated threshold for deciding whether a query is in-domain (legal)
    #     relative to the uploaded knowledge base.

    #     Override via env:
    #       RAG_DISTANCE_THRESHOLD=<float>
    #     """
    #     override = os.getenv("RAG_DISTANCE_THRESHOLD")
    #     if override:
    #         try:
    #             return float(override)
    #         except ValueError:
    #             current_app.logger.warning("Invalid RAG_DISTANCE_THRESHOLD override; ignoring.")

    #     if RAGService._distance_threshold is not None:
    #         return RAGService._distance_threshold

    #     # Calibrate once per process (fast enough for your dataset size).
    #     RAGService._distance_threshold = RAGService._calibrate_distance_threshold()
    #     return RAGService._distance_threshold

    @staticmethod
    def _calibrate_distance_threshold(sample_size: int = 60) -> float:
        """
        Compute a robust threshold from the dataset itself with improved fallback.
        
        Industry best practice: Auto-calibrate based on actual data distribution,
        with manual override support for production tuning.
        
        Methodology:
        - Sample random embeddings from knowledge base
        - For each, find nearest neighbor distance
        - Use P95 + 0.6 * IQR as threshold (slightly more lenient than before)
        - Fallback to 1.45 if calibration fails (tested to work with legal docs)
        
        Returns:
            float: Calibrated distance threshold
        """
        try:
            samples = (
                db.session.query(KnowledgeChunk.id, KnowledgeChunk.embedding)
                .filter(KnowledgeChunk.embedding.isnot(None))
                .order_by(func.random())
                .limit(sample_size)
                .all()
            )

            if not samples or len(samples) < 10:
                current_app.logger.warning(
                    "RAG threshold calibration: insufficient samples (n=%s). Using fallback.",
                    len(samples) if samples else 0,
                )
                return 1.45  # Tested fallback for legal documents

            distances: list[float] = []
            
            for chunk_id, emb in samples:
                if emb is None:
                    continue

                # Find nearest neighbor distance (excluding self)
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

            # Require minimum sample size for robust calibration
            if len(distances) < 10:
                current_app.logger.warning(
                    "RAG threshold calibration: insufficient distance samples (n=%s). Using fallback.",
                    len(distances),
                )
                return 1.45

            distances.sort()
            n = len(distances)
            
            # Compute robust percentiles
            p95_idx = int(0.95 * (n - 1))
            q1_idx = int(0.25 * (n - 1))
            q3_idx = int(0.75 * (n - 1))
            
            p95 = distances[p95_idx]
            q1 = distances[q1_idx]
            q3 = distances[q3_idx]
            iqr = max(0.0, q3 - q1)

            # More lenient threshold: P95 + 0.6 * IQR (was 0.5 before)
            threshold = float(p95 + 0.6 * iqr)
            
            # Safety bounds: not too strict, not too loose
            threshold = max(1.0, min(threshold, 2.0))

            current_app.logger.info(
                "RAG threshold calibrated: samples=%s p95=%.4f q1=%.4f q3=%.4f iqr=%.4f threshold=%.4f",
                n,
                p95,
                q1,
                q3,
                iqr,
                threshold,
            )
            return threshold

        except Exception:
            current_app.logger.exception(
                "RAG threshold calibration failed. Using safe fallback."
            )
            return 1.45  # Safe fallback tested with legal documents
        
    # @staticmethod
    # def _calibrate_distance_threshold(sample_size: int = 60) -> float:
    #     """
    #     Compute a robust threshold from the dataset itself:
    #     - sample embeddings
    #     - for each, compute nearest neighbor distance (excluding itself)
    #     - threshold = p95 + 0.5 * IQR (robust to outliers)

    #     This avoids hard-coded magic numbers.
    #     """
    #     try:
    #         samples = (
    #             db.session.query(KnowledgeChunk.id, KnowledgeChunk.embedding)
    #             .filter(KnowledgeChunk.embedding.isnot(None))
    #             .order_by(func.random())
    #             .limit(sample_size)
    #             .all()
    #         )

    #         distances: list[float] = []
    #         for chunk_id, emb in samples:
    #             if emb is None:
    #                 continue

    #             d = (
    #                 db.session.query(KnowledgeChunk.embedding.l2_distance(emb).label("d"))
    #                 .filter(KnowledgeChunk.embedding.isnot(None))
    #                 .filter(KnowledgeChunk.id != chunk_id)
    #                 .order_by("d")
    #                 .limit(1)
    #                 .scalar()
    #             )

    #             if d is not None:
    #                 distances.append(float(d))

    #         # Fallback if calibration couldn't collect enough values
    #         if len(distances) < 10:
    #             current_app.logger.warning(
    #                 "RAG threshold calibration had insufficient samples (n=%s). Using safe fallback.",
    #                 len(distances),
    #             )
    #             return 1.25  # safe fallback (can be overridden by env)

    #         distances.sort()
    #         p95 = distances[int(0.95 * (len(distances) - 1))]
    #         q1 = distances[int(0.25 * (len(distances) - 1))]
    #         q3 = distances[int(0.75 * (len(distances) - 1))]
    #         iqr = max(0.0, q3 - q1)

    #         threshold = float(p95 + 0.5 * iqr)

    #         current_app.logger.info(
    #             "RAG threshold calibrated sample_n=%s p95=%.4f iqr=%.4f threshold=%.4f",
    #             len(distances),
    #             p95,
    #             iqr,
    #             threshold,
    #         )
    #         return threshold

    #     except SQLAlchemyError:
    #         current_app.logger.exception("RAG threshold calibration failed. Using safe fallback.")
    #         return 1.25
        
    @staticmethod
    def search_similar_with_scores(embedding, top_k=None, language: str | None = None):
        """
        Returns: list of dicts: {"chunk_text": str, "distance": float, "chunk_id": int}
        Distance is L2 distance (smaller = more similar).
        """
        top_k = top_k or current_app.config["RAG_TOP_K"]

        distance_col = KnowledgeChunk.embedding.l2_distance(embedding).label("distance")

        q = db.session.query(
            KnowledgeChunk.id,
            KnowledgeChunk.chunk_text,
            distance_col
        ).filter(
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

        return [
            {
                "chunk_id": r.id,
                "chunk_text": r.chunk_text,
                "distance": float(r.distance)
            } 
            for r in rows
        ]
