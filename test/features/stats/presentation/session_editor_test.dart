import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/app_info_provider.dart';
import 'package:sleepy3/features/health/application/current_app_package_provider.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';
import 'package:sleepy3/features/stats/presentation/stats_screen.dart';
import 'package:sleepy3/features/stats/presentation/widgets/session_editor.dart';

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
    FakeAppInfoGateway? appInfo,
    String currentPackage = 'com.sleepy3.app',
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
                appInfoGatewayProvider.overrideWithValue(
                  appInfo ?? FakeAppInfoGateway(),
                ),
                currentAppPackageProvider.overrideWithValue(currentPackage),
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

      expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);

      await openLocalEditor(tester);

      expect(find.text('Session'), findsOneWidget);
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

      expect(find.text('Session'), findsNothing);
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

    expect(find.text('10:32 PM – 6:45 AM'), findsOneWidget);

    await openLocalEditor(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('the card opens the editor from the row content', (tester) async {
    await pumpStats(tester, sessions: [localSession()]);

    await tester.tap(find.text('10:32 PM – 6:45 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
  });

  testWidgets('editable rows are buttons that open the editor', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpStats(tester, sessions: [localSession()]);

    final node = tester.getSemantics(find.text('10:32 PM – 6:45 AM'));
    expect(
      node.label,
      'Today, 8 hours 13 minutes, goal met, 10:32 PM to 6:45 AM',
    );
    expect(node.hint, 'Opens the session');
    expect(node.flagsCollection.isButton, isTrue);

    handle.dispose();
  });

  testWidgets('shows the goal in the session details header', (tester) async {
    await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);

    expect(find.text('Goal met · 13m over the 8h goal'), findsOneWidget);
    expect(find.text('Woke Wed, Oct 21, 2026'), findsOneWidget);

    final badges = tester
        .widgetList<M3EShapeContainer>(
          find.descendant(
            of: find.byType(SessionEditor),
            matching: find.byType(M3EShapeContainer),
          ),
        )
        .toList();
    expect(badges, hasLength(1));
    expect(badges.single.kind, M3EShapeKind.clover8Leaf);
    expect(badges.single.width, 56);
    expect(badges.single.height, 56);

    final hero = tester.widget<M3ECard>(
      find
          .descendant(
            of: find.byType(SessionEditor),
            matching: find.byType(M3ECard),
          )
          .first,
    );
    expect(hero.color, Sleepy3Theme.light().colorScheme.primaryContainer);
  });

  testWidgets('describes a night below the goal in the header', (tester) async {
    await pumpStats(
      tester,
      sessions: [
        localSession(
          startedAt: DateTime(2026, 10, 20, 23, 10),
          endedAt: DateTime(2026, 10, 21, 6, 12),
        ),
      ],
    );

    await tester.tap(find.text('11:10 PM – 6:12 AM'));
    await tester.pumpAndSettle();

    expect(find.text('58m short of the 8h goal'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SessionEditor),
        matching: find.byType(M3EShapeContainer),
      ),
      findsNothing,
    );
    final ring = tester.widget<M3EProgressIndicator>(
      find.descendant(
        of: find.byType(SessionEditor),
        matching: find.byType(M3EProgressIndicator),
      ),
    );
    expect(ring.size, 56);
  });

  testWidgets('marks an exact eight-hour night as met', (tester) async {
    await pumpStats(
      tester,
      sessions: [
        localSession(
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
        ),
      ],
    );

    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Goal met'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SessionEditor),
        matching: find.byType(M3EShapeContainer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('updates the goal while the draft crosses it', (tester) async {
    await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    expect(find.text('Goal met · 13m over the 8h goal'), findsOneWidget);

    await tester.tap(find.text('10:32 PM'));
    await tester.pumpAndSettle();

    final dial = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == 'M3ETimeDialPainter',
    );
    final rect = tester.getRect(dial);
    final radius = rect.width * 0.35;

    // 11 o'clock is 30 degrees left of 12; the period stays PM.
    await tester.tapAt(rect.center + Offset(-radius * 0.5, -radius * 0.866));
    await tester.pumpAndSettle();
    // Tapping the minute field switches the dial to minute mode.
    await tester.tap(find.text('32'));
    await tester.pumpAndSettle();
    // 3 o'clock selects minute 15.
    await tester.tapAt(rect.center + Offset(radius, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('11:15 PM'), findsOneWidget);
    expect(find.text('30m short of the 8h goal'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SessionEditor),
        matching: find.byType(M3EShapeContainer),
      ),
      findsNothing,
    );
  });

  testWidgets('spells out the goal for screen readers', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpStats(tester, sessions: [localSession()]);
    await openLocalEditor(tester);

    expect(
      find.bySemanticsLabel(
        RegExp(
          '8 hours 13 minutes, goal met, 13 minutes over the 8-hour goal, '
          'woke Wednesday, October 21, 2026',
        ),
      ),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('saves a changed sleep date', (tester) async {
    final store = await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Wed, Oct 21'));
    await tester.pumpAndSettle();
    await pickDay(tester, '20');

    expect(find.text('Mon, Oct 19'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
    expect(store.updates, hasLength(1));
    expect(store.updates.single.startedAt, DateTime(2026, 10, 19, 22, 32));
    expect(store.updates.single.endedAt, DateTime(2026, 10, 20, 6, 45));
    expect(find.text('8h 13m'), findsWidgets);
  });

  testWidgets('saves a changed sleep time', (tester) async {
    final store = await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('10:32 PM'));
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
    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');

    await tester.tap(find.byIcon(M3EIcons.close));
    await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
    expect(store.updates, isEmpty);
  });

  testWidgets('shows a validation error inline', (tester) async {
    await pumpStats(tester, sessions: [localSession()]);

    await openLocalEditor(tester);
    await tester.tap(find.text('Wed, Oct 21'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('The wake time must be after the sleep time.'),
      findsOneWidget,
    );
    expect(find.text('Session'), findsOneWidget);
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
    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Wed, Oct 21'));
    await tester.pumpAndSettle();
    await pickDay(tester, '20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
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
    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Wed, Oct 21'));
    await tester.pumpAndSettle();
    await pickDay(tester, '20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
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
    gateway.writeTokens['fake-sleepy3-1'] = const HealthRecordWriteToken(
      clientRecordId: 'sleepy3-1',
      clientRecordVersion: 1,
    );

    await pumpStats(
      tester,
      sessions: [session],
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      healthSyncStore: sync,
    );

    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
    await tester.tap(find.text('10:32 PM – 6:45 AM'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This night is stored in Google Health. Saving updates the Health '
        'Connect record.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Wed, Oct 21'));
    await tester.pumpAndSettle();
    await pickDay(tester, '20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
    expect(gateway.writes, hasLength(1));
    expect(gateway.writes.single.clientRecordId, 'sleepy3-1');
    expect(gateway.writes.single.clientRecordVersion, 2);
    expect(gateway.sessions.single.startedAt, DateTime(2026, 10, 19, 22, 32));
    expect(gateway.sessions.single.endedAt, DateTime(2026, 10, 20, 6, 45));
    expect(find.text('8h 13m'), findsWidgets);
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
    expect(find.text('Session'), findsNothing);
    expect(find.text('Session deleted.'), findsOneWidget);
    expect(find.text('No sleep history yet'), findsOneWidget);
  });

  testWidgets('asks for permission and deletes after Allow', (tester) async {
    final session = localSession(
      healthRecordId: 'permission-record',
      healthClientRecordId: 'sleepy3-1',
    );
    final gateway = FakeHealthConnectGateway(
      writePermission: false,
      grantWriteOnRequest: true,
      sessions: [
        HealthSleepSession(
          uuid: 'permission-record',
          startedAt: session.startedAt,
          endedAt: session.endedAt!,
          sourceId: 'com.sleepy3.app',
        ),
      ],
    );
    final sync = FakeHealthSyncStore()
      ..addLocal(
        session,
        synced: true,
        healthRecordId: 'permission-record',
        healthClientRecordId: 'sleepy3-1',
        healthRecordVersion: 1,
      );
    final store = await pumpStats(
      tester,
      sessions: [session],
      gateway: gateway,
      healthSyncStore: sync,
    );

    await openLocalEditor(tester);
    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Google Health needs permission'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(gateway.permissionRequestCalls, 1);
    expect(gateway.sessions, isEmpty);
    expect(store.snapshot.closedSessions, isEmpty);
    expect(find.text('Session'), findsNothing);
    expect(find.text('Session deleted.'), findsOneWidget);
  });

  testWidgets('edits an own Health Connect record without a local copy', (
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

    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Fell asleep'), findsOneWidget);
    expect(find.text('Woke up'), findsOneWidget);

    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    await pickDay(tester, '19');
    await tester.tap(find.text('Wed, Oct 21'));
    await tester.pumpAndSettle();
    await pickDay(tester, '20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
    expect(gateway.updates, hasLength(1));
    expect(gateway.updates.single.healthRecordId, 'own-record');
    expect(gateway.updates.single.startedAt, DateTime(2026, 10, 19, 22));
    expect(gateway.updates.single.endedAt, DateTime(2026, 10, 20, 6));
    expect(find.text('8h 0m'), findsWidgets);
  });

  testWidgets('opens another app record as read-only details', (tester) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'other-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.google.android.apps.healthdata',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      appInfo: FakeAppInfoGateway({
        'com.google.android.apps.healthdata': 'Google Health',
      }),
    );

    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Read-only session'), findsOneWidget);
    expect(find.textContaining('created in Google Health'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Delete session'), findsNothing);
    expect(find.text('Close'), findsNothing);
    expect(find.byIcon(M3EIcons.close), findsOneWidget);
    expect(find.byIcon(M3EIcons.event_outlined), findsNothing);
    expect(find.byIcon(M3EIcons.schedule_outlined), findsNothing);

    final cardFinder = find.ancestor(
      of: find.text('Read-only session'),
      matching: find.byType(M3ECard),
    );
    final card = tester.widget<M3ECard>(cardFinder);
    final scheme = Sleepy3Theme.light().colorScheme;
    expect(card.variant, M3ECardVariant.filled);
    expect(card.color, scheme.surfaceContainerHighest);
    expect(
      tester.widget<Text>(find.text('Read-only session')).style?.color,
      scheme.onSurface,
    );
    final lockFinder = find.descendant(
      of: cardFinder,
      matching: find.byIcon(M3EIcons.lock_outlined),
    );
    expect(tester.widget<Icon>(lockFinder).color, scheme.onSurfaceVariant);

    final lockCenter = tester.getCenter(lockFinder);
    final cardCenter = tester.getCenter(cardFinder);
    expect((lockCenter.dy - cardCenter.dy).abs(), lessThanOrEqualTo(0.5));

    await tester.tap(find.text('Tue, Oct 20'));
    await tester.pumpAndSettle();
    expect(find.text('Select sleep date'), findsNothing);
    expect(find.text('Tue, Oct 20'), findsOneWidget);

    await tester.tap(find.byIcon(M3EIcons.close));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
    expect(gateway.writes, isEmpty);
    expect(gateway.updates, isEmpty);
    expect(gateway.deletes, isEmpty);
  });

  testWidgets('falls back to another app when the label is missing', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'other-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.example.unknown',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );

    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(find.textContaining('created in another app'), findsOneWidget);
  });

  testWidgets('opens a record from the other Sleepy3 build read-only', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'debug-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.sleepy3.app.debug',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      appInfo: FakeAppInfoGateway({'com.sleepy3.app.debug': 'Sleepy3 Debug'}),
    );

    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Read-only session'), findsOneWidget);
    expect(find.textContaining('created in Sleepy3 Debug'), findsOneWidget);
    expect(find.text('Delete session'), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('opens a downloaded copy as read-only details', (tester) async {
    final session = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      localId: 3,
      isDownloaded: true,
      healthRecordId: 'downloaded-record',
      sourceId: 'com.google.android.apps.healthdata',
    );

    await pumpStats(
      tester,
      sessions: [session],
      appInfo: FakeAppInfoGateway({
        'com.google.android.apps.healthdata': 'Google Health',
      }),
    );

    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(find.textContaining('created in Google Health'), findsOneWidget);
    expect(
      find.textContaining("Downloaded copies can't be edited in Local"),
      findsOneWidget,
    );
    expect(find.text('Save'), findsNothing);
    expect(find.text('Delete session'), findsNothing);
    expect(find.byIcon(M3EIcons.event_outlined), findsNothing);
  });

  testWidgets('read-only details fit at 200% text', (tester) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'other-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.google.android.apps.healthdata',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      appInfo: FakeAppInfoGateway({
        'com.google.android.apps.healthdata': 'Google Health',
      }),
      textScale: 2,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Read-only session'), findsOneWidget);
  });

  testWidgets('read-only details use a single Close on medium windows', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway(
      sessions: [
        HealthSleepSession(
          uuid: 'other-record',
          startedAt: DateTime(2026, 10, 20, 22),
          endedAt: DateTime(2026, 10, 21, 6),
          sourceId: 'com.google.android.apps.healthdata',
        ),
      ],
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      appInfo: FakeAppInfoGateway({
        'com.google.android.apps.healthdata': 'Google Health',
      }),
      size: const Size(800, 900),
    );

    await tester.tap(find.text('10:00 PM – 6:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Delete session'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsNothing);
  });
}
