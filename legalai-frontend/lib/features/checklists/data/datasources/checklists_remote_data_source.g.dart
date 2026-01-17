// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklists_remote_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checklistsRepository)
final checklistsRepositoryProvider = ChecklistsRepositoryProvider._();

final class ChecklistsRepositoryProvider
    extends
        $FunctionalProvider<
          ChecklistsRepository,
          ChecklistsRepository,
          ChecklistsRepository
        >
    with $Provider<ChecklistsRepository> {
  ChecklistsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChecklistsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistsRepository create(Ref ref) {
    return checklistsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistsRepository>(value),
    );
  }
}

String _$checklistsRepositoryHash() =>
    r'0ead4d11c168f488bf3e9f234b8c92bf5ac7972e';
