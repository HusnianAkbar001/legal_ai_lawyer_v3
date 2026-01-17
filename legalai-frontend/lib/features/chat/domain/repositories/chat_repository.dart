import '../models/chat_model.dart';

abstract class ChatRepository {
  Future<Map<String, dynamic>> askQuestion(String question, {int? conversationId, String language = 'en'});
  Future<List<Conversation>> getConversations({int page = 1, int limit = 20});
  Future<List<ChatMessage>> getMessages(int conversationId, {int page = 1, int limit = 30});
  Future<void> deleteConversation(int conversationId);
  Future<void> renameConversation(int conversationId, String title);
}
