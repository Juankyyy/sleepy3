import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../../../sleep_tracking/domain/sleep_insights.dart';
import 'chart_axis.dart';
import 'chart_empty_state.dart';
import 'chart_format.dart';
import 'chart_legend.dart';
import 'chart_motion.dart';
import 'chart_painter.dart';
import 'chart_scene.dart';
import 'chart_scrub_area.dart';
import 'chart_theme.dart';
import 'chart_tooltip.dart';

/// The Sleep duration chart on Stats.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `titleMedium`
/// emphasized, `bodySmall` support, `labelSmall` axes and `onSurfaceVariant`
/// for the secondary text.
/// My design decisions (not in M3): the 180dp canvas, 4dp bar radius, 4h grid
/// step, 16ms entry stagger and 2% selected-bar scale. M3 publishes no chart
/// component and no stagger value.
class SleepDurationChart extends StatelessWidget {
  const SleepDurationChart({
    super.key,
    required this.insights,
    this.historyLimited = false,
    this.showHeader = true,
  });

  final SleepInsights insights;

  /// Whether the selected range is wider than the Health Connect history
  /// permission allows. The card then names the 30 available days instead of
  /// the range the chips show.
  final bool historyLimited;

  /// Whether to draw the title and supporting line inside the card.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = ChartPalette.of(context);
    final goal = l10n.formatGoalDelta(dailySleepGoal);
    final range = chartRangeLabel(l10n, insights.range);
    final supportRange = historyLimited
        ? l10n.historyLast30DaysAvailable
        : range;
    final spokenRange = historyLimited ? l10n.historyLast30DaysRange : range;

    return ChartScene(
      title: l10n.chartSleepDurationTitle,
      support: l10n.chartSleepDurationSupport(
        supportRange,
        insights.recordedDays,
        goal,
      ),
      semanticSummary: _spokenSummary(context, spokenRange, goal),
      showHeader: showHeader,
      legend: insights.hasData
          ? [
              ChartLegendEntry(
                label: l10n.chartLegendSleep,
                mark: ChartLegendMark.bar,
                color: palette.bar,
              ),
              ChartLegendEntry(
                label: l10n.chartGoalLabel(goal),
                mark: ChartLegendMark.line,
                color: palette.goalLine,
              ),
              ChartLegendEntry(
                label: l10n.chartLegendAverage,
                mark: ChartLegendMark.line,
                color: palette.averageLine,
              ),
            ]
          : const [],
      child: insights.hasData
          ? _SleepDurationChartBody(insights: insights)
          : ChartEmptyState(message: l10n.noNightsInRange),
    );
  }

  String _spokenSummary(BuildContext context, String range, String goal) {
    final l10n = context.l10n;
    final average = insights.average;
    if (average == null) return l10n.noNightsInRange;

    final dates = DateFormat.MMMEd(l10n.localeName);
    final best = insights.bestDay;
    final worst = insights.worstDay;
    final missing = math.max(0, insights.windowDays - insights.recordedDays);

    return l10n.chartDurationSpoken(
      range,
      l10n.formatSpokenSleepDuration(average),
      best == null ? '—' : dates.format(best.date),
      worst == null ? '—' : dates.format(worst.date),
      insights.shortNights,
      missing,
      goal,
    );
  }
}

class _SleepDurationChartBody extends StatefulWidget {
  const _SleepDurationChartBody({required this.insights});

  final SleepInsights insights;

  @override
  State<_SleepDurationChartBody> createState() =>
      _SleepDurationChartBodyState();
}

