import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_provider.dart';
import 'auth_interceptor.dart';
import '../logging/app_logger.dart';
import '../session/session_invalidator.dart';
import 'safe_log_interceptor.dart';
import '../preferences/preferences_providers.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kDebugMode ? AppConstants.apiBaseUrlDev : AppConstants.apiBaseUrlProd,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final storage = ref.watch(secureStorageProvider);
  final logger = ref.watch(appLoggerProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final safeMode = ref.read(safeModeProvider);
        options.headers['X-Safe-Mode'] = safeMode ? '1' : '0';
        handler.next(options);
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      dio: dio,
      logger: logger,
      onSessionInvalidated: () {
        ref.read(sessionInvalidationProvider.notifier).bump();
      },
    ),
  );

  dio.interceptors.add(SafeLogInterceptor(logger));

  return dio;
}
