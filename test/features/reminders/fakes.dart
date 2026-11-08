import 'package:sleepy3/features/reminders/domain/reminder_notification_copy.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder_scheduler.dart';

class ScheduledReminder {
  const ScheduledReminder({required this.reminder, required this.copy});

  final SleepReminder reminder;
  final ReminderNotificationCopy copy;
}

class FakeSleepReminderScheduler implements SleepReminderScheduler {
  FakeSleepReminderScheduler({
    this.permissionGranted = true,
    this.notificationsAreEnabled = true,
    this.throwOnSchedule = false,
    this.throwOnCancel = false,
  });

  bool permissionGranted;
  bool notificationsAreEnabled;
  bool throwOnSchedule;
  bool throwOnCancel;

  int permissionRequests = 0;
  int notificationsEnabledChecks = 0;
  int cancels = 0;
  int openSettingsCalls = 0;
  final scheduled = <ScheduledReminder>[];

  @override
  Future<bool> notificationsEnabled() async {
    notificationsEnabledChecks++;
    return notificationsAreEnabled;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required SleepReminder reminder,
    required ReminderNotificationCopy copy,
  }) async {
    if (throwOnSchedule) throw StateError('schedule failed');
    scheduled.add(ScheduledReminder(reminder: reminder, copy: copy));
  }

  @override
  Future<void> cancel() async {
    if (throwOnCancel) throw StateError('cancel failed');
    cancels++;
  }

  @override
  Future<void> openNotificationSettings() async {
    openSettingsCalls++;
  }
}
