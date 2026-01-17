import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/chat_model.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../../core/errors/error_mapper.dart';

part 'chat_controller.g.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final int? conversationId;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.conversationId,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    int? conversationId,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      conversationId: conversationId ?? this.conversationId,
      error: error,
    );
  }
}

@riverpod
class ChatController extends _$ChatController {
  @override
  ChatState build() {
    return ChatState();
  }

  Future<void> askQuestion(String question) async {
    // Add user message immediately
    final userMsg = ChatMessage(role: 'user', content: question, createdAt: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final repo = ref.read(chatRepositoryProvider);
      final response = await repo.askQuestion(
        question, 
        conversationId: state.conversationId,
      );
      
      final answer = response['answer'] as String;
      final newConvId = response['conversationId'] as int?;

      final assistantMsg = ChatMessage(
        role: 'assistant', 
        content: answer, 
        createdAt: DateTime.now()
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
        conversationId: newConvId ?? state.conversationId,
      );
    } catch (e) {
      final err = ErrorMapper.from(e);
      state = state.copyWith(isLoading: false, error: err.userMessage);
    }
  }

  void loadConversation(int id) async {
      state = state.copyWith(isLoading: true, conversationId: id, messages: []);
       try {
      final repo = ref.read(chatRepositoryProvider);
      final messages = await repo.getMessages(id);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      final err = ErrorMapper.from(e);
      state = state.copyWith(isLoading: false, error: err.userMessage);
    }
  }
}
