from marshmallow import Schema, fields, validate

class TemplateSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    description = fields.Str(allow_none=True)
    body = fields.Str(required=True, validate=validate.Length(min=1))
    category = fields.Str(allow_none=True, validate=validate.Length(max=120))
    language = fields.Str(load_default="en", validate=validate.OneOf(["en", "ur"]))
    tags = fields.List(fields.Str(), load_default=[])

class TemplateQuerySchema(Schema):
    category = fields.Str()
    language = fields.Str(validate=validate.OneOf(["en", "ur"]))