class _SleepDurationChartBodyState extends State<_SleepDurationChartBody>
    with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _selectionController = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
  );
  late final SpringSimulation _barSpring = SpringSimulation(
    M3EMotion.expressiveSpatialDefault.toDescription(),
    0,
    1,
    0,
  );
  late final SpringSimulation _fadeSpring = SpringSimulation(
    M3EMotion.effectsFast.toDescription(),
    0,
    1,
    0,
  );

  List<SleepChartBucket> _fromBuckets = const [];
  List<SleepChartBucket> _toBuckets = const [];
  List<double?> _fromValues = const [];
  List<double?> _toValues = const [];
  SleepHistoryRange? _fromRange;
  SleepHistoryRange? _toRange;
  Duration? _fromAverage;
  Duration? _toAverage;

  Duration _elapsed = Duration.zero;
  bool _reduceMotion = false;
  bool _started = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _toBuckets = widget.insights.chartBuckets;
    _toValues = _valuesFor(_toBuckets);
    _toRange = widget.insights.range;
    _toAverage = widget.insights.average;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = ChartMotion.isReduced(context);
    if (!_started) {
      _started = true;
      _reduceMotion = reduceMotion;
      if (!reduceMotion) _startTicker();
      return;
    }
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _ticker.stop();
    } else {
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(_SleepDurationChartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameData(oldWidget.insights, widget.insights)) return;

    final currentValues = _displayedValues();
    final currentAverage = _displayedAverage();
    setState(() {
      _fromBuckets = _toBuckets;
      _fromValues = currentValues;
      _fromRange = _toRange;
      _fromAverage = currentAverage;
      _toBuckets = widget.insights.chartBuckets;
      _toValues = _valuesFor(_toBuckets);
      _toRange = widget.insights.range;
      _toAverage = widget.insights.average;
      _selectedIndex = null;
      _selectionController.value = 0;
    });
    _startTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _elapsed = Duration.zero;
    if (_reduceMotion) return;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    setState(() => _elapsed = elapsed);
    if (_settled(elapsed)) _ticker.stop();
  }

  bool _settled(Duration elapsed) {
    if (_reduceMotion) return true;
    final seconds = elapsed.inMicroseconds / 1e6;
    if (!_fadeSpring.isDone(seconds)) return false;

    final count = math.max(_fromValues.length, _toValues.length);
    if (count == 0) return true;
    final lastStart =
        (count - 1) * ChartMotion.staggerStep.inMicroseconds / 1e6;
    final lastTime = seconds - lastStart;
    return lastTime > 0 && _barSpring.isDone(lastTime);
  }

  List<double?> _valuesFor(List<SleepChartBucket> buckets) {
    return [
      for (final bucket in buckets)
        bucket.averageDuration?.inMinutes.toDouble(),
    ];
  }

  List<double?> _displayedValues() {
    final count = math.max(_fromValues.length, _toValues.length);
    return [
      for (var index = 0; index < count; index++)
        if ((index < _fromValues.length ? _fromValues[index] : null) != null ||
            (index < _toValues.length ? _toValues[index] : null) != null)
          _interpolateValue(index)
        else
          null,
    ];
  }

  double _interpolateValue(int index) {
    final progress = _barProgress(index);
    final from = index < _fromValues.length ? _fromValues[index] ?? 0 : 0;
    final to = index < _toValues.length ? _toValues[index] ?? 0 : 0;
    return from + (to - from) * progress;
  }

  Duration? _displayedAverage() {
    final from = _fromAverage?.inMinutes.toDouble();
    final to = _toAverage?.inMinutes.toDouble();
    if (from == null && to == null) return null;
    final progress = _averageProgress();
    final start = from ?? to!;
    final end = to ?? from!;
    return Duration(minutes: (start + (end - start) * progress).round());
  }

  double _barProgress(int index) {
    if (_reduceMotion) return 1;
    final seconds = _elapsed.inMicroseconds / 1e6;
    final delay = index * ChartMotion.staggerStep.inMicroseconds / 1e6;
    final local = seconds - delay;
    if (local <= 0) return 0;
    return _barSpring.x(local);
  }

  double _averageProgress() {
    if (_reduceMotion) return 1;
    return _barSpring.x(_elapsed.inMicroseconds / 1e6).clamp(0.0, 1.0);
  }

  double _fadeProgress() {
    if (_reduceMotion) return 1;
    return _fadeSpring.x(_elapsed.inMicroseconds / 1e6).clamp(0.0, 1.0);
  }

  bool _sameData(SleepInsights a, SleepInsights b) {
    if (a.range != b.range ||
        a.recordedDays != b.recordedDays ||
        a.total != b.total ||
        a.average != b.average ||
        a.chartBuckets.length != b.chartBuckets.length) {
      return false;
    }

    for (var index = 0; index < a.chartBuckets.length; index++) {
      final left = a.chartBuckets[index];
      final right = b.chartBuckets[index];
      if (left.start != right.start ||
          left.averageDuration != right.averageDuration ||
          left.recordedDays != right.recordedDays ||
          left.sessionsCount != right.sessionsCount) {
        return false;
      }
    }
    return true;
  }

  void _onSelectionChanged(int? index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (_reduceMotion) {
      _selectionController.value = index == null ? 0 : 1;
      return;
    }
    ChartMotion.springTo(
      _selectionController,
      to: index == null ? 0 : 1,
      spring: M3EMotion.expressiveSpatialPress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final l10n = context.l10n;
    final goal = dailySleepGoal;
    final goalLabel = l10n.chartGoalLabel(l10n.formatGoalDelta(goal));
    final averageLabel = l10n.chartAverageLabel;
    final axis = _buildAxis(context);
    final count = math.max(_fromBuckets.length, _toBuckets.length);
    final barProgress = [
      for (var index = 0; index < count; index++) _barProgress(index),
    ];
    final fade = _fadeProgress();
    final averageProgress = _averageProgress();
    final dense = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final fromLabels = _labelsFor(_fromBuckets, _fromRange, dense);
    final toLabels = _labelsFor(_toBuckets, _toRange, dense);

    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth,
              constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : ChartDimensions.canvasHeight,
            );
            final painter = _DurationChartPainter(
              palette: palette,
              axis: axis,
              fromBuckets: _fromBuckets,
              toBuckets: _toBuckets,
              fromValues: _fromValues,
              toValues: _toValues,
              fromLabels: fromLabels,
              toLabels: toLabels,
              fromAverage: _fromAverage,
              toAverage: _toAverage,
              barProgress: barProgress,
              fadeProgress: fade,
              averageProgress: averageProgress,
              goal: goal,
              goalLabel: goalLabel,
              averageLabel: averageLabel,
              selectedIndex: _selectedIndex,
              selectionProgress: _selectionController.value,
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ChartScrubArea(
                    slotCount: _toBuckets.length,
                    selectionInsets: const EdgeInsets.only(
                      left: ChartDimensions.axisGutter,
                      right: ChartDimensions.plotRightInset,
                    ),
                    onSelectionChanged: _onSelectionChanged,
                    child: CustomPaint(painter: painter),
                  ),
                ),
                if (_selectedIndex case final index?)
                  if (index < _toBuckets.length)
                    _tooltipLayer(context, painter, index, size),
              ],
            );
          },
        );
      },
    );
  }

  ChartAxis _buildAxis(BuildContext context) {
    final l10n = context.l10n;
    var maxMinutes = dailySleepGoal.inMinutes.toDouble();
    for (final value in [..._fromValues, ..._toValues]) {
      if (value != null && value > maxMinutes) maxMinutes = value;
    }
    final fromAverage = _fromAverage?.inMinutes.toDouble();
    final toAverage = _toAverage?.inMinutes.toDouble();
    if (fromAverage != null && fromAverage > maxMinutes) {
      maxMinutes = fromAverage;
    }
    if (toAverage != null && toAverage > maxMinutes) maxMinutes = toAverage;
    final maxHours = math.max(12, ((maxMinutes + 60) / 60 / 4).ceil() * 4);
    final dense = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final step = dense ? 8 : 4;
    final ticks = [
      for (var hour = 0; hour <= maxHours; hour += step)
        ChartTick(value: hour * 60, label: l10n.durationHours(hour)),
    ];
    if (ticks.last.value < maxHours * 60) {
      ticks.add(
        ChartTick(value: maxHours * 60, label: l10n.durationHours(maxHours)),
      );
    }

    return ChartAxis(min: 0, max: maxHours * 60, ticks: ticks);
  }

  List<String?> _labelsFor(
    List<SleepChartBucket> buckets,
    SleepHistoryRange? range,
    bool dense,
  ) {
    if (buckets.isEmpty) return const [];
    final span = _spanFor(buckets);
    final interval = _labelInterval(span, buckets.length, range, dense);
    final locale = context.l10n.localeName;
    final day = DateFormat.E(locale);
    final dayOfMonth = DateFormat.d(locale);
    final monthDay = DateFormat.MMMd(locale);
    final month = DateFormat.MMM(locale);

    return [
      for (var index = 0; index < buckets.length; index++)
        if (index % interval == 0)
          switch (span) {
            _BucketSpan.day =>
              range == SleepHistoryRange.week
                  ? day.format(buckets[index].start)
                  : dayOfMonth.format(buckets[index].start),
            _BucketSpan.week => monthDay.format(buckets[index].start),
            _BucketSpan.month => month.format(buckets[index].start),
          }
        else
          null,
    ];
  }

  int _labelInterval(
    _BucketSpan span,
    int count,
    SleepHistoryRange? range,
    bool dense,
  ) {
    switch (span) {
      case _BucketSpan.day:
        if (range == SleepHistoryRange.week) return dense ? 2 : 1;
        return dense ? 10 : 5;
      case _BucketSpan.week:
        return math.max(1, (count / (dense ? 4 : 6)).ceil());
      case _BucketSpan.month:
        return math.max(1, (count / (dense ? 4 : 6)).ceil());
    }
  }

  _BucketSpan _spanFor(List<SleepChartBucket> buckets) {
    final days = buckets.first.endExclusive
        .difference(buckets.first.start)
        .inDays;
    if (days <= 1) return _BucketSpan.day;
    if (days <= 8) return _BucketSpan.week;
    return _BucketSpan.month;
  }

  Widget _tooltipLayer(
    BuildContext context,
    _DurationChartPainter painter,
    int index,
    Size size,
  ) {
    final l10n = context.l10n;
    final plot = painter.plotRect(size);
    final count = _toBuckets.length;
    final center = plot.left + (index + 0.5) * plot.width / count;
    final value = index < _toValues.length ? _toValues[index] : null;
    final anchor = Offset(
      center,
      value == null || value <= 0 ? plot.bottom : painter.yFor(value, plot),
    );
    final bucket = _toBuckets[index];
    final duration = bucket.averageDuration;
    final useRich =
        _spanFor([bucket]) != _BucketSpan.day &&
        duration != null &&
        duration > Duration.zero;

    return ChartTooltipLayer(
      key: ValueKey('sleep-duration-tooltip-$index-${_toRange?.name}'),
      anchor: anchor,
      child: useRich
          ? ChartTooltip.rich(
              title: _bucketRange(context, bucket),
              label: l10n.chartTooltipAverageValue(
                l10n.formatSleepDuration(duration),
              ),
              supporting: l10n.chartTooltipNights(bucket.recordedDays),
            )
          : ChartTooltip.plain(label: _tooltipLabel(context, bucket)),
    );
  }

  String _bucketRange(BuildContext context, SleepChartBucket bucket) {
    final dates = DateFormat.MMMd(context.l10n.localeName);
    final end = bucket.endExclusive.subtract(const Duration(days: 1));
    return '${dates.format(bucket.start)} – ${dates.format(end)}';
  }

  String _tooltipLabel(BuildContext context, SleepChartBucket bucket) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final duration = bucket.averageDuration;
    final span = _spanFor([bucket]);

    if (span == _BucketSpan.day) {
      final date = DateFormat.MMMEd(locale).format(bucket.start);
      if (duration == null || duration <= Duration.zero) {
        return l10n.chartTooltipNoData(date);
      }
      if (bucket.sessionsCount > 1) {
        return l10n.chartTooltipSessions(
          date,
          l10n.formatSleepDuration(duration),
          bucket.sessionsCount,
        );
      }
      return l10n.chartTooltipDate(date, l10n.formatSleepDuration(duration));
    }

    final bucketRange = _bucketRange(context, bucket);
    if (duration == null || duration <= Duration.zero) {
      return l10n.chartTooltipNoData(bucketRange);
    }
    return l10n.chartTooltipDate(
      bucketRange,
      l10n.formatSleepDuration(duration),
    );
  }
}

