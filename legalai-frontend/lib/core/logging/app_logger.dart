import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'log_redactor.dart';

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

class AppLogger {
  void info(String event, [Map<String, dynamic>? meta]) {
    _log('INFO', event, meta);
  }

  void warn(String event, [Map<String, dynamic>? meta]) {
    _log('WARN', event, meta);
  }

  void error(String event, [Map<String, dynamic>? meta]) {
    _log('ERROR', event, meta);
  }

  void _log(String level, String event, Map<String, dynamic>? meta) {
    final payload = meta == null ? '{}' : jsonEncode(LogRedactor.redactMap(meta));
    debugPrint('[$level] $event $payload');
  }
}
