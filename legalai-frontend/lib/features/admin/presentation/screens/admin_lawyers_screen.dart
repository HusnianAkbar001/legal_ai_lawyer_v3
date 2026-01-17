import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../directory/domain/models/lawyer_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminLawyersProvider = FutureProvider.autoDispose<List<Lawyer>>((ref) async {
  return ref.watch(adminRepositoryProvider).getLawyers();
});

final lawyerCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(adminRepositoryProvider).getLawyerCategories();
});

class AdminLawyersScreen extends ConsumerWidget {
  const AdminLawyersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyersAsync = ref.watch(adminLawyersProvider);

    return AdminPage(
      title: 'Lawyers',
      subtitle: 'Manage verified lawyers and profiles',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showLawyerForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('New Lawyer'),
        ),
      ],
      body: lawyersAsync.when(
        data: (lawyers) {
          if (lawyers.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No lawyers yet',
                message: 'Add lawyers to populate the directory.',
                icon: Icons.gavel_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: lawyers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lawyer = lawyers[index];
              final statusLabel = lawyer.isVerified ? 'Active' : 'Inactive';
              final statusColor = lawyer.isVerified ? AdminColors.success : AdminColors.warning;
              return AdminCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: lawyer.imageUrl != null ? NetworkImage(lawyer.imageUrl!) : null,
                      backgroundColor: AdminColors.primary.withOpacity(0.12),
                      child: lawyer.imageUrl == null
                          ? Text(
                              lawyer.name.isNotEmpty ? lawyer.name[0] : 'L',
                              style: const TextStyle(color: AdminColors.primary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lawyer.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lawyer.specialization,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(statusLabel),
                      backgroundColor: statusColor.withOpacity(0.16),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                      ],
                      onSelected: (val) async {
                        if (val == 'edit') {
                          await _showLawyerForm(context, ref, lawyer);
                        } else if (val == 'deactivate') {
                          await _deactivateLawyer(context, ref, lawyer.id);
                        }
                      },
                    ),
                  ],
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

  Future<void> _showLawyerForm(BuildContext context, WidgetRef ref, Lawyer? lawyer) async {
    final nameController = TextEditingController(text: lawyer?.name ?? '');
    final emailController = TextEditingController(text: lawyer?.email ?? '');
    final phoneController = TextEditingController(text: lawyer?.phone ?? '');
    String? category = lawyer?.specialization;
    PlatformFile? imageFile;

    final categories = await ref.read(lawyerCategoriesProvider.future);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lawyer == null ? 'Create Lawyer' : 'Edit Lawyer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => category = value),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
                    if (result == null || result.files.isEmpty) {
                      return;
                    }
                    final selected = result.files.single;
                    final error = _validateImageFile(selected);
                    if (error != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      }
                      return;
                    }
                    setState(() => imageFile = selected);
                  },
                  child: Text(imageFile == null ? 'Select Image' : 'Change Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim().toLowerCase();
      final phone = phoneController.text.trim();

      if (name.isEmpty || email.isEmpty || phone.isEmpty || category == null || category!.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All fields are required')),
          );
        }
        return;
      }
      if (!_isValidEmail(email)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid email')),
          );
        }
        return;
      }
      if (imageFile != null) {
        final error = _validateImageFile(imageFile!);
        if (error != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          }
          return;
        }
      }

      if (lawyer == null) {
        if (imageFile == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture is required')),
            );
          }
          return;
        }
        await ref.read(adminRepositoryProvider).createLawyer({
          'fullName': name,
          'email': email,
          'phone': phone,
          'category': category,
        }, imageFile!);
      } else {
        await ref.read(adminRepositoryProvider).updateLawyer(
          lawyer.id,
          {
            'fullName': name,
            'email': email,
            'phone': phone,
            'category': category,
          },
          imageFile,
        );
      }
      ref.invalidate(adminLawyersProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deactivateLawyer(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Lawyer'),
        content: const Text('Are you sure you want to deactivate this lawyer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deactivateLawyer(id);
      ref.invalidate(adminLawyersProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

const int _maxAvatarBytes = 5 * 1024 * 1024;

bool _isValidEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at >= trimmed.length - 3) return false;
  return trimmed.contains('.', at);
}

String _fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

String? _validateImageFile(PlatformFile file) {
  final ext = _fileExtension(file.name);
  if (ext.isEmpty || !{'jpg', 'jpeg', 'png'}.contains(ext)) {
    return 'Only JPG and PNG images are allowed';
  }
  if (file.size > _maxAvatarBytes) {
    return 'Image too large (max 5MB)';
  }
  if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
    return 'Image data is missing';
  }
  return null;
}
