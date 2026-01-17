from flask import jsonify
from werkzeug.exceptions import HTTPException
from marshmallow import ValidationError
from ..exceptions import AppError

def register_error_handlers(app):
    """Register global error handlers for consistent API responses"""
    
    @app.errorhandler(ValidationError)
    def handle_validation(e: ValidationError):
        """
        Handle Marshmallow validation errors (400 Bad Request).
        
        These are input format/type errors from schemas.
        Examples: invalid email format, weak password, missing required fields.
        """
        return jsonify({
            "message": "Validation error",
            "errors": e.messages
        }), 400

    @app.errorhandler(ValueError)
    def handle_value_error(e):
        app.logger.warning("ValueError raised: %s", str(e))
        return jsonify(
            {
                "message": "Invalid request",
                "error": "Invalid request",
            }
        ), 400

    @app.errorhandler(HTTPException)
    def handle_http(e):
        payload = {}
        if isinstance(e, AppError):
            payload = getattr(e, "details", {}) or {}

        body = {
            "message": e.description,
            "error": getattr(e, "error", e.description),
        }
        if payload:
            body["details"] = payload
        return jsonify(body), e.code

    @app.errorhandler(Exception)
    def handle_any(e):
        """
        Handle uncaught exceptions (500 Internal Server Error).
        
        Log full details but return generic message to prevent information disclosure.
        """
        app.logger.exception("Unhandled exception: %s", type(e).__name__)
        return jsonify({
            "error": "Internal server error"
        }), 500