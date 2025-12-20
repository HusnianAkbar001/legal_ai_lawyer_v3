from marshmallow import Schema, fields, validate, validates_schema, ValidationError

class DraftGenerateSchema(Schema):
    templateId = fields.Int(required=True, data_key="templateId")
    answers = fields.Dict(required=True)
    userSnapshot = fields.Dict(required=True, data_key="userSnapshot")

    @validates_schema
    def validate_payload(self, data, **kwargs):
        if not isinstance(data.get("answers"), dict):
            raise ValidationError("answers must be an object.", "answers")
        if not isinstance(data.get("userSnapshot"), dict):
            raise ValidationError("userSnapshot must be an object.", "userSnapshot")

class DraftSchema(Schema):
    id = fields.Int(dump_only=True)
    userId = fields.Int(dump_only=True, data_key="userId")
    templateId = fields.Int(required=True, data_key="templateId")

    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    contentText = fields.Str(required=True, data_key="contentText")

    answers = fields.Dict(required=True)
    userSnapshot = fields.Dict(required=True, data_key="userSnapshot")

    createdAt = fields.DateTime(dump_only=True, data_key="createdAt")

class DraftExportQuerySchema(Schema):
    format = fields.Str(load_default="txt", validate=validate.OneOf(["txt", "pdf", "docx"]))
