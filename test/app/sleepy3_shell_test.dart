import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/navigation/sleepy3_destination.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';

import '../features/sleep_tracking/fakes.dart';

void main() {
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
        ],
        child: const Sleepy3App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  M3ENavigationBar navigationBar(WidgetTester tester) {
    return tester.widget<M3ENavigationBar>(find.byType(M3ENavigationBar));
  }

  Finder inNavigationBar(Finder matching) {
    return find.descendant(
      of: find.byType(M3ENavigationBar),
      matching: matching,
    );
  }

  testWidgets('starts on Home with three labelled destinations', (
    tester,
  ) async {
    await pumpApp(tester);

    final bar = navigationBar(tester);
    expect(bar.destinations.map((destination) => destination.label), [
      'Home',
      'Stats',
      'Settings',
    ]);
    expect(bar.selectedIndex, 0);
    expect(bar.size, M3ENavBarSize.small);
    expect(find.text('Sleepy3'), findsOneWidget);

    // The active destination uses the filled icon, the others the outlined one.
    expect(inNavigationBar(find.byIcon(M3EIcons.home)), findsOneWidget);
    expect(inNavigationBar(find.byIcon(M3EIcons.home_outlined)), findsNothing);
    expect(
      inNavigationBar(find.byIcon(M3EIcons.bar_chart_outlined)),
      findsOneWidget,
    );
    expect(
      inNavigationBar(find.byIcon(M3EIcons.settings_outlined)),
      findsOneWidget,
    );
  });

  testWidgets('switches destinations and reports the active one', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 1);
    expect(find.text('No stats yet'), findsOneWidget);
    expect(inNavigationBar(find.byIcon(M3EIcons.bar_chart)), findsOneWidget);
    expect(
      inNavigationBar(find.byIcon(M3EIcons.home_outlined)),
      findsOneWidget,
    );
    expect(inNavigationBar(find.byIcon(M3EIcons.home)), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 2);
    expect(find.text('Settings are coming soon'), findsOneWidget);
    expect(inNavigationBar(find.byIcon(M3EIcons.settings)), findsOneWidget);
    expect(
      inNavigationBar(find.byIcon(M3EIcons.bar_chart_outlined)),
      findsOneWidget,
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 0);
    expect(find.text('Sleepy3'), findsOneWidget);
  });

  testWidgets('back from a secondary destination returns to Home', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Stats'));
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

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sleeping since'), findsOneWidget);
  });

  testWidgets('labels stay visible at 360dp and 200% text', (tester) async {
    await pumpApp(tester, textScale: 2);

    for (final destination in Sleepy3Destination.values) {
      final paragraph = tester.renderObject<RenderParagraph>(
        inNavigationBar(find.text(destination.label)),
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '${destination.label} is truncated at 200% text',
      );
    }

    // The flexible bar grows vertically instead of clipping the labels.
    expect(
      tester.getSize(find.byType(M3ENavigationBar)).height,
      greaterThan(64),
    );
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

    final navRect = tester.getRect(find.byType(M3ENavigationBar));
    expect(navRect.bottom, 800);
    expect(navRect.height, closeTo(64 + bottomInset, 0.01));

    final contentRect = tester.getRect(find.byType(IndexedStack));
    expect(contentRect.top, topInset);
    expect(contentRect.bottom, 800 - navRect.height);
  });
}
