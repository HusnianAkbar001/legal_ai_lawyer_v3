import 'package:dio/dio.dart';
import '../logging/app_logger.dart';
import '../logging/log_redactor.dart';

class SafeLogInterceptor extends Interceptor {
  final AppLogger _logger;

  SafeLogInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTimeMs'] = DateTime.now().millisecondsSinceEpoch;
    _logger.info('network.request', {
      'method': options.method,
      'path': options.path,
      'queryKeys': options.queryParameters.keys.toList(),
      'data': LogRedactor.summarizePayload(options.data),
    });
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = response.requestOptions.extra['startTimeMs'] as int?;
    final durationMs = start == null
        ? null
        : DateTime.now().millisecondsSinceEpoch - start;
    _logger.info('network.response', {
      'method': response.requestOptions.method,
      'path': response.requestOptions.path,
      'status': response.statusCode,
      'durationMs': durationMs,
      'data': LogRedactor.summarizePayload(response.data),
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final start = err.requestOptions.extra['startTimeMs'] as int?;
    final durationMs = start == null
        ? null
        : DateTime.now().millisecondsSinceEpoch - start;
    _logger.warn('network.error', {
      'method': err.requestOptions.method,
      'path': err.requestOptions.path,
      'status': err.response?.statusCode,
      'durationMs': durationMs,
      'type': err.type.name,
    });
    handler.next(err);
  }
}
