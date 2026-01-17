from __future__ import annotations

from typing import Any

from werkzeug.exceptions import HTTPException


class AppError(HTTPException):
    code = 500

    def __init__(
        self,
        message: str,
        *,
        code: int | None = None,
        error: str | None = None,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(description=message)
        if code is not None:
            self.code = code
        self.error = error or message
        self.details = details or {}


class ValidationError400(AppError):
    code = 400


class ConflictError409(AppError):
    code = 409
