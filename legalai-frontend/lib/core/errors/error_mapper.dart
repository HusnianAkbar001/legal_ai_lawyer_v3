import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../preferences/app_preferences.dart';
import 'app_exception.dart';

class ErrorMapper {
  static AppException from(Object error) {
    final l10n = _l10n();
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      return _fromDio(error, l10n);
    }
    return AppException(userMessage: l10n.somethingWentWrong);
  }

  static AppException _fromDio(DioException error, AppLocalizations l10n) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? message;

    if (data is Map<String, dynamic>) {
      final raw = data['message'];
      if (raw is String && raw.trim().isNotEmpty) {
        message = raw.trim();
      }
    }

    if (message == null) {
      message = _fallbackMessage(status, l10n);
    }

    if (status != null && status >= 500) {
      message = l10n.serverError;
    }

    return AppException(
      userMessage: message,
      statusCode: status,
      cause: error,
    );
  }

  static String _fallbackMessage(int? status, AppLocalizations l10n) {
    if (status == null) {
      return l10n.networkError;
    }
    if (status == 400) {
      return l10n.invalidRequest;
    }
    if (status == 401) {
      return l10n.pleaseLoginAgain;
    }
    if (status == 403) {
      return l10n.permissionDenied;
    }
    if (status == 404) {
      return l10n.notFound;
    }
    if (status == 409) {
      return l10n.conflictDetected;
    }
    if (status == 429) {
      return l10n.tooManyRequests;
    }
    return l10n.unexpectedError;
  }

  static AppLocalizations _l10n() {
    final lang = _languageCode();
    return lookupAppLocalizations(Locale(lang));
  }

  static String _languageCode() {
    if (!Hive.isBoxOpen(AppPreferences.boxName)) {
      return 'en';
    }
    final prefs = AppPreferences(Hive.box(AppPreferences.boxName));
    return prefs.getLanguage();
  }
}
