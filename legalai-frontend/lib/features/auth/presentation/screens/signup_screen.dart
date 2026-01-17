import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../controllers/auth_controller.dart';
import '../controllers/signup_form_controller.dart';
import '../../../../core/layout/app_responsive.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _familyFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();

  final _fatherNameController = TextEditingController();
  final _fatherCnicController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherCnicController = TextEditingController();
  final _totalSiblingsController = TextEditingController();
  final _brothersController = TextEditingController();
  final _sistersController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _province;
  String? _gender;
  String _language = 'en';
  bool _submitting = false;

  final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _fatherNameController.dispose();
    _fatherCnicController.dispose();
    _motherNameController.dispose();
    _motherCnicController.dispose();
    _totalSiblingsController.dispose();
    _brothersController.dispose();
    _sistersController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signupState = ref.watch(signupFormControllerProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final err = next.error;
        final message = err is AppException ? err.userMessage : err.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccount)),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: signupState.currentStep,
        onStepContinue: () {
          if (signupState.currentStep == 0) {
            if (_personalFormKey.currentState!.validate()) {
              ref.read(signupFormControllerProvider.notifier).nextStep();
            }
          } else if (signupState.currentStep == 1) {
            if (_familyFormKey.currentState!.validate()) {
              ref.read(signupFormControllerProvider.notifier).nextStep();
            }
          } else {
            if (_accountFormKey.currentState!.validate()) {
              _submit();
            }
          }
        },
        onStepCancel: () {
          ref.read(signupFormControllerProvider.notifier).previousStep();
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: EdgeInsets.only(top: AppResponsive.spacing(context, 20)),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: authState.isLoading || _submitting ? null : details.onStepContinue,
                    child: Text(signupState.currentStep == 2 ? l10n.signUp : l10n.next),
                  ),
                ),
                if (signupState.currentStep > 0) ...[
                  SizedBox(width: AppResponsive.spacing(context, 12)),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.back),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(l10n.personal),
            content: _buildPersonalStep(),
            isActive: signupState.currentStep >= 0,
          ),
          Step(
            title: Text(l10n.family),
            content: _buildFamilyStep(),
            isActive: signupState.currentStep >= 1,
          ),
          Step(
            title: Text(l10n.account),
            content: _buildAccountStep(),
            isActive: signupState.currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStep() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _personalFormKey,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
          child: Column(children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (value) => value == null || value.trim().isEmpty ? l10n.nameRequired : null,
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.emailRequired;
                if (!value.contains('@')) return l10n.emailInvalid;
                return null;
              },
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.phone),
              validator: (value) => value == null || value.trim().isEmpty ? l10n.phoneRequired : null,
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _cnicController,
              decoration: InputDecoration(labelText: l10n.cnic),
              validator: (value) => value == null || value.trim().isEmpty ? l10n.cnicRequired : null,
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            DropdownButtonFormField<String>(
              value: _province,
              decoration: InputDecoration(labelText: l10n.province),
              items: [
                DropdownMenuItem(value: 'Punjab', child: Text(l10n.provincePunjab)),
                DropdownMenuItem(value: 'Sindh', child: Text(l10n.provinceSindh)),
                DropdownMenuItem(value: 'KP', child: Text(l10n.provinceKp)),
                DropdownMenuItem(value: 'Balochistan', child: Text(l10n.provinceBalochistan)),
                DropdownMenuItem(value: 'ICT', child: Text(l10n.provinceIct)),
              ],
              onChanged: (value) => setState(() => _province = value),
              validator: (value) => value == null || value.isEmpty ? l10n.provinceRequired : null,
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(labelText: l10n.cityOptional),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(labelText: l10n.genderOptional),
              items: [
                DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
                DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(labelText: l10n.ageOptional),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return int.tryParse(value) == null ? l10n.validNumber : null;
              },
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: InputDecoration(labelText: l10n.language),
              items: [
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                DropdownMenuItem(value: 'ur', child: Text(l10n.languageUrdu)),
              ],
              onChanged: (value) => setState(() => _language = value ?? 'en'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFamilyStep() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _familyFormKey,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
          child: Column(children: [
            TextFormField(
              controller: _fatherNameController,
              decoration: InputDecoration(labelText: l10n.fatherName),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _fatherCnicController,
              decoration: InputDecoration(labelText: l10n.fatherCnic),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _motherNameController,
              decoration: InputDecoration(labelText: l10n.motherName),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _motherCnicController,
              decoration: InputDecoration(labelText: l10n.motherCnic),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _totalSiblingsController,
              decoration: InputDecoration(labelText: l10n.totalSiblings),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return int.tryParse(value) == null ? l10n.validNumber : null;
              },
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _brothersController,
              decoration: InputDecoration(labelText: l10n.brothers),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return int.tryParse(value) == null ? l10n.validNumber : null;
              },
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _sistersController,
              decoration: InputDecoration(labelText: l10n.sisters),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return int.tryParse(value) == null ? l10n.validNumber : null;
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _accountFormKey,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
          child: Column(children: [
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: l10n.password),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.passwordRequired;
                if (!_passwordRegex.hasMatch(value)) {
                  return l10n.passwordRule;
                }
                return null;
              },
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: l10n.confirmPassword),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.confirmPasswordRequired;
                if (value != _passwordController.text) return l10n.passwordsDoNotMatch;
                return null;
              },
            ),
          ]),
        ),
      ),
    );
  }

  int? _parseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  Future<void> _submit() async {
    if (_province == null) {
      return;
    }
    setState(() => _submitting = true);
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'phone': _phoneController.text.trim(),
      'cnic': _cnicController.text.trim(),
      'password': _passwordController.text,
      'province': _province,
      'language': _language,
    };

    final city = _cityController.text.trim();
    if (city.isNotEmpty) data['city'] = city;
    if (_gender != null) data['gender'] = _gender;

    final age = _parseInt(_ageController.text);
    if (age != null) data['age'] = age;

    final fatherName = _fatherNameController.text.trim();
    if (fatherName.isNotEmpty) data['fatherName'] = fatherName;
    final fatherCnic = _fatherCnicController.text.trim();
    if (fatherCnic.isNotEmpty) data['fatherCnic'] = fatherCnic;
    final motherName = _motherNameController.text.trim();
    if (motherName.isNotEmpty) data['motherName'] = motherName;
    final motherCnic = _motherCnicController.text.trim();
    if (motherCnic.isNotEmpty) data['motherCnic'] = motherCnic;

    final totalSiblings = _parseInt(_totalSiblingsController.text);
    if (totalSiblings != null) data['totalSiblings'] = totalSiblings;
    final brothers = _parseInt(_brothersController.text);
    if (brothers != null) data['brothers'] = brothers;
    final sisters = _parseInt(_sistersController.text);
    if (sisters != null) data['sisters'] = sisters;

    try {
      await ref.read(authControllerProvider.notifier).signup(data);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
