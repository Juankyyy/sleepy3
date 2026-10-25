import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/presentation/widgets/track_buttons_row.dart';

void main() {
  setUpAll(() async {
    // Render with the bundled font so label-fit checks use production metrics
    // instead of the test font's square glyphs.
    final loader = FontLoader('RobotoFlex');
    loader.addFont(rootBundle.load('assets/fonts/RobotoFlex-VariableFont.ttf'));
    await loader.load();
  });

  Future<void> pumpButtons(
    WidgetTester tester, {
    required bool isSleeping,
    VoidCallback? onSleep,
    VoidCallback? onWake,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      M3EMaterialApp(
        data: data,
        theme: data.toThemeData(),
        home: Scaffold(
          body: Padding(
            // The Home screen's compact layout margin.
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TrackButtonsRow(
                  isSleeping: isSleeping,
                  onSleep: onSleep ?? () {},
                  onWake: onWake ?? () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<M3EButton> actions(WidgetTester tester) {
    return tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
  }

  bool labelIsWhole(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    return !paragraph.didExceedMaxLines;
  }

  Color? buttonBackground(WidgetTester tester, int index) {
    return tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(M3EButton).at(index),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;
  }

  testWidgets('uses extra-large square filled buttons with leading icons', (
    tester,
  ) async {
    await pumpButtons(tester, isSleeping: false);

    final buttons = actions(tester);
    expect(buttons, hasLength(2));
    for (final button in buttons) {
      expect(button.style, M3EButtonStyle.filled);
      expect(button.size.name, 'xl');
      // 16dp padding instead of the XL token's 64dp; the other XL
      // measurements stay at their tokens.
      expect(button.size.hPadding, 16);
      expect(button.size.iconGap, isNull);
      expect(button.size.iconSize, isNull);
      expect(button.shape, M3EButtonShape.square);
    }

    // The plan keeps the standard `labelLarge` label role for both actions.
    final sleepLabel = tester.renderObject<RenderParagraph>(find.text('Sleep'));
    expect(sleepLabel.text.style?.fontSize, 14);
    expect(sleepLabel.text.style?.fontWeight, FontWeight.w500);
    expect(sleepLabel.text.style?.fontFamily, Sleepy3Theme.fontFamily);

    final sleepSize = tester.getSize(find.byType(M3EButton).first);
    final wakeSize = tester.getSize(find.byType(M3EButton).last);
    expect(sleepSize.height, 136);
    expect(wakeSize.height, 136);
    expect(sleepSize.width, wakeSize.width);

    expect(
      tester.getSize(find.byIcon(M3EIcons.bedtime_rounded)),
      const Size(40, 40),
    );
    expect(
      tester.getSize(find.byIcon(M3EIcons.wb_sunny_rounded)),
      const Size(40, 40),
    );
    // The icon leads the label in left-to-right layouts.
    expect(
      tester.getCenter(find.byIcon(M3EIcons.bedtime_rounded)).dx,
      lessThan(tester.getCenter(find.text('Sleep')).dx),
    );
  });

  testWidgets('paints enabled actions with primary and disabled with tokens', (
    tester,
  ) async {
    await pumpButtons(tester, isSleeping: false);

    final scheme = Sleepy3Theme.light().colorScheme;
    expect(buttonBackground(tester, 0), scheme.primary);
    expect(
      buttonBackground(tester, 1),
      scheme.onSurface.withValues(alpha: 0.1),
    );

    final sleepLabel = tester
        .renderObject<RenderParagraph>(find.text('Sleep'))
        .text
        .style!;
    final wakeLabel = tester
        .renderObject<RenderParagraph>(find.text('Wake'))
        .text
        .style!;
    expect(sleepLabel.color, scheme.onPrimary);
    expect(wakeLabel.color, scheme.onSurface.withValues(alpha: 0.38));
  });

  testWidgets('enables only the action that matches the sleep state', (
    tester,
  ) async {
    var sleeps = 0;
    var wakes = 0;

    await pumpButtons(
      tester,
      isSleeping: false,
      onSleep: () => sleeps++,
      onWake: () => wakes++,
    );

    var buttons = actions(tester);
    expect(buttons[0].enabled, isTrue);
    expect(buttons[1].enabled, isFalse);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(sleeps, 1);

    await tester.tap(find.text('Wake'));
    await tester.pumpAndSettle();
    expect(wakes, 0);

    await pumpButtons(
      tester,
      isSleeping: true,
      onSleep: () => sleeps++,
      onWake: () => wakes++,
    );

    buttons = actions(tester);
    expect(buttons[0].enabled, isFalse);
    expect(buttons[1].enabled, isTrue);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(sleeps, 1);

    await tester.tap(find.text('Wake'));
    await tester.pumpAndSettle();
    expect(wakes, 1);
  });

  testWidgets('exposes the action label and enabled state to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpButtons(tester, isSleeping: false);

    expect(find.bySemanticsLabel('Sleep'), findsOneWidget);
    expect(find.bySemanticsLabel('Wake'), findsOneWidget);

    final sleep = tester.getSemantics(find.bySemanticsLabel('Sleep'));
    final wake = tester.getSemantics(find.bySemanticsLabel('Wake'));

    expect(sleep.flagsCollection.isEnabled, Tristate.isTrue);
    expect(wake.flagsCollection.isEnabled, Tristate.isFalse);
    expect(sleep.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(wake.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    handle.dispose();
  });

  testWidgets('fits both labels side by side on a 360dp phone', (tester) async {
    await pumpButtons(tester, isSleeping: false);

    expect(labelIsWhole(tester, 'Sleep'), isTrue);
    expect(labelIsWhole(tester, 'Wake'), isTrue);

    // Same row: both labels share a top edge.
    expect(
      tester.getTopLeft(find.text('Wake')).dy,
      tester.getTopLeft(find.text('Sleep')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks the actions at 200% text without truncating labels', (
    tester,
  ) async {
    await pumpButtons(tester, isSleeping: false, textScale: 2);

    expect(labelIsWhole(tester, 'Sleep'), isTrue);
    expect(labelIsWhole(tester, 'Wake'), isTrue);

    expect(
      tester.getTopLeft(find.text('Wake')).dy,
      greaterThan(tester.getBottomLeft(find.text('Sleep')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
