import pytest
from app.models.content import Pathway

class TestPathways:
    
    def test_list_pathways_public(self, client, db_session):
        """Test list pathways"""
        p1 = Pathway(title="Pathway 1", summary="Summary 1", steps=[{"step": 1}], category="divorce")
        p2 = Pathway(title="Pathway 2", summary="Summary 2", steps=[{"step": 1}], category="marriage")
        db_session.add_all([p1, p2])
        db_session.commit()
        
        response = client.get("/api/v1/pathways")
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_list_pathways_filter_category(self, client, db_session):
        """Test filter pathways by category"""
        p1 = Pathway(title="Pathway 1", summary="Summary 1", steps=[{"step": 1}], category="divorce")
        p2 = Pathway(title="Pathway 2", summary="Summary 2", steps=[{"step": 1}], category="marriage")
        db_session.add_all([p1, p2])
        db_session.commit()
        
        response = client.get("/api/v1/pathways?category=divorce")
        
        assert response.status_code == 200
        assert len(response.json) == 1
        assert response.json[0]["category"] == "divorce"
    
    def test_get_pathway_success(self, client, db_session):
        """Test get single pathway"""
        p = Pathway(
            title="Test Pathway",
            summary="Test Summary",
            steps=[
                {"stepNumber": 1, "title": "Step 1", "description": "Desc 1"},
                {"stepNumber": 2, "title": "Step 2", "description": "Desc 2"}
            ],
            category="test"
        )
        db_session.add(p)
        db_session.commit()
        
        response = client.get(f"/api/v1/pathways/{p.id}")
        
        assert response.status_code == 200
        assert response.json["title"] == "Test Pathway"
        assert len(response.json["steps"]) == 2
    
    def test_create_pathway_success(self, client, admin_headers):
        """Test create pathway"""
        response = client.post("/api/v1/pathways",
            headers=admin_headers,
            json={
                "title": "New Pathway",
                "summary": "Pathway summary",
                "steps": [
                    {"stepNumber": 1, "title": "First Step", "description": "Do this first"}
                ],
                "category": "legal",
                "language": "en",
                "tags": ["legal", "guide"]
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_create_pathway_empty_steps(self, client, admin_headers):
        """Test create pathway with empty steps"""
        response = client.post("/api/v1/pathways",
            headers=admin_headers,
            json={
                "title": "Invalid Pathway",
                "steps": []
            }
        )
        
        assert response.status_code == 400
    
    def test_update_pathway_success(self, client, admin_headers, db_session):
        """Test update pathway"""
        p = Pathway(title="Old", summary="Old", steps=[{"step": 1}])
        db_session.add(p)
        db_session.commit()
        
        response = client.put(f"/api/v1/pathways/{p.id}",
            headers=admin_headers,
            json={
                "title": "Updated Pathway",
                "steps": [
                    {"stepNumber": 1, "title": "Updated Step"}
                ]
            }
        )
        
        assert response.status_code == 200
        
        updated = Pathway.query.get(p.id)
        assert updated.title == "Updated Pathway"
    
    def test_delete_pathway_success(self, client, admin_headers, db_session):
        """Test delete pathway"""
        p = Pathway(title="To Delete", summary="Delete", steps=[{"step": 1}])
        db_session.add(p)
        db_session.commit()
        
        response = client.delete(f"/api/v1/pathways/{p.id}",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        assert Pathway.query.get(p.id) is None