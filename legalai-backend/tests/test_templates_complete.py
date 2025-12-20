import pytest
from app.models.content import Template

class TestTemplates:
    
    def test_list_templates_public(self, client, db_session):
        """Test list templates without auth"""
        t1 = Template(title="Template 1", body="Body 1", category="legal")
        t2 = Template(title="Template 2", body="Body 2", category="official")
        db_session.add_all([t1, t2])
        db_session.commit()
        
        response = client.get("/api/v1/templates")
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_list_templates_filter_category(self, client, db_session):
        """Test filter templates by category"""
        t1 = Template(title="Template 1", body="Body 1", category="legal")
        t2 = Template(title="Template 2", body="Body 2", category="official")
        db_session.add_all([t1, t2])
        db_session.commit()
        
        response = client.get("/api/v1/templates?category=legal")
        
        assert response.status_code == 200
        assert len(response.json) == 1
        assert response.json[0]["category"] == "legal"
    
    def test_get_template_success(self, client, db_session):
        """Test get single template"""
        t = Template(title="Test Template", body="Body {{name}}", category="test")
        db_session.add(t)
        db_session.commit()
        
        response = client.get(f"/api/v1/templates/{t.id}")
        
        assert response.status_code == 200
        assert response.json["title"] == "Test Template"
        assert "{{name}}" in response.json["body"]
    
    def test_create_template_success(self, client, admin_headers):
        """Test create template as admin"""
        response = client.post("/api/v1/templates",
            headers=admin_headers,
            json={
                "title": "New Template",
                "description": "Template description",
                "body": "I, {{name}}, son of {{fatherName}}...",
                "category": "legal",
                "language": "en",
                "tags": ["legal", "document"]
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_create_template_non_admin(self, client, auth_headers):
        """Test create template as non-admin"""
        response = client.post("/api/v1/templates",
            headers=auth_headers,
            json={
                "title": "New Template",
                "body": "Body"
            }
        )
        
        assert response.status_code == 403
    
    def test_update_template_success(self, client, admin_headers, db_session):
        """Test update template"""
        t = Template(title="Old Title", body="Old Body")
        db_session.add(t)
        db_session.commit()
        
        response = client.put(f"/api/v1/templates/{t.id}",
            headers=admin_headers,
            json={
                "title": "Updated Title",
                "body": "Updated Body {{placeholder}}"
            }
        )
        
        assert response.status_code == 200
        
        updated = Template.query.get(t.id)
        assert updated.title == "Updated Title"
    
    def test_delete_template_success(self, client, admin_headers, db_session):
        """Test delete template"""
        t = Template(title="To Delete", body="Delete Body")
        db_session.add(t)
        db_session.commit()
        
        response = client.delete(f"/api/v1/templates/{t.id}",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        assert Template.query.get(t.id) is None