import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/user_remote_data_source.dart';

final userActivityLoggerProvider = Provider<UserActivityLogger>((ref) {
  return UserActivityLogger(ref);
});

class UserActivityLogger {
  final Ref _ref;

  UserActivityLogger(this._ref);

  Future<void> logEvent(String eventType, {Map<String, dynamic> payload = const {}}) async {
    final logger = _ref.read(appLoggerProvider);
    final repository = _ref.read(userRepositoryProvider);
    final sanitized = _sanitizePayload(payload);
    logger.info('user.activity.log.start', {'eventType': eventType});
    try {
      await repository.logActivity(eventType, sanitized);
      logger.info('user.activity.log.success', {'eventType': eventType});
    } catch (e) {
      final err = ErrorMapper.from(e);
      logger.warn('user.activity.log.failed', {
        'eventType': eventType,
        'status': err.statusCode,
      });
    }
  }

  Future<void> logScreenView(String screen) async {
    await logEvent('SCREEN_VIEW', payload: {'screen': screen});
  }

  Map<String, dynamic> _sanitizePayload(Map<String, dynamic> payload) {
    final sanitized = <String, dynamic>{};
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is String || value is num || value is bool || value == null) {
        sanitized[entry.key] = value;
      } else {
        sanitized[entry.key] = value.toString();
      }
    }
    return sanitized;
  }
}
