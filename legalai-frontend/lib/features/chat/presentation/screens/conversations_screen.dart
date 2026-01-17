import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/chat_model.dart';
import '../controllers/chat_controller.dart';
import '../controllers/conversations_controller.dart';
import '../../../../core/layout/app_responsive.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(conversationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conversations)),
      body: conversationsAsync.when(
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.noConversations))
            : ListView.separated(
                padding: AppResponsive.pagePadding(context),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                itemBuilder: (context, index) {
                  final conversation = items[index];
                  return _ConversationTile(
                    conversation: conversation,
                    onOpen: () {
                      ref.read(appLoggerProvider).info('chat.conversation.open', {
                        'conversationId': conversation.id,
                      });
                      ref.read(chatControllerProvider.notifier).loadConversation(conversation.id);
                      if (context.mounted) context.pop();
                    },
                    onRename: () => _renameConversation(context, ref, conversation),
                    onDelete: () => _deleteConversation(context, ref, conversation),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }

  Future<void> _renameConversation(BuildContext context, WidgetRef ref, Conversation conversation) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: conversation.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameConversation),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    final errorMessage = await ref
        .read(conversationsControllerProvider.notifier)
        .renameConversation(conversation, result);
    if (errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _deleteConversation(BuildContext context, WidgetRef ref, Conversation conversation) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(conversationsControllerProvider.notifier);
    final pending = controller.removeConversation(conversation);
    if (pending == null) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    var undoPressed = false;
    await messenger
        .showSnackBar(
          SnackBar(
            content: Text(l10n.conversationDeleted),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                undoPressed = true;
                controller.restoreConversation(pending);
              },
            ),
          ),
        )
        .closed;

    if (undoPressed) return;

    final errorMessage = await controller.finalizeDelete(pending);
    if (errorMessage != null) {
      controller.restoreConversation(pending);
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return;
    }

    final refreshError = await controller.refresh();
    if (refreshError != null && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(refreshError)));
    }
  }
}

class _ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  Timer? _renameTimer;
  bool _renameTriggered = false;

  void _startRenameTimer() {
    _renameTimer?.cancel();
    _renameTriggered = false;
    _renameTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _renameTriggered = true;
      widget.onRename();
    });
  }

  void _cancelRenameTimer() {
    _renameTimer?.cancel();
    _renameTimer = null;
  }

  @override
  void dispose() {
    _renameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        padding: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 20)),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppPalette.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: (_) => _startRenameTimer(),
          onTapCancel: _cancelRenameTimer,
          onTap: () {
            _cancelRenameTimer();
            if (_renameTriggered) {
              _renameTriggered = false;
              return;
            }
            widget.onOpen();
          },
          child: Padding(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
            child: Row(
              children: [
                Container(
                  width: AppResponsive.spacing(context, 44),
                  height: AppResponsive.spacing(context, 44),
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: AppPalette.primary),
                ),
                SizedBox(width: AppResponsive.spacing(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 4)),
                      Text(
                        conversation.lastMessageSnippet ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppPalette.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
