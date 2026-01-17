// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklists_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checklistCategories)
final checklistCategoriesProvider = ChecklistCategoriesProvider._();

final class ChecklistCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChecklistCategory>>,
          List<ChecklistCategory>,
          FutureOr<List<ChecklistCategory>>
        >
    with
        $FutureModifier<List<ChecklistCategory>>,
        $FutureProvider<List<ChecklistCategory>> {
  ChecklistCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<ChecklistCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChecklistCategory>> create(Ref ref) {
    return checklistCategories(ref);
  }
}

String _$checklistCategoriesHash() =>
    r'3f4f52e1ccc46c726267e82f599da20d2a8c0915';

@ProviderFor(checklistItems)
final checklistItemsProvider = ChecklistItemsFamily._();

final class ChecklistItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChecklistItem>>,
          List<ChecklistItem>,
          FutureOr<List<ChecklistItem>>
        >
    with
        $FutureModifier<List<ChecklistItem>>,
        $FutureProvider<List<ChecklistItem>> {
  ChecklistItemsProvider._({
    required ChecklistItemsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'checklistItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checklistItemsHash();

  @override
  String toString() {
    return r'checklistItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ChecklistItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChecklistItem>> create(Ref ref) {
    final argument = this.argument as int;
    return checklistItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChecklistItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checklistItemsHash() => r'dc797d87ce8546e6591ae50c36d30b18059a217d';

final class ChecklistItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ChecklistItem>>, int> {
  ChecklistItemsFamily._()
    : super(
        retry: null,
        name: r'checklistItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChecklistItemsProvider call(int categoryId) =>
      ChecklistItemsProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'checklistItemsProvider';
}
