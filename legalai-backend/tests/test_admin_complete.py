import pytest
import io
from app.models.rag import KnowledgeSource, KnowledgeChunk
from app.models.user import User
from app.utils.security import hash_password

class TestAdmin:
    
    def test_upload_knowledge_success(self, client, admin_headers, db_session):
        """Test upload knowledge file"""
        data = {
            'file': (io.BytesIO(b"This is test legal content for ingestion."), 'test.txt'),
            'language': 'en'
        }
        
        response = client.post("/api/v1/admin/knowledge/upload",
            headers=admin_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 201
        assert "id" in response.json
        
        # Verify source created
        src = KnowledgeSource.query.get(response.json["id"])
        assert src is not None
        assert src.status == "queued"
        assert src.source_type == "txt"
    
    def test_upload_knowledge_non_admin(self, client, auth_headers):
        """Test upload knowledge as non-admin"""
        data = {
            'file': (io.BytesIO(b"content"), 'test.txt')
        }
        
        response = client.post("/api/v1/admin/knowledge/upload",
            headers=auth_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 403
    
    def test_upload_knowledge_no_file(self, client, admin_headers):
        """Test upload without file"""
        response = client.post("/api/v1/admin/knowledge/upload",
            headers=admin_headers,
            data={},
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 400
    
    def test_upload_knowledge_unsupported_type(self, client, admin_headers):
        """Test upload unsupported file type"""
        data = {
            'file': (io.BytesIO(b"content"), 'test.exe')
        }
        
        response = client.post("/api/v1/admin/knowledge/upload",
            headers=admin_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 400
        assert "Unsupported" in response.json.get("message", "")
    
    def test_upload_knowledge_empty_file(self, client, admin_headers):
        """Test upload empty file"""
        data = {
            'file': (io.BytesIO(b""), 'empty.txt')
        }
        
        response = client.post("/api/v1/admin/knowledge/upload",
            headers=admin_headers,
            data=data,
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 400
        assert "empty" in response.json.get("message", "").lower()
    
    def test_upload_knowledge_duplicate(self, client, admin_headers, db_session):
        """Test upload duplicate content"""
        content = b"Unique legal content for testing"
        
        # First upload
        data1 = {
            'file': (io.BytesIO(content), 'test1.txt')
        }
        response1 = client.post("/api/v1/admin/knowledge/upload",
            headers=admin_headers,
            data=data1,
            content_type='multipart/form-data'
        )
        assert response1.status_code == 201
        
        # Second upload with same content
        data2 = {
            'file': (io.BytesIO(content), 'test2.txt')
        }
        response2 = client.post("/api/v1/admin/knowledge/upload",
            headers=admin_headers,
            data=data2,
            content_type='multipart/form-data'
        )
        
        assert response2.status_code == 400
        assert "already been uploaded" in response2.json.get("message", "")
    
    def test_ingest_url_success(self, client, admin_headers):
        """Test ingest from URL"""
        response = client.post("/api/v1/admin/knowledge/url",
            headers=admin_headers,
            json={
                "url": "https://example.com/legal-doc",
                "title": "Legal Document",
                "language": "en"
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_ingest_url_missing_fields(self, client, admin_headers):
        """Test ingest URL without required fields"""
        response = client.post("/api/v1/admin/knowledge/url",
            headers=admin_headers,
            json={
                "url": "https://example.com"
            }
        )
        
        assert response.status_code == 400
    
    def test_list_sources(self, client, admin_headers, db_session):
        """Test list knowledge sources"""
        src1 = KnowledgeSource(
            title="Source 1",
            source_type="txt",
            file_path="/test1.txt",
            status="done"
        )
        src2 = KnowledgeSource(
            title="Source 2",
            source_type="pdf",
            file_path="/test2.pdf",
            status="queued"
        )
        db_session.add_all([src1, src2])
        db_session.commit()
        
        response = client.get("/api/v1/admin/knowledge/sources",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_list_sources_non_admin(self, client, auth_headers):
        """Test list sources as non-admin"""
        response = client.get("/api/v1/admin/knowledge/sources",
            headers=auth_headers
        )
        
        assert response.status_code == 403
    
    def test_retry_source_success(self, client, admin_headers, db_session):
        """Test retry failed source"""
        src = KnowledgeSource(
            title="Failed Source",
            source_type="txt",
            file_path="/test.txt",
            status="failed",
            retry_count=2
        )
        db_session.add(src)
        db_session.commit()
        
        response = client.post(f"/api/v1/admin/knowledge/sources/{src.id}/retry",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        
        # Verify status changed to queued
        updated = KnowledgeSource.query.get(src.id)
        assert updated.status == "queued"
    
    def test_retry_source_invalid(self, client, admin_headers, db_session):
        """Test retry invalid source"""
        src = KnowledgeSource(
            title="Invalid Source",
            source_type="txt",
            file_path="/test.txt",
            status="invalid"
        )
        db_session.add(src)
        db_session.commit()
        
        response = client.post(f"/api/v1/admin/knowledge/sources/{src.id}/retry",
            headers=admin_headers
        )
        
        assert response.status_code == 400
        assert "invalid" in response.json.get("message", "").lower()
    
    def test_retry_source_done(self, client, admin_headers, db_session):
        """Test retry already done source"""
        src = KnowledgeSource(
            title="Done Source",
            source_type="txt",
            file_path="/test.txt",
            status="done"
        )
        db_session.add(src)
        db_session.commit()
        
        response = client.post(f"/api/v1/admin/knowledge/sources/{src.id}/retry",
            headers=admin_headers
        )
        
        assert response.status_code == 400
        assert "already ingested" in response.json.get("message", "").lower()
    
    def test_retry_source_max_retries(self, client, admin_headers, db_session):
        """Test retry source with max retries reached"""
        src = KnowledgeSource(
            title="Max Retry Source",
            source_type="txt",
            file_path="/test.txt",
            status="failed",
            retry_count=10
        )
        db_session.add(src)
        db_session.commit()
        
        response = client.post(f"/api/v1/admin/knowledge/sources/{src.id}/retry",
            headers=admin_headers
        )
        
        assert response.status_code == 400
        assert "limit reached" in response.json.get("message", "").lower()
    
    def test_retry_source_not_found(self, client, admin_headers):
        """Test retry non-existent source"""
        response = client.post("/api/v1/admin/knowledge/sources/99999/retry",
            headers=admin_headers
        )
        
        assert response.status_code == 404
    
    def test_delete_source_success(self, client, admin_headers, db_session):
        """Test delete knowledge source"""
        src = KnowledgeSource(
            title="To Delete",
            source_type="txt",
            file_path="/test.txt",
            status="done"
        )
        db_session.add(src)
        db_session.commit()
        
        response = client.delete(f"/api/v1/admin/knowledge/sources/{src.id}",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        assert KnowledgeSource.query.get(src.id) is None
    
    def test_delete_source_non_admin(self, client, auth_headers, db_session):
        """Test delete source as non-admin"""
        src = KnowledgeSource(
            title="Source",
            source_type="txt",
            file_path="/test.txt"
        )
        db_session.add(src)
        db_session.commit()
        
        response = client.delete(f"/api/v1/admin/knowledge/sources/{src.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 403

    def test_admin_list_users_success(self, client, admin_headers):
        resp = client.get("/api/v1/admin/users", headers=admin_headers)
        assert resp.status_code == 200
        assert "items" in resp.json
        assert "page" in resp.json
        assert "pageSize" in resp.json
        assert "total" in resp.json

    def test_admin_list_users_non_admin_forbidden(self, client, auth_headers):
        resp = client.get("/api/v1/admin/users", headers=auth_headers)
        assert resp.status_code in (401, 403)

    def test_admin_create_user_success(self, client, admin_headers, db_session):
        payload = {
            "name": "New User",
            "email": "newuser@example.com",
            "phone": "03009998888",
            "cnic": "99999-9999999-9",
            "password": "NewUser@Pass123",
            "isAdmin": False,
        }
        resp = client.post("/api/v1/admin/users", headers=admin_headers, json=payload)
        assert resp.status_code == 201
        assert "id" in resp.json

        u = db_session.query(User).get(resp.json["id"])
        assert u is not None
        assert u.email == "newuser@example.com"
        assert u.is_email_verified is False

    def test_admin_create_user_conflict_email_or_cnic(self, client, admin_headers, db_session):
        # create an existing user in db
        existing = User(
            name="Existing",
            email="exists@example.com",
            phone="03001110000",
            cnic="55555-5555555-5",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
        )
        db_session.add(existing)
        db_session.commit()

        # same email -> conflict
        payload = {
            "name": "Dup",
            "email": "exists@example.com",
            "phone": "03002220000",
            "cnic": "66666-6666666-6",
            "password": "DupUser@Pass123",
        }
        resp = client.post("/api/v1/admin/users", headers=admin_headers, json=payload)
        assert resp.status_code == 409

        # same cnic -> conflict
        payload2 = {
            "name": "Dup2",
            "email": "dup2@example.com",
            "phone": "03003330000",
            "cnic": "55555-5555555-5",
            "password": "DupUser@Pass123",
        }
        resp2 = client.post("/api/v1/admin/users", headers=admin_headers, json=payload2)
        assert resp2.status_code == 409

    def test_admin_update_user_success(self, client, admin_headers, db_session):
        target = User(
            name="Target",
            email="target@example.com",
            phone="03000000001",
            cnic="77777-7777777-7",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
            is_admin=False,
        )
        db_session.add(target)
        db_session.commit()

        resp = client.put(
            f"/api/v1/admin/users/{target.id}",
            headers=admin_headers,
            json={"name": "Target Updated", "phone": "03000000002", "isAdmin": True},
        )
        assert resp.status_code == 200
        assert resp.json["ok"] is True

        db_session.refresh(target)
        assert target.name == "Target Updated"
        assert target.phone == "03000000002"
        assert bool(target.is_admin) is True

    def test_admin_update_deleted_user_fails(self, client, admin_headers, db_session):
        target = User(
            name="Deleted Target",
            email="deleted_target@example.com",
            phone="03000000003",
            cnic="88888-8888888-8",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
        )
        # soft-delete flags expected by route (getattr checks)
        target.is_deleted = True
        db_session.add(target)
        db_session.commit()

        resp = client.put(
            f"/api/v1/admin/users/{target.id}",
            headers=admin_headers,
            json={"name": "Should Fail"},
        )
        assert resp.status_code == 400

    def test_admin_soft_delete_user_idempotent_and_invalidates_tokens(self, client, admin_headers, db_session):
        # create a user and login to get tokens
        target = User(
            name="Logout Target",
            email="logout_target@example.com",
            phone="03000000004",
            cnic="44444-4444444-4",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
            token_version=0,
        )
        db_session.add(target)
        db_session.commit()

        login = client.post("/api/v1/auth/login", json={
            "email": target.email,
            "password": "TestPass@123",
        })
        assert login.status_code == 200
        old_refresh = login.json["refreshToken"]
        old_access = login.json["accessToken"]

        # admin soft delete
        resp = client.delete(f"/api/v1/admin/users/{target.id}", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json["ok"] is True

        # idempotent delete again
        resp2 = client.delete(f"/api/v1/admin/users/{target.id}", headers=admin_headers)
        assert resp2.status_code == 200
        assert resp2.json["ok"] is True

        # old refresh token should now fail
        r2 = client.post("/api/v1/auth/refresh", json={"refreshToken": old_refresh})
        assert r2.status_code == 401

        # old access token should no longer authorize
        me = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {old_access}"})
        assert me.status_code == 401
        
    def test_upload_knowledge_empty_file_400(self, client, admin_headers):
        data = {
            "file": (io.BytesIO(b""), "empty.txt"),
            "language": "en",
        }
        resp = client.post("/api/v1/admin/knowledge/upload", headers=admin_headers, data=data)
        assert resp.status_code == 400

    def test_upload_knowledge_duplicate_content_400(self, client, admin_headers):
        payload = b"same content for hashing"

        r1 = client.post("/api/v1/admin/knowledge/upload", headers=admin_headers, data={
            "file": (io.BytesIO(payload), "a.txt"),
            "language": "en",
        })
        assert r1.status_code == 201

        r2 = client.post("/api/v1/admin/knowledge/upload", headers=admin_headers, data={
            "file": (io.BytesIO(payload), "b.txt"),
            "language": "en",
        })
        assert r2.status_code == 400

    def test_admin_create_user_duplicate_email_or_cnic_409(self, client, admin_headers, db_session):
        existing = User(
            name="Existing",
            email="exists@example.com",
            phone="03001110000",
            cnic="55555-5555555-5",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
        )
        db_session.add(existing)
        db_session.commit()

        # dup email
        r1 = client.post("/api/v1/admin/users", headers=admin_headers, json={
            "name": "Dup",
            "email": "exists@example.com",
            "phone": "03002220000",
            "cnic": "66666-6666666-6",
            "password": "DupUser@Pass123",
        })
        assert r1.status_code == 409

        # dup cnic
        r2 = client.post("/api/v1/admin/users", headers=admin_headers, json={
            "name": "Dup2",
            "email": "dup2@example.com",
            "phone": "03003330000",
            "cnic": "55555-5555555-5",
            "password": "DupUser@Pass123",
        })
        assert r2.status_code == 409
        
    def test_admin_update_deleted_user_400(self, client, admin_headers, db_session):
        target = User(
            name="Deleted Target",
            email="deleted_target@example.com",
            phone="03000000003",
            cnic="88888-8888888-8",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
        )
        target.is_deleted = True
        db_session.add(target)
        db_session.commit()

        resp = client.put(f"/api/v1/admin/users/{target.id}", headers=admin_headers, json={
            "name": "Should Fail",
        })
        assert resp.status_code == 400

    def test_admin_soft_delete_user_allows_recreate_same_cnic(self, client, admin_headers, db_session):
        u = User(
            name="To Delete",
            email="todelete@example.com",
            phone="03000000010",
            cnic="12121-1212121-1",
            password_hash=hash_password("TestPass@123"),
            is_email_verified=True,
        )
        db_session.add(u)
        db_session.commit()

        d1 = client.delete(f"/api/v1/admin/users/{u.id}", headers=admin_headers)
        assert d1.status_code == 200
        assert d1.json["ok"] is True

        # recreate with same CNIC should succeed (partial unique index behavior)
        r = client.post("/api/v1/admin/users", headers=admin_headers, json={
            "name": "Recreated",
            "email": "recreated@example.com",
            "phone": "03000000011",
            "cnic": "12121-1212121-1",
            "password": "Recreated@Pass123",
            "isAdmin": False,
        })
        assert r.status_code == 201
        assert "id" in r.json