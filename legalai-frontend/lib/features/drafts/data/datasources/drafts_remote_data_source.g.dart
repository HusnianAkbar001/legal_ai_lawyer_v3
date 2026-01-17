// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drafts_remote_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(draftsRepository)
final draftsRepositoryProvider = DraftsRepositoryProvider._();

final class DraftsRepositoryProvider
    extends
        $FunctionalProvider<
          DraftsRepository,
          DraftsRepository,
          DraftsRepository
        >
    with $Provider<DraftsRepository> {
  DraftsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'draftsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$draftsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DraftsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DraftsRepository create(Ref ref) {
    return draftsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DraftsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DraftsRepository>(value),
    );
  }
}

String _$draftsRepositoryHash() => r'1afc31ec998f897d5ccac3ea61f78f90335c8707';
