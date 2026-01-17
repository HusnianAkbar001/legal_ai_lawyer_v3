import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_stats_model.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_layout.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(ragMetricsProvider(days: 7));
    final knowledgeAsync = ref.watch(knowledgeSourcesProvider);
    final userName = ref.watch(authControllerProvider).value?.name ?? 'Admin';

    return AdminPage(
      title: 'Dashboard',
      header: _DashboardHeader(
        userName: userName,
        role: 'System Administrator',
        onSearch: () {},
        onNotifications: () {},
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final knowledgeCount = knowledgeAsync.maybeWhen(
            data: (sources) => sources.length,
            orElse: () => null,
          );
          final answerRate = metrics.totalQueries == 0
              ? 0.0
              : (metrics.decisions.answer / metrics.totalQueries) * 100;
          final ragAccuracy = metrics.quality.inDomainRate;
          final fallbackRate = metrics.quality.fallbackRate;
          final avgDistance = metrics.quality.avgDistance;
          final avgContexts = metrics.quality.avgContextsUsed;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1100
                      ? 4
                      : width >= 760
                          ? 2
                          : 1;
                  final ratio = width >= 1100 ? 1.7 : 1.5;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: ratio,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _MetricCard(
                        label: 'Total Queries',
                        value: _formatNumber(metrics.totalQueries),
                        icon: Icons.query_stats_outlined,
                        iconColor: AdminColors.primary,
                        badge: '+${_formatNumber(metrics.decisions.answer)}',
                        badgeColor: AdminColors.success,
                      ),
                      _MetricCard(
                        label: 'Knowledge Docs',
                        value: knowledgeCount == null ? '--' : _formatNumber(knowledgeCount),
                        icon: Icons.menu_book_outlined,
                        iconColor: AdminColors.accent,
                        badge: knowledgeCount == null ? 'Syncing' : 'Live',
                        badgeColor: AdminColors.accent,
                      ),
                      _MetricCard(
                        label: 'Answer Rate',
                        value: '${_formatPercent(answerRate)}%',
                        icon: Icons.check_circle_outline,
                        iconColor: AdminColors.success,
                        badge: _statusLabel(answerRate),
                        badgeColor: _statusColor(answerRate),
                      ),
                      _MetricCard(
                        label: 'RAG Accuracy',
                        value: '${_formatPercent(ragAccuracy)}%',
                        icon: Icons.auto_awesome_outlined,
                        iconColor: AdminColors.primary,
                        badge: _statusLabel(ragAccuracy),
                        badgeColor: _statusColor(ragAccuracy),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'MANAGEMENT HUB'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1100
                      ? 3
                      : width >= 760
                          ? 2
                          : 1;
                  final ratio = width >= 1100 ? 1.35 : 1.2;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: ratio,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _HubCard(
                        title: 'Users',
                        subtitle: 'Directory, creation, access',
                        icon: Icons.people_outline,
                        onTap: () => context.go('/admin/users'),
                      ),
                      _HubCard(
                        title: 'Knowledge',
                        subtitle: 'Vector ingestion and cleanup',
                        icon: Icons.auto_awesome_outlined,
                        onTap: () => context.go('/admin/knowledge'),
                      ),
                      _HubCard(
                        title: 'Lawyers',
                        subtitle: 'Verification and category',
                        icon: Icons.gavel_outlined,
                        onTap: () => context.go('/admin/lawyers'),
                      ),
                      _HubCard(
                        title: 'Moderation',
                        subtitle: 'Feedback and oversight',
                        icon: Icons.shield_outlined,
                        onTap: () => context.go('/admin/feedback'),
                      ),
                      _HubCard(
                        title: 'Content',
                        subtitle: 'Rights, templates, pathways',
                        icon: Icons.layers_outlined,
                        onTap: () => context.go('/admin/rights'),
                      ),
                      _HubCard(
                        title: 'Checklists',
                        subtitle: 'Operational CRUD flows',
                        icon: Icons.fact_check_outlined,
                        onTap: () => context.go('/admin/checklists'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _PerformanceCard(metrics: metrics),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'EVALUATION METRICS',
                trailing: TextButton(
                  onPressed: () => context.go('/admin/rag-queries'),
                  child: const Text('See all'),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1100
                      ? 3
                      : width >= 760
                          ? 2
                          : 1;
                  final ratio = width >= 1100 ? 2.4 : 2.1;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: ratio,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _EvaluationMetricCard(
                        label: 'Avg Distance',
                        value: _formatDecimal(avgDistance, digits: 3),
                        progress: _clamp(avgDistance, 0, 1),
                        color: AdminColors.primary,
                      ),
                      _EvaluationMetricCard(
                        label: 'Avg Contexts',
                        value: _formatDecimal(avgContexts, digits: 1),
                        progress: _clamp(avgContexts / 6, 0, 1),
                        color: AdminColors.accent,
                      ),
                      _EvaluationMetricCard(
                        label: 'Fallback Rate',
                        value: '${_formatPercent(fallbackRate)}%',
                        progress: _clamp(fallbackRate / 100, 0, 1),
                        color: AdminColors.warning,
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

final NumberFormat _decimalFormatter = NumberFormat.decimalPattern();
final NumberFormat _compactFormatter = NumberFormat.compact();

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final String role;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;

  const _DashboardHeader({
    required this.userName,
    required this.role,
    required this.onSearch,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final roleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AdminColors.accent,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
        );
    final initials = userName.trim().isNotEmpty ? userName.trim()[0] : 'A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Dashboard',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AdminColors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AdminColors.primary.withOpacity(0.18),
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AdminColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: nameStyle),
                const SizedBox(height: 4),
                Text(role.toUpperCase(), style: roleStyle),
              ],
            ),
            const Spacer(),
            _HeaderActionButton(
              icon: Icons.search,
              onTap: onSearch,
            ),
            const SizedBox(width: 10),
            _HeaderActionButton(
              icon: Icons.notifications_outlined,
              onTap: onNotifications,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AdminColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Icon(icon, color: AdminColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final Color? badgeColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AdminColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    final valueStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    return AdminCard(
      padding: const EdgeInsets.all(18),
      elevated: true,
      gradient: LinearGradient(
        colors: [
          AdminColors.surface,
          AdminColors.surfaceAlt,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              if (badge != null)
                _StatusBadge(
                  label: badge!,
                  color: badgeColor ?? AdminColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AdminColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        );
    return Row(
      children: [
        Text(title, style: titleStyle),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AdminColors.border.withOpacity(0.6),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AdminCard(
          padding: const EdgeInsets.all(18),
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AdminColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Icon(icon, color: AdminColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final RagMetrics metrics;

  const _PerformanceCard({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final periodLabel = metrics.period.isEmpty || metrics.period == 'N/A'
        ? 'Last 7 Days'
        : metrics.period;
    return AdminCard(
      padding: const EdgeInsets.all(20),
      elevated: true,
      gradient: LinearGradient(
        colors: [
          AdminColors.surface,
          AdminColors.surfaceAlt,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RAG Performance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              _StatusBadge(
                label: periodLabel.toUpperCase(),
                color: AdminColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Usage (Weekly)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AdminColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatCompact(metrics.tokens.totalUsed)} tokens',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg/query ${metrics.tokens.avgPerQuery.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AdminColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Text(
                  '${_formatPercent(metrics.quality.inDomainRate)}% in-domain',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AdminColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _WeeklyBars(),
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars();

  @override
  Widget build(BuildContext context) {
    const bars = [0.25, 0.42, 0.58, 0.3, 0.65, 0.82, 0.92];
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(bars.length, (index) {
              final height = 30 + (bars[index] * 80);
              final isPeak = index == bars.length - 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: isPeak
                            ? AdminColors.primary
                            : AdminColors.primary.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Center(
                child: Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _EvaluationMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _EvaluationMetricCard({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AdminColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int value) {
  return _decimalFormatter.format(value);
}

String _formatCompact(int value) {
  return _compactFormatter.format(value);
}

String _formatPercent(double value) {
  if (value.isNaN || value.isInfinite) {
    return '0.0';
  }
  return value.toStringAsFixed(1);
}

String _formatDecimal(double value, {int digits = 2}) {
  if (value.isNaN || value.isInfinite) {
    return '0.0';
  }
  return value.toStringAsFixed(digits);
}

String _statusLabel(double value) {
  if (value >= 90) return 'Optimal';
  if (value >= 75) return 'Stable';
  return 'Watch';
}

Color _statusColor(double value) {
  if (value >= 90) return AdminColors.success;
  if (value >= 75) return AdminColors.warning;
  return AdminColors.error;
}

double _clamp(double value, double min, double max) {
  if (value.isNaN || value.isInfinite) {
    return min;
  }
  return value.clamp(min, max).toDouble();
}
