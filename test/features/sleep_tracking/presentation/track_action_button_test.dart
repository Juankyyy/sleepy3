import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/presentation/widgets/track_action_button.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  setUpAll(() async {
    // Render with the bundled fonts so label-fit checks use production metrics
    // instead of the test font's square glyphs.
    final loader = FontLoader(Sleepy3Theme.fontFamily);
    loader.addFont(
      rootBundle.load('assets/fonts/SpaceGrotesk-VariableFont.ttf'),
    );
    await loader.load();

    final brandLoader = FontLoader(Sleepy3Theme.brandFontFamily);
    brandLoader.addFont(
      rootBundle.load('assets/fonts/GoogleSansFlex-Titles.ttf'),
    );
    await brandLoader.load();
  });

  Future<SleepWakeOutcome?> defaultWake(VoidCallback onSaving) async {
    onSaving();
    return SleepWakeOutcome.closed;
  }

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool isSleeping,
    Duration sleepDuration = const Duration(hours: 3, minutes: 42),
    VoidCallback? onSleep,
    Future<SleepWakeOutcome?> Function(VoidCallback onSaving)? onWake,
    double textScale = 1,
    bool disableAnimations = false,
    bool settle = true,
    double width = 360,
    Locale locale = const Locale('en'),
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
        locale: locale,
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
                      sleepDuration: isSleeping ? sleepDuration : null,
                      onSleep: onSleep ?? () {},
                      onWake: onWake ?? defaultWake,
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

  /// Drags the Wake slide from its center; 240dp clears the full 192dp
  /// travel.
  Future<void> dragToWake(WidgetTester tester, {double dx = 240}) async {
    await tester.drag(
      find.byKey(const Key('track-action-slide')),
      Offset(dx, 0),
    );
    await tester.pump();
  }

  bool labelIsWhole(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    return !paragraph.didExceedMaxLines;
  }

  void expectSliderLabelStyle(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final style = paragraph.text.style;
    expect(style?.fontSize, 22, reason: label);
    expect(style?.fontWeight, FontWeight.w500, reason: label);
    expect(style?.fontFamily, Sleepy3Theme.brandFontFamily, reason: label);
    expect(
      style?.fontVariations?.any(
        (variation) => variation.axis == 'opsz' && variation.value == 28,
      ),
      isTrue,
      reason: label,
    );
  }

  void expectDurationStyle(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final style = paragraph.text.style;
    expect(style?.fontSize, 24, reason: label);
    expect(style?.fontWeight, FontWeight.w700, reason: label);
    expect(style?.fontFamily, Sleepy3Theme.fontFamily, reason: label);
    expect(
      style?.fontFeatures?.any((feature) => feature.feature == 'tnum'),
      isTrue,
      reason: label,
    );
  }

  void expectSlideHintStyle(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final style = paragraph.text.style;
    expect(style?.fontSize, 14, reason: label);
    expect(style?.fontWeight, FontWeight.w500, reason: label);
    expect(style?.fontFamily, Sleepy3Theme.brandFontFamily, reason: label);
    expect(
      style?.fontVariations?.any(
        (variation) => variation.axis == 'opsz' && variation.value == 28,
      ),
      isTrue,
      reason: label,
    );
  }

  Color? surfaceColor(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byKey(const Key('track-action-surface')),
    );
    final decoration = container.decoration;
    return decoration is BoxDecoration ? decoration.color : null;
  }

  testWidgets(
    'uses one extra-large square filled Sleep button with a leading icon',
    (tester) async {
      await pumpButton(tester, isSleeping: false);

      final buttons = tester
          .widgetList<M3EButton>(find.byType(M3EButton))
          .toList();
      expect(buttons, hasLength(1));
      final button = buttons.single;
      expect(button.style, M3EButtonStyle.filled);
      expect(button.size, M3EButtonSize.xl);
      expect(button.shape, M3EButtonShape.square);
      expect(button.enabled, isTrue);

      // The Sleep action uses the brand face at `titleLarge` (22 sp).
      final sleepLabel = tester.renderObject<RenderParagraph>(
        find.text('Sleep'),
      );
      expect(sleepLabel.text.style?.fontSize, 22);
      expect(sleepLabel.text.style?.fontWeight, FontWeight.w500);
      expect(sleepLabel.text.style?.fontFamily, Sleepy3Theme.brandFontFamily);
      expect(
        sleepLabel.text.style?.fontVariations?.any(
          (variation) => variation.axis == 'opsz' && variation.value == 28,
        ),
        isTrue,
      );

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
    },
  );

  testWidgets(
    'uses the clock face for the duration and the brand face for the action',
    (tester) async {
      await pumpButton(tester, isSleeping: true);
      expectDurationStyle(tester, '3h 42m');
      expectSlideHintStyle(tester, 'Slide to wake');

      await dragToWake(tester);
      expectSliderLabelStyle(tester, 'Saving session');

      await tester.pump(TrackActionButton.savingMinimum);
      expectSliderLabelStyle(tester, 'Session saved');
    },
  );

  testWidgets('paints the action with primary and onPrimary', (tester) async {
    await pumpButton(tester, isSleeping: false);

    final scheme = Sleepy3Theme.light().colorScheme;
    expect(surfaceColor(tester), scheme.primary);

    final label = tester
        .renderObject<RenderParagraph>(find.text('Sleep'))
        .text
        .style!;
    expect(label.color, scheme.onPrimary);
  });

  testWidgets('presses the Sleep surface to the M3 16 dp radius', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: false);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Sleep')),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final surface = tester.widget<AnimatedContainer>(
      find.byKey(const Key('track-action-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(16));

    final pressScale = tester.widget<AnimatedScale>(
      find.byKey(const Key('track-action-press-scale')),
    );
    expect(pressScale.scale, 0.98);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('the nightfall sheen crosses the action when sleep starts', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: false);
    await tester.tap(find.text('Sleep'));
    await tester.pump();
    await pumpButton(tester, isSleeping: true, settle: false);

    double sheenBegin() {
      final band = tester.widget<DecoratedBox>(
        find.byKey(const Key('track-action-sheen-band')),
      );
      final gradient =
          (band.decoration as BoxDecoration).gradient! as LinearGradient;
      return (gradient.begin as Alignment).x;
    }

    final start = sheenBegin();
    await tester.pump(const Duration(milliseconds: 200));
    final middle = sheenBegin();
    expect(middle, greaterThan(start));

    await tester.pump(TrackActionButton.nightfallDuration);
    final end = sheenBegin();
    expect(end, greaterThan(middle));
  });

  testWidgets('lands the wake moon when sleep starts', (tester) async {
    await pumpButton(tester, isSleeping: false);
    await tester.tap(find.text('Sleep'));
    await tester.pump();
    await pumpButton(tester, isSleeping: true, settle: false);

    final start = tester.widget<ScaleTransition>(
      find.byKey(const Key('track-action-moon-landing')),
    );
    expect(start.scale.value, lessThan(1));

    await tester.pump(TrackActionButton.moonLandingDuration);

    final settled = tester.widget<ScaleTransition>(
      find.byKey(const Key('track-action-moon-landing')),
    );
    expect(settled.scale.value, closeTo(1, 0.001));
  });

  testWidgets('does not play the nightfall on a restored session', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true, settle: false);

    final landing = tester.widget<ScaleTransition>(
      find.byKey(const Key('track-action-moon-landing')),
    );
    expect(landing.scale.value, 1);

    final band = tester.widget<DecoratedBox>(
      find.byKey(const Key('track-action-sheen-band')),
    );
    final gradient =
        (band.decoration as BoxDecoration).gradient! as LinearGradient;
    expect((gradient.begin as Alignment).x, lessThan(-1));
  });

  testWidgets('skips the nightfall cue with reduce motion', (tester) async {
    await pumpButton(tester, isSleeping: false, disableAnimations: true);
    await tester.tap(find.text('Sleep'));
    await tester.pump();
    await pumpButton(
      tester,
      isSleeping: true,
      disableAnimations: true,
      settle: false,
    );

    expect(find.byKey(const Key('track-action-sheen')), findsNothing);

    final landing = tester.widget<ScaleTransition>(
      find.byKey(const Key('track-action-moon-landing')),
    );
    expect(landing.scale.value, 1);
  });

  testWidgets('replaces the button with the Wake slide while sleeping', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpButton(tester, isSleeping: true);

    expect(find.byType(M3EButton), findsNothing);
    expect(find.text('3h 42m'), findsOneWidget);
    expect(find.text('Slide to wake'), findsOneWidget);
    expect(find.byKey(const Key('track-action-trail')), findsOneWidget);
    expect(find.byKey(const Key('track-action-grip')), findsOneWidget);
    expect(find.byKey(const Key('track-action-slide')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('track-action-surface'))),
      const Size(328, 136),
    );

    expect(
      find.bySemanticsLabel('Sleeping for 3h 42m. Slide to wake.'),
      findsOneWidget,
    );
    final slide = tester.getSemantics(
      find.bySemanticsLabel('Sleeping for 3h 42m. Slide to wake.'),
    );
    expect(slide.flagsCollection.isEnabled, Tristate.isTrue);
    expect(slide.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    handle.dispose();
  });

  testWidgets('leaves 24 dp between the capsule and the label', (tester) async {
    await pumpButton(tester, isSleeping: true);

    final grip = find.byKey(const Key('track-action-grip'));
    final label = find.byKey(const Key('track-action-label'));
    expect(tester.getTopLeft(label).dx - tester.getTopRight(grip).dx, 24);
  });

  testWidgets('keeps the arrow visible at the end of the slide', (
    tester,
  ) async {
    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async => null,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('track-action-slide'))),
    );
    await gesture.moveBy(const Offset(240, 0));
    await tester.pump();

    final surface = tester.getRect(
      find.byKey(const Key('track-action-surface')),
    );
    final grip = tester.getRect(find.byKey(const Key('track-action-grip')));
    expect(grip.left, surface.left + 16 + 192);
    expect(grip.right, surface.right - 16);
    expect(
      tester.getSize(find.byKey(const Key('track-action-trail'))).width,
      296,
    );

    final arrow = tester.widget<Icon>(
      find.byIcon(M3EIcons.arrow_forward_rounded),
    );
    expect(arrow.color, Sleepy3Theme.light().colorScheme.primary);

    await gesture.cancel();
    await tester.pump();
  });

  testWidgets('shows the saving indicator on the right at the sunny size', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true);
    await dragToWake(tester);

    expect(find.text('Saving session'), findsOneWidget);
    final indicator = tester.widget<M3ELoadingIndicator>(
      find.byKey(const Key('track-action-saving-indicator')),
    );
    expect(indicator.size, 106);
    expect(
      tester
          .getCenter(find.byKey(const Key('track-action-saving-indicator')))
          .dx,
      greaterThan(tester.getCenter(find.text('Saving session')).dx),
    );

    await tester.pump(TrackActionButton.savingMinimum);
    await tester.pump(TrackActionButton.savedHold);
  });

  testWidgets('uses the same text-figure gap as the saved row', (tester) async {
    await pumpButton(tester, isSleeping: true);
    await dragToWake(tester);

    final savingText = find.text('Saving session');
    final savingFigure = find.byKey(const Key('track-action-saving-figure'));
    final savingGap =
        tester.getTopLeft(savingFigure).dx - tester.getTopRight(savingText).dx;
    expect(savingGap, 16);

    await tester.pump(TrackActionButton.savingMinimum);

    final savedText = find.text('Session saved');
    final savedFigure = find.byKey(const Key('track-action-figure'));
    final savedGap =
        tester.getTopLeft(savedFigure).dx - tester.getTopRight(savedText).dx;
    expect(savedGap, 16);
    expect(savingGap, savedGap);

    await tester.pump(TrackActionButton.savedHold);
  });

  testWidgets('fits the saving row at 200% text on a 320dp phone', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true, textScale: 2, width: 320);
    await dragToWake(tester);

    expect(find.text('Saving session'), findsOneWidget);
    expect(
      find.byKey(const Key('track-action-saving-indicator')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pump(TrackActionButton.savingMinimum);
    await tester.pump(TrackActionButton.savedHold);
  });

  testWidgets('updates the live duration when the minute changes', (
    tester,
  ) async {
    await pumpButton(
      tester,
      isSleeping: true,
      sleepDuration: const Duration(hours: 3, minutes: 42),
    );
    expect(find.text('3h 42m'), findsOneWidget);

    await pumpButton(
      tester,
      isSleeping: true,
      sleepDuration: const Duration(hours: 3, minutes: 43),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('3h 43m'), findsOneWidget);
    expect(find.text('3h 42m'), findsNothing);
  });

  testWidgets('shows just now during the first minute', (tester) async {
    await pumpButton(
      tester,
      isSleeping: true,
      sleepDuration: const Duration(seconds: 30),
      locale: const Locale('es'),
    );

    expect(find.text('Ahora'), findsOneWidget);
    final semantics = tester.widget<Semantics>(
      find.byKey(const Key('track-action-semantics')),
    );
    expect(
      semantics.properties.label,
      'Acabas de dormirte. Desliza para despertar.',
    );
  });

  testWidgets('plays the entrance cue once and then rests', (tester) async {
    await pumpButton(tester, isSleeping: true, settle: false);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 800));

    var arrow = tester.widget<Transform>(
      find.byKey(const Key('track-action-arrow-nudge')),
    );
    expect(arrow.transform.getTranslation().x, greaterThan(0));

    var moon = tester.widget<Transform>(
      find.byKey(const Key('track-action-moon-breath')),
    );
    expect(moon.transform.entry(0, 0), lessThan(1.0));

    await tester.pumpAndSettle();

    arrow = tester.widget<Transform>(
      find.byKey(const Key('track-action-arrow-nudge')),
    );
    moon = tester.widget<Transform>(
      find.byKey(const Key('track-action-moon-breath')),
    );
    expect(arrow.transform.getTranslation().x, 0);
    expect(moon.transform.entry(0, 0), closeTo(1.0, 0.001));
  });

  testWidgets('skips the entrance cue with reduce motion', (tester) async {
    await pumpButton(
      tester,
      isSleeping: true,
      settle: false,
      disableAnimations: true,
    );
    await tester.pump(const Duration(milliseconds: 1150));

    final arrow = tester.widget<Transform>(
      find.byKey(const Key('track-action-arrow-nudge')),
    );
    final moon = tester.widget<Transform>(
      find.byKey(const Key('track-action-moon-breath')),
    );
    expect(arrow.transform.getTranslation().x, 0);
    expect(moon.transform.entry(0, 0), closeTo(1.0, 0.001));
  });

  testWidgets('shows the focus ring only for keyboard focus', (tester) async {
    await pumpButton(tester, isSleeping: true);

    // Dragging with a pointer must not focus the slide or paint the ring.
    await dragToWake(tester, dx: 100);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('track-action-focus')), findsNothing);

    // Tab focuses the slide and shows the keyboard ring.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(const Key('track-action-focus')), findsOneWidget);
  });

  testWidgets('the awake action starts the session', (tester) async {
    var sleeps = 0;

    await pumpButton(tester, isSleeping: false, onSleep: () => sleeps++);
    await tester.tap(find.text('Sleep'));
    await tester.pump();

    expect(sleeps, 1);
  });

  testWidgets('a slide that reaches 80% commits before the end', (
    tester,
  ) async {
    var wakes = 0;

    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async {
        wakes++;
        return null;
      },
    );

    // The track travels 192dp at 360dp. 160dp is about 83% of the travel,
    // past the 80% commit zone.
    await dragToWake(tester, dx: 160);
    await tester.pump(const Duration(milliseconds: 300));

    expect(wakes, 1);
    expect(find.text('Slide to wake'), findsOneWidget);
  });

  testWidgets('a full slide saves and shows the Amanecer seal at the right', (
    tester,
  ) async {
    var saves = 0;

    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async {
        onSaving();
        saves++;
        return SleepWakeOutcome.closed;
      },
    );

    // Releasing below the 80% commit zone returns to the start and does not
    // save. 145dp is about 75% of the travel.
    await dragToWake(tester, dx: 145);
    expect(saves, 0);
    await tester.pump(const Duration(milliseconds: 300));

    await dragToWake(tester);
    expect(saves, 1);
    expect(find.text('Saving session'), findsOneWidget);

    // The saving state is visible for at least 1.2 s.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Saving session'), findsOneWidget);
    await tester.pump(
      TrackActionButton.savingMinimum - const Duration(milliseconds: 300),
    );
    expect(find.text('Session saved'), findsOneWidget);

    final figures = tester
        .widgetList<M3EShapeContainer>(find.byType(M3EShapeContainer))
        .toList();
    expect(figures, hasLength(1));
    expect(figures.single.kind, M3EShapeKind.sunny);
    expect(find.byIcon(M3EIcons.check_rounded), findsOneWidget);

    // The sun and check trail the label, and the pair stays centered.
    final figure = find.byKey(const Key('track-action-figure'));
    expect(
      tester.getCenter(figure).dx,
      greaterThan(tester.getCenter(find.text('Session saved')).dx),
    );
    expect(
      tester.getCenter(find.byKey(const Key('track-action-result'))).dx,
      closeTo(
        tester.getCenter(find.byKey(const Key('track-action-surface'))).dx,
        1,
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Slide to wake'), findsOneWidget);
  });

  testWidgets('the saving row hands off to the seal before the saved text', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true);
    await dragToWake(tester);
    await tester.pump(TrackActionButton.savingMinimum);

    expect(find.byKey(const Key('track-action-saving-row')), findsOneWidget);
    expect(find.byKey(const Key('track-action-saved-row')), findsOneWidget);

    final savingFade = tester.widget<FadeTransition>(
      find.byKey(const Key('track-action-saving-row')),
    );
    final savedTextFade = tester.widget<FadeTransition>(
      find.byKey(const Key('track-action-saved-text')),
    );
    final sunFade = tester.widget<FadeTransition>(
      find.byKey(const Key('track-action-sun')),
    );
    expect(savingFade.opacity.value, 1);
    expect(savedTextFade.opacity.value, 0);
    expect(sunFade.opacity.value, 0);

    // The seal starts appearing while the saving row is still fading out; the
    // saved text waits until the saving copy is gone.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('track-action-saving-row')), findsOneWidget);
    expect(savingFade.opacity.value, lessThan(1));
    expect(savedTextFade.opacity.value, 0);
    expect(sunFade.opacity.value, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const Key('track-action-saving-row')), findsNothing);
    expect(savedTextFade.opacity.value, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 300));
    expect(savedTextFade.opacity.value, 1);
    expect(sunFade.opacity.value, 1);
    expect(
      tester
          .widget<ScaleTransition>(
            find.byKey(const Key('track-action-sun-scale')),
          )
          .scale
          .value,
      closeTo(1, 0.01),
    );
    expect(
      tester
          .widget<RotationTransition>(
            find.byKey(const Key('track-action-sun-turn')),
          )
          .turns
          .value,
      closeTo(0, 0.001),
    );
    expect(
      tester
          .widget<FadeTransition>(find.byKey(const Key('track-action-check')))
          .opacity
          .value,
      1,
    );

    await tester.pump(TrackActionButton.savedHold);
  });

  testWidgets('the success beat settles back to the resting scale', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true);
    await dragToWake(tester);
    await tester.pump(TrackActionButton.savingMinimum);

    final beat = tester.widget<ScaleTransition>(
      find.byKey(const Key('track-action-beat')),
    );
    expect(beat.scale.value, 1);

    await tester.pump(const Duration(milliseconds: 100));
    expect(beat.scale.value, greaterThan(1));

    await tester.pump(const Duration(milliseconds: 300));
    expect(beat.scale.value, closeTo(1, 0.001));

    await tester.pump(TrackActionButton.savedHold);
  });

  testWidgets('reduce motion skips the saved handoff and the beat', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true, disableAnimations: true);
    await dragToWake(tester);
    await tester.pump(TrackActionButton.savingMinimum);

    expect(find.byKey(const Key('track-action-saving-row')), findsNothing);
    expect(
      tester
          .widget<FadeTransition>(
            find.byKey(const Key('track-action-saved-text')),
          )
          .opacity
          .value,
      1,
    );
    expect(
      tester
          .widget<FadeTransition>(find.byKey(const Key('track-action-sun')))
          .opacity
          .value,
      1,
    );
    expect(
      tester
          .widget<ScaleTransition>(find.byKey(const Key('track-action-beat')))
          .scale
          .value,
      1,
    );

    await tester.pump(TrackActionButton.savedHold);
  });

  testWidgets('the saved state holds and then returns to Sleep', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true);
    await dragToWake(tester);
    expect(find.text('Saving session'), findsOneWidget);

    // The parent flips to awake while the control keeps the confirmation.
    await pumpButton(tester, isSleeping: false, settle: false);
    await tester.pump(TrackActionButton.savingMinimum);
    expect(find.text('Session saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Session saved'), findsNothing);
  });

  testWidgets('a cancelled wake returns the slide to the start', (
    tester,
  ) async {
    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async => null,
    );

    await dragToWake(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Slide to wake'), findsOneWidget);
    expect(find.text('Saving session'), findsNothing);
    expect(find.byKey(const Key('track-action-figure')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('track-action-trail'))).width,
      104,
    );
  });

  testWidgets('a discarded wake shows the cancel icon and returns to Sleep', (
    tester,
  ) async {
    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async {
        onSaving();
        return SleepWakeOutcome.discarded;
      },
    );

    await dragToWake(tester);
    expect(find.text('Saving session'), findsOneWidget);

    await pumpButton(tester, isSleeping: false, settle: false);
    await tester.pump(TrackActionButton.savingMinimum);

    expect(find.text('Session discarded'), findsOneWidget);
    expect(surfaceColor(tester), Sleepy3Theme.light().colorScheme.error);
    expectSliderLabelStyle(tester, 'Session discarded');

    // The icon trails the label, and the pair is centered instead of pinned
    // to the trailing edge of the surface.
    final result = find.byKey(const Key('track-action-result'));
    final icon = find.byIcon(M3EIcons.cancel_outlined);
    final surface = find.byKey(const Key('track-action-surface'));
    expect(
      tester.getCenter(result).dx,
      closeTo(tester.getCenter(surface).dx, 1),
    );
    expect(
      tester.getCenter(icon).dx,
      greaterThan(tester.getCenter(find.text('Session discarded')).dx),
    );
    expect(
      tester.getTopLeft(icon).dx -
          tester.getTopRight(find.text('Session discarded')).dx,
      closeTo(16, 0.5),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Sleep'), findsOneWidget);
  });

  testWidgets('a discard without a save never shows the saving row', (
    tester,
  ) async {
    final discard = Completer<SleepWakeOutcome?>();
    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) => discard.future,
    );

    await dragToWake(tester);

    // The parent flips to awake while the discard write is in flight. The
    // committed confirmation must stay on screen instead of swapping to the
    // Sleep button and remounting a slide that never plays its result.
    await pumpButton(tester, isSleeping: false, settle: false);
    await tester.pump();

    expect(find.text('Sleep'), findsNothing);

    discard.complete(SleepWakeOutcome.discarded);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));

    expect(find.text('Saving session'), findsNothing);
    expect(find.byKey(const Key('track-action-saving-row')), findsNothing);
    expect(find.text('Session discarded'), findsOneWidget);
    expect(find.byIcon(M3EIcons.cancel_outlined), findsOneWidget);
    final resultText = tester.widget<FadeTransition>(
      find.byKey(const Key('track-action-saved-text')),
    );
    expect(resultText.opacity.value, closeTo(1, 0.01));

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Sleep'), findsOneWidget);
  });

  testWidgets('a failed save shows the error', (tester) async {
    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async {
        onSaving();
        throw StateError('write failed');
      },
    );

    await dragToWake(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Couldn't save the session"), findsOneWidget);
    expect(surfaceColor(tester), Sleepy3Theme.light().colorScheme.error);
    expect(find.byIcon(M3EIcons.error_outline_rounded), findsOneWidget);
    expect(find.byIcon(M3EIcons.cancel_outlined), findsNothing);
  });

  testWidgets('ignores a slide right after the state changes', (tester) async {
    var wakes = 0;

    Future<SleepWakeOutcome?> wake(VoidCallback onSaving) async {
      wakes++;
      return null;
    }

    await pumpButton(tester, isSleeping: false, onWake: wake);
    await tester.tap(find.text('Sleep'));
    await tester.pump();

    await pumpButton(tester, isSleeping: true, onWake: wake, settle: false);

    // The switch guard is still running after the first frame.
    await dragToWake(tester);
    expect(wakes, 0);

    await tester.pump(TrackActionButton.tapGuard);
    await dragToWake(tester);
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

    expect(find.text('Slide to wake'), findsOneWidget);
    expect(find.byType(M3EButton), findsNothing);

    // Let the post-change guard expire before dragging.
    await tester.pump(TrackActionButton.tapGuard);
    await dragToWake(tester);
    await tester.pump(TrackActionButton.savingMinimum);
    await tester.pump();
    expect(find.text('Session saved'), findsOneWidget);
    expect(find.byKey(const Key('track-action-figure')), findsOneWidget);
    expect(find.byIcon(M3EIcons.check_rounded), findsOneWidget);
  });

  testWidgets('fits the slide labels at 200% text on a 320dp phone', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true, textScale: 2, width: 320);

    expect(labelIsWhole(tester, '3h 42m'), isTrue);
    expect(labelIsWhole(tester, 'Slide to wake'), isTrue);
    expect(tester.takeException(), isNull);

    await dragToWake(tester);
    await tester.pump(TrackActionButton.savingMinimum);

    expect(labelIsWhole(tester, 'Session saved'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the Sleep label at 200% text on a 320dp phone', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: false, textScale: 2, width: 320);

    expect(labelIsWhole(tester, 'Sleep'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the Spanish slide labels with the brand style', (
    tester,
  ) async {
    await pumpButton(tester, isSleeping: true, locale: const Locale('es'));

    expectDurationStyle(tester, '3 h 42 min');
    expectSlideHintStyle(tester, 'Desliza para despertar');
    expect(labelIsWhole(tester, '3 h 42 min'), isTrue);
    expect(labelIsWhole(tester, 'Desliza para despertar'), isTrue);

    await dragToWake(tester);
    expect(labelIsWhole(tester, 'Guardando sesión'), isTrue);

    await tester.pump(TrackActionButton.savingMinimum);
    expect(labelIsWhole(tester, 'Sesión guardada'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the discarded result at 200% text on a 320dp phone', (
    tester,
  ) async {
    await pumpButton(
      tester,
      isSleeping: true,
      textScale: 2,
      width: 320,
      onWake: (onSaving) async {
        onSaving();
        return SleepWakeOutcome.discarded;
      },
    );

    await dragToWake(tester);
    await tester.pump(TrackActionButton.savingMinimum);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Session discarded'), findsOneWidget);
    expect(labelIsWhole(tester, 'Session discarded'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('announces the saving and saved states', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpButton(tester, isSleeping: true);
    await dragToWake(tester);
    expect(find.bySemanticsLabel('Saving session'), findsOneWidget);

    await tester.pump(TrackActionButton.savingMinimum);
    expect(find.bySemanticsLabel('Session saved'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('the TalkBack action completes the slide', (tester) async {
    final handle = tester.ensureSemantics();
    var wakes = 0;

    await pumpButton(
      tester,
      isSleeping: true,
      onWake: (onSaving) async {
        onSaving();
        wakes++;
        return SleepWakeOutcome.closed;
      },
    );

    final slide = tester.widget<Semantics>(
      find.byKey(const Key('track-action-semantics')),
    );
    expect(slide.properties.label, 'Sleeping for 3h 42m. Slide to wake.');
    slide.properties.onTap!();
    await tester.pump();

    expect(wakes, 1);

    await tester.pump(TrackActionButton.savingMinimum);
    await tester.pump(const Duration(milliseconds: 1200));
    handle.dispose();
  });
}
