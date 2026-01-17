import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/draft_model.dart';
import '../../domain/repositories/drafts_repository.dart';
import '../../../../features/auth/domain/models/user_model.dart';

part 'drafts_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
DraftsRepository draftsRepository(Ref ref) {
  return DraftsRemoteDataSource(ref.watch(dioProvider));
}

class DraftsRemoteDataSource implements DraftsRepository {
  final Dio _dio;

  DraftsRemoteDataSource(this._dio);

  @override
  Future<Draft> generateDraft(int templateId, Map<String, dynamic> answers, User userSnapshot) async {
    final response = await _dio.post('/drafts/generate', data: {
      'templateId': templateId,
      'answers': answers,
      'userSnapshot': userSnapshot.toJson(),
    });
    return Draft.fromJson(response.data);
  }

  @override
  Future<List<Draft>> getDrafts() async {
    final response = await _dio.get('/drafts');
    return (response.data as List).map((e) => Draft.fromJson(e)).toList();
  }

  @override
  Future<Draft> getDraft(int id) async {
    final response = await _dio.get('/drafts/$id');
    return Draft.fromJson(response.data);
  }

  @override
  Future<String> exportDraftTxt(int id) async {
      final response = await _dio.get('/drafts/$id/export', queryParameters: {'format': 'txt'});
      return response.data['text'];
  }

  @override
  Future<List<int>> exportDraftPdf(int id) async {
    final response = await _dio.get(
      '/drafts/$id/export',
      queryParameters: {'format': 'pdf'},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }

  @override
  Future<List<int>> exportDraftDocx(int id) async {
    final response = await _dio.get(
      '/drafts/$id/export',
      queryParameters: {'format': 'docx'},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }

  @override
  Future<void> deleteDraft(int id) async {
    await _dio.delete('/drafts/$id');
  }
}
