// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Draft _$DraftFromJson(Map<String, dynamic> json) => Draft(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  contentText: json['contentText'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  answers: json['answers'] as Map<String, dynamic>?,
  userSnapshot: json['userSnapshot'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$DraftToJson(Draft instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'contentText': instance.contentText,
  'createdAt': instance.createdAt.toIso8601String(),
  'answers': instance.answers,
  'userSnapshot': instance.userSnapshot,
};
