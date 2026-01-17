import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';
import '../network/dio_provider.dart';
import 'content_cache.dart';

final contentSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final dio = ref.watch(dioProvider);
  final logger = ref.read(appLoggerProvider);
  try {
    final manifestResponse = await dio.get('/content/manifest');
    final manifest = manifestResponse.data as Map<String, dynamic>;
    final version = (manifest['version'] as num?)?.toInt() ?? 0;
    final cachedVersion = await ContentCache.getVersion();
    if (cachedVersion == version) {
      return;
    }

    final files = manifest['files'] as Map<String, dynamic>? ?? {};
    final rightsUrl = _resolveUrl(dio, files['rights']?['url'] as String? ?? '/content/rights.json');
    final templatesUrl = _resolveUrl(dio, files['templates']?['url'] as String? ?? '/content/templates.json');

    final rightsResponse = await dio.getUri(rightsUrl);
    final templatesResponse = await dio.getUri(templatesUrl);

    if (rightsResponse.data is List) {
      await ContentCache.saveRights(rightsResponse.data as List<dynamic>);
    }
    if (templatesResponse.data is List) {
      await ContentCache.saveTemplates(templatesResponse.data as List<dynamic>);
    }
    await ContentCache.setVersion(version);
    logger.info('content.sync.success', {'version': version});
  } catch (e) {
    logger.warn('content.sync.failed');
  }
});

Uri _resolveUrl(Dio dio, String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Uri.parse(url);
  }
  final base = Uri.parse(dio.options.baseUrl);
  if (url.startsWith('/')) {
    return base.replace(path: url);
  }
  return base.resolve(url);
}
