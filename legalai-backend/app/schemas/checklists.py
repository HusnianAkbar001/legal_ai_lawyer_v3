from marshmallow import Schema, fields, validate

class ChecklistCategorySchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    icon = fields.Str(allow_none=True, validate=validate.Length(max=80))
    order = fields.Int(load_default=0)

class ChecklistItemSchema(Schema):
    id = fields.Int(dump_only=True)
    categoryId = fields.Int(required=True, data_key="categoryId")
    text = fields.Str(required=True, validate=validate.Length(min=1, max=300))
    required = fields.Bool(load_default=False)
    order = fields.Int(load_default=0)

class ChecklistItemQuerySchema(Schema):
    categoryId = fields.Int(data_key="categoryId")
