import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/navigation/pill_navigation_bar.dart';
import 'package:sleepy3/app/navigation/sleepy3_destination.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/reminders/application/reminder_providers.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';

import '../features/health/fakes.dart';
import '../features/sleep_tracking/fakes.dart';

void main() {
  const labels = {
    Sleepy3Destination.home: 'Home',
    Sleepy3Destination.stats: 'Stats',
    Sleepy3Destination.settings: 'Settings',
  };

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(360, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 20, 22, 30),
          ),
          sleepSessionStoreProvider.overrideWithValue(FakeSleepSessionStore()),
          healthConnectGatewayProvider.overrideWithValue(
            FakeHealthConnectGateway(),
          ),
          healthSyncStoreProvider.overrideWithValue(FakeHealthSyncStore()),
        ],
        child: Sleepy3App(splashStartSignal: Future<void>.value()),
      ),
    );
    await tester.pumpAndSettle();
  }

  PillNavigationBar navigationBar(WidgetTester tester) {
    return tester.widget<PillNavigationBar>(find.byType(PillNavigationBar));
  }

  Finder inNavigationBar(Finder matching) {
    return find.descendant(
      of: find.byType(PillNavigationBar),
      matching: matching,
    );
  }

  ValueKey<String> navKey(Sleepy3Destination destination) {
    return ValueKey('nav-${destination.name}');
  }

  testWidgets('starts on Home with three labelled destinations', (
    tester,
  ) async {
    await pumpApp(tester);

    final bar = navigationBar(tester);
    expect(bar.destinations.map((destination) => labels[destination]), [
      'Home',
      'Stats',
      'Settings',
    ]);
    expect(bar.selectedIndex, 0);
    expect(find.text('Sleepy3'), findsOneWidget);

    // The active destination uses the filled icon, the others the outlined one.
    expect(inNavigationBar(find.byIcon(M3EIcons.home)), findsOneWidget);
    expect(inNavigationBar(find.byIcon(M3EIcons.home_outlined)), findsNothing);
    expect(
      inNavigationBar(find.byIcon(M3EIcons.analytics_outlined)),
      findsOneWidget,
    );
    expect(
      inNavigationBar(find.byIcon(M3EIcons.settings_outlined)),
      findsOneWidget,
    );

    // Hidden labels stay available to assistive technology.
    for (final destination in Sleepy3Destination.values) {
      final semantics = tester.widget<Semantics>(
        find.byKey(navKey(destination)),
      );
      expect(semantics.properties.label, labels[destination]);
      expect(
        semantics.properties.selected,
        destination == Sleepy3Destination.home,
      );
    }
  });

  testWidgets('centers a content-sized glass bar', (tester) async {
    await pumpApp(tester);

    final surface = tester.getRect(find.byKey(PillNavigationBar.surfaceKey));
    expect(surface.width, lessThan(360 - 2 * PillNavigationBar.outerMargin));
    expect(surface.center.dx, closeTo(180, 0.01));
    expect(surface.height, closeTo(PillNavigationBar.minHeight, 0.01));
    expect(inNavigationBar(find.byType(BackdropFilter)), findsOneWidget);
  });

  testWidgets('switches destinations and reports the active one', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.stats)));
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 1);
    expect(find.text('No sleep history yet'), findsOneWidget);
    expect(inNavigationBar(find.byIcon(M3EIcons.analytics)), findsOneWidget);
    expect(
      inNavigationBar(find.byIcon(M3EIcons.home_outlined)),
      findsOneWidget,
    );
    expect(inNavigationBar(find.byIcon(M3EIcons.home)), findsNothing);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.settings)));
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 2);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(inNavigationBar(find.byIcon(M3EIcons.settings)), findsOneWidget);
    expect(
      inNavigationBar(find.byIcon(M3EIcons.analytics_outlined)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(navKey(Sleepy3Destination.home)));
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 0);
    expect(find.text('Sleepy3'), findsOneWidget);
  });

  testWidgets('a reminder tap returns to Home from Settings', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.settings)));
    await tester.pumpAndSettle();
    expect(navigationBar(tester).selectedIndex, 2);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PillNavigationBar)),
    );
    container.read(reminderHomeRequestProvider.notifier).requestHome();
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 0);
    expect(find.text('Sleepy3'), findsOneWidget);
  });

  testWidgets('back from a secondary destination returns to Home', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.stats)));
    await tester.pumpAndSettle();
    expect(navigationBar(tester).selectedIndex, 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 0);
    expect(find.text('Sleepy3'), findsOneWidget);
  });

  testWidgets('switching destinations preserves the home state', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sleeping since'), findsOneWidget);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.stats)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(navKey(Sleepy3Destination.home)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sleeping since'), findsOneWidget);
  });

  testWidgets('the selected label stays inside the bar at 200% text', (
    tester,
  ) async {
    await pumpApp(tester, textScale: 2);

    for (final destination in Sleepy3Destination.values) {
      await tester.tap(find.byKey(navKey(destination)));
      await tester.pumpAndSettle();

      final itemRect = tester.getRect(find.byKey(navKey(destination)));
      final label = labels[destination]!;
      final labelRect = tester.getRect(inNavigationBar(find.text(label)));
      expect(
        labelRect.left,
        greaterThanOrEqualTo(itemRect.left),
        reason: '$label starts outside its pill',
      );
      expect(
        labelRect.right,
        lessThanOrEqualTo(itemRect.right - 10),
        reason: '$label is clipped at 200% text',
      );
      expect(
        labelRect.top,
        greaterThanOrEqualTo(itemRect.top),
        reason: '$label overflows its pill vertically',
      );
      expect(
        labelRect.bottom,
        lessThanOrEqualTo(itemRect.bottom),
        reason: '$label overflows its pill vertically',
      );
    }

    // The flexible bar can grow vertically; at 2x this label still fits in 48dp.
    expect(
      tester.getSize(find.byKey(PillNavigationBar.surfaceKey)).height,
      greaterThanOrEqualTo(PillNavigationBar.minHeight),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserves the status bar and the system bottom inset', (
    tester,
  ) async {
    const topInset = 24.0;
    const bottomInset = 24.0;
    const pixelRatio = 3.0;

    // View padding is expressed in physical pixels in the test view.
    tester.view.padding = const FakeViewPadding(
      top: topInset * pixelRatio,
      bottom: bottomInset * pixelRatio,
    );
    tester.view.viewPadding = const FakeViewPadding(
      top: topInset * pixelRatio,
      bottom: bottomInset * pixelRatio,
    );
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await pumpApp(tester);

    final surfaceRect = tester.getRect(
      find.byKey(PillNavigationBar.surfaceKey),
    );
    expect(
      surfaceRect.bottom,
      closeTo(800 - bottomInset - PillNavigationBar.bottomGap, 0.01),
    );
    expect(surfaceRect.height, closeTo(PillNavigationBar.minHeight, 0.01));

    final contentRect = tester.getRect(find.byType(IndexedStack));
    expect(contentRect.top, topInset);
    expect(contentRect.bottom, 800);

    final bodyBottomInset = MediaQuery.paddingOf(
      tester.element(find.byType(IndexedStack)),
    ).bottom;
    expect(
      bodyBottomInset,
      closeTo(
        PillNavigationBar.topGap +
            PillNavigationBar.minHeight +
            PillNavigationBar.bottomGap +
            bottomInset,
        0.01,
      ),
    );

    await tester.tap(find.byKey(navKey(Sleepy3Destination.settings)));
    await tester.pumpAndSettle();
    final settingsList = tester.widget<ListView>(find.byType(ListView));
    expect(
      (settingsList.padding! as EdgeInsets).bottom,
      closeTo(24 + bodyBottomInset, 0.01),
    );
  });
}
