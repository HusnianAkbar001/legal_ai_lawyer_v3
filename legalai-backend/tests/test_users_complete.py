import io
import pytest
from app.models.activity import Bookmark, ActivityEvent

class TestUsers:
    
    def test_get_me_success(self, client, auth_headers):
        """Test get current user"""
        response = client.get("/api/v1/users/me", headers=auth_headers)
        
        assert response.status_code == 200
        assert response.json["email"] == "test@example.com"
        assert "id" in response.json
        assert "isAdmin" in response.json
    
    def test_get_me_unauthorized(self, client):
        """Test get me without auth"""
        response = client.get("/api/v1/users/me")
        
        assert response.status_code == 401
    
    def test_update_me_success(self, client, auth_headers):
        """Test update user profile"""
        response = client.put("/api/v1/users/me",
            headers=auth_headers,
            json={
                "name": "Updated Name",
                "city": "Lahore",
                "age": 30
            }
        )
        
        assert response.status_code == 200
        
        # Verify update
        get_response = client.get("/api/v1/users/me", headers=auth_headers)
        assert get_response.json["name"] == "Updated Name"
        assert get_response.json["city"] == "Lahore"
        assert get_response.json["age"] == 30
    
    def test_update_me_safe_mode(self, client, auth_headers):
        """Test update blocked in safe mode"""
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.put("/api/v1/users/me",
            headers=headers,
            json={"name": "Should Not Update"}
        )
        
        assert response.status_code == 403
    
    def test_upload_avatar_success(self, client, auth_headers):
        """Test avatar upload"""
        data = {
            'file': (io.BytesIO(b"fake image content"), 'avatar.jpg')
        }
        
        response = client.post("/api/v1/users/me/avatar",
            headers=auth_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 200
        assert "avatarPath" in response.json
    
    def test_add_bookmark_success(self, client, auth_headers, db_session):
        """Test add bookmark"""
        response = client.post("/api/v1/users/me/bookmarks",
            headers=auth_headers,
            json={
                "itemType": "right",
                "itemId": 1
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_add_bookmark_invalid_type(self, client, auth_headers):
        """Test add bookmark with invalid type"""
        response = client.post("/api/v1/users/me/bookmarks",
            headers=auth_headers,
            json={
                "itemType": "invalid",
                "itemId": 1
            }
        )
        
        assert response.status_code == 400
    
    def test_list_bookmarks(self, client, auth_headers, user, db_session):
        """Test list bookmarks"""
        # Add bookmarks
        bm1 = Bookmark(user_id=user.id, item_type="right", item_id=1)
        bm2 = Bookmark(user_id=user.id, item_type="template", item_id=2)
        db_session.add_all([bm1, bm2])
        db_session.commit()
        
        response = client.get("/api/v1/users/me/bookmarks", headers=auth_headers)
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_delete_bookmark_success(self, client, auth_headers, user, db_session):
        """Test delete bookmark"""
        bm = Bookmark(user_id=user.id, item_type="right", item_id=1)
        db_session.add(bm)
        db_session.commit()
        
        response = client.delete(f"/api/v1/users/me/bookmarks/{bm.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        
        # Verify deletion
        assert Bookmark.query.get(bm.id) is None
    
    def test_log_activity_success(self, client, auth_headers):
        """Test log activity"""
        response = client.post("/api/v1/users/me/activity",
            headers=auth_headers,
            json={
                "eventType": "viewed_right",
                "payload": {"rightId": 5, "duration": 120}
            }
        )
        
        assert response.status_code == 200
    
    def test_get_activity(self, client, auth_headers, user, db_session):
        """Test get activity"""
        # Add activity events
        ev1 = ActivityEvent(user_id=user.id, event_type="viewed_right", payload={"rightId": 1})
        ev2 = ActivityEvent(user_id=user.id, event_type="searched", payload={"query": "divorce"})
        db_session.add_all([ev1, ev2])
        db_session.commit()
        
        response = client.get("/api/v1/users/me/activity", headers=auth_headers)
        
        assert response.status_code == 200
        assert len(response.json) == 2