enum _BucketSpan { day, week, month }

class _DurationChartPainter extends ChartPainter {
  _DurationChartPainter({
    required super.palette,
    required super.axis,
    required this.fromBuckets,
    required this.toBuckets,
    required this.fromValues,
    required this.toValues,
    required this.fromLabels,
    required this.toLabels,
    required this.fromAverage,
    required this.toAverage,
    required this.barProgress,
    required this.fadeProgress,
    required this.averageProgress,
    required this.goal,
    required this.goalLabel,
    required this.averageLabel,
    required this.selectedIndex,
    required this.selectionProgress,
  });

  final List<SleepChartBucket> fromBuckets;
  final List<SleepChartBucket> toBuckets;
  final List<double?> fromValues;
  final List<double?> toValues;
  final List<String?> fromLabels;
  final List<String?> toLabels;
  final Duration? fromAverage;
  final Duration? toAverage;
  final List<double> barProgress;
  final double fadeProgress;
  final double averageProgress;
  final Duration goal;
  final String goalLabel;
  final String averageLabel;
  final int? selectedIndex;
  final double selectionProgress;

  @override
  void paintChart(Canvas canvas, Rect plot) {
    final fade = fadeProgress.clamp(0.0, 1.0);
    final count = math.max(fromBuckets.length, toBuckets.length);
    final fromCount = fromBuckets.length;
    final toCount = toBuckets.length;
    final fromSlotWidth = fromCount == 0 ? 0.0 : plot.width / fromCount;
    final toSlotWidth = toCount == 0 ? 0.0 : plot.width / toCount;

    for (var index = 0; index < count; index++) {
      final fromHas = index < fromBuckets.length && _hasBar(fromBuckets[index]);
      final toHas = index < toBuckets.length && _hasBar(toBuckets[index]);
      final progress = index < barProgress.length ? barProgress[index] : 1;
      final fromValue = index < fromValues.length
          ? fromValues[index] ?? 0.0
          : 0.0;
      final toValue = index < toValues.length ? toValues[index] ?? 0.0 : 0.0;
      final toCenter =
          plot.left + (index + 0.5) * (toCount == 0 ? 0 : toSlotWidth);

      if (toHas) {
        final fromCenter =
            plot.left + (index + 0.5) * (fromCount == 0 ? 0 : fromSlotWidth);
        final center = fromHas
            ? fromCenter + (toCenter - fromCenter) * progress
            : toCenter;
        final width = fromHas
            ? fromSlotWidth + (toSlotWidth - fromSlotWidth) * progress
            : toSlotWidth;
        final bar = fromValue + (toValue - fromValue) * progress;
        paintBar(
          canvas,
          plot,
          Rect.fromCenter(
            center: Offset(center, plot.center.dy),
            width: width,
            height: plot.height,
          ),
          value: bar,
          selected: selectedIndex == index,
          selectionProgress: selectionProgress,
          opacity: fromHas ? 1 : fade,
        );
      } else if (fromHas) {
        final fromCenter =
            plot.left + (index + 0.5) * (fromCount == 0 ? 0 : fromSlotWidth);
        paintBar(
          canvas,
          plot,
          Rect.fromCenter(
            center: Offset(fromCenter, plot.center.dy),
            width: fromSlotWidth,
            height: plot.height,
          ),
          value: fromValue,
          opacity: 1 - fade,
        );
      } else if (index < toCount) {
        paintNoDataMark(
          canvas,
          plot,
          Rect.fromCenter(
            center: Offset(toCenter, plot.center.dy),
            width: toSlotWidth,
            height: plot.height,
          ),
          opacity: fade,
        );
      }
    }

    final average = _averageValue();
    final goalY = yFor(goal.inMinutes.toDouble(), plot);
    if (average != null) {
      final averageY = yFor(average, plot);
      paintRule(
        canvas,
        plot,
        value: average,
        color: palette.averageLine,
        label: averageLabel,
        labelBackground: palette.surface,
        labelBelow: (goalY - averageY).abs() < 20,
      );
    }
    paintRule(
      canvas,
      plot,
      value: goal.inMinutes.toDouble(),
      color: palette.goalLine,
      label: goalLabel,
      labelBackground: palette.surface,
    );

    if (fade < 1) {
      paintXAxisLabels(
        canvas,
        plot,
        _labels(fromLabels, fromCount, plot),
        opacity: 1 - fade,
      );
    }
    paintXAxisLabels(
      canvas,
      plot,
      _labels(toLabels, toCount, plot),
      opacity: fade,
    );
  }

  double? _averageValue() {
    final from = fromAverage?.inMinutes.toDouble();
    final to = toAverage?.inMinutes.toDouble();
    if (from == null && to == null) return null;
    final start = from ?? to!;
    final end = to ?? from!;
    return start + (end - start) * averageProgress;
  }

  bool _hasBar(SleepChartBucket bucket) {
    final duration = bucket.averageDuration;
    return bucket.hasData && duration != null && duration > Duration.zero;
  }

  List<ChartXLabel> _labels(List<String?> labels, int count, Rect plot) {
    if (count == 0) return const [];
    final slotWidth = plot.width / count;
    return [
      for (var index = 0; index < count; index++)
        if (index < labels.length && labels[index] != null)
          ChartXLabel(
            center: plot.left + (index + 0.5) * slotWidth,
            label: labels[index]!,
          ),
    ];
  }

  @override
  bool shouldRepaint(covariant _DurationChartPainter oldDelegate) => true;
}
