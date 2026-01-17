import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  final AppLogger? _logger;
  final void Function()? _onSessionInvalidated;
  
  bool _isRefreshing = false;
  final List<_RequestRetryInfo> _pendingRequests = [];

  AuthInterceptor({
    required FlutterSecureStorage storage,
    required Dio dio,
    AppLogger? logger,
    void Function()? onSessionInvalidated,
  })  : _storage = storage,
        _dio = dio,
        _logger = logger,
        _onSessionInvalidated = onSessionInvalidated;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.authTokenKey);
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    _logger?.info('auth.request', {
      'method': options.method,
      'path': options.path,
      'hasToken': token != null && token.isNotEmpty,
    });

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }
    
    final requestOptions = err.requestOptions;
    
    if (requestOptions.path.contains('/auth/login') ||
        requestOptions.path.contains('/auth/refresh') ||
        requestOptions.path.contains('/auth/signup')) {
      return handler.next(err);
    }

    _logger?.warn('auth.unauthorized', {
      'path': requestOptions.path,
    });

    if (_isRefreshing) {
      final completer = Completer<Response>();
      _pendingRequests.add(_RequestRetryInfo(
        options: requestOptions,
        completer: completer,
      ));
      
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearTokens();
        _onSessionInvalidated?.call();
        return handler.next(err);
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _storage.write(
            key: AppConstants.authTokenKey,
            value: newAccessToken,
          );
        }
        
        if (newRefreshToken != null) {
          await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: newRefreshToken,
          );
        }

        _logger?.info('auth.refresh.success');

        requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(requestOptions);
        
        for (final pending in _pendingRequests) {
          pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final pendingResponse = await _dio.fetch(pending.options);
            pending.completer.complete(pendingResponse);
          } catch (e) {
            pending.completer.completeError(e);
          }
        }
        _pendingRequests.clear();
        
        return handler.resolve(retryResponse);
      } else {
        await _clearTokens();
        _onSessionInvalidated?.call();
        return handler.next(err);
      }
    } on DioException catch (refreshError) {
      _logger?.warn('auth.refresh.failed', {
        'status': refreshError.response?.statusCode,
        'type': refreshError.type.name,
      });
      await _clearTokens();
      _onSessionInvalidated?.call();
      
      for (final pending in _pendingRequests) {
        pending.completer.completeError(refreshError);
      }
      _pendingRequests.clear();
      
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.authTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);

    _logger?.info('auth.tokens.cleared');
  }
}

class _RequestRetryInfo {
  final RequestOptions options;
  final Completer<Response> completer;

  _RequestRetryInfo({
    required this.options,
    required this.completer,
  });
}
