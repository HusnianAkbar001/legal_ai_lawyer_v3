import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/repositories/support_repository.dart';

part 'support_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
SupportRepository supportRepository(Ref ref) {
  return SupportRemoteDataSource(ref.watch(dioProvider));
}

class SupportRemoteDataSource implements SupportRepository {
  final Dio _dio;

  SupportRemoteDataSource(this._dio);

  @override
  Future<void> submitContact(String fullName, String email, String phone, String subject, String description) async {
    await _dio.post('/support/contact', data: {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'subject': subject,
      'description': description,
    });
  }

  @override
  Future<void> submitFeedback(int rating, String comment) async {
    await _dio.post('/support/feedback', data: {
      'rating': rating,
      'comment': comment,
    });
  }
}
