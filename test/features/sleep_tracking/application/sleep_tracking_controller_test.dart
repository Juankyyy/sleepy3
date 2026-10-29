import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

import '../../health/fakes.dart';
import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  group('SleepTrackingController', () {
    late DateTime now;
    late FakeSleepSessionStore store;
    late FakeHealthConnectGateway gateway;
    late FakeSettingsStore settingsStore;
    late ProviderContainer container;
    late SleepTrackingController controller;

    SleepSession closed(DateTime start, DateTime end) =>
        SleepSession(startedAt: start, endedAt: end);

    void create({
      SleepSnapshot storeSnapshot = SleepSnapshot.empty,
      SleepSnapshot initial = SleepSnapshot.empty,
      SleepDataSource source = SleepDataSource.local,
      FakeHealthConnectGateway? healthGateway,
    }) {
      now = DateTime(2026, 10, 20, 22, 30);
      store = FakeSleepSessionStore(snapshot: storeSnapshot);
      gateway = healthGateway ?? FakeHealthConnectGateway();
      settingsStore = FakeSettingsStore(sleepDataSource: source);
      container = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepSnapshotProvider.overrideWithValue(initial),
          initialSleepDataSourceProvider.overrideWithValue(source),
          healthConnectGatewayProvider.overrideWithValue(gateway),
          settingsStoreProvider.overrideWithValue(settingsStore),
        ],
      );
      controller = container.read(sleepTrackingControllerProvider.notifier);
    }

    test('starts awake with no previous session', () async {
      create();
      await controller.historyLoad;

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.openSession, isNull);
      expect(state.lastSession, isNull);
      expect(state.closedSessions, isEmpty);
      expect(state.historyStatus, SleepHistoryStatus.ready);
    });

    test('loads local history from the store and marks it ready', () async {
      final session = closed(
        DateTime(2026, 10, 19, 23),
        DateTime(2026, 10, 20, 7),
      );
      create(storeSnapshot: SleepSnapshot(closedSessions: [session]));

      expect(
        container.read(sleepTrackingControllerProvider).historyStatus,
        SleepHistoryStatus.initial,
      );

      await controller.historyLoad;

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.historyStatus, SleepHistoryStatus.ready);
      expect(state.closedSessions, [session]);
      expect(store.closedLoads, 1);
    });

    test('stays loading while the source is being read', () async {
      now = DateTime(2026, 10, 20, 22, 30);
      store = FakeSleepSessionStore();
      store.closedLoadGate = Completer<void>();
      settingsStore = FakeSettingsStore();
      gateway = FakeHealthConnectGateway();
      container = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepDataSourceProvider.overrideWithValue(
            SleepDataSource.local,
          ),
          healthConnectGatewayProvider.overrideWithValue(gateway),
          settingsStoreProvider.overrideWithValue(settingsStore),
        ],
      );
      controller = container.read(sleepTrackingControllerProvider.notifier);

      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(sleepTrackingControllerProvider).historyStatus,
        SleepHistoryStatus.loading,
      );

      store.closedLoadGate!.complete();
      await controller.historyLoad;
      expect(
        container.read(sleepTrackingControllerProvider).historyStatus,
        SleepHistoryStatus.ready,
      );
    });

    test('reports an error and recovers on retry', () async {
      now = DateTime(2026, 10, 20, 22, 30);
      store = FakeSleepSessionStore()..closedLoadError = StateError('nope');
      settingsStore = FakeSettingsStore();
      container = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepDataSourceProvider.overrideWithValue(
            SleepDataSource.local,
          ),
          healthConnectGatewayProvider.overrideWithValue(
            FakeHealthConnectGateway(),
          ),
          settingsStoreProvider.overrideWithValue(settingsStore),
        ],
      );
      controller = container.read(sleepTrackingControllerProvider.notifier);

      await controller.historyLoad;
      var state = container.read(sleepTrackingControllerProvider);
      expect(state.historyStatus, SleepHistoryStatus.error);
      expect(state.historyError, isA<StateError>());
      expect(state.closedSessions, isEmpty);

      store.closedLoadError = null;
      store.snapshot = SleepSnapshot(
        closedSessions: [
          closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 7)),
        ],
      );
      await controller.reloadHistory();

      state = container.read(sleepTrackingControllerProvider);
      expect(state.historyStatus, SleepHistoryStatus.ready);
      expect(state.historyError, isNull);
      expect(state.closedSessions, hasLength(1));
    });

    test('sleep opens a session and persists it', () async {
      create();
      await controller.historyLoad;
      await controller.sleep();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.openSession?.startedAt, now);
      expect(state.openSession?.isOpen, isTrue);
      expect(store.starts.single.startedAt, now);
    });

    test('a second sleep tap does not overwrite the start time', () async {
      create();
      await controller.historyLoad;
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
        create();
        await controller.historyLoad;
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
      create();
      await controller.historyLoad;
      await controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.lastSession, isNull);
      expect(store.finishes, isEmpty);
    });

    test('clock skew never produces a negative duration', () async {
      create();
      await controller.historyLoad;
      await controller.sleep();
      final startedAt = now;
      now = now.subtract(const Duration(minutes: 5));
      await controller.wake();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.lastSession?.duration, Duration.zero);
      expect(store.finishes.single, startedAt);
    });

    test('a wake tap right after sleep waits for the start write', () async {
      create();
      await controller.historyLoad;
      final sleeping = controller.sleep();
      final waking = controller.wake();
      await Future.wait([sleeping, waking]);

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(store.starts, hasLength(1));
      expect(store.finishes, hasLength(1));
      expect(state.lastSession, isNotNull);
    });

    test('restores an open session from the startup snapshot', () async {
      final startedAt = DateTime(2026, 10, 20, 23, 10);
      create(
        initial: SleepSnapshot(openSession: SleepSession(startedAt: startedAt)),
      );
      await controller.historyLoad;

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.openSession?.startedAt, startedAt);
      expect(state.lastSession, isNull);
    });

    test('restores the last finished session from the local history', () async {
      final session = closed(
        DateTime(2026, 10, 19, 23),
        DateTime(2026, 10, 20, 7),
      );
      create(storeSnapshot: SleepSnapshot(closedSessions: [session]));
      await controller.historyLoad;

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isFalse);
      expect(state.lastSession?.duration, const Duration(hours: 8));
    });

    test('keeps closed sessions across Sleep', () async {
      final recent = closed(
        DateTime(2026, 10, 19, 23),
        DateTime(2026, 10, 20, 7),
      );
      create(storeSnapshot: SleepSnapshot(closedSessions: [recent]));
      await controller.historyLoad;

      await controller.sleep();

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.isSleeping, isTrue);
      expect(state.closedSessions, [recent]);
    });

    test('Google Health reads only Health Connect sessions', () async {
      final local = closed(
        DateTime(2026, 10, 18, 23),
        DateTime(2026, 10, 19, 7),
      );
      final health = HealthSleepSession(
        uuid: 'health-1',
        startedAt: DateTime(2026, 10, 19, 23),
        endedAt: DateTime(2026, 10, 20, 6),
        sourceName: 'Other app',
      );
      create(
        storeSnapshot: SleepSnapshot(closedSessions: [local]),
        source: SleepDataSource.healthConnect,
        healthGateway: FakeHealthConnectGateway(sessions: [health]),
      );
      await controller.historyLoad;

      final state = container.read(sleepTrackingControllerProvider);
      expect(state.historyStatus, SleepHistoryStatus.ready);
      expect(state.closedSessions.single.startedAt, health.startedAt);
      expect(state.closedSessions.single.endedAt, health.endedAt);
      expect(store.closedLoads, 0);
      expect(gateway.lastReadFrom, isNotNull);
    });

    test('switching source clears and reloads without mixing', () async {
      final local = closed(
        DateTime(2026, 10, 18, 23),
        DateTime(2026, 10, 19, 7),
      );
      final health = HealthSleepSession(
        uuid: 'health-1',
        startedAt: DateTime(2026, 10, 19, 23),
        endedAt: DateTime(2026, 10, 20, 6),
      );
      create(
        storeSnapshot: SleepSnapshot(closedSessions: [local]),
        healthGateway: FakeHealthConnectGateway(sessions: [health]),
      );
      await controller.historyLoad;
      expect(container.read(sleepTrackingControllerProvider).closedSessions, [
        local,
      ]);

      await container
          .read(sleepDataSourceProvider.notifier)
          .select(SleepDataSource.healthConnect);

      // The local list disappears before the Health Connect result arrives.
      var state = container.read(sleepTrackingControllerProvider);
      expect(state.closedSessions, isEmpty);
      expect(state.historyStatus, SleepHistoryStatus.loading);

      await controller.historyLoad;
      state = container.read(sleepTrackingControllerProvider);
      expect(state.closedSessions.single.startedAt, health.startedAt);
      expect(state.closedSessions.single.endedAt, health.endedAt);

      await container
          .read(sleepDataSourceProvider.notifier)
          .select(SleepDataSource.local);
      await controller.historyLoad;

      state = container.read(sleepTrackingControllerProvider);
      expect(state.closedSessions, [local]);
    });

    test('wake in Google Health keeps the local copy but hides it', () async {
      final startedAt = DateTime(2026, 10, 20, 22, 30);
      final open = SleepSession(startedAt: startedAt);
      final previous = HealthSleepSession(
        uuid: 'previous',
        startedAt: DateTime(2026, 10, 19, 23),
        endedAt: DateTime(2026, 10, 20, 6),
      );
      create(
        initial: SleepSnapshot(openSession: open),
        storeSnapshot: SleepSnapshot(openSession: open),
        source: SleepDataSource.healthConnect,
        healthGateway: FakeHealthConnectGateway(sessions: [previous]),
      );
      await controller.historyLoad;

      now = startedAt.add(const Duration(hours: 7));
      await controller.wake();

      var state = container.read(sleepTrackingControllerProvider);
      expect(store.finishes.single, now);
      expect(state.isSleeping, isFalse);
      expect(state.closedSessions, hasLength(1));
      expect(state.closedSessions.single.startedAt, previous.startedAt);

      // The local copy is there for Local mode; Health Connect has not been
      // written yet, so it must stay out of the visible history.
      await container
          .read(sleepDataSourceProvider.notifier)
          .select(SleepDataSource.local);
      await controller.historyLoad;

      state = container.read(sleepTrackingControllerProvider);
      expect(state.closedSessions, hasLength(1));
      expect(state.lastSession?.startedAt, startedAt);
      expect(state.lastSession?.endedAt, now);
    });
  });
}
