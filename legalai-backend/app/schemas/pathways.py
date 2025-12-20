from marshmallow import Schema, fields, validate, validates_schema, ValidationError

class PathwaySchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    summary = fields.Str(allow_none=True)
    steps = fields.List(fields.Dict(), required=True)
    category = fields.Str(allow_none=True, validate=validate.Length(max=120))
    language = fields.Str(load_default="en", validate=validate.OneOf(["en", "ur"]))
    tags = fields.List(fields.Str(), load_default=[])

    @validates_schema
    def validate_steps(self, data, **kwargs):
        steps = data.get("steps")
        if steps is None or not isinstance(steps, list) or len(steps) == 0:
            raise ValidationError("steps must be a non-empty list.", "steps")

class PathwayQuerySchema(Schema):
    category = fields.Str()
    language = fields.Str(validate=validate.OneOf(["en", "ur"]))
