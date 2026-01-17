import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/session/session_invalidator.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  FutureOr<User?> build() async {
    ref.listen<int>(sessionInvalidationProvider, (prev, next) {
      if (prev != null && next != prev) {
        state = const AsyncValue.data(null);
        ref.read(appLoggerProvider).warn('auth.session.invalidated');
      }
    });
    return _checkUser();
  }

  Future<User?> _checkUser() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      return await repo.getCurrentUser();
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.session.check_failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.login.start');
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(email, password);
      final user = await repo.getCurrentUser();
      state = AsyncValue.data(user);
      ref.read(appLoggerProvider).info('auth.login.success', {
        'userId': user?.id,
      });
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.login.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> signup(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.signup.start');
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signup(data);
      final user = await repo.getCurrentUser();
      state = AsyncValue.data(user);
      ref.read(appLoggerProvider).info('auth.signup.success', {
        'userId': user?.id,
      });
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.signup.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.logout.start');
    try {
      await ref.read(authRepositoryProvider).logout();
      state = const AsyncValue.data(null);
      ref.read(appLoggerProvider).info('auth.logout.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.logout.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> forgotPassword(String email) async {
    ref.read(appLoggerProvider).info('auth.forgot_password.start');
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      ref.read(appLoggerProvider).info('auth.forgot_password.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.forgot_password.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    ref.read(appLoggerProvider).info('auth.reset_password.start');
    try {
      await ref.read(authRepositoryProvider).resetPassword(token, newPassword);
      ref.read(appLoggerProvider).info('auth.reset_password.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.reset_password.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    ref.read(appLoggerProvider).info('auth.change_password.start');
    try {
      await ref.read(authRepositoryProvider).changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );
      ref.read(appLoggerProvider).info('auth.change_password.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.change_password.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<bool> verifyEmail(String token) async {
    ref.read(appLoggerProvider).info('auth.verify_email.start');
    try {
      final ok = await ref.read(authRepositoryProvider).verifyEmail(token);
      ref.read(appLoggerProvider).info('auth.verify_email.success');
      return ok;
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.verify_email.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }
}
