// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rights)
final rightsProvider = RightsFamily._();

final class RightsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LegalRight>>,
          List<LegalRight>,
          FutureOr<List<LegalRight>>
        >
    with $FutureModifier<List<LegalRight>>, $FutureProvider<List<LegalRight>> {
  RightsProvider._({
    required RightsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'rightsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rightsHash();

  @override
  String toString() {
    return r'rightsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LegalRight>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LegalRight>> create(Ref ref) {
    final argument = this.argument as String?;
    return rights(ref, category: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RightsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rightsHash() => r'7168c41c5426ae993d3764b0d839146ac2cd41b5';

final class RightsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LegalRight>>, String?> {
  RightsFamily._()
    : super(
        retry: null,
        name: r'rightsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RightsProvider call({String? category}) =>
      RightsProvider._(argument: category, from: this);

  @override
  String toString() => r'rightsProvider';
}

@ProviderFor(templates)
final templatesProvider = TemplatesFamily._();

final class TemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LegalTemplate>>,
          List<LegalTemplate>,
          FutureOr<List<LegalTemplate>>
        >
    with
        $FutureModifier<List<LegalTemplate>>,
        $FutureProvider<List<LegalTemplate>> {
  TemplatesProvider._({
    required TemplatesFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'templatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$templatesHash();

  @override
  String toString() {
    return r'templatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LegalTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LegalTemplate>> create(Ref ref) {
    final argument = this.argument as String?;
    return templates(ref, category: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TemplatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$templatesHash() => r'840b57f52a27b7efcbd27a1a907abc3f4b7f2f31';

final class TemplatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LegalTemplate>>, String?> {
  TemplatesFamily._()
    : super(
        retry: null,
        name: r'templatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TemplatesProvider call({String? category}) =>
      TemplatesProvider._(argument: category, from: this);

  @override
  String toString() => r'templatesProvider';
}

@ProviderFor(pathways)
final pathwaysProvider = PathwaysFamily._();

final class PathwaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LegalPathway>>,
          List<LegalPathway>,
          FutureOr<List<LegalPathway>>
        >
    with
        $FutureModifier<List<LegalPathway>>,
        $FutureProvider<List<LegalPathway>> {
  PathwaysProvider._({
    required PathwaysFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'pathwaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pathwaysHash();

  @override
  String toString() {
    return r'pathwaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LegalPathway>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LegalPathway>> create(Ref ref) {
    final argument = this.argument as String?;
    return pathways(ref, category: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PathwaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pathwaysHash() => r'c20050441961ce9816d8252c584990f8200d6019';

final class PathwaysFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LegalPathway>>, String?> {
  PathwaysFamily._()
    : super(
        retry: null,
        name: r'pathwaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PathwaysProvider call({String? category}) =>
      PathwaysProvider._(argument: category, from: this);

  @override
  String toString() => r'pathwaysProvider';
}
