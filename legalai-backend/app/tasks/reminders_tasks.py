from datetime import datetime, timedelta
import pytz
from .celery_app import celery
from ..extensions import db
from ..models.reminders import Reminder
from ..services.push_service import PushService

@celery.task
def send_due_reminders():
    now_utc = datetime.utcnow()
    window = now_utc + timedelta(minutes=1)

    due = Reminder.query.filter(
        Reminder.is_done == False,
        Reminder.scheduled_at <= window
    ).all()

    for r in due:
        PushService.send_to_user(
            r.user_id,
            title=r.title,
            body=r.notes or "Reminder",
            data={"reminderId": r.id}
        )

@celery.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    sender.add_periodic_task(60.0, send_due_reminders.s(), name="send reminders every minute")
