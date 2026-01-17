import jwt
from functools import wraps
from flask import request, current_app, g
from werkzeug.exceptions import Unauthorized, Forbidden
from ..models.user import User

def require_auth(admin=False):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            header = request.headers.get("Authorization", "")
            if not header.startswith("Bearer "):
                raise Unauthorized("Missing token")
            token = header.split(" ", 1)[1]

            try:
                payload = jwt.decode(token, current_app.config["SECRET_KEY"], algorithms=["HS256"])
            except jwt.PyJWTError:
                raise Unauthorized("Invalid token")

            if payload.get("type") != "access":
                raise Unauthorized("Invalid token type")

            user = User.query.get(payload["sub"])
            if not user:
                raise Unauthorized("User not found")
            if getattr(user, "is_deleted", False):
                raise Unauthorized("User not found")
            token_version = payload.get("v", 0)
            if token_version != (user.token_version or 0):
                raise Unauthorized("Session expired")

            if admin and not user.is_admin:
                raise Forbidden("Admin only")

            g.user = user
            return fn(*args, **kwargs)
        return wrapper
    return decorator

def safe_mode_on():
    return request.headers.get("X-Safe-Mode", "0") == "1"
