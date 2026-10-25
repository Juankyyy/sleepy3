import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

import '../fakes.dart';

void main() {
  group('SleepTrackingController', () {
    late DateTime now;
    late ProviderContainer container;
    late SleepTrackingController controller;
    late FakeSleepSessionStore store;

    setUp(() {
      now = DateTime(2026, 10, 20, 22, 30);
      store = FakeSleepSessionStore();
      container = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
        ],
      );
      controller = container.read(sleepTrackingControllerProvider.notifier);
    });

    test('starts awake with no previous session', () {
      final state = container.read(sleepTrackingControllerProvider);

      expect(state.isSleeping, isFalse);
      expect(state.openSession, isNull);
      expect(state.lastSession, isNull);
      expect(state.closedSessions, isEmpty);
    });

    test('sleep opens a session and persists it', () async {
      await controller.sleep();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.openSession?.startedAt, now);
      expect(state.openSession?.isOpen, isTrue);
      expect(store.starts.single.startedAt, now);
    });

    test('a second sleep tap does not overwrite the start time', () async {
      await controller.sleep();
      now = now.add(const Duration(minutes: 30));
      await controller.sleep();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.openSession?.startedAt, DateTime(2026, 10, 20, 22, 30));
      expect(store.starts, hasLength(1));
    });

    test(
      'wake closes the session, records its duration and persists',
      () async {
        await controller.sleep();
        now = now.add(const Duration(hours: 7, minutes: 45));
        await controller.wake();

        final state = container.read(sleepTrackingControllerProvider);
        expect(state.isSleeping, isFalse);
        expect(state.openSession, isNull);
        expect(
          state.lastSession?.duration,
          const Duration(hours: 7, minutes: 45),
        );
        expect(store.finishes.single, now);
        expect(state.closedSessions, hasLength(1));
        expect(
          state.closedSessions.single.duration,
          state.lastSession?.duration,
        );
      },
    );

    test('wake without an open session is a no-op', () async {
      await controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.lastSession, isNull);
      expect(store.finishes, isEmpty);
    });

    test('clock skew never produces a negative duration', () async {
      await controller.sleep();
      final startedAt = now;
      now = now.subtract(const Duration(minutes: 5));
      await controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.lastSession?.duration, Duration.zero);
      expect(store.finishes.single, startedAt);
    });

    test('a wake tap right after sleep waits for the start write', () async {
      final sleeping = controller.sleep();
      final waking = controller.wake();
      await Future.wait([sleeping, waking]);

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(store.starts, hasLength(1));
      expect(store.finishes, hasLength(1));
      expect(state.lastSession, isNotNull);
    });

    test('restores an open session from the startup snapshot', () {
      final startedAt = DateTime(2026, 10, 20, 23, 10);
      final restored = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepSnapshotProvider.overrideWithValue(
            SleepSnapshot(openSession: SleepSession(startedAt: startedAt)),
          ),
        ],
      );

      final state = restored.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.openSession?.startedAt, startedAt);
      expect(state.lastSession, isNull);
    });

    test('restores the last finished session from the startup snapshot', () {
      final session = SleepSession(
        startedAt: DateTime(2026, 10, 19, 23),
        endedAt: DateTime(2026, 10, 20, 7),
      );
      final restored = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepSnapshotProvider.overrideWithValue(
            SleepSnapshot(closedSessions: [session]),
          ),
        ],
      );

      final state = restored.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.lastSession?.duration, const Duration(hours: 8));
    });

    test('restores closed sessions and keeps them across Sleep', () async {
      final recent = SleepSession(
        startedAt: DateTime(2026, 10, 19, 23),
        endedAt: DateTime(2026, 10, 20, 7),
      );
      final restored = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepSnapshotProvider.overrideWithValue(
            SleepSnapshot(closedSessions: [recent]),
          ),
        ],
      );

      expect(restored.read(sleepTrackingControllerProvider).closedSessions, [
        recent,
      ]);

      await restored.read(sleepTrackingControllerProvider.notifier).sleep();

      final state = restored.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.closedSessions, [recent]);
    });
  });
}
