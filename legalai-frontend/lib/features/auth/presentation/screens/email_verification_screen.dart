import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/layout/app_responsive.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? token;
  const EmailVerificationScreen({super.key, this.token});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _tokenController = TextEditingController();
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() => _verifying = true);
    try {
      final ok = await ref.read(authControllerProvider.notifier).verifyEmail(token);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final message = ok ? l10n.emailVerifiedSuccess : l10n.emailVerifiedFail;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        if (ok) context.go('/login');
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxWidth = AppResponsive.maxContentWidth(context);
    final cardWidth = maxWidth > 520 ? 520.0 : maxWidth;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyEmail)),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
                    child: TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(labelText: l10n.verificationToken),
                    ),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _verifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.verifyEmail),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
