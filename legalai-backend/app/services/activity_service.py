from ..extensions import db
from ..models.activity import ActivityEvent

class ActivityService:
    @staticmethod
    def log(user_id: int, event_type: str, payload=None):
        ev = ActivityEvent(user_id=user_id, event_type=event_type, payload=payload or {})
        db.session.add(ev)
        db.session.commit()
        return ev
