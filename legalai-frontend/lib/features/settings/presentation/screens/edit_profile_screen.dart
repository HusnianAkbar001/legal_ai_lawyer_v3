import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProviderSubscription<AsyncValue<dynamic>> _authSub;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherCnicController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherCnicController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _totalSiblingsController = TextEditingController();
  final _brothersController = TextEditingController();
  final _sistersController = TextEditingController();
  final _timezoneController = TextEditingController();

  String? _gender;
  String _language = 'en';
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _syncFromUser();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('profile_edit');
    });
    _authSub = ref.listenManual(authControllerProvider, (prev, next) {
      if (!_initialized && next.value != null) {
        _syncFromUser();
      }
    });
  }

  void _syncFromUser() {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      return;
    }
    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _cnicController.text = user.cnic ?? '';
    _fatherNameController.text = user.fatherName ?? '';
    _fatherCnicController.text = user.fatherCnic ?? '';
    _motherNameController.text = user.motherName ?? '';
    _motherCnicController.text = user.motherCnic ?? '';
    _cityController.text = user.city ?? '';
    _ageController.text = user.age?.toString() ?? '';
    _totalSiblingsController.text = user.totalSiblings?.toString() ?? '';
    _brothersController.text = user.brothers?.toString() ?? '';
    _sistersController.text = user.sisters?.toString() ?? '';
    _timezoneController.text = user.timezone ?? '';
    _gender = user.gender;
    _language = user.language ?? 'en';
    _initialized = true;
  }

  @override
  void dispose() {
    _authSub.close();
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _fatherNameController.dispose();
    _fatherCnicController.dispose();
    _motherNameController.dispose();
    _motherCnicController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _totalSiblingsController.dispose();
    _brothersController.dispose();
    _sistersController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      return;
    }

    final data = <String, dynamic>{};
    void addIfChanged(String key, String value, String? oldValue) {
      final newValue = value.trim();
      final oldValueSafe = oldValue?.trim() ?? '';
      if (newValue != oldValueSafe) {
        data[key] = newValue;
      }
    }

    addIfChanged('name', _nameController.text, user.name);
    addIfChanged('phone', _phoneController.text, user.phone);
    addIfChanged('cnic', _cnicController.text, user.cnic);
    addIfChanged('fatherName', _fatherNameController.text, user.fatherName);
    addIfChanged('fatherCnic', _fatherCnicController.text, user.fatherCnic);
    addIfChanged('motherName', _motherNameController.text, user.motherName);
    addIfChanged('motherCnic', _motherCnicController.text, user.motherCnic);
    addIfChanged('city', _cityController.text, user.city);
    addIfChanged('timezone', _timezoneController.text, user.timezone);

    if (_gender != (user.gender ?? '')) {
      data['gender'] = _gender;
    }
    if (_language != (user.language ?? 'en')) {
      data['language'] = _language;
    }

    final age = _parseInt(_ageController.text);
    if (age != user.age) {
      data['age'] = age;
    }
    final totalSiblings = _parseInt(_totalSiblingsController.text);
    if (totalSiblings != user.totalSiblings) {
      data['totalSiblings'] = totalSiblings;
    }
    final brothers = _parseInt(_brothersController.text);
    if (brothers != user.brothers) {
      data['brothers'] = brothers;
    }
    final sisters = _parseInt(_sistersController.text);
    if (sisters != user.sisters) {
      data['sisters'] = sisters;
    }

    if (data.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(data);
      ref.invalidate(authControllerProvider);
      await ref.read(userActivityLoggerProvider).logEvent('PROFILE_UPDATED');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated)),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  int? _parseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppResponsive.pagePadding(context),
                children: [
                  const SafeModeBanner(),
                  SizedBox(height: AppResponsive.spacing(context, 16)),
                  _Section(
                    title: l10n.basicInformation,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: l10n.fullName),
                        validator: (value) => value == null || value.trim().isEmpty ? l10n.nameRequired : null,
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: l10n.phone),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _cnicController,
                        decoration: InputDecoration(labelText: l10n.cnic),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(labelText: l10n.city),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(labelText: l10n.gender),
                        items: [
                          DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
                          DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                          DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
                        ],
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(labelText: l10n.age),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          return int.tryParse(value) == null ? l10n.validNumber : null;
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 16)),
                  _Section(
                    title: l10n.familyDetails,
                    children: [
                      TextFormField(
                        controller: _fatherNameController,
                        decoration: InputDecoration(labelText: l10n.fatherName),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _fatherCnicController,
                        decoration: InputDecoration(labelText: l10n.fatherCnic),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _motherNameController,
                        decoration: InputDecoration(labelText: l10n.motherName),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      TextFormField(
                        controller: _motherCnicController,
                        decoration: InputDecoration(labelText: l10n.motherCnic),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalSiblingsController,
                              decoration: InputDecoration(labelText: l10n.totalSiblings),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                return int.tryParse(value) == null ? l10n.validNumber : null;
                              },
                            ),
                          ),
                          SizedBox(width: AppResponsive.spacing(context, 12)),
                          Expanded(
                            child: TextFormField(
                              controller: _brothersController,
                              decoration: InputDecoration(labelText: l10n.brothers),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                return int.tryParse(value) == null ? l10n.validNumber : null;
                              },
                            ),
                          ),
                          SizedBox(width: AppResponsive.spacing(context, 12)),
                          Expanded(
                            child: TextFormField(
                              controller: _sistersController,
                              decoration: InputDecoration(labelText: l10n.sisters),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                return int.tryParse(value) == null ? l10n.validNumber : null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 16)),
                  _Section(
                    title: l10n.preferences,
                    children: [
                      TextFormField(
                        controller: _timezoneController,
                        decoration: InputDecoration(labelText: l10n.timezone),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 12)),
                      DropdownButtonFormField<String>(
                        value: _language,
                        decoration: InputDecoration(labelText: l10n.language),
                        items: [
                          DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                          DropdownMenuItem(value: 'ur', child: Text(l10n.languageUrdu)),
                        ],
                        onChanged: (value) => setState(() => _language = value ?? 'en'),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 24)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.saveChanges),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
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
