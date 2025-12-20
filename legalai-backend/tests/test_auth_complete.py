import pytest
from app.models.user import User
from app.extensions import db
from datetime import datetime, timedelta
from app.models.user import EmailVerificationToken, PasswordResetToken
from app.utils.security import hash_password

class TestAuth:
    
    def test_signup_success(self, client, db_session):
        """Test successful signup"""
        response = client.post("/api/v1/auth/signup", json={
            "name": "New User",
            "email": "new@example.com",
            "phone": "03001111111",
            "cnic": "11111-1111111-1",
            "password": "NewPass@123",
            "fatherName": "Father",
            "fatherCnic": "11111-1111111-2",
            "motherName": "Mother",
            "motherCnic": "11111-1111111-3",
            "city": "Karachi",
            "gender": "male",
            "age": 25,
            "totalSiblings": 2,
            "brothers": 1,
            "sisters": 1,
            "timezone": "Asia/Karachi"
        })
        
        assert response.status_code == 201
        assert "accessToken" in response.json
        assert "refreshToken" in response.json
        assert response.json["user"]["email"] == "new@example.com"
        
        # Verify user in DB
        user = db_session.query(User).filter_by(email="new@example.com").first()
        assert user is not None
        assert user.name == "New User"
    
    def test_signup_duplicate_email(self, client, user):
        """Test signup with existing email"""
        response = client.post("/api/v1/auth/signup", json={
            "name": "Duplicate",
            "email": "test@example.com",
            "phone": "03002222222",
            "cnic": "22222-2222222-2",
            "password": "DupPass@123"
        })
        
        assert response.status_code == 400
        assert "already exists" in response.json["message"].lower()
    
    def test_signup_weak_password(self, client):
        """Test signup with weak password"""
        response = client.post("/api/v1/auth/signup", json={
            "name": "Weak Pass User",
            "email": "weak@example.com",
            "phone": "03003333333",
            "cnic": "33333-3333333-3",
            "password": "weak"
        })
        
        assert response.status_code == 400
        assert "password" in response.json["errors"]["password"][0].lower()
    
    def test_signup_same_cnic_validation(self, client):
        """Test CNIC uniqueness validation"""
        response = client.post("/api/v1/auth/signup", json={
            "name": "CNIC Test",
            "email": "cnic@example.com",
            "phone": "03004444444",
            "cnic": "44444-4444444-4",
            "password": "TestPass@123",
            "fatherCnic": "44444-4444444-4"  # Same as user CNIC
        })
        
        assert response.status_code == 400
    
    def test_login_success(self, client, user):
        """Test successful login"""
        response = client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "TestPass@123"
        })
        
        assert response.status_code == 200
        assert "accessToken" in response.json
        assert "refreshToken" in response.json
    
    def test_login_invalid_credentials(self, client, user):
        """Test login with wrong password"""
        response = client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "WrongPass@123"
        })
        
        assert response.status_code == 401
    
    def test_login_unverified_email(self, client, db_session):
        """Test login with unverified email"""
        u = User(
            name="Unverified",
            email="unverified@example.com",
            phone="03005555555",
            cnic="55555-5555555-5",
            password_hash=hash_password("TestPass@123")
            is_email_verified=False
        )
        db_session.add(u)
        db_session.commit()
        
        response = client.post("/api/v1/auth/login", json={
            "email": "unverified@example.com",
            "password": "TestPass@123"
        })
        
        assert response.status_code == 403
    
    def test_refresh_token_success(self, client, user):
        """Test token refresh"""
        login_response = client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "TestPass@123"
        })
        
        refresh_token = login_response.json["refreshToken"]
        
        response = client.post("/api/v1/auth/refresh", json={
            "refreshToken": refresh_token
        })
        
        assert response.status_code == 200
        assert "accessToken" in response.json
        assert "refreshToken" in response.json
    
    def test_refresh_token_invalid(self, client):
        """Test refresh with invalid token"""
        response = client.post("/api/v1/auth/refresh", json={
            "refreshToken": "invalid_token"
        })
        
        assert response.status_code == 401
    
    def test_change_password_success(self, client, auth_headers):
        """Test password change"""
        response = client.post("/api/v1/auth/change-password", 
            headers=auth_headers,
            json={
                "currentPassword": "TestPass@123",
                "newPassword": "NewSecure@Pass456",
                "confirmPassword": "NewSecure@Pass456"
            }
        )
        
        assert response.status_code == 200
        assert "accessToken" in response.json
    
    def test_change_password_wrong_current(self, client, auth_headers):
        """Test password change with wrong current password"""
        response = client.post("/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "currentPassword": "WrongPass@123",
                "newPassword": "NewSecure@Pass456",
                "confirmPassword": "NewSecure@Pass456"
            }
        )
        
        assert response.status_code == 400
    
    def test_change_password_mismatch(self, client, auth_headers):
        """Test password change with mismatched confirmation"""
        response = client.post("/api/v1/auth/change-password",
            headers=auth_headers,
            json={
                "currentPassword": "TestPass@123",
                "newPassword": "NewSecure@Pass456",
                "confirmPassword": "DifferentPass@789"
            }
        )
        
        assert response.status_code == 400
    
    def test_forgot_password(self, client, user):
        """Test forgot password request"""
        response = client.post("/api/v1/auth/forgot-password", json={
            "email": "test@example.com"
        })
        
        assert response.status_code == 200
        assert response.json["ok"] is True
    
    def test_forgot_password_nonexistent_email(self, client):
        """Test forgot password with non-existent email"""
        response = client.post("/api/v1/auth/forgot-password", json={
            "email": "nonexistent@example.com"
        })
        
        # Should still return 200 for security
        assert response.status_code == 200


    def test_verify_email_success(self, client, db_session):
        """Test verify-email endpoint (valid token)"""
        u = User(
            name="Unverified User",
            email="unverified@example.com",
            phone="03001112222",
            cnic="11111-1111111-1",
            password_hash=hash_password("TempPass@123"),
            is_email_verified=False,
        )
        db_session.add(u)
        db_session.commit()

        vt = EmailVerificationToken(
            user_id=u.id,
            token="verify-token-123",
            expires_at=datetime.utcnow() + timedelta(hours=1),
        )
        db_session.add(vt)
        db_session.commit()

        resp = client.get("/api/v1/auth/verify-email?token=verify-token-123")
        assert resp.status_code == 200
        assert resp.json["verified"] is True

        db_session.refresh(u)
        assert u.is_email_verified is True
        db_session.refresh(vt)
        assert vt.used is True

    def test_verify_email_missing_token(self, client):
        """Test verify-email endpoint (missing token)"""
        resp = client.get("/api/v1/auth/verify-email")
        assert resp.status_code == 400

    def test_reset_password_success_and_invalidates_old_tokens(self, client, db_session, user):
        """Reset password should increment token_version and invalidate prior access/refresh tokens"""
        login = client.post("/api/v1/auth/login", json={
            "email": user.email,
            "password": "TestPass@123"
        })
        assert login.status_code == 200
        old_access = login.json["accessToken"]
        old_refresh = login.json["refreshToken"]

        rt = PasswordResetToken(
            user_id=user.id,
            token="reset-token-123",
            expires_at=datetime.utcnow() + timedelta(hours=1),
        )
        db_session.add(rt)
        db_session.commit()

        resp = client.post("/api/v1/auth/reset-password", json={
            "token": "reset-token-123",
            "newPassword": "BrandNew@Pass789",
            "confirmPassword": "BrandNew@Pass789",
        })
        assert resp.status_code == 200
        assert resp.json["ok"] is True

        # old refresh token should no longer work
        r2 = client.post("/api/v1/auth/refresh", json={"refreshToken": old_refresh})
        assert r2.status_code == 401

        # old access token should no longer authorize protected endpoints
        me = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {old_access}"})
        assert me.status_code == 401

    def test_change_password_invalidates_old_tokens(self, client, user):
        """Change password should also invalidate prior tokens via token_version"""
        login = client.post("/api/v1/auth/login", json={
            "email": user.email,
            "password": "TestPass@123"
        })
        assert login.status_code == 200
        old_access = login.json["accessToken"]
        old_refresh = login.json["refreshToken"]

        cp = client.post(
            "/api/v1/auth/change-password",
            headers={"Authorization": f"Bearer {old_access}"},
            json={
                "currentPassword": "TestPass@123",
                "newPassword": "AnotherNew@Pass123",
                "confirmPassword": "AnotherNew@Pass123",
            },
        )
        assert cp.status_code == 200
        assert "accessToken" in cp.json and "refreshToken" in cp.json

        # old refresh should be invalid
        r2 = client.post("/api/v1/auth/refresh", json={"refreshToken": old_refresh})
        assert r2.status_code == 401

        # old access should be invalid
        me = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {old_access}"})
        assert me.status_code == 401

    def test_verify_email_invalid_or_expired_returns_false(self, client, db_session, user):
        vt = EmailVerificationToken(
            user_id=user.id,
            token="expired-token-1",
            used=False,
            expires_at=datetime.utcnow() - timedelta(minutes=1),
        )
        db_session.add(vt)
        db_session.commit()

        resp = client.get("/api/v1/auth/verify-email?token=expired-token-1")
        assert resp.status_code == 200
        assert resp.json["verified"] is False

    def test_reset_password_invalid_token_400(self, client):
        resp = client.post("/api/v1/auth/reset-password", json={
            "token": "does-not-exist",
            "newPassword": "BrandNew@Pass789",
            "confirmPassword": "BrandNew@Pass789",
        })
        assert resp.status_code == 400
