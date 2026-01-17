import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) {
    return null;
  }
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = kDebugMode ? AppConstants.apiBaseUrlDev : AppConstants.apiBaseUrlProd;
  final baseUri = Uri.parse(base);
  final root = Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
  );
  final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return root.resolve('uploads/$normalized').toString();
}
