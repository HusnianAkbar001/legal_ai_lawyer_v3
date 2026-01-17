import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/multipart_file.dart';
import '../../domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRemoteDataSource(ref.watch(dioProvider));
});

class UserRemoteDataSource implements UserRepository {
  final Dio _dio;
  UserRemoteDataSource(this._dio);

  @override
  Future<String> uploadAvatar(PlatformFile file) async {
    final multipart = await multipartFileFromPlatformFile(file);
    final formData = FormData.fromMap({'file': multipart});
    final response = await _dio.post('/users/me/avatar', data: formData);
    return response.data['avatarPath'];
  }

  @override
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final response = await _dio.get('/users/me/bookmarks');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> addBookmark(String itemType, int itemId) async {
    await _dio.post('/users/me/bookmarks', data: {'itemType': itemType, 'itemId': itemId});
  }

  @override
  Future<void> deleteBookmark(int id) async {
    await _dio.delete('/users/me/bookmarks/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> getActivityLog() async {
    final response = await _dio.get('/users/me/activity');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put('/users/me', data: data);
  }

  @override
  Future<void> logActivity(String eventType, Map<String, dynamic> payload) async {
    await _dio.post('/users/me/activity', data: {
      'eventType': eventType,
      'payload': payload,
    });
  }
}
