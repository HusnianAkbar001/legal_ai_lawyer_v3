from marshmallow import Schema, fields, validate, validates, validates_schema, ValidationError
import re

PASSWORD_RE = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$")

class SignupSchema(Schema):
    name = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    email = fields.Email(required=True)
    phone = fields.Str(required=True, validate=validate.Length(min=5, max=30))
    cnic = fields.Str(required=True, validate=validate.Length(min=5, max=30))
    password = fields.Str(required=True, load_only=True)

    city = fields.Str(load_default=None)
    gender = fields.Str(load_default=None)
    age = fields.Int(load_default=None)

    fatherName = fields.Str(load_default=None, data_key="fatherName")
    fatherCnic = fields.Str(load_default=None, data_key="fatherCnic")
    motherName = fields.Str(load_default=None, data_key="motherName")
    motherCnic = fields.Str(load_default=None, data_key="motherCnic")

    totalSiblings = fields.Int(load_default=0)
    brothers = fields.Int(load_default=0)
    sisters = fields.Int(load_default=0)

    timezone = fields.Str(load_default="UTC")

    @validates("password")
    def validate_password(self, value):
        if not PASSWORD_RE.match(value or ""):
            raise ValidationError(
                "Password must be at least 8 characters and include uppercase, lowercase, and a special character."
            )
            
    @validates_schema
    def validate_cnic_uniqueness(self, data, **kwargs):
        def norm(v):
            return re.sub(r"[^0-9]", "", (v or ""))

        user_cnic = norm(data.get("cnic"))
        father_cnic = norm(data.get("fatherCnic"))
        mother_cnic = norm(data.get("motherCnic"))

        # Only enforce when parent CNICs are provided
        if father_cnic and father_cnic == user_cnic:
            raise ValidationError(
                "Father CNIC cannot be the same as user CNIC.",
                field_name="fatherCnic",
            )

        if mother_cnic and mother_cnic == user_cnic:
            raise ValidationError(
                "Mother CNIC cannot be the same as user CNIC.",
                field_name="motherCnic",
            )

        if father_cnic and mother_cnic and father_cnic == mother_cnic:
            raise ValidationError(
                "Father CNIC and Mother CNIC cannot be the same.",
                field_name="motherCnic",
            )

class LoginSchema(Schema):
    email = fields.Email(required=True)
    password = fields.Str(required=True, load_only=True, validate=validate.Length(min=1))

class RefreshSchema(Schema):
    refreshToken = fields.Str(required=True)

class ForgotPasswordSchema(Schema):
    email = fields.Email(required=True)

class ResetPasswordSchema(Schema):
    token = fields.Str(required=True)
    newPassword = fields.Str(required=True, load_only=True)

    @validates("newPassword")
    def validate_password(self, value):
        if not PASSWORD_RE.match(value or ""):
            raise ValidationError(
                "Password must be at least 8 characters and include uppercase, lowercase, and a special character."
            )


class ChangePasswordSchema(Schema):
    currentPassword = fields.Str(required=True, load_only=True)
    newPassword = fields.Str(required=True, load_only=True)
    confirmPassword = fields.Str(required=True, load_only=True)

    @validates("newPassword")
    def validate_password(self, value):
        if not PASSWORD_RE.match(value or ""):
            raise ValidationError(
                "Password must be at least 8 characters and include uppercase, lowercase, and a special character."
            )

    @validates_schema
    def validate_match(self, data, **kwargs):
        if data.get("newPassword") != data.get("confirmPassword"):
            raise ValidationError(
                "New password and confirmation must match.",
                field_name="confirmPassword",
            )
        if data.get("currentPassword") == data.get("newPassword"):
            raise ValidationError(
                "New password must be different from the current password.",
                field_name="newPassword",
            )
