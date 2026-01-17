import 'dart:convert';
import 'package:dio/dio.dart';

class LogRedactor {
  static const Set<String> _sensitiveKeys = {
    'authorization',
    'password',
    'currentpassword',
    'newpassword',
    'confirmpassword',
    'token',
    'accesstoken',
    'refreshtoken',
    'email',
    'phone',
    'cnic',
    'fathercnic',
    'mothercnic',
    'subject',
    'description',
    'comment',
    'message',
    'body',
    'answers',
    'usersnapshot',
    'question',
    'answer',
    'content',
    'file',
  };

  static String summarizePayload(Object? data) {
    if (data == null) {
      return 'null';
    }
    if (data is FormData) {
      final fields = data.fields.map((e) => e.key).toList();
      final files = data.files.map((e) => e.key).toList();
      return jsonEncode({
        'fields': fields,
        'files': files,
      });
    }
    if (data is Map<String, dynamic>) {
      return jsonEncode(_redactMap(data));
    }
    if (data is List) {
      return jsonEncode(data.map(_redactValue).toList());
    }
    return '"[redacted]"';
  }

  static Map<String, dynamic> redactMap(Map<String, dynamic> data) {
    return _redactMap(data);
  }

  static Object? _redactValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return _redactMap(value);
    }
    if (value is List) {
      return value.map(_redactValue).toList();
    }
    if (value is String) {
      return '[redacted]';
    }
    return value;
  }

  static Map<String, dynamic> _redactMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key;
      final keyLower = key.toLowerCase();
      if (_isSensitiveKey(keyLower)) {
        sanitized[key] = '[redacted]';
      } else {
        sanitized[key] = _redactValue(entry.value);
      }
    }
    return sanitized;
  }

  static bool _isSensitiveKey(String keyLower) {
    if (_sensitiveKeys.contains(keyLower)) {
      return true;
    }
    if (keyLower.contains('token')) {
      return true;
    }
    if (keyLower.contains('password')) {
      return true;
    }
    if (keyLower.contains('email')) {
      return true;
    }
    if (keyLower.contains('phone')) {
      return true;
    }
    if (keyLower.contains('cnic')) {
      return true;
    }
    return false;
  }
}
