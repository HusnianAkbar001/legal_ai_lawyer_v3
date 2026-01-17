import 'package:json_annotation/json_annotation.dart';

part 'content_models.g.dart';

@JsonSerializable()
class LegalRight {
  final int id;
  final String topic;
  final String body;
  final String category;
  final String language;
  final List<String>? tags;

  LegalRight({
    required this.id,
    required this.topic,
    required this.body,
    required this.category,
    required this.language,
    this.tags,
  });

  factory LegalRight.fromJson(Map<String, dynamic> json) => _$LegalRightFromJson(json);
  Map<String, dynamic> toJson() => _$LegalRightToJson(this);

  factory LegalRight.fromApi(Map<String, dynamic> json) {
    return LegalRight(
      id: json['id'] as int,
      topic: (json['topic'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'en',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

@JsonSerializable()
class LegalTemplate {
  final int id;
  final String title;
  final String description;
  final String body;
  final String category;
  final String language;
  final List<String>? tags;

  LegalTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.body,
    required this.category,
    required this.language,
    this.tags,
  });

  factory LegalTemplate.fromJson(Map<String, dynamic> json) => _$LegalTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$LegalTemplateToJson(this);

  factory LegalTemplate.fromApi(Map<String, dynamic> json) {
    return LegalTemplate(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'en',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

@JsonSerializable()
class LegalPathwayStep {
  final int step;
  final String title;
  final String description;

  LegalPathwayStep({required this.step, required this.title, required this.description});

  factory LegalPathwayStep.fromJson(Map<String, dynamic> json) => _$LegalPathwayStepFromJson(json);
  Map<String, dynamic> toJson() => _$LegalPathwayStepToJson(this);
}

@JsonSerializable()
class LegalPathway {
  final int id;
  final String title;
  final String summary;
  final List<LegalPathwayStep> steps;
  final String category;
  final String language;
  final List<String>? tags;

  LegalPathway({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
    required this.category,
    required this.language,
    this.tags,
  });

  factory LegalPathway.fromJson(Map<String, dynamic> json) => _$LegalPathwayFromJson(json);
  Map<String, dynamic> toJson() => _$LegalPathwayToJson(this);

  factory LegalPathway.fromApi(Map<String, dynamic> json) {
    final steps = (json['steps'] as List? ?? [])
        .map((e) => LegalPathwayStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return LegalPathway(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      steps: steps,
      category: (json['category'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'en',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
