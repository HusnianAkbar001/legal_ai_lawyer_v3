from marshmallow import Schema, fields, validate

class RightSchema(Schema):
    id = fields.Int(dump_only=True)
    topic = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    body = fields.Str(required=True, validate=validate.Length(min=1))
    category = fields.Str(allow_none=True, validate=validate.Length(max=120))
    language = fields.Str(load_default="en", validate=validate.OneOf(["en", "ur"]))
    tags = fields.List(fields.Str(), load_default=[])

class RightQuerySchema(Schema):
    category = fields.Str()
    language = fields.Str(validate=validate.OneOf(["en", "ur"]))
