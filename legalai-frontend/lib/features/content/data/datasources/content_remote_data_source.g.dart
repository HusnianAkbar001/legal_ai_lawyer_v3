// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_remote_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contentRemoteDataSource)
final contentRemoteDataSourceProvider = ContentRemoteDataSourceProvider._();

final class ContentRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ContentRemoteDataSource,
          ContentRemoteDataSource,
          ContentRemoteDataSource
        >
    with $Provider<ContentRemoteDataSource> {
  ContentRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ContentRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentRemoteDataSource create(Ref ref) {
    return contentRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentRemoteDataSource>(value),
    );
  }
}

String _$contentRemoteDataSourceHash() =>
    r'9a996794fe58c79165101ff5f4feb69eef58b2c3';
