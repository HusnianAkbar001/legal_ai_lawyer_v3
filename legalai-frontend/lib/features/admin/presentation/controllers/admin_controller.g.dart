// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ragMetrics)
final ragMetricsProvider = RagMetricsFamily._();

final class RagMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<RagMetrics>,
          RagMetrics,
          FutureOr<RagMetrics>
        >
    with $FutureModifier<RagMetrics>, $FutureProvider<RagMetrics> {
  RagMetricsProvider._({
    required RagMetricsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'ragMetricsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ragMetricsHash();

  @override
  String toString() {
    return r'ragMetricsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RagMetrics> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RagMetrics> create(Ref ref) {
    final argument = this.argument as int;
    return ragMetrics(ref, days: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RagMetricsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ragMetricsHash() => r'7bfbe98fd425cdf6e2de98d21db6ee728e7d0500';

final class RagMetricsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RagMetrics>, int> {
  RagMetricsFamily._()
    : super(
        retry: null,
        name: r'ragMetricsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RagMetricsProvider call({int days = 7}) =>
      RagMetricsProvider._(argument: days, from: this);

  @override
  String toString() => r'ragMetricsProvider';
}

@ProviderFor(knowledgeSources)
final knowledgeSourcesProvider = KnowledgeSourcesProvider._();

final class KnowledgeSourcesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KnowledgeSource>>,
          List<KnowledgeSource>,
          FutureOr<List<KnowledgeSource>>
        >
    with
        $FutureModifier<List<KnowledgeSource>>,
        $FutureProvider<List<KnowledgeSource>> {
  KnowledgeSourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knowledgeSourcesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knowledgeSourcesHash();

  @$internal
  @override
  $FutureProviderElement<List<KnowledgeSource>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KnowledgeSource>> create(Ref ref) {
    return knowledgeSources(ref);
  }
}

String _$knowledgeSourcesHash() => r'81206a177bffd55d71b4b9fce719219f0b31ec75';

@ProviderFor(AdminActions)
final adminActionsProvider = AdminActionsProvider._();

final class AdminActionsProvider extends $NotifierProvider<AdminActions, void> {
  AdminActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminActionsHash();

  @$internal
  @override
  AdminActions create() => AdminActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$adminActionsHash() => r'4d5167ac0ca118132f86164f077844c001eeee43';

abstract class _$AdminActions extends $Notifier<void> {
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
