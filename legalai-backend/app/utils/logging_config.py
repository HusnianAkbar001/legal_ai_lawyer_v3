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

    log_file = os.getenv("LOG_FILE", "logs/app.log")
    log_path = Path(log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    root = logging.getLogger()
    root.setLevel(log_level)

    formatter = logging.Formatter(
        fmt="%(asctime)s %(levelname)s %(name)s: %(message)s"
    )

    for h in list(root.handlers):
        root.removeHandler(h)

    sh = logging.StreamHandler()
    sh.setLevel(log_level)
    sh.setFormatter(formatter)
    root.addHandler(sh)

    fh = RotatingFileHandler(
        log_path,
        maxBytes=10 * 1024 * 1024,
        backupCount=5,
        encoding="utf-8",
    )
    fh.setLevel(log_level)
    fh.setFormatter(formatter)
    root.addHandler(fh)

    app.logger.handlers = []
    app.logger.propagate = True
    app.logger.setLevel(log_level)

    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("werkzeug").setLevel(logging.INFO)
