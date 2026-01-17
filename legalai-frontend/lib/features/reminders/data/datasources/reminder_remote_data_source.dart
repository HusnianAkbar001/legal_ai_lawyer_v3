import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/reminder_model.dart';
import '../../domain/repositories/reminder_repository.dart';

part 'reminder_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
ReminderRepository reminderRepository(Ref ref) {
  return ReminderRemoteDataSource(ref.watch(dioProvider));
}

class ReminderRemoteDataSource implements ReminderRepository {
  final Dio _dio;

  ReminderRemoteDataSource(this._dio);

  @override
  Future<List<Reminder>> getReminders() async {
    final response = await _dio.get('/reminders');
    return (response.data as List).map((e) => Reminder.fromApi(e)).toList();
  }

  @override
  Future<void> createReminder(String title, String notes, DateTime scheduledAt, {String? timezone}) async {
    await _dio.post('/reminders', data: {
      'title': title,
      'notes': notes,
      'scheduledAt': scheduledAt.toIso8601String(),
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
    });
  }

  @override
  Future<void> updateReminder(int id, {String? title, String? notes, DateTime? scheduledAt, String? timezone, bool? isDone}) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (notes != null) data['notes'] = notes;
    if (scheduledAt != null) data['scheduledAt'] = scheduledAt.toIso8601String();
    if (timezone != null) data['timezone'] = timezone;
    if (isDone != null) data['isDone'] = isDone;
    await _dio.put('/reminders/$id', data: data);
  }

  @override
  Future<void> deleteReminder(int id) async {
    await _dio.delete('/reminders/$id');
  }

  @override
  Future<void> registerDeviceToken(String platform, String token) async {
    await _dio.post('/reminders/register-device-token', data: {
      'platform': platform,
      'token': token,
    });
  }
}
