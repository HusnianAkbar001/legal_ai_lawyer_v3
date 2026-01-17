import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/lawyer_model.dart';
import '../../domain/repositories/directory_repository.dart';

part 'directory_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
DirectoryRepository directoryRepository(Ref ref) {
  return DirectoryRemoteDataSource(ref.watch(dioProvider));
}

class DirectoryRemoteDataSource implements DirectoryRepository {
  final Dio _dio;

  DirectoryRemoteDataSource(this._dio);

  @override
  Future<List<Lawyer>> getLawyers({int page = 1, int limit = 20, String? city, String? specialization}) async {
    final response = await _dio.get('/lawyers', queryParameters: {
      'page': page,
      'perPage': limit,
    });
    final items = response.data['items'] as List;
    return items.map((e) => Lawyer.fromApi(e)).toList();
  }
}
