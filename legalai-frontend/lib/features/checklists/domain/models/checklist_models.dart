import 'package:json_annotation/json_annotation.dart';

part 'checklist_models.g.dart';

@JsonSerializable()
class ChecklistCategory {
  final int id;
  final String title;
  final String? icon;
  final int order;

  ChecklistCategory({
    required this.id,
    required this.title,
    this.icon,
    this.order = 0,
  });

  factory ChecklistCategory.fromJson(Map<String, dynamic> json) => _$ChecklistCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ChecklistCategoryToJson(this);
}

@JsonSerializable()
class ChecklistItem {
  final int id;
  final int categoryId;
  final String text;
  final bool required;
  final int order;

  ChecklistItem({
    required this.id,
    required this.categoryId,
    required this.text,
    this.required = false,
    this.order = 0,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => _$ChecklistItemFromJson(json);
  Map<String, dynamic> toJson() => _$ChecklistItemToJson(this);
}
