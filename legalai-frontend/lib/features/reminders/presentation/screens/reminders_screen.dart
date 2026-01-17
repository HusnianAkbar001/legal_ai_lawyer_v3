import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/datasources/reminder_remote_data_source.dart';
import '../../domain/models/reminder_model.dart';
import '../../../../core/layout/app_responsive.dart';

String formatReminderDate(DateTime dateTime) {
  final d = dateTime;
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final h = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $h:$min';
}

final remindersProvider = FutureProvider.autoDispose<List<Reminder>>((ref) async {
  return ref.watch(reminderRepositoryProvider).getReminders();
});

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminders),
      ),
      body: remindersAsync.when(
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.noReminders))
            : ListView.separated(
                padding: AppResponsive.pagePadding(context),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                itemBuilder: (context, index) {
                  final reminder = items[index];
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: reminder.isCompleted,
                        onChanged: (val) async {
                          try {
                            await ref.read(reminderRepositoryProvider).updateReminder(
                                  reminder.id,
                                  isDone: val ?? false,
                                );
                            ref.invalidate(remindersProvider);
                          } catch (e) {
                            final err = ErrorMapper.from(e);
                            final message = err is AppException ? err.userMessage : err.toString();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                      ),
                      title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${reminder.description.isEmpty ? l10n.noNotes : reminder.description}\n${formatReminderDate(reminder.dateTime)}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderFormScreen(reminder: reminder),
                              ),
                            );
                            ref.invalidate(remindersProvider);
                          } else if (value == 'delete') {
                            await _deleteReminder(context, ref, reminder.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReminderFormScreen()),
          );
          ref.invalidate(remindersProvider);
        },
        label: Text(l10n.newReminder),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteReminder(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(reminderRepositoryProvider).deleteReminder(id);
      ref.invalidate(remindersProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class ReminderFormScreen extends ConsumerStatefulWidget {
  final Reminder? reminder;
  const ReminderFormScreen({super.key, this.reminder});

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _titleController.text = reminder.title;
      _notesController.text = reminder.description;
      _scheduledAt = reminder.dateTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleDateTime)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.reminder == null) {
        await ref.read(reminderRepositoryProvider).createReminder(
              _titleController.text.trim(),
              _notesController.text.trim(),
              _scheduledAt!,
              timezone: DateTime.now().timeZoneName,
            );
      } else {
        await ref.read(reminderRepositoryProvider).updateReminder(
              widget.reminder!.id,
              title: _titleController.text.trim(),
              notes: _notesController.text.trim(),
              scheduledAt: _scheduledAt,
              timezone: DateTime.now().timeZoneName,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.reminder == null ? l10n.newReminder : l10n.editReminder)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppResponsive.pagePadding(context),
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: l10n.title),
                      validator: (value) => value == null || value.trim().isEmpty ? l10n.titleRequired : null,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(labelText: l10n.notes),
                      maxLines: 3,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _scheduledAt == null ? l10n.noDateSelected : formatReminderDate(_scheduledAt!),
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDateTime,
                          child: Text(l10n.pickDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppResponsive.spacing(context, 20)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.reminder == null ? l10n.create : l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
