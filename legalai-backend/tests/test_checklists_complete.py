import pytest
from app.models.content import ChecklistCategory, ChecklistItem

class TestChecklists:
    
    def test_list_categories_public(self, client, db_session):
        """Test list checklist categories"""
        c1 = ChecklistCategory(title="Category 1", icon="📄", order=1)
        c2 = ChecklistCategory(title="Category 2", icon="📋", order=2)
        db_session.add_all([c1, c2])
        db_session.commit()
        
        response = client.get("/api/v1/checklists/categories")
        
        assert response.status_code == 200
        assert len(response.json) == 2
        assert response.json[0]["order"] <= response.json[1]["order"]
    
    def test_list_items_public(self, client, db_session):
        """Test list checklist items"""
        cat = ChecklistCategory(title="Category", icon="📄", order=1)
        db_session.add(cat)
        db_session.commit()
        
        i1 = ChecklistItem(category_id=cat.id, text="Item 1", required=True, order=1)
        i2 = ChecklistItem(category_id=cat.id, text="Item 2", required=False, order=2)
        db_session.add_all([i1, i2])
        db_session.commit()
        
        response = client.get("/api/v1/checklists/items")
        
        assert response.status_code == 200
        assert len(response.json) == 2
    
    def test_list_items_filter_category(self, client, db_session):
        """Test filter items by category"""
        cat1 = ChecklistCategory(title="Cat 1", icon="📄", order=1)
        cat2 = ChecklistCategory(title="Cat 2", icon="📋", order=2)
        db_session.add_all([cat1, cat2])
        db_session.commit()
        
        i1 = ChecklistItem(category_id=cat1.id, text="Item 1", required=True, order=1)
        i2 = ChecklistItem(category_id=cat2.id, text="Item 2", required=False, order=1)
        db_session.add_all([i1, i2])
        db_session.commit()
        
        response = client.get(f"/api/v1/checklists/items?categoryId={cat1.id}")
        
        assert response.status_code == 200
        assert len(response.json) == 1
        assert response.json[0]["categoryId"] == cat1.id
    
    def test_create_category_success(self, client, admin_headers):
        """Test create checklist category"""
        response = client.post("/api/v1/checklists/categories",
            headers=admin_headers,
            json={
                "title": "New Category",
                "icon": "✅",
                "order": 5
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_create_category_non_admin(self, client, auth_headers):
        """Test create category as non-admin"""
        response = client.post("/api/v1/checklists/categories",
            headers=auth_headers,
            json={
                "title": "New Category",
                "icon": "✅"
            }
        )
        
        assert response.status_code == 403
    
    def test_create_category_missing_title(self, client, admin_headers):
        """Test create category without title"""
        response = client.post("/api/v1/checklists/categories",
            headers=admin_headers,
            json={
                "icon": "✅"
            }
        )
        
        assert response.status_code == 400
    
    def test_update_category_success(self, client, admin_headers, db_session):
        """Test update category"""
        cat = ChecklistCategory(title="Old Title", icon="📄", order=1)
        db_session.add(cat)
        db_session.commit()
        
        response = client.put(f"/api/v1/checklists/categories/{cat.id}",
            headers=admin_headers,
            json={
                "title": "Updated Title",
                "icon": "✅",
                "order": 10
            }
        )
        
        assert response.status_code == 200
        
        updated = ChecklistCategory.query.get(cat.id)
        assert updated.title == "Updated Title"
        assert updated.order == 10
    
    def test_delete_category_success(self, client, admin_headers, db_session):
        """Test delete category"""
        cat = ChecklistCategory(title="To Delete", icon="📄", order=1)
        db_session.add(cat)
        db_session.commit()
        
        response = client.delete(f"/api/v1/checklists/categories/{cat.id}",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        assert ChecklistCategory.query.get(cat.id) is None
    
    def test_create_item_success(self, client, admin_headers, db_session):
        """Test create checklist item"""
        cat = ChecklistCategory(title="Category", icon="📄", order=1)
        db_session.add(cat)
        db_session.commit()
        
        response = client.post("/api/v1/checklists/items",
            headers=admin_headers,
            json={
                "categoryId": cat.id,
                "text": "New Item",
                "required": True,
                "order": 1
            }
        )
        
        assert response.status_code == 201
        assert "id" in response.json
    
    def test_create_item_missing_fields(self, client, admin_headers):
        """Test create item without required fields"""
        response = client.post("/api/v1/checklists/items",
            headers=admin_headers,
            json={
                "text": "Item without category"
            }
        )
        
        assert response.status_code == 400
    
    def test_update_item_success(self, client, admin_headers, db_session):
        """Test update item"""
        cat = ChecklistCategory(title="Category", icon="📄", order=1)
        db_session.add(cat)
        db_session.commit()
        
        item = ChecklistItem(category_id=cat.id, text="Old Text", required=False, order=1)
        db_session.add(item)
        db_session.commit()
        
        response = client.put(f"/api/v1/checklists/items/{item.id}",
            headers=admin_headers,
            json={
                "text": "Updated Text",
                "required": True,
                "order": 5
            }
        )
        
        assert response.status_code == 200
        
        updated = ChecklistItem.query.get(item.id)
        assert updated.text == "Updated Text"
        assert updated.required is True
        assert updated.order == 5
    
    def test_delete_item_success(self, client, admin_headers, db_session):
        """Test delete item"""
        cat = ChecklistCategory(title="Category", icon="📄", order=1)
        db_session.add(cat)
        db_session.commit()
        
        item = ChecklistItem(category_id=cat.id, text="To Delete", required=False, order=1)
        db_session.add(item)
        db_session.commit()
        
        response = client.delete(f"/api/v1/checklists/items/{item.id}",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        assert ChecklistItem.query.get(item.id) is None