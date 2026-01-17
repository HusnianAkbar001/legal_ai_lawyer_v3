import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(secureStorageProvider),
  );
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<User?> getCurrentUser() async {
    final token = await storage.read(key: AppConstants.authTokenKey);
    if (token == null) return null;
    try {
      return await remoteDataSource.getCurrentUser();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> login(String email, String password) async {
    final data = await remoteDataSource.login(email, password);
    await _saveTokens(data);
  }

  @override
  Future<void> signup(Map<String, dynamic> data) async {
    final response = await remoteDataSource.signup(data);
    await _saveTokens(response);
  }

  @override
  Future<void> logout() async {
    await storage.delete(key: AppConstants.authTokenKey);
    await storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    if (data['accessToken'] != null) {
      await storage.write(key: AppConstants.authTokenKey, value: data['accessToken']);
    }
    if (data['refreshToken'] != null) {
      await storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
    }
  }
  
  @override
  Future<void> forgotPassword(String email) async {
    await remoteDataSource.forgotPassword(email);
  }
  
  @override
  Future<void> refreshToken() async {
    final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) {
      throw Exception('No refresh token found');
    }
    final tokens = await remoteDataSource.refreshToken(refreshToken);
    await _saveTokens(tokens);
  }
  
  @override
  Future<void> resetPassword(String token, String newPassword) async {
    await remoteDataSource.resetPassword(token, newPassword);
  }
  
  @override
  Future<bool> verifyEmail(String token) async {
    return await remoteDataSource.verifyEmail(token);
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    final response = await remoteDataSource.changePassword(currentPassword, newPassword, confirmPassword);
    await _saveTokens(response);
  }
}
