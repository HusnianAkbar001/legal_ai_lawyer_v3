import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<void> login(String email, String password);
  Future<void> signup(Map<String, dynamic> data);
  Future<void> logout();
  Future<void> refreshToken();
  Future<bool> verifyEmail(String token);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);
}
