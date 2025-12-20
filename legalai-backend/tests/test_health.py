def test_health_check(client):
    """Test health endpoint"""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json["status"] == "ok"