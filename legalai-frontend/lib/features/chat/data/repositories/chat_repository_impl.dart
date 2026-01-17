import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

part 'chat_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> askQuestion(String question, {int? conversationId, String language = 'en'}) {
    return remoteDataSource.ask(question, conversationId: conversationId, language: language);
  }

  @override
  Future<List<Conversation>> getConversations({int page = 1, int limit = 20}) {
    return remoteDataSource.getConversations(page, limit);
  }

  @override
  Future<List<ChatMessage>> getMessages(int conversationId, {int page = 1, int limit = 30}) {
    return remoteDataSource.getMessages(conversationId, page, limit);
  }

  @override
  Future<void> deleteConversation(int conversationId) {
    return remoteDataSource.deleteConversation(conversationId);
  }

  @override
  Future<void> renameConversation(int conversationId, String title) {
    return remoteDataSource.renameConversation(conversationId, title);
  }
}
