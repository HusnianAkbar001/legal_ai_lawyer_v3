from datetime import datetime, timedelta
import pytz
from .celery_app import celery
from ..extensions import db
from ..models.reminders import Reminder
from ..services.push_service import PushService
from flask import current_app

_flask_app = None


def _get_app():
    """
    Return a Flask app instance usable inside Celery worker tasks.
    
    Creates the app once and caches it for reuse across task executions.
    """
    global _flask_app
    if _flask_app is None:
        from .. import create_app
        _flask_app = create_app()
    return _flask_app


@celery.task
def send_due_reminders():
    """
    Check for reminders due in the next minute and send push notifications.
    
    Runs every 60 seconds via Celery beat schedule.
    """
    app = _get_app()
    with app.app_context():
        try:
            now_utc = datetime.utcnow()
            window = now_utc + timedelta(minutes=1)

            due = Reminder.query.filter(
                Reminder.is_done == False,
                Reminder.scheduled_at <= window
            ).all()

            current_app.logger.info(
                "Checking reminders: found %d due reminders",
                len(due)
            )

            for r in due:
                try:
                    PushService.send_to_user(
                        r.user_id,
                        title=r.title,
                        body=r.notes or "Reminder",
                        data={"reminderId": r.id}
                    )
                    current_app.logger.debug(
                        "Sent reminder notification: reminder_id=%s, user_id=%s",
                        r.id,
                        r.user_id
                    )
                except Exception as e:
                    # Log error but continue processing other reminders
                    current_app.logger.error(
                        "Failed to send reminder notification: reminder_id=%s, error=%s",
                        r.id,
                        str(e)
                    )
                    
        except Exception as e:
            current_app.logger.exception(
                "Failed to process due reminders: %s",
                str(e)
            )


@celery.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    """
    Register periodic task to check for due reminders every minute.
    """
    sender.add_periodic_task(
        60.0,
        send_due_reminders.s(),
        name="send_reminders_every_minute"
    )