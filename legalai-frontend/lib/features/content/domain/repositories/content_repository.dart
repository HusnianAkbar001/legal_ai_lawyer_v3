import '../models/content_models.dart';

abstract class ContentRepository {
  Future<List<LegalRight>> getRights({String? category, String language = 'en'});
  Future<LegalRight> getRight(int id);
  
  Future<List<LegalTemplate>> getTemplates({String? category, String language = 'en'});
  Future<LegalTemplate> getTemplate(int id);
  
  Future<List<LegalPathway>> getPathways({String? category, String language = 'en'});
  Future<LegalPathway> getPathway(int id);
}
