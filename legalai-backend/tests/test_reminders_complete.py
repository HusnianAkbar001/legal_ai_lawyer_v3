import pytest
from datetime import datetime, timedelta
from app.models.reminders import Reminder, DeviceToken

class TestReminders:
    
    def test_create_reminder_success(self, client, auth_headers, user):
        """Test create reminder"""
        scheduled_time = (datetime.utcnow() + timedelta(days=1)).isoformat()
        
        response = client.post("/api/v1/reminders",
            headers=auth_headers,
            json={
                "title": "Court Hearing",
                "notes": "Bring all documents",
                "scheduledAt": scheduled_time,
                "timezone": "Asia/Karachi"
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_create_reminder_missing_fields(self, client, auth_headers):
        """Test create reminder without required fields"""
        response = client.post("/api/v1/reminders",
            headers=auth_headers,
            json={
                "title": "Test"
            }
        )
        
        assert response.status_code == 400
    
    def test_create_reminder_safe_mode(self, client, auth_headers):
        """Test create reminder blocked in safe mode"""
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        scheduled_time = (datetime.utcnow() + timedelta(days=1)).isoformat()
        
        response = client.post("/api/v1/reminders",
            headers=headers,
            json={
                "title": "Test",
                "scheduledAt": scheduled_time,
                "timezone": "Asia/Karachi"
            }
        )
        
        assert response.status_code == 403
    
    def test_list_reminders(self, client, auth_headers, user, db_session):
        """Test list reminders"""
        r1 = Reminder(
            user_id=user.id,
            title="Reminder 1",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        r2 = Reminder(
            user_id=user.id,
            title="Reminder 2",
            scheduled_at=datetime.utcnow() + timedelta(days=2),
            timezone="Asia/Karachi"
        )
        db_session.add_all([r1, r2])
        db_session.commit()
        
        response = client.get("/api/v1/reminders", headers=auth_headers)
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_update_reminder_success(self, client, auth_headers, user, db_session):
        """Test update reminder"""
        reminder = Reminder(
            user_id=user.id,
            title="Old Title",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        db_session.add(reminder)
        db_session.commit()
        
        new_time = (datetime.utcnow() + timedelta(days=5)).isoformat()
        
        response = client.put(f"/api/v1/reminders/{reminder.id}",
            headers=auth_headers,
            json={
                "title": "Updated Title",
                "notes": "New notes",
                "scheduledAt": new_time,
                "isDone": True
            }
        )
        
        assert response.status_code == 200
        
        updated = Reminder.query.get(reminder.id)
        assert updated.title == "Updated Title"
        assert updated.notes == "New notes"
        assert updated.is_done is True
    
    def test_update_reminder_not_owner(self, client, auth_headers, db_session):
        """Test update another user's reminder"""
        other_user_id = 99999
        reminder = Reminder(
            user_id=other_user_id,
            title="Other's Reminder",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        db_session.add(reminder)
        db_session.commit()
        
        response = client.put(f"/api/v1/reminders/{reminder.id}",
            headers=auth_headers,
            json={
                "title": "Hacked"
            }
        )
        
        assert response.status_code == 403
    
    def test_update_reminder_safe_mode(self, client, auth_headers, user, db_session):
        """Test update reminder blocked in safe mode"""
        reminder = Reminder(
            user_id=user.id,
            title="Test Reminder",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        db_session.add(reminder)
        db_session.commit()
        
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.put(f"/api/v1/reminders/{reminder.id}",
            headers=headers,
            json={
                "title": "Should Not Update"
            }
        )
        
        assert response.status_code == 403
    
    def test_delete_reminder_success(self, client, auth_headers, user, db_session):
        """Test delete reminder"""
        reminder = Reminder(
            user_id=user.id,
            title="To Delete",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        db_session.add(reminder)
        db_session.commit()
        
        response = client.delete(f"/api/v1/reminders/{reminder.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        assert Reminder.query.get(reminder.id) is None
    
    def test_delete_reminder_not_owner(self, client, auth_headers, db_session):
        """Test delete another user's reminder"""
        other_user_id = 99999
        reminder = Reminder(
            user_id=other_user_id,
            title="Other's Reminder",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        db_session.add(reminder)
        db_session.commit()
        
        response = client.delete(f"/api/v1/reminders/{reminder.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        # Since filter_by uses user_id, it won't delete other's reminder
        assert Reminder.query.get(reminder.id) is not None
    
    def test_delete_reminder_safe_mode(self, client, auth_headers, user, db_session):
        """Test delete reminder blocked in safe mode"""
        reminder = Reminder(
            user_id=user.id,
            title="Test",
            scheduled_at=datetime.utcnow() + timedelta(days=1),
            timezone="Asia/Karachi"
        )
        db_session.add(reminder)
        db_session.commit()
        
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.delete(f"/api/v1/reminders/{reminder.id}",
            headers=headers
        )
        
        assert response.status_code == 403
    
    def test_register_device_token_android(self, client, auth_headers, user):
        """Test register Android device token"""
        response = client.post("/api/v1/reminders/register-device-token",
            headers=auth_headers,
            json={
                "platform": "android",
                "token": "test_android_token_123456"
            }
        )
        
        assert response.status_code == 200
        assert response.json["ok"] is True
        
        # Verify token created
        token = DeviceToken.query.filter_by(token="test_android_token_123456").first()
        assert token is not None
        assert token.platform == "android"
        assert token.user_id == user.id
    
    def test_register_device_token_ios(self, client, auth_headers, user):
        """Test register iOS device token"""
        response = client.post("/api/v1/reminders/register-device-token",
            headers=auth_headers,
            json={
                "platform": "ios",
                "token": "test_ios_token_abcdef"
            }
        )
        
        assert response.status_code == 200
        
        token = DeviceToken.query.filter_by(token="test_ios_token_abcdef").first()
        assert token is not None
        assert token.platform == "ios"
    
    def test_register_device_token_invalid_platform(self, client, auth_headers):
        """Test register device token with invalid platform"""
        response = client.post("/api/v1/reminders/register-device-token",
            headers=auth_headers,
            json={
                "platform": "windows",
                "token": "test_token"
            }
        )
        
        assert response.status_code == 400
    
    def test_register_device_token_missing_fields(self, client, auth_headers):
        """Test register device token without required fields"""
        response = client.post("/api/v1/reminders/register-device-token",
            headers=auth_headers,
            json={
                "platform": "android"
            }
        )
        
        assert response.status_code == 400
    
    def test_register_device_token_upsert(self, client, auth_headers, user, db_session):
        """Test device token upsert (replaces existing)"""
        # Create existing token
        old_token = DeviceToken(
            user_id=user.id,
            platform="android",
            token="old_token_123"
        )
        db_session.add(old_token)
        db_session.commit()
        
        # Register same token again (should delete old and create new)
        response = client.post("/api/v1/reminders/register-device-token",
            headers=auth_headers,
            json={
                "platform": "android",
                "token": "old_token_123"
            }
        )
        
        assert response.status_code == 200
        
        # Should only have one token with this value
        tokens = DeviceToken.query.filter_by(token="old_token_123").all()
        assert len(tokens) == 1
        assert tokens[0].user_id == user.id
    
    def test_register_device_token_safe_mode(self, client, auth_headers):
        """Test register device token blocked in safe mode"""
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.post("/api/v1/reminders/register-device-token",
            headers=headers,
            json={
                "platform": "android",
                "token": "test_token"
            }
        )
        
        assert response.status_code == 403