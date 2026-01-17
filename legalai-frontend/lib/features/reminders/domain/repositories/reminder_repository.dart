import '../models/reminder_model.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
  Future<void> createReminder(String title, String notes, DateTime scheduledAt, {String? timezone});
  Future<void> updateReminder(int id, {String? title, String? notes, DateTime? scheduledAt, String? timezone, bool? isDone});
  Future<void> deleteReminder(int id);
  Future<void> registerDeviceToken(String platform, String token);
}
