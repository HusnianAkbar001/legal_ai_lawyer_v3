import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../data/datasources/support_remote_data_source.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/layout/app_responsive.dart';

part 'support_screen.g.dart';

@riverpod
class SupportController extends _$SupportController {
  @override
  void build() {}

  Future<void> submitContact({
    required String fullName,
    required String email,
    required String phone,
    required String subject,
    required String description,
  }) async {
    ref.read(appLoggerProvider).info('support.contact.start');
    try {
      await ref.read(supportRepositoryProvider).submitContact(fullName, email, phone, subject, description);
      ref.read(appLoggerProvider).info('support.contact.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('support.contact.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> submitFeedback(int rating, String comment) async {
    ref.read(appLoggerProvider).info('support.feedback.start');
    try {
      await ref.read(supportRepositoryProvider).submitFeedback(rating, comment);
      ref.read(appLoggerProvider).info('support.feedback.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('support.feedback.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppPalette.primary,
          tabs: [
            Tab(text: l10n.contactUs),
            Tab(text: l10n.feedback),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContactForm(),
          FeedbackForm(),
        ],
      ),
    );
  }
}

class ContactForm extends ConsumerStatefulWidget {
  const ContactForm({super.key});

  @override
  ConsumerState<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(supportControllerProvider.notifier).submitContact(
          fullName: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          subject: _subjectCtrl.text,
          description: _descCtrl.text,
        );
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.messageSent)));
          _nameCtrl.clear();
          _emailCtrl.clear();
          _phoneCtrl.clear();
          _subjectCtrl.clear();
          _descCtrl.clear();
        }
      } catch (e) {
        final err = ErrorMapper.from(e);
        final message = err is AppException ? err.userMessage : err.toString();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: AppResponsive.pagePadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: l10n.fullName),
                      validator: (v) => v!.isEmpty ? l10n.requiredField : null,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(labelText: l10n.email),
                      validator: (v) => v!.isEmpty ? l10n.requiredField : null,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(labelText: l10n.phone),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: InputDecoration(labelText: l10n.subject),
                      validator: (v) => v!.isEmpty ? l10n.requiredField : null,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: InputDecoration(labelText: l10n.message),
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? l10n.requiredField : null,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppResponsive.spacing(context, 20)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.sendMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackForm extends ConsumerStatefulWidget {
  const FeedbackForm({super.key});

  @override
  ConsumerState<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<FeedbackForm> {
  final _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_commentCtrl.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await ref.read(supportControllerProvider.notifier).submitFeedback(_rating, _commentCtrl.text);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedbackSubmitted)));
          _commentCtrl.clear();
        }
      } catch (e) {
        final err = ErrorMapper.from(e);
        final message = err is AppException ? err.userMessage : err.toString();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: AppResponsive.pagePadding(context),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
              child: Column(
                children: [
                  Text(l10n.rateExperience),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                        onPressed: () => setState(() => _rating = index + 1),
                      );
                    }),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 16)),
                  TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(labelText: l10n.comments),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 20)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary, foregroundColor: Colors.white),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.submitFeedback),
            ),
          ),
        ],
      ),
    );
  }
}
