// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drafts_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(drafts)
final draftsProvider = DraftsProvider._();

final class DraftsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Draft>>,
          List<Draft>,
          FutureOr<List<Draft>>
        >
    with $FutureModifier<List<Draft>>, $FutureProvider<List<Draft>> {
  DraftsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'draftsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$draftsHash();

  @$internal
  @override
  $FutureProviderElement<List<Draft>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Draft>> create(Ref ref) {
    return drafts(ref);
  }
}

String _$draftsHash() => r'cc3c087cb5f165deefe0eb7c66f9014dd6dfb549';
