from datetime import datetime, timedelta
from .celery_app import celery
from ..extensions import db
from ..models.reminders import Reminder
from ..services.push_service import PushService
from flask import current_app


@celery.task(bind=True)
def send_due_reminders(self):
    """
    Check for reminders due in the next minute and send push notifications.
    
    Runs every 60 seconds via Celery beat schedule.
    Executes inside Flask app context via ContextTask.
    """
    try:
        current_app.logger.info(
            f"[TASK START] send_due_reminders | task_id={self.request.id}"
        )
        
        now_utc = datetime.utcnow()
        window = now_utc + timedelta(minutes=1)

        due = Reminder.query.filter(
            Reminder.is_done == False,
            Reminder.scheduled_at <= window
        ).all()

        current_app.logger.info(
            f"[TASK] Found {len(due)} due reminders | window={window.isoformat()}"
        )

        sent_count = 0
        failed_count = 0

        for r in due:
            try:
                PushService.send_to_user(
                    r.user_id,
                    title=r.title,
                    body=r.notes or "Reminder",
                    data={"reminderId": r.id}
                )
                sent_count += 1
                current_app.logger.debug(
                    f"[TASK] Sent reminder | reminder_id={r.id} | user_id={r.user_id}"
                )
            except Exception as e:
                failed_count += 1
                current_app.logger.error(
                    f"[TASK ERROR] Failed to send reminder | "
                    f"reminder_id={r.id} | user_id={r.user_id} | error={str(e)}"
                )
        
        current_app.logger.info(
            f"[TASK SUCCESS] send_due_reminders completed | "
            f"sent={sent_count} | failed={failed_count}"
        )
                    
    except Exception as e:
        current_app.logger.error(
            f"[TASK ERROR] send_due_reminders failed | error={str(e)}",
            exc_info=True
        )
        raise


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