import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/layout/app_responsive.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final maxWidth = AppResponsive.maxContentWidth(context);
    final cardWidth = maxWidth > 520 ? 520.0 : maxWidth;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final err = next.error;
        final message = err is AppException ? err.userMessage : err.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      // Success is handled by router redirect
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 24)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.loginTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 8)),
                    Text(
                      l10n.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppPalette.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 28)),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email)),
                              validator: (value) => value!.isEmpty ? l10n.enterEmail : null,
                            ),
                            SizedBox(height: AppResponsive.spacing(context, 16)),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock)),
                              obscureText: true,
                              validator: (value) => value!.isEmpty ? l10n.enterPassword : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                child: Text(l10n.forgotPassword),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 20)),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : _login,
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.login),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 8)),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: Text(l10n.createAccount),
                    ),
                    TextButton(
                      onPressed: () => context.push('/verify-email'),
                      child: Text(l10n.verifyEmail),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
