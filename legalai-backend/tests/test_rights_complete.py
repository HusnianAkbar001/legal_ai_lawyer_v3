import pytest
from app.models.content import Right

class TestRights:
    
    def test_list_rights_public(self, client, db_session):
        """Test list rights without auth"""
        # Add test rights
        r1 = Right(topic="Right 1", body="Body 1", category="family")
        r2 = Right(topic="Right 2", body="Body 2", category="education")
        db_session.add_all([r1, r2])
        db_session.commit()
        
        response = client.get("/api/v1/rights")
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_list_rights_filter_category(self, client, db_session):
        """Test filter rights by category"""
        r1 = Right(topic="Right 1", body="Body 1", category="family")
        r2 = Right(topic="Right 2", body="Body 2", category="education")
        db_session.add_all([r1, r2])
        db_session.commit()
        
        response = client.get("/api/v1/rights?category=family")
        
        assert response.status_code == 200
        assert len(response.json) == 1
        assert response.json[0]["category"] == "family"
    
    def test_get_right_success(self, client, db_session):
        """Test get single right"""
        r = Right(topic="Test Right", body="Test Body", category="test")
        db_session.add(r)
        db_session.commit()
        
        response = client.get(f"/api/v1/rights/{r.id}")
        
        assert response.status_code == 200
        assert response.json["topic"] == "Test Right"
    
    def test_get_right_not_found(self, client):
        """Test get non-existent right"""
        response = client.get("/api/v1/rights/99999")
        
        assert response.status_code == 404
    
    def test_create_right_success(self, client, admin_headers):
        """Test create right as admin"""
        response = client.post("/api/v1/rights",
            headers=admin_headers,
            json={
                "topic": "New Right",
                "body": "New Body",
                "category": "family",
                "language": "en",
                "tags": ["family", "rights"]
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_create_right_non_admin(self, client, auth_headers):
        """Test create right as non-admin (should fail)"""
        response = client.post("/api/v1/rights",
            headers=auth_headers,
            json={
                "topic": "New Right",
                "body": "New Body"
            }
        )
        
        assert response.status_code == 403
    
    def test_create_right_missing_fields(self, client, admin_headers):
        """Test create right with missing required fields"""
        response = client.post("/api/v1/rights",
            headers=admin_headers,
            json={"topic": "Only Topic"}
        )
        
        assert response.status_code == 400
    
    def test_update_right_success(self, client, admin_headers, db_session):
        """Test update right"""
        r = Right(topic="Old Topic", body="Old Body", category="old")
        db_session.add(r)
        db_session.commit()
        
        response = client.put(f"/api/v1/rights/{r.id}",
            headers=admin_headers,
            json={
                "topic": "Updated Topic",
                "body": "Updated Body",
                "category": "updated"
            }
        )
        
        assert response.status_code == 200
        
        # Verify update
        updated = Right.query.get(r.id)
        assert updated.topic == "Updated Topic"
    
    def test_delete_right_success(self, client, admin_headers, db_session):
        """Test delete right"""
        r = Right(topic="To Delete", body="Delete Body")
        db_session.add(r)
        db_session.commit()
        
        response = client.delete(f"/api/v1/rights/{r.id}",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        
        # Verify deletion
        assert Right.query.get(r.id) is None