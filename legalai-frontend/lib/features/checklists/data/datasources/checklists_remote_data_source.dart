import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/checklist_models.dart';
import '../../domain/repositories/checklists_repository.dart';

part 'checklists_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
ChecklistsRepository checklistsRepository(Ref ref) {
  return ChecklistsRemoteDataSource(ref.watch(dioProvider));
}

class ChecklistsRemoteDataSource implements ChecklistsRepository {
  final Dio _dio;

  ChecklistsRemoteDataSource(this._dio);

  @override
  Future<List<ChecklistCategory>> getCategories() async {
    final response = await _dio.get('/checklists/categories');
    return (response.data as List).map((e) => ChecklistCategory.fromJson(e)).toList();
  }

  @override
  Future<List<ChecklistItem>> getItems(int categoryId) async {
    final response = await _dio.get('/checklists/items', queryParameters: {'categoryId': categoryId});
    return (response.data as List).map((e) => ChecklistItem.fromJson(e)).toList();
  }

  @override
  Future<void> createCategory({required String title, String? icon, int order = 0}) async {
    await _dio.post('/checklists/categories', data: {
      'title': title,
      if (icon != null) 'icon': icon,
      'order': order,
    });
  }

  @override
  Future<void> updateCategory(int id, {String? title, String? icon, int? order}) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (icon != null) data['icon'] = icon;
    if (order != null) data['order'] = order;
    await _dio.put('/checklists/categories/$id', data: data);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _dio.delete('/checklists/categories/$id');
  }

  @override
  Future<void> createItem({required int categoryId, required String text, bool required = false, int order = 0}) async {
    await _dio.post('/checklists/items', data: {
      'categoryId': categoryId,
      'text': text,
      'required': required,
      'order': order,
    });
  }

  @override
  Future<void> updateItem(int id, {String? text, bool? required, int? order, int? categoryId}) async {
    final data = <String, dynamic>{};
    if (text != null) data['text'] = text;
    if (required != null) data['required'] = required;
    if (order != null) data['order'] = order;
    if (categoryId != null) data['categoryId'] = categoryId;
    await _dio.put('/checklists/items/$id', data: data);
  }

  @override
  Future<void> deleteItem(int id) async {
    await _dio.delete('/checklists/items/$id');
  }
}
