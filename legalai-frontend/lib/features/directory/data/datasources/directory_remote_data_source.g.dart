// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_remote_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(directoryRepository)
final directoryRepositoryProvider = DirectoryRepositoryProvider._();

final class DirectoryRepositoryProvider
    extends
        $FunctionalProvider<
          DirectoryRepository,
          DirectoryRepository,
          DirectoryRepository
        >
    with $Provider<DirectoryRepository> {
  DirectoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<DirectoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DirectoryRepository create(Ref ref) {
    return directoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectoryRepository>(value),
    );
  }
}

String _$directoryRepositoryHash() =>
    r'9e710c8a254b43f37f1c3383d41d5aa590e9d190';
