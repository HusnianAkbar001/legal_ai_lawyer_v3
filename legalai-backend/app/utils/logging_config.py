import os
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path


def _resolve_log_level(app) -> int:
    """
    Industry default:
    - DEBUG in development
    - INFO in production
    Can be overridden via LOG_LEVEL env var.
    """
    override = os.getenv("LOG_LEVEL")
    if override:
        return getattr(logging, override.upper(), logging.INFO)
    return logging.DEBUG if app.debug else logging.INFO


def setup_logging(app) -> None:
    """
    Centralized, production-friendly logging:
    - Console + rotating file
    - No sensitive data logging by default
    - Single configuration point for the whole app
    """
    log_level = _resolve_log_level(app)

    # File logging destination (env override) — default requested by you
    log_file = os.getenv("LOG_FILE", "logs/app.log")
    log_path = Path(log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    # Avoid duplicated handlers on Flask reload
    root = logging.getLogger()
    root.setLevel(log_level)

    formatter = logging.Formatter(
        fmt="%(asctime)s %(levelname)s %(name)s: %(message)s"
    )

    # Clear existing handlers to prevent double logs (common in debug reloader)
    for h in list(root.handlers):
        root.removeHandler(h)

    # Console handler
    sh = logging.StreamHandler()
    sh.setLevel(log_level)
    sh.setFormatter(formatter)
    root.addHandler(sh)

    # Rotating file handler (10MB x 5 backups)
    fh = RotatingFileHandler(
        log_path,
        maxBytes=10 * 1024 * 1024,
        backupCount=5,
        encoding="utf-8",
    )
    fh.setLevel(log_level)
    fh.setFormatter(formatter)
    root.addHandler(fh)

    # Ensure Flask app logger propagates to root handlers
    app.logger.handlers = []
    app.logger.propagate = True
    app.logger.setLevel(log_level)

    # Optional: reduce noisy libraries
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("werkzeug").setLevel(logging.INFO)
