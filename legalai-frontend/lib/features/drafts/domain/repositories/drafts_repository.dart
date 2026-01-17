import '../models/draft_model.dart';
import '../../../../features/auth/domain/models/user_model.dart';

abstract class DraftsRepository {
  Future<Draft> generateDraft(int templateId, Map<String, dynamic> answers, User userSnapshot);
  Future<List<Draft>> getDrafts();
  Future<Draft> getDraft(int id);
  Future<String> exportDraftTxt(int id);
  Future<List<int>> exportDraftPdf(int id);
  Future<List<int>> exportDraftDocx(int id);
  Future<void> deleteDraft(int id);
}
