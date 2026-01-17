import re
from passlib.hash import argon2
from ..exceptions import ValidationError400

PASSWORD_RE = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$")

def validate_password(pw: str):
    if not PASSWORD_RE.match(pw or ""):
        raise ValidationError400(
    "Password must be 8+ chars with uppercase, lowercase, special char.",
    details={"field": "password"},
)

def hash_password(pw: str) -> str:
    return argon2.hash(pw)

def verify_password(pw: str, hashed: str) -> bool:
    return argon2.verify(pw, hashed)
