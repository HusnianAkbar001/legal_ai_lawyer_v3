import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminContactMessagesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getContactMessages();
});

class AdminContactMessagesScreen extends ConsumerWidget {
  const AdminContactMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(adminContactMessagesProvider);

    return AdminPage(
      title: 'Contact Messages',
      subtitle: 'Review and respond to user inquiries',
      body: messagesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No messages yet',
                message: 'Incoming support requests will appear here.',
                icon: Icons.support_agent_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = items[index];
              final subject = (msg['subject'] ?? '').toString();
              final name = (msg['fullName'] ?? '').toString();
              final email = (msg['email'] ?? '').toString();
              return InkWell(
                onTap: () => context.go('/admin/contact/${msg['id']}'),
                borderRadius: BorderRadius.circular(18),
                child: AdminCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.mail_outline, color: AdminColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.isEmpty ? 'No subject' : subject,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$name - $email',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AdminColors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class AdminContactMessageDetailScreen extends ConsumerWidget {
  final int messageId;
  const AdminContactMessageDetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminPage(
      title: 'Message Detail',
      subtitle: 'Review the full support request',
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(adminRepositoryProvider).getContactMessage(messageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final err = ErrorMapper.from(snapshot.error!);
            final message = err is AppException ? err.userMessage : err.toString();
            return Center(child: Text(message));
          }
          final data = snapshot.data ?? {};
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminInfoRow(label: 'Name', value: data['fullName']?.toString() ?? ''),
                    AdminInfoRow(label: 'Email', value: data['email']?.toString() ?? ''),
                    AdminInfoRow(label: 'Phone', value: data['phone']?.toString() ?? ''),
                    AdminInfoRow(label: 'Subject', value: data['subject']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['description']?.toString() ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

