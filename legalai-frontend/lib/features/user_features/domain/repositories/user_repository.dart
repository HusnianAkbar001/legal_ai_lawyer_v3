import 'package:file_picker/file_picker.dart';

abstract class UserRepository {
  Future<String> uploadAvatar(PlatformFile file);
  Future<List<Map<String, dynamic>>> getBookmarks();
  Future<void> addBookmark(String itemType, int itemId);
  Future<void> deleteBookmark(int id);
  Future<List<Map<String, dynamic>>> getActivityLog();
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> logActivity(String eventType, Map<String, dynamic> payload);
}
