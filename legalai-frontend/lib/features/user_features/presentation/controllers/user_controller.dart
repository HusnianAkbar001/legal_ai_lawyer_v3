import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final userBookmarksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(userRepositoryProvider).getBookmarks();
});

final userActivityProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(userRepositoryProvider).getActivityLog();
});

class UserController extends Notifier<void> {
  @override
  void build() {
    return;
  }

  Future<void> uploadAvatar(PlatformFile file) async {
    await ref.read(userRepositoryProvider).uploadAvatar(file);
    ref.invalidate(authControllerProvider);
  }
}

final userControllerProvider = NotifierProvider.autoDispose<UserController, void>(() => UserController());
