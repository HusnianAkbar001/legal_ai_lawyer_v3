import pytest
from app.models.content import Right, Template

class TestContent:
    
    def test_manifest(self, client):
        """Test content manifest endpoint"""
        response = client.get("/api/v1/content/manifest")
        
        assert response.status_code == 200
        assert "version" in response.json
        assert "files" in response.json
        assert "rights" in response.json["files"]
        assert "templates" in response.json["files"]
    
    def test_rights_json(self, client, db_session):
        """Test rights JSON endpoint"""
        r1 = Right(
            topic="Right 1",
            body="Body 1",
            category="family",
            language="en",
            tags=["tag1", "tag2"]
        )
        r2 = Right(
            topic="Right 2",
            body="Body 2",
            category="education",
            language="ur",
            tags=["tag3"]
        )
        db_session.add_all([r1, r2])
        db_session.commit()
        
        response = client.get("/api/v1/content/rights.json")
        
        assert response.status_code == 200
        assert len(response.json) == 2
        assert response.json[0]["topic"] in ["Right 1", "Right 2"]
        assert "body" in response.json[0]
        assert "category" in response.json[0]
        assert "language" in response.json[0]
        assert "tags" in response.json[0]
    
    def test_rights_json_empty(self, client):
        """Test rights JSON with no data"""
        response = client.get("/api/v1/content/rights.json")
        
        assert response.status_code == 200
        assert response.json == []
    
    def test_templates_json(self, client, db_session):
        """Test templates JSON endpoint"""
        t1 = Template(
            title="Template 1",
            body="Body with {{placeholder}}",
            category="legal"
        )
        t2 = Template(
            title="Template 2",
            body="Another body",
            category="official"
        )
        db_session.add_all([t1, t2])
        db_session.commit()
        
        response = client.get("/api/v1/content/templates.json")
        
        assert response.status_code == 200
        assert len(response.json) == 2
        assert response.json[0]["title"] in ["Template 1", "Template 2"]
        assert "body" in response.json[0]
        assert "category" in response.json[0]
    
    def test_templates_json_empty(self, client):
        """Test templates JSON with no data"""
        response = client.get("/api/v1/content/templates.json")
        
        assert response.status_code == 200
        assert response.json == []
    
    def test_manifest_version(self, client, app):
        """Test manifest version from config"""
        with app.app_context():
            app.config["CONTENT_VERSION"] = 42
            response = client.get("/api/v1/content/manifest")
            
            assert response.status_code == 200
            assert response.json["version"] == 42
    
    def test_manifest_default_version(self, client):
        """Test manifest default version"""
        response = client.get("/api/v1/content/manifest")
        
        assert response.status_code == 200
        assert isinstance(response.json["version"], int)
        assert response.json["version"] >= 1