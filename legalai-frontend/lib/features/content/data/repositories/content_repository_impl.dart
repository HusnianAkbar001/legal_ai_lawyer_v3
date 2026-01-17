import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/content_models.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_remote_data_source.dart';
import '../../../../core/content/content_cache.dart';

part 'content_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ContentRepository contentRepository(Ref ref) {
  return ContentRepositoryImpl(ref.watch(contentRemoteDataSourceProvider));
}

class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource remoteDataSource;

  ContentRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LegalRight>> getRights({String? category, String language = 'en'}) {
    return _getRightsCached(category: category, language: language);
  }

  @override
  Future<LegalRight> getRight(int id) {
    return remoteDataSource.getRight(id);
  }

  @override
  Future<List<LegalTemplate>> getTemplates({String? category, String language = 'en'}) {
    return _getTemplatesCached(category: category, language: language);
  }

  @override
  Future<LegalTemplate> getTemplate(int id) {
    return remoteDataSource.getTemplate(id);
  }

  @override
  Future<List<LegalPathway>> getPathways({String? category, String language = 'en'}) {
    return remoteDataSource.getPathways(category: category, language: language);
  }

  @override
  Future<LegalPathway> getPathway(int id) {
    return remoteDataSource.getPathway(id);
  }

  Future<List<LegalRight>> _getRightsCached({String? category, required String language}) async {
    final cached = await ContentCache.getRights();
    if (cached != null) {
      final rights = cached
          .map((e) => LegalRight.fromApi(Map<String, dynamic>.from(e as Map)))
          .where((item) => item.language == language)
          .where((item) => category == null || item.category == category)
          .toList();
      if (rights.isNotEmpty) {
        return rights;
      }
    }
    return remoteDataSource.getRights(category: category, language: language);
  }

  Future<List<LegalTemplate>> _getTemplatesCached({String? category, required String language}) async {
    final cached = await ContentCache.getTemplates();
    if (cached != null) {
      final templates = cached
          .map((e) => LegalTemplate.fromApi(Map<String, dynamic>.from(e as Map)))
          .where((item) => item.language == language)
          .where((item) => category == null || item.category == category)
          .toList();
      if (templates.isNotEmpty) {
        return templates;
      }
    }
    return remoteDataSource.getTemplates(category: category, language: language);
  }
}
