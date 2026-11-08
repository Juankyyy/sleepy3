import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/presentation/widgets/track_action_button.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  setUpAll(() async {
    // Render with the bundled font so label-fit checks use production metrics
    // instead of the test font's square glyphs.
    final loader = FontLoader('SpaceGrotesk');
    loader.addFont(
      rootBundle.load('assets/fonts/SpaceGrotesk-VariableFont.ttf'),
    );
    await loader.load();
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool isSleeping,
    VoidCallback? onSleep,
    VoidCallback? onWake,
    double textScale = 1,
    bool disableAnimations = false,
    bool settle = true,
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 800) * 3;
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
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: Scaffold(
              body: Padding(
                // The Home screen's compact layout margin.
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TrackActionButton(
                      isSleeping: isSleeping,
                      onSleep: onSleep ?? () {},
                      onWake: onWake ?? () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  List<M3EButton> actions(WidgetTester tester) {
    return tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
  }

  bool labelIsWhole(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    return !paragraph.didExceedMaxLines;
  }

  Color? buttonBackground(WidgetTester tester) {
    return tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(M3EButton),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;
  }

  testWidgets('uses one extra-large square filled button with a leading icon', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: false);

    final buttons = actions(tester);
    expect(buttons, hasLength(1));
    final button = buttons.single;
    expect(button.style, M3EButtonStyle.filled);
    expect(button.size, M3EButtonSize.xl);
    expect(button.shape, M3EButtonShape.square);
    expect(button.enabled, isTrue);

    // The plan keeps the standard `labelLarge` label role.
    final sleepLabel = tester.renderObject<RenderParagraph>(find.text('Sleep'));
    expect(sleepLabel.text.style?.fontSize, 14);
    expect(sleepLabel.text.style?.fontWeight, FontWeight.w500);
    expect(sleepLabel.text.style?.fontFamily, Sleepy3Theme.fontFamily);

    final size = tester.getSize(find.byType(M3EButton));
    expect(size.height, 136);
    expect(size.width, 328);
    expect(
      tester.getSize(find.byIcon(M3EIcons.bedtime_rounded)),
      const Size(40, 40),
    );
    // The icon leads the label in left-to-right layouts.
    expect(
      tester.getCenter(find.byIcon(M3EIcons.bedtime_rounded)).dx,
      lessThan(tester.getCenter(find.text('Sleep')).dx),
    );
  });

  testWidgets('paints the action with primary and onPrimary', (tester) async {
    await pumpButton(tester, isSleeping: false);

    final scheme = Sleepy3Theme.light().colorScheme;
    expect(buttonBackground(tester), scheme.primary);

    final label = tester
        .renderObject<RenderParagraph>(find.text('Sleep'))
        .text
        .style!;
    expect(label.color, scheme.onPrimary);
  });

  testWidgets('shows only the action that matches the sleep state', (
    tester,
  ) async {
    var sleeps = 0;
    var wakes = 0;

    await pumpButton(
      tester,
      isSleeping: false,
      onSleep: () => sleeps++,
      onWake: () => wakes++,
    );

    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Wake'), findsNothing);
    expect(actions(tester), hasLength(1));
    expect(actions(tester).single.enabled, isTrue);

    await tester.tap(find.text('Sleep'));
    await tester.pump();
    expect(sleeps, 1);
    expect(wakes, 0);

    await pumpButton(
      tester,
      isSleeping: true,
      onSleep: () => sleeps++,
      onWake: () => wakes++,
    );

    expect(find.text('Sleep'), findsNothing);
    expect(find.text('Wake'), findsOneWidget);
    expect(actions(tester), hasLength(1));
    expect(actions(tester).single.enabled, isTrue);

    // Let the post-change tap guard expire before using the new action.
    await tester.pump(TrackActionButton.tapGuard);
    await tester.tap(find.text('Wake'));
    await tester.pump();
    expect(wakes, 1);
    expect(sleeps, 1);
  });

  testWidgets('exposes only the current action to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpButton(tester, isSleeping: false);
    expect(find.bySemanticsLabel('Sleep'), findsOneWidget);
    expect(find.bySemanticsLabel('Wake'), findsNothing);

    final sleep = tester.getSemantics(find.bySemanticsLabel('Sleep'));
    expect(sleep.flagsCollection.isEnabled, Tristate.isTrue);
    expect(sleep.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await pumpButton(tester, isSleeping: true);
    expect(find.bySemanticsLabel('Wake'), findsOneWidget);
    expect(find.bySemanticsLabel('Sleep'), findsNothing);

    final wake = tester.getSemantics(find.bySemanticsLabel('Wake'));
    expect(wake.flagsCollection.isEnabled, Tristate.isTrue);
    expect(wake.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    handle.dispose();
  });

  testWidgets('keeps the outgoing content during the rise', (tester) async {
    await pumpButton(tester, isSleeping: false);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Wake'), findsNothing);

    await pumpButton(tester, isSleeping: true, settle: false);

    // The new action is already current while the old one rises out.
    expect(find.text('Wake'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Sleep'), findsNothing);
    expect(find.text('Wake'), findsOneWidget);
  });

  testWidgets('fits the label on a 360dp phone', (tester) async {
    await pumpButton(tester, isSleeping: false);

    expect(labelIsWhole(tester, 'Sleep'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the label whole at 200% text', (tester) async {
    await pumpButton(tester, isSleeping: false, textScale: 2);

    expect(labelIsWhole(tester, 'Sleep'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the label whole on a 320dp phone at 200% text', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: false, textScale: 2, width: 320);

    expect(labelIsWhole(tester, 'Sleep'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores a tap right after the state changes', (tester) async {
    var wakes = 0;

    await pumpButton(tester, isSleeping: false, onWake: () => wakes++);
    await pumpButton(
      tester,
      isSleeping: true,
      onWake: () => wakes++,
      settle: false,
    );

    // The rise and its guard are still running after the first frame.
    await tester.tap(find.byType(M3EButton));
    await tester.pump();
    expect(wakes, 0);

    await tester.pump(TrackActionButton.tapGuard);
    await tester.tap(find.byType(M3EButton));
    await tester.pump();
    expect(wakes, 1);
  });

  testWidgets('changes instantly with reduce motion', (tester) async {
    await pumpButton(tester, isSleeping: false, disableAnimations: true);
    await pumpButton(
      tester,
      isSleeping: true,
      disableAnimations: true,
      settle: false,
    );

    expect(find.text('Wake'), findsOneWidget);
    expect(find.text('Sleep'), findsNothing);
  });
}
