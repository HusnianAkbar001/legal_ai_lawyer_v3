import 'package:json_annotation/json_annotation.dart';

part 'reminder_model.g.dart';

@JsonSerializable()
class Reminder {
  final int id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isCompleted = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderToJson(this);

  factory Reminder.fromApi(Map<String, dynamic> json) {
    final scheduledAt = json['scheduledAt'] as String?;
    return Reminder(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      description: (json['notes'] as String?) ?? '',
      dateTime: scheduledAt == null ? DateTime.now() : DateTime.parse(scheduledAt),
      isCompleted: (json['isDone'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'title': title,
      'notes': description,
      'scheduledAt': dateTime.toIso8601String(),
      'isDone': isCompleted,
    };
  }
}
