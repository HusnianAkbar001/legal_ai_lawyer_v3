import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class ContentCache {
  static const String _boxName = 'content_cache';
  static const String _versionKey = 'content_version';
  static const String _rightsKey = 'rights_json';
  static const String _templatesKey = 'templates_json';

  static Future<Box> _box() async {
    return Hive.openBox(_boxName);
  }

  static Future<int?> getVersion() async {
    final box = await _box();
    return box.get(_versionKey) as int?;
  }

  static Future<void> setVersion(int version) async {
    final box = await _box();
    await box.put(_versionKey, version);
  }

  static Future<void> saveRights(List<dynamic> data) async {
    final box = await _box();
    await box.put(_rightsKey, jsonEncode(data));
  }

  static Future<void> saveTemplates(List<dynamic> data) async {
    final box = await _box();
    await box.put(_templatesKey, jsonEncode(data));
  }

  static Future<List<dynamic>?> getRights() async {
    final box = await _box();
    final raw = box.get(_rightsKey) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  static Future<List<dynamic>?> getTemplates() async {
    final box = await _box();
    final raw = box.get(_templatesKey) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }
}
