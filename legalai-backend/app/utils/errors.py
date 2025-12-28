from flask import jsonify
from werkzeug.exceptions import HTTPException
from marshmallow import ValidationError

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
        """
        Handle ValueError from service layer (409 Conflict).
        
        These are business logic errors.
        Examples: duplicate email/CNIC, invalid state transitions.
        """
        app.logger.warning(f"Business logic validation failed: {str(e)}")
        return jsonify({"message": str(e)}), 409

    @app.errorhandler(HTTPException)
    def handle_http(e):
        """Handle Werkzeug HTTP exceptions (400, 401, 403, 404, etc.)"""
        return jsonify({
            "message": e.description,
            "error": e.description
        }), e.code

    @app.errorhandler(Exception)
    def handle_any(e):
        """
        Handle uncaught exceptions (500 Internal Server Error).
        
        Log full details but return generic message to prevent information disclosure.
        """
        app.logger.exception(f"Unhandled exception: {type(e).__name__}: {str(e)}")
        return jsonify({
            "error": "Internal server error"
        }), 500