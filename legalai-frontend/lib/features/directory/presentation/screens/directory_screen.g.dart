// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lawyers)
final lawyersProvider = LawyersFamily._();

final class LawyersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Lawyer>>,
          List<Lawyer>,
          FutureOr<List<Lawyer>>
        >
    with $FutureModifier<List<Lawyer>>, $FutureProvider<List<Lawyer>> {
  LawyersProvider._({
    required LawyersFamily super.from,
    required ({String? city, String? specialization}) super.argument,
  }) : super(
         retry: null,
         name: r'lawyersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lawyersHash();

  @override
  String toString() {
    return r'lawyersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Lawyer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Lawyer>> create(Ref ref) {
    final argument = this.argument as ({String? city, String? specialization});
    return lawyers(
      ref,
      city: argument.city,
      specialization: argument.specialization,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LawyersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lawyersHash() => r'86c8cca647efd1efb65d5a8664a2d6f979aea445';

final class LawyersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Lawyer>>,
          ({String? city, String? specialization})
        > {
  LawyersFamily._()
    : super(
        retry: null,
        name: r'lawyersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LawyersProvider call({String? city, String? specialization}) =>
      LawyersProvider._(
        argument: (city: city, specialization: specialization),
        from: this,
      );

  @override
  String toString() => r'lawyersProvider';
}
