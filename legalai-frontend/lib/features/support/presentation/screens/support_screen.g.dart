// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupportController)
final supportControllerProvider = SupportControllerProvider._();

final class SupportControllerProvider
    extends $NotifierProvider<SupportController, void> {
  SupportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportControllerHash();

  @$internal
  @override
  SupportController create() => SupportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$supportControllerHash() => r'02274acd7e8ce750e014a788a2beeb1853e6b50b';

abstract class _$SupportController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
