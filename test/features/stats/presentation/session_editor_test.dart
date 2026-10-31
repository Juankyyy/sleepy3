import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';
import 'package:sleepy3/features/stats/presentation/stats_screen.dart';

import '../../health/fakes.dart';
import '../../sleep_tracking/fakes.dart';

void main() {
  SleepSession localSession({
    int id = 1,
    DateTime? startedAt,
    DateTime? endedAt,
    String? healthRecordId,
    String? healthClientRecordId,
  }) {
    return SleepSession(
      startedAt: startedAt ?? DateTime(2026, 10, 20, 22, 32),
      endedAt: endedAt ?? DateTime(2026, 10, 21, 6, 45),
      localId: id,
      healthRecordId: healthRecordId,
      healthClientRecordId: healthClientRecordId,
    );
  }

  Future<FakeSleepSessionStore> pumpStats(
    WidgetTester tester, {
    List<SleepSession> sessions = const [],
    FakeSleepSessionStore? store,
    SleepDataSource source = SleepDataSource.local,
    FakeHealthConnectGateway? gateway,
    FakeHealthSyncStore? healthSyncStore,
    bool use24HourFormat = false,
    Size size = const Size(360, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final sleepStore =
        store ??
        FakeSleepSessionStore(
          snapshot: SleepSnapshot(closedSessions: sessions),
        );
    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: use24HourFormat),
            child: ProviderScope(
              overrides: [
                sleepClockProvider.overrideWithValue(
                  () => DateTime(2026, 10, 21, 10),
                ),
                sleepSessionStoreProvider.overrideWithValue(sleepStore),
                initialSleepSnapshotProvider.overrideWithValue(
                  SleepSnapshot.empty,
                ),
                initialSleepDataSourceProvider.overrideWithValue(source),
                healthConnectGatewayProvider.overrideWithValue(
                  gateway ?? FakeHealthConnectGateway(),
                ),
                healthSyncStoreProvider.overrideWithValue(
                  healthSyncStore ?? FakeHealthSyncStore(),
                ),
              ],
              child: M3EMaterialApp(
                title: 'Sleepy3',
                data: data,
                theme: data.toThemeData(),
                locale: const Locale('en', 'US'),
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                supportedLocales: const [Locale('en', 'US')],
                home: const Scaffold(body: StatsScreen()),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    return sleepStore;
  }

  Future<void> openLocalEditor(WidgetTester tester) async {
    await tester.tap(find.text('10:32 PM – 6:45 AM'));
    await tester.pumpAndSettle();
  }

  Future<void> pickDay(WidgetTester tester, String day) async {
    await tester.tap(find.text(day).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opens the editor from an editable row and saves without changes',
    (tester) async {
      await pumpStats(tester, sessions: [localSession()]);

      expect(find.byIcon(M3EIcons.edit_outlined), findsOneWidget);
      final iconCenter = tester.getCenter(find.byIcon(M3EIcons.edit_outlined));
      final rowCenter = tester.getCenter(
        find.byWidgetPredicate((widget) => widget is M3EListItem),
      );
      expect((iconCenter.dy - rowCenter.dy).abs(), lessThanOrEqualTo(0.5));

      await openLocalEditor(tester);

      expect(find.text('Edit session'), findsOneWidget);
      expect(find.text('Fell asleep'), findsOneWidget);
      expect(find.text('Woke up'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(
        find.text(
          'This night is also in Google Health. Saving updates both copies.',
        ),
        findsNothing,
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Edit session'), findsNothing);
      expect(find.text('Session deleted.'), findsNothing);
    },
  );

  testWidgets('uses a full-screen dialog on a compact window', (tester) async {
    await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);

    expect(find.byIcon(M3EIcons.close), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('uses a basic dialog on a medium window', (tester) async {
    await pumpStats(
      tester,
      sessions: [localSession()],
      size: const Size(800, 900),
    );

    await openLocalEditor(tester);

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byIcon(M3EIcons.close), findsNothing);
  });

  testWidgets('fits at 200% text', (tester) async {
    await pumpStats(tester, sessions: [localSession()], textScale: 2);

    // The summary grows at 200% text and pushes the history row below it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final iconCenter = tester.getCenter(find.byIcon(M3EIcons.edit_outlined));
    final rowCenter = tester.getCenter(
      find.byWidgetPredicate((widget) => widget is M3EListItem),
    );
    expect((iconCenter.dy - rowCenter.dy).abs(), lessThanOrEqualTo(0.5));

    await openLocalEditor(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Edit session'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('editable rows are buttons that open the editor', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpStats(tester, sessions: [localSession()]);

    final node = tester.getSemantics(find.text('10:32 PM – 6:45 AM'));
    expect(node.label, 'Today, 8 hours 13 minutes, 10:32 PM to 6:45 AM');
    expect(node.hint, 'Opens the session editor');
    expect(node.flagsCollection.isButton, isTrue);

    handle.dispose();
  });

  testWidgets('saves a changed sleep date', (tester) async {
    final store = await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Date').first);
    await tester.pumpAndSettle();
    await pickDay(tester, '19');

    expect(find.text('Mon, Oct 19, 2026'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsNothing);
    expect(store.updates, hasLength(1));
    expect(store.updates.single.startedAt, DateTime(2026, 10, 19, 22, 32));
    expect(store.updates.single.endedAt, DateTime(2026, 10, 21, 6, 45));
    expect(find.text('32h 13m'), findsWidgets);
  });

  testWidgets('saves a changed sleep time', (tester) async {
    final store = await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Time').first);
    await tester.pumpAndSettle();

    final dial = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == 'M3ETimeDialPainter',
    );
    final rect = tester.getRect(dial);
    final radius = rect.width * 0.35;

    // 9 o'clock selects hour 9; the initial period is PM (10:32 PM).
    await tester.tapAt(rect.center + Offset(-radius, 0));
    await tester.pumpAndSettle();
    // Tapping the minute field switches the dial to minute mode.
    await tester.tap(find.text('32'));
    await tester.pumpAndSettle();
    // 3 o'clock selects minute 15.
    await tester.tapAt(rect.center + Offset(radius, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('9:15 PM'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.updates, hasLength(1));
    expect(store.updates.single.startedAt, DateTime(2026, 10, 20, 21, 15));
  });

  testWidgets('discards a changed date when closing the editor', (
    tester,
  ) async {
    final store = await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Date').first);
    await tester.pumpAndSettle();
    await pickDay(tester, '19');

    await tester.tap(find.byIcon(M3EIcons.close));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsNothing);
    expect(store.updates, isEmpty);
  });

  testWidgets('shows a validation error inline', (tester) async {
    await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Date').last);
    await tester.pumpAndSettle();
    await pickDay(tester, '19');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('The wake time must be after the sleep time.'),
      findsOneWidget,
    );
    expect(find.text('Edit session'), findsOneWidget);
  });

  testWidgets('uses the system 24-hour format in the editor', (tester) async {
    await pumpStats(tester, sessions: [localSession()], use24HourFormat: true);

    await tester.tap(find.text('22:32 – 06:45'));
    await tester.pumpAndSettle();

    expect(find.text('22:32'), findsOneWidget);
    expect(find.text('06:45'), findsOneWidget);
  });

  testWidgets('warns when a local session is also in Google Health', (
    tester,
  ) async {
    await pumpStats(
      tester,
      sessions: [
        localSession(
          healthRecordId: 'own-record',
          healthClientRecordId: 'sleepy3-1',
        ),
      ],
    );

    await openLocalEditor(tester);

    expect(
      find.text(
        'This night is also in Google Health. Saving updates both copies.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reports a pending Google Health update after saving', (
    tester,
  ) async {
    final session = localSession(
      healthRecordId: 'own-record',
      healthClientRecordId: 'sleepy3-1',
    );
    final sync = FakeHealthSyncStore()
      ..addLocal(
        session,
        synced: true,
        healthRecordId: 'own-record',
        healthClientRecordId: 'sleepy3-1',
        healthRecordVersion: 1,
      );

    await pumpStats(
      tester,
      sessions: [session],
      healthSyncStore: sync,
      gateway: FakeHealthConnectGateway(writeSucceeds: false),
    );

    await openLocalEditor(tester);
    await tester.tap(find.text('Date').first);
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsNothing);
    expect(
      find.text('Saved. Google Health will update when it can.'),
      findsOneWidget,
    );
  });

  testWidgets('reports a missing Google Health write permission', (
    tester,
  ) async {
    final session = localSession(
      healthRecordId: 'own-record',
      healthClientRecordId: 'sleepy3-1',
    );
    final sync = FakeHealthSyncStore()
      ..addLocal(
        session,
        synced: true,
        healthRecordId: 'own-record',
        healthClientRecordId: 'sleepy3-1',
        healthRecordVersion: 1,
      );

    await pumpStats(
      tester,
      sessions: [session],
      healthSyncStore: sync,
      gateway: FakeHealthConnectGateway(writePermission: false),
    );

    await openLocalEditor(tester);
    await tester.tap(find.text('Date').first);
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsNothing);
    expect(
      find.text('Saved locally. Allow Google Health write access to sync it.'),
      findsOneWidget,
    );
  });

  testWidgets('edits an own Google Health record through its local copy', (
    tester,
  ) async {
    final session = localSession(
      healthRecordId: 'fake-sleepy3-1',
      healthClientRecordId: 'sleepy3-1',
    );
    final sync = FakeHealthSyncStore()
      ..addLocal(
        session,
        synced: true,
        healthRecordId: 'fake-sleepy3-1',
        healthClientRecordId: 'sleepy3-1',
        healthRecordVersion: 1,
      );
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'fake-sleepy3-1',
          startedAt: session.startedAt,
          endedAt: session.endedAt!,
          sourceId: 'com.sleepy3.app',
        ),
      ],
    );

    await pumpStats(
      tester,
      sessions: [session],
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      healthSyncStore: sync,
    );

    expect(find.byIcon(M3EIcons.edit_outlined), findsOneWidget);
    await tester.tap(find.text('10:32 PM – 6:45 AM'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This night is stored in Google Health. Saving updates the Health '
        'Connect record.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Date').first);
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsNothing);
    expect(gateway.writes, hasLength(1));
    expect(gateway.writes.single.clientRecordId, 'sleepy3-1');
    expect(gateway.writes.single.clientRecordVersion, 2);
    expect(gateway.sessions.single.startedAt, DateTime(2026, 10, 19, 22, 32));
    expect(find.text('32h 13m'), findsWidgets);
  });

  testWidgets('deletes an editable session after confirmation', (tester) async {
    final store = await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.deletes, [1]);
    expect(find.text('Edit session'), findsNothing);
    expect(find.text('Session deleted.'), findsOneWidget);
    expect(find.text('No sleep history yet'), findsOneWidget);
  });

  testWidgets('offers only delete for an own Health Connect record', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'own-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.sleepy3.app',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );

    expect(find.byIcon(M3EIcons.edit_outlined), findsOneWidget);
    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(
      find.text(
        'This Google Health record has no local copy. You can delete it, but '
        'its times cannot be edited here.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(gateway.deletes, hasLength(1));
    expect(gateway.deletes.single.healthRecordId, 'own-record');
    expect(gateway.deletes.single.clientRecordId, isNull);
    expect(find.text('Session deleted.'), findsOneWidget);
    expect(find.text('No sleep history in Google Health'), findsOneWidget);
  });

  testWidgets('leaves records from other apps read-only', (tester) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'other-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.example.other',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );

    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Edit session'), findsNothing);
  });
}
