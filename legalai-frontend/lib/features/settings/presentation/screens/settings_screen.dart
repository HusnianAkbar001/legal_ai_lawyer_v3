import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('profile');
    });
  }

  Future<void> _showPhotoSourceDialog() async {
    if (_uploading) return;
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndUpload(source);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final platformFile = PlatformFile(
        name: file.name,
        size: bytes.length,
        bytes: bytes,
      );
      setState(() => _uploading = true);
      final path = await ref.read(userRepositoryProvider).uploadAvatar(platformFile);
      ref.invalidate(authControllerProvider);
      await ref.read(userActivityLoggerProvider).logEvent(
        'PROFILE_IMAGE_UPDATED',
        payload: {
          'source': source.name,
          'path': path.isNotEmpty,
        },
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profilePhotoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profilePhotoUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _toggleSafeMode(bool enabled) async {
    ref.read(safeModeProvider.notifier).setSafeMode(enabled);
    await ref.read(userActivityLoggerProvider).logEvent(
      'SAFE_MODE_TOGGLED',
      payload: {'enabled': enabled},
    );
  }

  Future<void> _emergencyExit() async {
    await ref.read(userActivityLoggerProvider).logEvent('EMERGENCY_EXIT');
    await ref.read(authControllerProvider.notifier).logout();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final initials = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim()[0] : l10n.userInitialFallback;
    final avatarUrl = resolveMediaUrl(user?.avatarPath);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          const SafeModeBanner(),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          Container(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 18)),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppResponsive.spacing(context, 34),
                  backgroundColor: scheme.primary.withOpacity(0.12),
                  foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
                  child: avatarUrl == null
                      ? Text(
                          initials,
                          style: TextStyle(fontSize: AppResponsive.font(context, 28), color: scheme.primary),
                        )
                      : null,
                ),
                SizedBox(width: AppResponsive.spacing(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? l10n.guestUser,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 4)),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 10)),
                      Wrap(
                        spacing: AppResponsive.spacing(context, 8),
                        runSpacing: AppResponsive.spacing(context, 8),
                        children: [
                          OutlinedButton.icon(
                            onPressed: _uploading ? null : _showPhotoSourceDialog,
                            icon: const Icon(Icons.photo_camera_outlined, size: 18),
                            label: Text(_uploading ? l10n.uploading : l10n.changePhoto),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/profile/edit'),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(l10n.editProfile),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 20)),
          _SettingsSection(
            title: l10n.account,
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: l10n.changePassword,
                onTap: () => context.push('/change-password'),
              ),
              _SettingsTile(
                icon: Icons.language,
                title: l10n.appearanceLanguage,
                onTap: () => context.push('/preferences'),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.tools,
            children: [
              _SettingsTile(
                icon: Icons.alarm_outlined,
                title: l10n.reminders,
                onTap: () => context.push('/reminders'),
              ),
              _SettingsTile(
                icon: Icons.bookmark_border,
                title: l10n.bookmarks,
                onTap: () => context.push('/bookmarks'),
              ),
              _SettingsTile(
                icon: Icons.history,
                title: l10n.activityLog,
                onTap: () => context.push('/activity'),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.safety,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: ref.watch(safeModeProvider),
                onChanged: _toggleSafeMode,
                title: Text(l10n.safeMode),
                subtitle: Text(
                  l10n.safeModeDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 6)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: scheme.error),
                onPressed: _emergencyExit,
                icon: const Icon(Icons.warning_amber_rounded),
                label: Text(l10n.emergencyExit),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.support,
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: l10n.helpSupport,
                onTap: () => context.push('/support'),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 24)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 10)),
        child: Row(
          children: [
            Container(
              width: AppResponsive.spacing(context, 36),
              height: AppResponsive.spacing(context, 36),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.primary, size: 18),
            ),
            SizedBox(width: AppResponsive.spacing(context, 12)),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
