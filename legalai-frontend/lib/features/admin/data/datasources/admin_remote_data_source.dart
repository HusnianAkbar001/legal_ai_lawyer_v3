import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/multipart_file.dart';
import 'package:legalai_frontend/features/directory/domain/models/lawyer_model.dart';
import '../../domain/models/admin_stats_model.dart';
import '../../domain/repositories/admin_repository.dart';

part 'admin_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) {
  return AdminRemoteDataSource(ref.watch(dioProvider));
}

class AdminRemoteDataSource implements AdminRepository {
  final Dio _dio;

  AdminRemoteDataSource(this._dio);

  @override
  Future<List<Map<String, dynamic>>> getUsers({int page = 1, int? perPage}) async {
    final response = await _dio.get('/admin/users', queryParameters: _pageQuery(page, perPage));
    return (response.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<int> getUsersTotal() async {
    final response = await _dio.get('/admin/users', queryParameters: _pageQuery(1, 1));
    return _extractTotal(response);
  }

  @override
  Future<void> createUser(Map<String, dynamic> data) async {
    await _dio.post('/admin/users', data: data);
  }

  @override
  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    await _dio.put('/admin/users/$id', data: data);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _dio.delete('/admin/users/$id');
  }

  @override
  Future<List<Lawyer>> getLawyers({int page = 1, int? perPage}) async {
    final response = await _dio.get('/admin/lawyers', queryParameters: _pageQuery(page, perPage));
    return (response.data['items'] as List).map((e) => Lawyer.fromApi(e)).toList();
  }

  @override
  Future<int> getLawyersTotal() async {
    final response = await _dio.get('/admin/lawyers', queryParameters: _pageQuery(1, 1));
    return _extractTotal(response);
  }

  @override
  Future<void> createLawyer(Map<String, dynamic> data, PlatformFile imageFile) async {
    final formData = FormData.fromMap(data);
    formData.files.add(MapEntry('file', await multipartFileFromPlatformFile(imageFile)));
    await _dio.post('/admin/lawyers', data: formData);
  }

  @override
  Future<void> updateLawyer(int id, Map<String, dynamic> data, PlatformFile? imageFile) async {
    if (imageFile != null) {
      final formData = FormData.fromMap(data);
      formData.files.add(MapEntry('file', await multipartFileFromPlatformFile(imageFile)));
      await _dio.put('/admin/lawyers/$id', data: formData);
    } else {
      await _dio.put('/admin/lawyers/$id', data: data);
    }
  }

  @override
  Future<void> deactivateLawyer(int id) async {
    await _dio.delete('/admin/lawyers/$id');
  }

  @override
  Future<List<String>> getLawyerCategories() async {
    final response = await _dio.get('/admin/lawyers/categories');
    return List<String>.from(response.data['items']);
  }

  @override
  Future<Lawyer> getLawyer(int id) async {
    final response = await _dio.get('/admin/lawyers/$id');
    return Lawyer.fromApi(response.data);
  }

  @override
  Future<RagMetrics> getRagMetrics({int days = 7}) async {
    final response = await _dio.get('/admin/rag/metrics/summary', queryParameters: {'days': days});
    return RagMetrics.fromApi(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getRagQueries({int page = 1, int days = 7, int? perPage}) async {
    final query = <String, dynamic>{'page': page, 'days': days, if (perPage != null) 'perPage': perPage};
    final response = await _dio.get('/admin/rag/metrics/queries', queryParameters: query);
    return (response.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>> getRagQueryDetail(int id) async {
    final response = await _dio.get('/admin/rag/metrics/queries/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<List<KnowledgeSource>> getKnowledgeSources() async {
    final response = await _dio.get('/admin/knowledge/sources');
    return (response.data as List).map((e) => KnowledgeSource.fromApi(e)).toList();
  }

  @override
  Future<void> uploadKnowledge(PlatformFile file, String language) async {
    final formData = FormData.fromMap({
      'language': language,
      'file': await multipartFileFromPlatformFile(file),
    });
    await _dio.post('/admin/knowledge/upload', data: formData);
  }

  @override
  Future<void> ingestUrl(String title, String url, String language) async {
    await _dio.post('/admin/knowledge/url', data: {'title': title, 'url': url, 'language': language});
  }

  @override
  Future<void> retrySource(int id) async {
    await _dio.post('/admin/knowledge/sources/$id/retry');
  }

  @override
  Future<void> deleteSource(int id) async {
    await _dio.delete('/admin/knowledge/sources/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> getContactMessages({int page = 1, int? perPage}) async {
    final response = await _dio.get('/admin/contact-messages', queryParameters: _pageQuery(page, perPage));
    return (response.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>> getContactMessage(int id) async {
    final response = await _dio.get('/admin/contact-messages/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> getFeedback({int page = 1, int? perPage}) async {
    final response = await _dio.get('/admin/feedback', queryParameters: _pageQuery(page, perPage));
    return (response.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>> getFeedbackDetail(int id) async {
    final response = await _dio.get('/admin/feedback/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }
}

Map<String, dynamic> _pageQuery(int page, int? perPage) {
  return {
    'page': page,
    if (perPage != null) 'perPage': perPage,
  };
}

int _extractTotal(Response response) {
  final data = response.data;
  if (data is Map<String, dynamic>) {
    final meta = data['meta'];
    if (meta is Map<String, dynamic>) {
      final total = meta['total'];
      if (total is num) {
        return total.toInt();
      }
    }
  }
  throw FormatException('Invalid pagination payload');
}
