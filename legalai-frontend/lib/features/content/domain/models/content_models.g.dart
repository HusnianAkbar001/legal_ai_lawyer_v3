// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegalRight _$LegalRightFromJson(Map<String, dynamic> json) => LegalRight(
  id: (json['id'] as num).toInt(),
  topic: json['topic'] as String,
  body: json['body'] as String,
  category: json['category'] as String,
  language: json['language'] as String,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$LegalRightToJson(LegalRight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topic': instance.topic,
      'body': instance.body,
      'category': instance.category,
      'language': instance.language,
      'tags': instance.tags,
    };

LegalTemplate _$LegalTemplateFromJson(Map<String, dynamic> json) =>
    LegalTemplate(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      language: json['language'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$LegalTemplateToJson(LegalTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'body': instance.body,
      'category': instance.category,
      'language': instance.language,
      'tags': instance.tags,
    };

LegalPathwayStep _$LegalPathwayStepFromJson(Map<String, dynamic> json) =>
    LegalPathwayStep(
      step: (json['step'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$LegalPathwayStepToJson(LegalPathwayStep instance) =>
    <String, dynamic>{
      'step': instance.step,
      'title': instance.title,
      'description': instance.description,
    };

LegalPathway _$LegalPathwayFromJson(Map<String, dynamic> json) => LegalPathway(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  summary: json['summary'] as String,
  steps: (json['steps'] as List<dynamic>)
      .map((e) => LegalPathwayStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  category: json['category'] as String,
  language: json['language'] as String,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$LegalPathwayToJson(LegalPathway instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'steps': instance.steps,
      'category': instance.category,
      'language': instance.language,
      'tags': instance.tags,
    };
