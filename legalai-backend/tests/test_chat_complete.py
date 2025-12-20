import pytest
from app.models.chat import ChatConversation, ChatMessage
from app.models.rag import KnowledgeSource, KnowledgeChunk

class TestChat:
    
    def test_ask_new_conversation(self, client, auth_headers, db_session):
        """Test ask question creating new conversation"""
        # Add knowledge for RAG
        src = KnowledgeSource(
            title="Legal Doc",
            source_type="txt",
            file_path="/test.txt",
            language="en",
            status="done"
        )
        db_session.add(src)
        db_session.commit()
        
        chunk = KnowledgeChunk(
            source_id=src.id,
            chunk_text="Divorce rights in Pakistan include right to alimony and custody.",
            embedding=[0.1] * 3072  # Mock embedding
        )
        db_session.add(chunk)
        db_session.commit()
        
        response = client.post("/api/v1/chat/ask",
            headers=auth_headers,
            json={
                "question": "What are divorce rights?",
                "language": "en"
            }
        )
        
        assert response.status_code == 200
        assert "answer" in response.json
        assert "conversationId" in response.json
        assert response.json["conversationId"] is not None
    
    def test_ask_continue_conversation(self, client, auth_headers, user, db_session):
        """Test continue existing conversation"""
        conv = ChatConversation(user_id=user.id, title="Test Chat")
        db_session.add(conv)
        db_session.commit()
        
        msg1 = ChatMessage(
            user_id=user.id,
            conversation_id=conv.id,
            role="user",
            content="First question"
        )
        msg2 = ChatMessage(
            user_id=user.id,
            conversation_id=conv.id,
            role="assistant",
            content="First answer"
        )
        db_session.add_all([msg1, msg2])
        db_session.commit()
        
        response = client.post("/api/v1/chat/ask",
            headers=auth_headers,
            json={
                "question": "Follow-up question",
                "conversationId": conv.id,
                "language": "en"
            }
        )
        
        assert response.status_code == 200
        assert response.json["conversationId"] == conv.id
        
        # Verify messages stored
        messages = ChatMessage.query.filter_by(conversation_id=conv.id).count()
        assert messages >= 4  # 2 existing + 2 new
    
    def test_ask_safe_mode(self, client, auth_headers):
        """Test ask in safe mode (no DB writes)"""
        headers = {**auth_headers, "X-Safe-Mode": "1"}
        response = client.post("/api/v1/chat/ask",
            headers=headers,
            json={
                "question": "What are my rights?",
                "language": "en"
            }
        )
        
        assert response.status_code == 200
        assert "answer" in response.json
        assert response.json["conversationId"] is None
    
    def test_ask_missing_question(self, client, auth_headers):
        """Test ask without question"""
        response = client.post("/api/v1/chat/ask",
            headers=auth_headers,
            json={
                "language": "en"
            }
        )
        
        assert response.status_code == 400
    
    def test_ask_question_too_long(self, client, auth_headers):
        """Test ask with too long question"""
        response = client.post("/api/v1/chat/ask",
            headers=auth_headers,
            json={
                "question": "x" * 2001,
                "language": "en"
            }
        )
        
        assert response.status_code == 400
    
    def test_list_conversations(self, client, auth_headers, user, db_session):
        """Test list conversations"""
        c1 = ChatConversation(user_id=user.id, title="Chat 1")
        c2 = ChatConversation(user_id=user.id, title="Chat 2")
        db_session.add_all([c1, c2])
        db_session.commit()
        
        response = client.get("/api/v1/chat/conversations", headers=auth_headers)
        
        assert response.status_code == 200
        assert len(response.json["items"]) == 2
        assert "page" in response.json
        assert "limit" in response.json
    
    def test_list_conversations_paginated(self, client, auth_headers, user, db_session):
        """Test list conversations with pagination"""
        for i in range(25):
            conv = ChatConversation(user_id=user.id, title=f"Chat {i}")
            db_session.add(conv)
        db_session.commit()
        
        response = client.get("/api/v1/chat/conversations?page=2&limit=10",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        assert response.json["page"] == 2
        assert response.json["limit"] == 10
        assert len(response.json["items"]) == 10
    
    def test_get_conversation_messages(self, client, auth_headers, user, db_session):
        """Test get messages from conversation"""
        conv = ChatConversation(user_id=user.id, title="Test Chat")
        db_session.add(conv)
        db_session.commit()
        
        for i in range(5):
            msg = ChatMessage(
                user_id=user.id,
                conversation_id=conv.id,
                role="user" if i % 2 == 0 else "assistant",
                content=f"Message {i}"
            )
            db_session.add(msg)
        db_session.commit()
        
        response = client.get(f"/api/v1/chat/conversations/{conv.id}/messages",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        assert len(response.json["items"]) == 5
        assert response.json["conversationId"] == conv.id
    
    def test_get_conversation_messages_not_owner(self, client, auth_headers, db_session):
        """Test get messages from another user's conversation"""
        other_user_id = 99999
        conv = ChatConversation(user_id=other_user_id, title="Other's Chat")
        db_session.add(conv)
        db_session.commit()
        
        response = client.get(f"/api/v1/chat/conversations/{conv.id}/messages",
            headers=auth_headers
        )
        
        assert response.status_code == 403
    
    def test_rename_conversation_success(self, client, auth_headers, user, db_session):
        """Test rename conversation"""
        conv = ChatConversation(user_id=user.id, title="Old Title")
        db_session.add(conv)
        db_session.commit()
        
        response = client.put(f"/api/v1/chat/conversations/{conv.id}",
            headers=auth_headers,
            json={
                "title": "New Title"
            }
        )
        
        assert response.status_code == 200
        
        updated = ChatConversation.query.get(conv.id)
        assert updated.title == "New Title"
    
    def test_rename_conversation_empty_title(self, client, auth_headers, user, db_session):
        """Test rename with empty title"""
        conv = ChatConversation(user_id=user.id, title="Title")
        db_session.add(conv)
        db_session.commit()
        
        response = client.put(f"/api/v1/chat/conversations/{conv.id}",
            headers=auth_headers,
            json={
                "title": ""
            }
        )
        
        assert response.status_code == 400
    
    def test_rename_conversation_title_too_long(self, client, auth_headers, user, db_session):
        """Test rename with title too long"""
        conv = ChatConversation(user_id=user.id, title="Title")
        db_session.add(conv)
        db_session.commit()
        
        response = client.put(f"/api/v1/chat/conversations/{conv.id}",
            headers=auth_headers,
            json={
                "title": "x" * 201
            }
        )
        
        assert response.status_code == 400
    
    def test_delete_conversation_success(self, client, auth_headers, user, db_session):
        """Test delete conversation"""
        conv = ChatConversation(user_id=user.id, title="To Delete")
        db_session.add(conv)
        db_session.commit()
        
        msg = ChatMessage(
            user_id=user.id,
            conversation_id=conv.id,
            role="user",
            content="Message"
        )
        db_session.add(msg)
        db_session.commit()
        
        response = client.delete(f"/api/v1/chat/conversations/{conv.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        
        # Verify conversation and messages deleted
        assert ChatConversation.query.get(conv.id) is None
        assert ChatMessage.query.filter_by(conversation_id=conv.id).count() == 0
    
    def test_delete_conversation_not_owner(self, client, auth_headers, db_session):
        """Test delete another user's conversation"""
        other_user_id = 99999
        conv = ChatConversation(user_id=other_user_id, title="Other's Chat")
        db_session.add(conv)
        db_session.commit()
        
        response = client.delete(f"/api/v1/chat/conversations/{conv.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 403