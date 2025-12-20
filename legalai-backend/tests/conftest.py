import pytest
import os
import tempfile
from app import create_app
from app.extensions import db
from app.models.user import User
from app.utils.security import hash_password

@pytest.fixture(scope="session")
def app():
    """Create application for testing"""
    # Use in-memory SQLite for tests
    db_fd, db_path = tempfile.mkstemp()
    
    os.environ["DATABASE_URL"] = f"sqlite:///{db_path}"
    os.environ["TESTING"] = "1"
    os.environ["SECRET_KEY"] = "test-secret-key"
    os.environ["JWT_ACCESS_MIN"] = "60"
    os.environ["JWT_REFRESH_DAYS"] = "7"
    
    app = create_app()
    app.config["TESTING"] = True
    app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{db_path}"
    
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()
    
    os.close(db_fd)
    os.unlink(db_path)

@pytest.fixture
def client(app):
    """Test client"""
    return app.test_client()

@pytest.fixture
def runner(app):
    """CLI runner"""
    return app.test_cli_runner()

@pytest.fixture
def db_session(app):
    """Database session for tests"""
    with app.app_context():
        yield db.session
        db.session.rollback()

@pytest.fixture
def user(app, db_session):
    """Create test user"""
    u = User(
        name="Test User",
        email="test@example.com",
        phone="03001234567",
        cnic="12345-1234567-1",
        password_hash=hash_password("TestPass@123"),
        is_email_verified=True,
    )
    db_session.add(u)
    db_session.commit()
    return u

@pytest.fixture
def admin_user(app, db_session):
    """Create admin user"""
    u = User(
        name="Admin User",
        email="admin@example.com",
        phone="03009999999",
        cnic="99999-9999999-9",
        password_hash=hash_password("AdminPass@123"),
        is_admin=True,
        is_email_verified=True,
    )
    db_session.add(u)
    db_session.commit()
    return u

@pytest.fixture
def auth_token(client, user):
    """Get auth token for regular user"""
    response = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "TestPass@123"
    })
    return response.json["accessToken"]

@pytest.fixture
def admin_token(client, admin_user):
    """Get auth token for admin"""
    response = client.post("/api/v1/auth/login", json={
        "email": "admin@example.com",
        "password": "AdminPass@123"
    })
    return response.json["accessToken"]

@pytest.fixture
def auth_headers(auth_token):
    """Auth headers for regular user"""
    return {"Authorization": f"Bearer {auth_token}"}

@pytest.fixture
def admin_headers(admin_token):
    """Auth headers for admin"""
    return {"Authorization": f"Bearer {admin_token}"}