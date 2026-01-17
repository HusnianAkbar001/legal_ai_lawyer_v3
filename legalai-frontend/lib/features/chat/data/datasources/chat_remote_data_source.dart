import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/chat_model.dart';

part 'chat_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
ChatRemoteDataSource chatRemoteDataSource(Ref ref) {
  return ChatRemoteDataSource(ref.watch(dioProvider));
}

class ChatRemoteDataSource {
  final Dio _dio;

  ChatRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> ask(String question, {int? conversationId, String language = 'en'}) async {
    final response = await _dio.post('/chat/ask', data: {
      'question': question,
      'language': language,
      if (conversationId != null) 'conversationId': conversationId,
    });
    return response.data;
  }

  Future<List<Conversation>> getConversations(int page, int limit) async {
    final response = await _dio.get('/chat/conversations', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final items = response.data['items'] as List;
    return items.map((e) => Conversation.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getMessages(int conversationId, int page, int limit) async {
    final response = await _dio.get('/chat/conversations/$conversationId/messages', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final items = response.data['items'] as List;
    return items.map((e) => ChatMessage.fromJson(e)).toList();
  }
  
  Future<void> deleteConversation(int id) async {
      await _dio.delete('/chat/conversations/$id');
  }

  Future<void> renameConversation(int id, String title) async {
    await _dio.put('/chat/conversations/$id', data: {'title': title});
  }
}
