import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/repositories/chat_repository.dart';

final conversationsControllerProvider =
    NotifierProvider.autoDispose<ConversationsController, AsyncValue<List<Conversation>>>(
  ConversationsController.new,
);

class PendingConversationDelete {
  final Conversation conversation;
  final int index;

  PendingConversationDelete({
    required this.conversation,
    required this.index,
  });
}

class ConversationsController extends Notifier<AsyncValue<List<Conversation>>> {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  AppLogger get _logger => ref.read(appLoggerProvider);

  @override
  AsyncValue<List<Conversation>> build() {
    Future.microtask(() => refresh(initialLoad: true));
    return const AsyncValue.loading();
  }

  Future<String?> refresh({bool initialLoad = false}) async {
    final previous = state.asData?.value;
    _logger.info(
      initialLoad ? 'chat.conversations.load.start' : 'chat.conversations.refresh.start',
    );
    if (initialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final items = await _repository.getConversations();
      state = AsyncValue.data(items);
      _logger.info(
        initialLoad ? 'chat.conversations.load.success' : 'chat.conversations.refresh.success',
        {
          'count': items.length,
        },
      );
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      _logger.error(
        initialLoad ? 'chat.conversations.load.failed' : 'chat.conversations.refresh.failed',
        {
          'status': err.statusCode,
        },
      );
      if (initialLoad || previous == null) {
        state = AsyncValue.error(err, st);
      } else {
        state = AsyncValue.data(previous);
      }
      return err.userMessage;
    }
    return null;
  }

  PendingConversationDelete? removeConversation(Conversation conversation) {
    final current = state.asData?.value;
    if (current == null) {
      _logger.warn('chat.conversation.delete.skipped', {
        'conversationId': conversation.id,
        'reason': 'state_not_ready',
      });
      return null;
    }
    final index = current.indexWhere((item) => item.id == conversation.id);
    if (index == -1) {
      _logger.warn('chat.conversation.delete.skipped', {
        'conversationId': conversation.id,
        'reason': 'not_found',
      });
      return null;
    }
    final updated = [...current]..removeAt(index);
    state = AsyncValue.data(updated);
    _logger.info('chat.conversation.delete.optimistic', {
      'conversationId': conversation.id,
    });
    return PendingConversationDelete(conversation: conversation, index: index);
  }

  void restoreConversation(PendingConversationDelete pending) {
    final current = state.asData?.value ?? [];
    if (current.any((item) => item.id == pending.conversation.id)) {
      _logger.warn('chat.conversation.delete.restore.skipped', {
        'conversationId': pending.conversation.id,
        'reason': 'already_present',
      });
      return;
    }
    final safeIndex = pending.index < 0
        ? 0
        : pending.index > current.length
            ? current.length
            : pending.index;
    final updated = [...current]..insert(safeIndex, pending.conversation);
    state = AsyncValue.data(updated);
    _logger.info('chat.conversation.delete.restored', {
      'conversationId': pending.conversation.id,
    });
  }

  Future<String?> finalizeDelete(PendingConversationDelete pending) async {
    _logger.info('chat.conversation.delete.start', {
      'conversationId': pending.conversation.id,
    });
    try {
      await _repository.deleteConversation(pending.conversation.id);
      _logger.info('chat.conversation.delete.success', {
        'conversationId': pending.conversation.id,
      });
      return null;
    } catch (e) {
      final err = ErrorMapper.from(e);
      _logger.error('chat.conversation.delete.failed', {
        'conversationId': pending.conversation.id,
        'status': err.statusCode,
      });
      return err.userMessage;
    }
  }

  Future<String?> renameConversation(Conversation conversation, String title) async {
    _logger.info('chat.conversation.rename.start', {
      'conversationId': conversation.id,
    });
    try {
      await _repository.renameConversation(conversation.id, title);
      _updateTitle(conversation.id, title);
      _logger.info('chat.conversation.rename.success', {
        'conversationId': conversation.id,
      });
      return null;
    } catch (e) {
      final err = ErrorMapper.from(e);
      _logger.error('chat.conversation.rename.failed', {
        'conversationId': conversation.id,
        'status': err.statusCode,
      });
      return err.userMessage;
    }
  }

  void _updateTitle(int conversationId, String title) {
    final current = state.asData?.value;
    if (current == null) return;
    final index = current.indexWhere((item) => item.id == conversationId);
    if (index == -1) return;
    final existing = current[index];
    final updated = [...current];
    updated[index] = Conversation(
      id: existing.id,
      title: title,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      lastMessageSnippet: existing.lastMessageSnippet,
    );
    state = AsyncValue.data(updated);
  }
}
