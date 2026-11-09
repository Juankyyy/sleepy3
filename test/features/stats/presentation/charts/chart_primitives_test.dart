import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_axis.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_empty_state.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_legend.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_motion.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_painter.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_scene.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_scrub_area.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_theme.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_tooltip.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool disableAnimations = false,
    Size size = const Size(360, 500),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: disableAnimations);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      M3EMaterialApp(
        title: 'Sleepy3',
        data: data,
        theme: data.toThemeData(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('ChartAxis', () {
    const axis = ChartAxis(
      min: 0,
      max: 10,
      ticks: [
        ChartTick(value: 0, label: '0h'),
        ChartTick(value: 5, label: '5h'),
        ChartTick(value: 10, label: '10h'),
      ],
    );

    test('maps values into the plot and clamps the ends', () {
      expect(axis.fractionFor(0), 0);
      expect(axis.fractionFor(5), 0.5);
      expect(axis.fractionFor(10), 1);
      expect(axis.fractionFor(-2), 0);
      expect(axis.fractionFor(12), 1);
    });

    test('handles an empty range without dividing by zero', () {
      const empty = ChartAxis(min: 4, max: 4, ticks: []);
      expect(empty.fractionFor(4), 0);
    });
  });

  test('computes the WCAG contrast ratio', () {
    expect(
      chartContrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      chartContrastRatio(const Color(0xFF112233), const Color(0xFF112233)),
      1,
    );
  });

  testWidgets('ChartScene frames the title, support, legend and semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      SizedBox(
        width: 320,
        child: ChartScene(
          title: 'Sleep duration',
          support: 'Week · 5 nights recorded · Goal 8h',
          semanticSummary: 'Average 7 hours 21 minutes across 3 nights.',
          legend: const [
            ChartLegendEntry(
              label: 'Sleep',
              mark: ChartLegendMark.bar,
              color: Color(0xFF252B81),
            ),
            ChartLegendEntry(
              label: 'Goal',
              mark: ChartLegendMark.line,
              color: Color(0xFF74777F),
            ),
          ],
          child: const ColoredBox(color: Color(0xFFEEEEEE)),
        ),
      ),
    );

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Week · 5 nights recorded · Goal 8h'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Average 7 hours 21 minutes across 3 nights.'),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<RepaintBoundary>(
            find.descendant(
              of: find.byType(ChartScene),
              matching: find.byType(RepaintBoundary),
            ),
          )
          .length,
      1,
    );

    handle.dispose();
  });

  testWidgets('ChartEmptyState explains an empty canvas', (tester) async {
    await pump(
      tester,
      const SizedBox(
        width: 320,
        height: 180,
        child: ChartEmptyState(message: 'No nights in this range'),
      ),
    );

    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.byIcon(M3EIcons.analytics_outlined), findsOneWidget);
  });

  testWidgets('plain tooltip follows the M3 measurements', (tester) async {
    await pump(tester, const ChartTooltip.plain(label: 'Today · 8h 13m'));

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(ChartTooltip),
        matching: find.byType(Container),
      ),
    );
    expect(
      container.padding,
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(ChartTooltip),
              matching: find.byType(Container),
            ),
          )
          .height,
      24,
    );
    final decoration = container.decoration! as BoxDecoration;
    final scheme = Sleepy3Theme.light().colorScheme;
    expect(decoration.color, scheme.inverseSurface);
    expect(decoration.borderRadius, BorderRadius.circular(4));
    expect(
      tester.widget<Text>(find.text('Today · 8h 13m')).style?.color,
      scheme.onInverseSurface,
    );
  });

  testWidgets('rich tooltip uses the surface container and 12dp corners', (
    tester,
  ) async {
    await pump(
      tester,
      const ChartTooltip.rich(
        title: 'Longest night',
        label: '8h 13m',
        supporting: 'Tuesday, October 20',
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(ChartTooltip),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final scheme = Sleepy3Theme.light().colorScheme;
    expect(decoration.color, scheme.surfaceContainer);
    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(container.padding, const EdgeInsets.fromLTRB(16, 12, 16, 8));
    expect(find.text('Longest night'), findsOneWidget);
    expect(find.text('8h 13m'), findsOneWidget);
    expect(find.text('Tuesday, October 20'), findsOneWidget);
  });

  testWidgets('tooltip layer sits 4dp above its anchor and flips below', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox(
        width: 300,
        height: 200,
        child: Stack(
          children: [
            SizedBox.expand(),
            ChartTooltipLayer(
              anchor: Offset(150, 100),
              child: SizedBox(
                width: 100,
                child: ChartTooltip.plain(label: 'Value'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final origin = tester.getTopLeft(find.byType(Stack).first);
    expect(
      tester.getTopLeft(find.byType(ChartTooltip)) - origin,
      const Offset(100, 72),
    );

    await pump(
      tester,
      const SizedBox(
        width: 300,
        height: 200,
        child: Stack(
          children: [
            SizedBox.expand(),
            ChartTooltipLayer(
              anchor: Offset(5, 10),
              child: SizedBox(
                width: 100,
                child: ChartTooltip.plain(label: 'Value'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final flippedOrigin = tester.getTopLeft(find.byType(Stack).first);
    expect(
      tester.getTopLeft(find.byType(ChartTooltip)) - flippedOrigin,
      const Offset(0, 14),
    );
  });

  testWidgets('scrub area selects the nearest slot and clears on release', (
    tester,
  ) async {
    final selections = <int?>[];
    await pump(
      tester,
      SizedBox(
        width: 200,
        height: 100,
        child: ChartScrubArea(
          slotCount: 4,
          enableHaptics: false,
          onSelectionChanged: selections.add,
          child: const SizedBox.expand(),
        ),
      ),
    );

    final origin = tester.getTopLeft(find.byType(ChartScrubArea));
    final gesture = await tester.startGesture(origin + const Offset(25, 50));
    await tester.pump(const Duration(milliseconds: 110));
    expect(selections, [0]);

    await gesture.moveTo(origin + const Offset(125, 50));
    await tester.pump();
    expect(selections, [0, 2]);

    await gesture.up();
    await tester.pump();
    expect(selections, [0, 2, null]);
  });

  testWidgets('scrub area can select on tap without capturing drags', (
    tester,
  ) async {
    final selections = <int?>[];
    await pump(
      tester,
      SizedBox(
        width: 200,
        height: 100,
        child: ChartScrubArea(
          slotCount: 4,
          axis: Axis.vertical,
          dragEnabled: false,
          enableHaptics: false,
          onSelectionChanged: selections.add,
          child: const SizedBox.expand(),
        ),
      ),
    );

    final origin = tester.getTopLeft(find.byType(ChartScrubArea));
    final gesture = await tester.startGesture(origin + const Offset(20, 70));
    await tester.pump(const Duration(milliseconds: 110));
    expect(selections, [2]);

    await gesture.moveTo(origin + const Offset(20, 30));
    await tester.pump();
    expect(selections, [2]);

    await gesture.up();
    await tester.pump();
    expect(selections, [2, null]);
  });

  testWidgets('scrub area maps the vertical axis to rows', (tester) async {
    final selections = <int?>[];
    await pump(
      tester,
      SizedBox(
        width: 200,
        height: 100,
        child: ChartScrubArea(
          slotCount: 4,
          axis: Axis.vertical,
          enableHaptics: false,
          onSelectionChanged: selections.add,
          child: const SizedBox.expand(),
        ),
      ),
    );

    final origin = tester.getTopLeft(find.byType(ChartScrubArea));
    final gesture = await tester.startGesture(origin + const Offset(20, 70));
    await tester.pump(const Duration(milliseconds: 110));
    expect(selections, [2]);
    await gesture.up();
    await tester.pump();
    expect(selections, [2, null]);
  });

  testWidgets('legend renders every mark and label', (tester) async {
    await pump(
      tester,
      const SizedBox(
        width: 320,
        child: ChartLegend(
          entries: [
            ChartLegendEntry(
              label: 'Bar',
              mark: ChartLegendMark.bar,
              color: Color(0xFF252B81),
            ),
            ChartLegendEntry(
              label: 'Line',
              mark: ChartLegendMark.line,
              color: Color(0xFF74777F),
            ),
            ChartLegendEntry(
              label: 'Dashed',
              mark: ChartLegendMark.dashed,
              color: Color(0xFF74777F),
            ),
            ChartLegendEntry(
              label: 'Band',
              mark: ChartLegendMark.band,
              color: Color(0xFFC6CCF7),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Bar'), findsOneWidget);
    expect(find.text('Line'), findsOneWidget);
    expect(find.text('Dashed'), findsOneWidget);
    expect(find.text('Band'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ChartLegend),
        matching: find.byType(CustomPaint),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('ChartFade jumps to the final opacity with reduced motion', (
    tester,
  ) async {
    await pump(
      tester,
      const ChartFade(visible: true, child: Text('Tooltip')),
      disableAnimations: true,
    );

    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(ChartFade),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('ChartFade uses the effects spring when motion is allowed', (
    tester,
  ) async {
    await pump(tester, const ChartFade(visible: true, child: Text('Tooltip')));

    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(ChartFade),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(fade.opacity.value, closeTo(1, 0.001));
  });

  testWidgets('spring progress jumps to 1 with reduced motion', (tester) async {
    final progress = ChartSpringProgress(
      vsync: const TestVSync(),
      reduceMotion: true,
    );
    addTearDown(progress.dispose);

    progress.restart();
    expect(progress.value, 1);
  });

  testWidgets('spring progress animates and can jump to a value', (
    tester,
  ) async {
    final progress = ChartSpringProgress(
      vsync: const TestVSync(),
      reduceMotion: false,
    );
    addTearDown(progress.dispose);

    progress.restart();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(progress.value, greaterThan(0));

    progress.jumpTo(1);
    await tester.pump();
    expect(progress.value, 1);
  });

  test('base painter maps the plot and value axis', () {
    final painter = _TestPainter(
      palette: _palette(),
      axis: const ChartAxis(
        min: 0,
        max: 10,
        ticks: [ChartTick(value: 0, label: '0h')],
      ),
    );

    final plot = painter.plotRect(const Size(300, 180));
    expect(plot.left, ChartDimensions.axisGutter);
    expect(plot.top, ChartDimensions.plotTopInset);
    expect(plot.right, 292);
    expect(plot.bottom, 156);
    expect(painter.yFor(0, plot), plot.bottom);
    expect(painter.yFor(10, plot), plot.top);
    expect(painter.yFor(5, plot), closeTo(82, 0.01));
  });

  testWidgets('base painter draws bars, rules and missing-data marks', (
    tester,
  ) async {
    await pump(
      tester,
      CustomPaint(
        size: const Size(300, 180),
        painter: _TestPainter(
          palette: _palette(),
          axis: const ChartAxis(
            min: 0,
            max: 10,
            ticks: [
              ChartTick(value: 0, label: '0h'),
              ChartTick(value: 5, label: '5h'),
              ChartTick(value: 10, label: '10h'),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

class _TestPainter extends ChartPainter {
  _TestPainter({required super.palette, required super.axis});

  @override
  void paintChart(Canvas canvas, Rect plot) {
    final slot = Rect.fromLTWH(plot.left + 8, plot.top, 24, plot.height);
    paintBar(canvas, plot, slot, value: 6, selected: true);
    paintNoDataMark(canvas, plot, slot.shift(const Offset(32, 0)));
    paintRule(
      canvas,
      plot,
      value: 8,
      color: palette.goalLine,
      label: 'Goal 8h',
      labelBackground: palette.surface,
    );
  }

  @override
  bool shouldRepaint(covariant _TestPainter oldDelegate) => true;
}

ChartPalette _palette() {
  return const ChartPalette(
    surface: Color(0xFFEFF4F9),
    bar: Color(0xFF252B81),
    goalLine: Color(0xFF74777F),
    averageLine: Color(0xFF3C5A78),
    grid: Color(0x9974777F),
    emptyMark: Color(0xFF74777F),
    selectionHalo: Color(0xFFDDE1FF),
    band: Color(0x33C6CCF7),
    axisLabel: TextStyle(color: Color(0xFF43474E)),
    legendLabel: TextStyle(color: Color(0xFF43474E)),
    plainTooltipContainer: Color(0xFF2F3033),
    plainTooltipLabel: TextStyle(color: Color(0xFFF1F0F4)),
    richTooltipContainer: Color(0xFFF1F0F4),
    richTooltipText: TextStyle(color: Color(0xFF43474E)),
    textScaler: TextScaler.noScaling,
  );
}
