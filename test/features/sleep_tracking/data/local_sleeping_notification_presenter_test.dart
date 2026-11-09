import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/data/local_sleeping_notification_presenter.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleeping_notification_presenter.dart';

void main() {
  test('the sleep notification is an ongoing silent chronometer', () {
    final startedAt = DateTime(2026, 10, 20, 23, 15);

    final details = sleepingNotificationDetails(
      startedAt: startedAt,
      copy: const SleepingNotificationCopy(
        title: 'Sleeping',
        body: 'Goal 8h · until 07:15',
        channelName: 'Sleep status',
        channelDescription: 'A quiet timer while a sleep session is active.',
      ),
    );
    final android = details.android!;

    expect(android.channelId, 'sleep_status');
    expect(android.channelName, 'Sleep status');
    expect(
      android.channelDescription,
      'A quiet timer while a sleep session is active.',
    );
    expect(android.icon, 'ic_notification');
    expect(android.importance, Importance.low);
    expect(android.priority, Priority.low);
    expect(android.playSound, isFalse);
    expect(android.enableVibration, isFalse);
    expect(android.channelShowBadge, isFalse);
    expect(android.silent, isTrue);
    expect(android.ongoing, isTrue);
    expect(android.autoCancel, isFalse);
    expect(android.onlyAlertOnce, isTrue);
    expect(android.showWhen, isTrue);
    expect(android.when, startedAt.millisecondsSinceEpoch);
    expect(android.usesChronometer, isTrue);
    expect(android.category, AndroidNotificationCategory.stopwatch);
  });
}
