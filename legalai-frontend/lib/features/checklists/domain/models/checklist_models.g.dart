// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistCategory _$ChecklistCategoryFromJson(Map<String, dynamic> json) =>
    ChecklistCategory(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      icon: json['icon'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChecklistCategoryToJson(ChecklistCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'icon': instance.icon,
      'order': instance.order,
    };

ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    ChecklistItem(
      id: (json['id'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      text: json['text'] as String,
      required: json['required'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChecklistItemToJson(ChecklistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'text': instance.text,
      'required': instance.required,
      'order': instance.order,
    };
