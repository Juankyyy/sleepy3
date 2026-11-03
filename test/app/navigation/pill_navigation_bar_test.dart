import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/navigation/pill_navigation_bar.dart';
import 'package:sleepy3/app/navigation/sleepy3_destination.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final data = Sleepy3Theme.light();
    var selectedIndex = 0;

    await tester.pumpWidget(
      M3EMaterialApp(
        data: data,
        theme: data.toThemeData(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: PillNavigationBar.topGap,
                    bottom: PillNavigationBar.bottomGap,
                  ),
                  child: PillNavigationBar(
                    destinations: Sleepy3Destination.values,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => selectedIndex = index);
                    },
                    semanticLabel: 'Main navigation',
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ValueKey<String> navKey(Sleepy3Destination destination) {
    return ValueKey('nav-${destination.name}');
  }

  testWidgets('shows three tabs with only the active pill expanded', (
    tester,
  ) async {
    await pumpBar(tester);

    final bar = tester.widget<PillNavigationBar>(
      find.byType(PillNavigationBar),
    );
    expect(bar.selectedIndex, 0);

    final home = tester.widget<Semantics>(
      find.byKey(navKey(Sleepy3Destination.home)),
    );
    final stats = tester.widget<Semantics>(
      find.byKey(navKey(Sleepy3Destination.stats)),
    );
    final settings = tester.widget<Semantics>(
      find.byKey(navKey(Sleepy3Destination.settings)),
    );
    expect(home.properties.selected, isTrue);
    expect(stats.properties.selected, isFalse);
    expect(settings.properties.selected, isFalse);
    expect(stats.properties.label, 'Stats');
    expect(settings.properties.label, 'Settings');

    // Inactive labels are laid out beyond the visible item and clipped.
    final statsRect = tester.getRect(
      find.byKey(navKey(Sleepy3Destination.stats)),
    );
    final statsLabelRect = tester.getRect(find.text('Stats'));
    expect(statsLabelRect.left, greaterThanOrEqualTo(statsRect.right - 0.5));
  });

  testWidgets('renders a centered glass bar narrower than the screen', (
    tester,
  ) async {
    await pumpBar(tester);

    final surface = tester.getRect(find.byKey(PillNavigationBar.surfaceKey));
    expect(surface.width, lessThan(360 - 2 * PillNavigationBar.outerMargin));
    expect(surface.center.dx, closeTo(180, 0.01));
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.settings)));
    await tester.pumpAndSettle();

    final settingsSurface = tester.getRect(
      find.byKey(PillNavigationBar.surfaceKey),
    );
    expect(settingsSurface.width, greaterThan(surface.width));
    expect(settingsSurface.center.dx, closeTo(180, 0.01));
  });

  testWidgets('selecting Stats expands its pill and lifts the label', (
    tester,
  ) async {
    await pumpBar(tester);

    final collapsedWidth = tester
        .getSize(find.byKey(navKey(Sleepy3Destination.stats)))
        .width;

    await tester.tap(find.byKey(navKey(Sleepy3Destination.stats)));
    await tester.pumpAndSettle();

    final statsRect = tester.getRect(
      find.byKey(navKey(Sleepy3Destination.stats)),
    );
    final labelRect = tester.getRect(find.text('Stats'));

    expect(statsRect.width, greaterThan(collapsedWidth));
    expect(labelRect.left, greaterThanOrEqualTo(statsRect.left));
    expect(labelRect.right, lessThanOrEqualTo(statsRect.right - 10));
    expect(
      tester
          .widget<Semantics>(find.byKey(navKey(Sleepy3Destination.stats)))
          .properties
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(navKey(Sleepy3Destination.home)))
          .properties
          .selected,
      isFalse,
    );
  });

  testWidgets('keeps the Settings label visible at 200% text', (tester) async {
    await pumpBar(tester, textScale: 2);

    await tester.tap(find.byKey(navKey(Sleepy3Destination.settings)));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(
      find.byKey(navKey(Sleepy3Destination.settings)),
    );
    final labelRect = tester.getRect(find.text('Settings'));

    expect(labelRect.left, greaterThanOrEqualTo(itemRect.left));
    expect(labelRect.right, lessThanOrEqualTo(itemRect.right - 10));
    expect(labelRect.top, greaterThanOrEqualTo(itemRect.top));
    expect(labelRect.bottom, lessThanOrEqualTo(itemRect.bottom));
    expect(
      tester.getSize(find.byKey(PillNavigationBar.surfaceKey)).height,
      greaterThanOrEqualTo(PillNavigationBar.minHeight),
    );
    expect(tester.takeException(), isNull);
  });
}
