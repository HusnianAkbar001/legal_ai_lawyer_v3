// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignupFormController)
final signupFormControllerProvider = SignupFormControllerProvider._();

final class SignupFormControllerProvider
    extends $NotifierProvider<SignupFormController, SignupState> {
  SignupFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signupFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signupFormControllerHash();

  @$internal
  @override
  SignupFormController create() => SignupFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignupState>(value),
    );
  }
}

String _$signupFormControllerHash() =>
    r'a5a5c34ae298f8d2e09da31a3ba2a97ccd2abb08';

abstract class _$SignupFormController extends $Notifier<SignupState> {
  SignupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SignupState, SignupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignupState, SignupState>,
              SignupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
