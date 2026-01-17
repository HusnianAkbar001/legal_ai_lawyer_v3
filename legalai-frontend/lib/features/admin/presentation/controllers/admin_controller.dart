import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/admin_stats_model.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/datasources/admin_remote_data_source.dart';

part 'admin_controller.g.dart';

@riverpod
Future<RagMetrics> ragMetrics(Ref ref, {int days = 7}) {
  return ref.watch(adminRepositoryProvider).getRagMetrics(days: days);
}

@riverpod
Future<List<KnowledgeSource>> knowledgeSources(Ref ref) {
  return ref.watch(adminRepositoryProvider).getKnowledgeSources();
}

@riverpod
class AdminActions extends _$AdminActions {
  @override
  void build() {}

  Future<void> ingestUrl(String title, String url, String language) async {
    await ref.read(adminRepositoryProvider).ingestUrl(title, url, language);
    ref.invalidate(knowledgeSourcesProvider);
  }

  Future<void> deleteSource(int id) async {
    await ref.read(adminRepositoryProvider).deleteSource(id);
    ref.invalidate(knowledgeSourcesProvider);
  }

  Future<void> retrySource(int id) async {
    await ref.read(adminRepositoryProvider).retrySource(id);
    ref.invalidate(knowledgeSourcesProvider);
  }

  Future<void> uploadFile(PlatformFile file, String language) async {
    await ref.read(adminRepositoryProvider).uploadKnowledge(file, language);
    ref.invalidate(knowledgeSourcesProvider);
  }
}
