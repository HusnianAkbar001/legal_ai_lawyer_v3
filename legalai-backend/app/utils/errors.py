from flask import jsonify
from werkzeug.exceptions import HTTPException
from marshmallow import ValidationError

def register_error_handlers(app):
    @app.errorhandler(ValidationError)
    def handle_validation(e: ValidationError):
        return jsonify({"message": "Validation error", "errors": e.messages}), 400

    @app.errorhandler(HTTPException)
    def handle_http(e):
        return jsonify({"message": e.description, "error": e.description}), e.code

    @app.errorhandler(Exception)
    def handle_any(e):
        app.logger.exception(e)
        return jsonify({"error": "Internal server error"}), 500
