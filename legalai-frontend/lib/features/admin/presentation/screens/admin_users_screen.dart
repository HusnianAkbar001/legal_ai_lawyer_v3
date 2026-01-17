import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getUsers();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AdminPage(
      title: 'Users',
      subtitle: 'Control access and manage user accounts',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showUserForm(context, ref, null),
          icon: const Icon(Icons.person_add),
          label: const Text('New User'),
        ),
      ],
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: AdminEmptyState(
                title: 'No users yet',
                message: 'Create the first user to get started.',
                icon: Icons.people_outline,
              ),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final name = (user['name'] ?? '').toString();
              final email = (user['email'] ?? '').toString();
              final isAdmin = user['isAdmin'] == true;
              final isDeleted = user['isDeleted'] == true;
              return AdminCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AdminColors.primary.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0] : 'U',
                        style: const TextStyle(color: AdminColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Unnamed User' : name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (isAdmin)
                          Chip(
                            label: const Text('Admin'),
                            backgroundColor: AdminColors.accent.withOpacity(0.18),
                          ),
                        if (isDeleted)
                          const Chip(
                            label: Text('Deleted'),
                            backgroundColor: Color(0xFFFFE4E6),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showUserForm(context, ref, user);
                        } else if (value == 'delete') {
                          await _deleteUser(context, ref, user['id'] as int);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          enabled: !isDeleted,
                          child: const Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: !isDeleted,
                          child: const Text('Delete'),
                        ),
                      ],
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

  Future<void> _showUserForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) async {
    final nameController = TextEditingController(text: user?['name']?.toString() ?? '');
    final emailController = TextEditingController(text: user?['email']?.toString() ?? '');
    final phoneController = TextEditingController(text: user?['phone']?.toString() ?? '');
    final cnicController = TextEditingController(text: user?['cnic']?.toString() ?? '');
    final passwordController = TextEditingController();
    bool isAdmin = user?['isAdmin'] == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(user == null ? 'Create User' : 'Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: user == null,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cnicController,
                  decoration: const InputDecoration(labelText: 'CNIC'),
                  enabled: user == null,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: user == null ? 'Password' : 'New Password (optional)'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isAdmin,
                  title: const Text('Admin'),
                  onChanged: (value) => setState(() => isAdmin = value),
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
      if (user == null) {
        final name = nameController.text.trim();
        final email = emailController.text.trim().toLowerCase();
        final phone = phoneController.text.trim();
        final cnic = cnicController.text.trim();
        final password = passwordController.text;

        if (name.isEmpty || email.isEmpty || phone.isEmpty || cnic.isEmpty || password.isEmpty) {
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
        if (!_isValidPassword(password)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password must be 8+ chars with uppercase, lowercase, and a special character')),
            );
          }
          return;
        }
        await ref.read(adminRepositoryProvider).createUser({
          'name': name,
          'email': email,
          'phone': phone,
          'cnic': cnic,
          'password': password,
          'isAdmin': isAdmin,
        });
      } else {
        final name = nameController.text.trim();
        final phone = phoneController.text.trim();
        if (name.isEmpty || phone.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name and phone are required')),
            );
          }
          return;
        }
        final data = <String, dynamic>{
          'name': name,
          'phone': phone,
          'isAdmin': isAdmin,
        };
        if (passwordController.text.trim().isNotEmpty) {
          final password = passwordController.text;
          if (!_isValidPassword(password)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password must be 8+ chars with uppercase, lowercase, and a special character')),
              );
            }
            return;
          }
          data['password'] = password;
        }
        await ref.read(adminRepositoryProvider).updateUser(user['id'] as int, data);
      }
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteUser(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUser(id);
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

final RegExp _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');

bool _isValidEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at >= trimmed.length - 3) return false;
  return trimmed.contains('.', at);
}

bool _isValidPassword(String value) {
  return _passwordRegex.hasMatch(value);
}
