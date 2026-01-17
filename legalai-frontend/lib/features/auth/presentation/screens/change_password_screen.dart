import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/layout/app_responsive.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            _currentController.text,
            _newController.text,
            _confirmController.text,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      if (mounted) {
        final message = err is AppException ? err.userMessage : err.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxWidth = AppResponsive.maxContentWidth(context);
    final cardWidth = maxWidth > 520 ? 520.0 : maxWidth;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currentController,
                            decoration: InputDecoration(labelText: l10n.currentPassword),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.currentPasswordRequired;
                              return null;
                            },
                          ),
                          SizedBox(height: AppResponsive.spacing(context, 12)),
                          TextFormField(
                            controller: _newController,
                            decoration: InputDecoration(labelText: l10n.newPassword),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.newPasswordRequired;
                              if (!_passwordRegex.hasMatch(value)) {
                                return l10n.passwordRule;
                              }
                              if (value == _currentController.text) {
                                return l10n.newPasswordDifferent;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppResponsive.spacing(context, 12)),
                          TextFormField(
                            controller: _confirmController,
                            decoration: InputDecoration(labelText: l10n.confirmNewPassword),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.confirmPasswordRequired;
                              if (value != _newController.text) return l10n.passwordsDoNotMatch;
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 20)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.updatePassword),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
