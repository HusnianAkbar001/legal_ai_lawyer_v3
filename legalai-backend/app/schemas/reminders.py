from marshmallow import Schema, fields, validate

class ReminderCreateSchema(Schema):
    title = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    notes = fields.Str(allow_none=True)
    scheduledAt = fields.DateTime(required=True, data_key="scheduledAt")
    timezone = fields.Str(allow_none=True)

class ReminderUpdateSchema(Schema):
    title = fields.Str(validate=validate.Length(min=1, max=200))
    notes = fields.Str(allow_none=True)
    scheduledAt = fields.DateTime(data_key="scheduledAt")
    timezone = fields.Str()
    isDone = fields.Bool(data_key="isDone")

class ReminderSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True)
    notes = fields.Str(allow_none=True)
    scheduledAt = fields.DateTime(required=True, data_key="scheduledAt")
    timezone = fields.Str(required=True)
    isDone = fields.Bool(required=True, data_key="isDone")

class DeviceTokenSchema(Schema):
    platform = fields.Str(required=True, validate=validate.OneOf(["android", "ios"]))
    token = fields.Str(required=True, validate=validate.Length(min=10))
