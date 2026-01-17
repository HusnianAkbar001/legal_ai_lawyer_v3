import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../controllers/user_controller.dart';
import '../controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('activity_log');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activityAsync = ref.watch(userActivityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activityLog)),
      body: activityAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return ListView(
              padding: AppResponsive.pagePadding(context),
              children: [
                const SafeModeBanner(),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                Center(child: Text(l10n.noActivity)),
              ],
            );
          }
          return ListView.separated(
            padding: AppResponsive.pagePadding(context),
            itemCount: logs.length,
            separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    const SafeModeBanner(),
                    SizedBox(height: AppResponsive.spacing(context, 16)),
                    _ActivityTile(log: logs[index]),
                  ],
                );
              }
              return _ActivityTile(log: logs[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> log;

  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: Icon(Icons.history, color: scheme.onSurfaceVariant),
        title: Text(log['type'] ?? l10n.unknown),
        subtitle: Text(log['createdAt'] ?? ''),
      ),
    );
  }
}
