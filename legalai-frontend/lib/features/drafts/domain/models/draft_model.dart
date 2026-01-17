import 'package:json_annotation/json_annotation.dart';

part 'draft_model.g.dart';

@JsonSerializable()
class Draft {
  final int id;
  final String title;
  final String? contentText;
  final DateTime createdAt;
  final Map<String, dynamic>? answers;
  final Map<String, dynamic>? userSnapshot;

  Draft({
    required this.id,
    required this.title,
    this.contentText,
    required this.createdAt,
    this.answers,
    this.userSnapshot,
  });

  factory Draft.fromJson(Map<String, dynamic> json) => _$DraftFromJson(json);
  Map<String, dynamic> toJson() => _$DraftToJson(this);
}
