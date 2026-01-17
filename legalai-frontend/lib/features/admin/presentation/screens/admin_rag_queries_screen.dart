import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final ragQueriesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getRagQueries();
});

class AdminRagQueriesScreen extends ConsumerWidget {
  const AdminRagQueriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queriesAsync = ref.watch(ragQueriesProvider);

    return AdminPage(
      title: 'RAG Queries',
      subtitle: 'Inspect decisions and system responses',
      body: queriesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No queries yet',
                message: 'RAG traces will show up after user activity.',
                icon: Icons.query_stats_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = items[index];
              final question = q['question']?.toString() ?? '';
              final decision = q['decision']?.toString() ?? '';
              final createdAt = q['createdAt']?.toString() ?? '';
              return InkWell(
                onTap: () => context.go('/admin/rag-queries/${q['id']}'),
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
                        child: const Icon(Icons.query_stats_outlined, color: AdminColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.isEmpty ? 'No question text' : question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$decision - $createdAt',
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

class AdminRagQueryDetailScreen extends ConsumerWidget {
  final int queryId;
  const AdminRagQueryDetailScreen({super.key, required this.queryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminPage(
      title: 'Query Detail',
      subtitle: 'Full trace of the selected request',
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(adminRepositoryProvider).getRagQueryDetail(queryId),
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
                    Text(
                      'Question',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(data['question']?['text']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(data['answer']?['text']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminInfoRow(label: 'Decision', value: data['rag']?['decision']?.toString() ?? ''),
                    AdminInfoRow(label: 'In Domain', value: data['rag']?['inDomain']?.toString() ?? ''),
                    AdminInfoRow(label: 'Contexts Used', value: data['rag']?['contextsUsed']?.toString() ?? ''),
                    AdminInfoRow(label: 'Total Time (ms)', value: data['performance']?['totalTimeMs']?.toString() ?? ''),
                    AdminInfoRow(label: 'Tokens', value: data['tokens']?['total']?.toString() ?? ''),
                    if (data['error'] != null)
                      AdminInfoRow(label: 'Error', value: data['error']?['message']?.toString() ?? ''),
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

