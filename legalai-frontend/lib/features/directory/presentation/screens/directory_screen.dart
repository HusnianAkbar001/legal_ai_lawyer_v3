import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../domain/models/lawyer_model.dart';
import '../../data/datasources/directory_remote_data_source.dart';
import 'lawyer_detail_screen.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';

part 'directory_screen.g.dart';

@riverpod
Future<List<Lawyer>> lawyers(Ref ref, {String? city, String? specialization}) {
  return ref.watch(directoryRepositoryProvider).getLawyers(city: city, specialization: specialization);
}

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('directory');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lawyersAsync = ref.watch(lawyersProvider());
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.findLawyer)),
      body: lawyersAsync.when(
        data: (lawyers) => lawyers.isEmpty
            ? ListView(
                padding: AppResponsive.pagePadding(context),
                children: [
                  const SafeModeBanner(),
                  SizedBox(height: AppResponsive.spacing(context, 16)),
                  Center(child: Text(l10n.noLawyersAvailable)),
                ],
              )
            : ListView.separated(
                padding: AppResponsive.pagePadding(context),
                itemCount: lawyers.length + 1,
                separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const SafeModeBanner();
                  }
                  final lawyer = lawyers[index - 1];
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                      child: Row(
                        children: [
                          _LawyerAvatar(lawyer: lawyer),
                          SizedBox(width: AppResponsive.spacing(context, 16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lawyer.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppResponsive.font(context, 16),
                                  ),
                                ),
                                Text(
                                  lawyer.specialization,
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                                if (lawyer.phone != null && lawyer.phone!.isNotEmpty)
                                  Text(
                                    lawyer.phone!,
                                    style: TextStyle(color: scheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => LawyerDetailScreen(lawyer: lawyer)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }
}

class _LawyerAvatar extends StatelessWidget {
  final Lawyer lawyer;

  const _LawyerAvatar({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = lawyer.name.isNotEmpty ? lawyer.name[0] : 'L';
    final imageUrl = lawyer.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: AppResponsive.spacing(context, 28),
        backgroundColor: scheme.primary.withOpacity(0.12),
        child: Text(initials, style: TextStyle(color: scheme.primary)),
      );
    }
    return ClipOval(
      child: Image.network(
        imageUrl,
        width: AppResponsive.spacing(context, 56),
        height: AppResponsive.spacing(context, 56),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: AppResponsive.spacing(context, 28),
            backgroundColor: scheme.primary.withOpacity(0.12),
            child: Text(initials, style: TextStyle(color: scheme.primary)),
          );
        },
      ),
    );
  }
}
