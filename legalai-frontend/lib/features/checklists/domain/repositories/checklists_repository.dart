import '../models/checklist_models.dart';

abstract class ChecklistsRepository {
  Future<List<ChecklistCategory>> getCategories();
  Future<List<ChecklistItem>> getItems(int categoryId);
  Future<void> createCategory({required String title, String? icon, int order = 0});
  Future<void> updateCategory(int id, {String? title, String? icon, int? order});
  Future<void> deleteCategory(int id);
  Future<void> createItem({required int categoryId, required String text, bool required = false, int order = 0});
  Future<void> updateItem(int id, {String? text, bool? required, int? order, int? categoryId});
  Future<void> deleteItem(int id);
}
