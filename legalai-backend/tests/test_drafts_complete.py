import pytest
from app.models.content import Template
from app.models.drafts import Draft

class TestDrafts:
    
    def test_generate_draft_success(self, client, auth_headers, db_session):
        """Test generate draft from template"""
        template = Template(
            title="Test Template",
            body="I, {{name}}, son of {{fatherName}}, CNIC {{cnic}}, apply for {{purpose}}.",
            category="legal"
        )
        db_session.add(template)
        db_session.commit()
        
        response = client.post("/api/v1/drafts/generate",
            headers=auth_headers,
            json={
                "templateId": template.id,
                "answers": {
                    "purpose": "Marriage Certificate"
                },
                "userSnapshot": {
                    "name": "Ahmed Ali",
                    "fatherName": "Ali Khan",
                    "cnic": "12345-1234567-1"
                }
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
        assert "contentText" in response.json
        assert "Ahmed Ali" in response.json["contentText"]
        assert "Marriage Certificate" in response.json["contentText"]
    
    def test_generate_draft_missing_template(self, client, auth_headers):
        """Test generate draft with non-existent template"""
        response = client.post("/api/v1/drafts/generate",
            headers=auth_headers,
            json={
                "templateId": 99999,
                "answers": {},
                "userSnapshot": {}
            }
        )
        
        assert response.status_code == 404
    
    def test_generate_draft_missing_fields(self, client, auth_headers):
        """Test generate draft without required fields"""
        response = client.post("/api/v1/drafts/generate",
            headers=auth_headers,
            json={
                "templateId": 1
            }
        )
        
        assert response.status_code == 400
    
    def test_generate_draft_safe_mode(self, client, auth_headers, db_session):
        """Test generate draft blocked in safe mode"""
        template = Template(title="Test", body="Body", category="test")
        db_session.add(template)
        db_session.commit()
        
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.post("/api/v1/drafts/generate",
            headers=headers,
            json={
                "templateId": template.id,
                "answers": {},
                "userSnapshot": {}
            }
        )
        
        assert response.status_code == 403
    
    def test_list_drafts(self, client, auth_headers, user, db_session):
        """Test list user drafts"""
        d1 = Draft(
            user_id=user.id,
            template_id=1,
            title="Draft 1",
            content_text="Content 1",
            answers={},
            user_snapshot={}
        )
        d2 = Draft(
            user_id=user.id,
            template_id=1,
            title="Draft 2",
            content_text="Content 2",
            answers={},
            user_snapshot={}
        )
        db_session.add_all([d1, d2])
        db_session.commit()
        
        response = client.get("/api/v1/drafts", headers=auth_headers)
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_get_draft_success(self, client, auth_headers, user, db_session):
        """Test get single draft"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="Test Draft",
            content_text="Test Content",
            answers={"key": "value"},
            user_snapshot={"name": "Test"}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.get(f"/api/v1/drafts/{draft.id}", headers=auth_headers)
        
        assert response.status_code == 200
        assert response.json["title"] == "Test Draft"
        assert response.json["contentText"] == "Test Content"
        assert response.json["answers"]["key"] == "value"
    
    def test_get_draft_not_owner(self, client, auth_headers, db_session):
        """Test get draft from another user"""
        other_user_id = 99999
        draft = Draft(
            user_id=other_user_id,
            template_id=1,
            title="Other's Draft",
            content_text="Content",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.get(f"/api/v1/drafts/{draft.id}", headers=auth_headers)
        
        assert response.status_code == 403
    
    def test_export_draft_txt(self, client, auth_headers, user, db_session):
        """Test export draft as TXT"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="Export Test",
            content_text="This is the content to export.",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.get(f"/api/v1/drafts/{draft.id}/export?format=txt",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        assert response.json["text"] == "This is the content to export."
    
    def test_export_draft_pdf(self, client, auth_headers, user, db_session):
        """Test export draft as PDF"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="PDF Test",
            content_text="PDF Content",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.get(f"/api/v1/drafts/{draft.id}/export?format=pdf",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        assert response.content_type == "application/pdf"
    
    def test_export_draft_docx(self, client, auth_headers, user, db_session):
        """Test export draft as DOCX"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="DOCX Test",
            content_text="DOCX Content",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.get(f"/api/v1/drafts/{draft.id}/export?format=docx",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        assert "application" in response.content_type
    
    def test_export_draft_invalid_format(self, client, auth_headers, user, db_session):
        """Test export with invalid format"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="Test",
            content_text="Content",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.get(f"/api/v1/drafts/{draft.id}/export?format=invalid",
            headers=auth_headers
        )
        
        assert response.status_code == 400
    
    def test_delete_draft_success(self, client, auth_headers, user, db_session):
        """Test delete draft"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="To Delete",
            content_text="Content",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        response = client.delete(f"/api/v1/drafts/{draft.id}", headers=auth_headers)
        
        assert response.status_code == 200
        assert Draft.query.get(draft.id) is None
    
    def test_delete_draft_safe_mode(self, client, auth_headers, user, db_session):
        """Test delete draft blocked in safe mode"""
        draft = Draft(
            user_id=user.id,
            template_id=1,
            title="Test",
            content_text="Content",
            answers={},
            user_snapshot={}
        )
        db_session.add(draft)
        db_session.commit()
        
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.delete(f"/api/v1/drafts/{draft.id}", headers=headers)
        
        assert response.status_code == 403