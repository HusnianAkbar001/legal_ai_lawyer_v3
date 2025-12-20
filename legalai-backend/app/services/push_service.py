import requests, json
from flask import current_app
from ..models.reminders import DeviceToken

class PushService:
    @staticmethod
    def send_fcm(tokens: list[str], title: str, body: str, data=None):
        if not tokens:
            return
        key = current_app.config.get("FCM_SERVER_KEY")
        if not key:
            return

        url = "https://fcm.googleapis.com/fcm/send"
        headers = {"Authorization": f"key={key}", "Content-Type": "application/json"}
        payload = {
            "registration_ids": tokens,
            "notification": {"title": title, "body": body},
            "data": data or {}
        }
        requests.post(url, headers=headers, data=json.dumps(payload), timeout=20)

    @staticmethod
    def send_apns(tokens: list[str], title: str, body: str, data=None):
        # Minimal APNS placeholder. In production use apns2 or a worker service.
        # We keep it safe/no-op if keys not set.
        if not tokens:
            return
        if not current_app.config.get("APNS_KEY_ID"):
            return
        # Implement via apns2 if needed.
        return

    @staticmethod
    def send_to_user(user_id: int, title: str, body: str, data=None):
        qt = DeviceToken.query.filter_by(user_id=user_id).all()
        android_tokens = [t.token for t in qt if t.platform == "android"]
        ios_tokens = [t.token for t in qt if t.platform == "ios"]

        PushService.send_fcm(android_tokens, title, body, data=data)
        PushService.send_apns(ios_tokens, title, body, data=data)
