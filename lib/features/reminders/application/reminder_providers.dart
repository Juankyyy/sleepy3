import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_sleep_reminder_scheduler.dart';
import '../domain/sleep_reminder.dart';
import '../domain/sleep_reminder_scheduler.dart';

/// Overridden in `main` with the value loaded before the first frame.
final initialSleepReminderProvider = Provider<SleepReminder>(
  (ref) => SleepReminder.defaults,
);

/// The platform scheduler used by [SleepReminderController].
///
/// Tests override it with a fake. The tap callback only asks the shell to
/// return to Home; the reminder itself never changes sleep data.
final sleepReminderSchedulerProvider = Provider<SleepReminderScheduler>((ref) {
  return LocalSleepReminderScheduler(
    onTap: () {
      ref.read(reminderHomeRequestProvider.notifier).requestHome();
    },
  );
});

/// Increments whenever the reminder notification is tapped.
///
/// `Sleepy3Shell` listens to it and selects Home, so the user lands on the
/// large Sleep action even when another tab was open.
final reminderHomeRequestProvider =
    NotifierProvider<ReminderHomeRequestController, int>(
      ReminderHomeRequestController.new,
    );

class ReminderHomeRequestController extends Notifier<int> {
  @override
  int build() => 0;

  void requestHome() => state++;
}
