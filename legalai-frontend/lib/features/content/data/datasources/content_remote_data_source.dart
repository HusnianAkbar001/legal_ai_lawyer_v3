import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/content_models.dart';

part 'content_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
ContentRemoteDataSource contentRemoteDataSource(Ref ref) {
  return ContentRemoteDataSource(ref.watch(dioProvider));
}

class ContentRemoteDataSource {
  final Dio _dio;

  ContentRemoteDataSource(this._dio);

  Future<List<LegalRight>> getRights({String? category, String language = 'en'}) async {
    final response = await _dio.get('/rights', queryParameters: {
      if (category != null) 'category': category,
      'language': language,
    });
    return (response.data['data'] as List).map((e) => LegalRight.fromApi(e)).toList();
  }

  Future<LegalRight> getRight(int id) async {
    final response = await _dio.get('/rights/$id');
    return LegalRight.fromApi(response.data['data']);
  }

  Future<List<LegalTemplate>> getTemplates({String? category, String language = 'en'}) async {
     final response = await _dio.get('/templates', queryParameters: {
      if (category != null) 'category': category,
      'language': language,
    });
    return (response.data['data'] as List).map((e) => LegalTemplate.fromApi(e)).toList();
  }

  Future<LegalTemplate> getTemplate(int id) async {
    final response = await _dio.get('/templates/$id');
    return LegalTemplate.fromApi(response.data['data']);
  }

  Future<List<LegalPathway>> getPathways({String? category, String language = 'en'}) async {
    final response = await _dio.get('/pathways', queryParameters: {
      if (category != null) 'category': category,
      'language': language,
    });
    return (response.data['data'] as List).map((e) => LegalPathway.fromApi(e)).toList();
  }

  Future<LegalPathway> getPathway(int id) async {
     final response = await _dio.get('/pathways/$id');
    return LegalPathway.fromApi(response.data['data']);
  }

  Future<void> createRight(Map<String, dynamic> data) async {
    await _dio.post('/rights', data: data);
  }

  Future<void> updateRight(int id, Map<String, dynamic> data) async {
    await _dio.put('/rights/$id', data: data);
  }

  Future<void> deleteRight(int id) async {
    await _dio.delete('/rights/$id');
  }

  Future<void> createTemplate(Map<String, dynamic> data) async {
    await _dio.post('/templates', data: data);
  }

  Future<void> updateTemplate(int id, Map<String, dynamic> data) async {
    await _dio.put('/templates/$id', data: data);
  }

  Future<void> deleteTemplate(int id) async {
    await _dio.delete('/templates/$id');
  }

  Future<void> createPathway(Map<String, dynamic> data) async {
    await _dio.post('/pathways', data: data);
  }

  Future<void> updatePathway(int id, Map<String, dynamic> data) async {
    await _dio.put('/pathways/$id', data: data);
  }

  Future<void> deletePathway(int id) async {
    await _dio.delete('/pathways/$id');
  }
}
