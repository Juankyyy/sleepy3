import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';

void main() {
  group('SleepTrackingController', () {
    late DateTime now;
    late ProviderContainer container;
    late SleepTrackingController controller;

    setUp(() {
      now = DateTime(2026, 10, 20, 22, 30);
      container = ProviderContainer.test(
        overrides: [sleepClockProvider.overrideWithValue(() => now)],
      );
      controller = container.read(sleepTrackingControllerProvider.notifier);
    });

    test('starts awake with no previous session', () {
      final state = container.read(sleepTrackingControllerProvider);

      expect(state.isSleeping, isFalse);
      expect(state.openSession, isNull);
      expect(state.lastSession, isNull);
    });

    test('sleep opens a session at the current time', () {
      controller.sleep();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.openSession?.startedAt, now);
      expect(state.openSession?.isOpen, isTrue);
    });

    test('a second sleep tap does not overwrite the start time', () {
      controller.sleep();
      now = now.add(const Duration(minutes: 30));
      controller.sleep();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.openSession?.startedAt, DateTime(2026, 10, 20, 22, 30));
    });

    test('wake closes the session and records its duration', () {
      controller.sleep();
      now = now.add(const Duration(hours: 7, minutes: 45));
      controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.openSession, isNull);
      expect(
        state.lastSession?.duration,
        const Duration(hours: 7, minutes: 45),
      );
    });

    test('wake without an open session is a no-op', () {
      controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.lastSession, isNull);
    });

    test('clock skew never produces a negative duration', () {
      controller.sleep();
      now = now.subtract(const Duration(minutes: 5));
      controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.lastSession?.duration, Duration.zero);
    });
  });
}
