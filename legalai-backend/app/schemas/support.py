from marshmallow import Schema, fields, validates, ValidationError


class ContactUsSchema(Schema):
    fullName = fields.Str(required=True)
    email = fields.Email(required=True)
    phone = fields.Str(required=True)
    subject = fields.Str(required=True)
    description = fields.Str(required=True)

    @validates("fullName")
    def _name(self, v: str):
        if not v.strip():
            raise ValidationError("Full name is required")

    @validates("phone")
    def _phone(self, v: str):
        if not v.strip():
            raise ValidationError("Phone is required")

    @validates("subject")
    def _subject(self, v: str):
        if not v.strip():
            raise ValidationError("Subject is required")

    @validates("description")
    def _desc(self, v: str):
        if not v.strip():
            raise ValidationError("Description is required")


class FeedbackSchema(Schema):
    rating = fields.Int(required=True)
    comment = fields.Str(required=True)

    @validates("rating")
    def _rating(self, v: int):
        if v < 1 or v > 5:
            raise ValidationError("Rating must be between 1 and 5")

    @validates("comment")
    def _comment(self, v: str):
        if not v.strip():
            raise ValidationError("Comment is required")
