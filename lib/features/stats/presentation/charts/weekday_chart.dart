import 'dart:math' as math;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../../sleep_tracking/domain/sleep_insights.dart';
import 'chart_axis.dart';
import 'chart_empty_state.dart';
import 'chart_format.dart';
import 'chart_motion.dart';
import 'chart_painter.dart';
import 'chart_scene.dart';
import 'chart_scrub_area.dart';
import 'chart_theme.dart';
import 'chart_tooltip.dart';

/// The average sleep for each weekday.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `titleMedium`
/// emphasized, `bodySmall` support and `labelSmall` axes.
/// My design decisions (not in M3): the 180dp canvas, the 4dp bar radius and
/// the small `Best` label above the longest day. M3 has no chart component.
class WeekdayChart extends StatelessWidget {
  const WeekdayChart({super.key, required this.insights});

  final SleepInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = chartRangeLabel(l10n, insights.range);
    final hasData = insights.weekdayStats.any((stat) => stat != null);

    return ChartScene(
      title: l10n.chartWeekdayTitle,
      support: l10n.chartWeekdaySupport(range),
      semanticSummary: _spokenSummary(context, range),
      child: hasData
          ? _WeekdayChartBody(insights: insights)
          : ChartEmptyState(message: l10n.noNightsInRange),
    );
  }

  String _spokenSummary(BuildContext context, String range) {
    final l10n = context.l10n;
    final best = _bestWeekday(insights);
    if (best == null) return l10n.noNightsInRange;

    final count = insights.weekdayStats.where((stat) => stat != null).length;
    return l10n.chartWeekdaySpoken(
      range,
      chartWeekdayLong(l10n, best.weekday),
      l10n.formatSpokenSleepDuration(best.average),
      count,
    );
  }
}

SleepWeekdayStat? _bestWeekday(SleepInsights insights) {
  SleepWeekdayStat? best;
  for (final stat in insights.weekdayStats) {
    if (stat == null) continue;
    if (best == null || stat.average > best.average) best = stat;
  }
  return best;
}

class _WeekdayChartBody extends StatefulWidget {
  const _WeekdayChartBody({required this.insights});

  final SleepInsights insights;

  @override
  State<_WeekdayChartBody> createState() => _WeekdayChartBodyState();
}

class _WeekdayChartBodyState extends State<_WeekdayChartBody>
    with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  late final AnimationController _selectionController = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
  );

  List<double?> _fromValues = const [];
  List<double?> _toValues = const [];
  bool _reduceMotion = false;
  bool _started = false;
  int? _selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = ChartMotion.isReduced(context);

    if (!_started) {
      _started = true;
      _reduceMotion = reduceMotion;
      _toValues = _valuesFor(widget.insights);
      if (reduceMotion) {
        _progress.value = 1;
      } else {
        ChartMotion.springTo(_progress, to: 1);
      }
      return;
    }

    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _progress.stop();
      _progress.value = 1;
    } else {
      ChartMotion.springTo(_progress, to: 1);
    }
  }

  @override
  void didUpdateWidget(_WeekdayChartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameData(oldWidget.insights, widget.insights)) return;

    setState(() {
      _fromValues = _displayedValues();
      _toValues = _valuesFor(widget.insights);
      _selectedIndex = null;
      _selectionController.value = 0;
    });
    _progress.stop();
    _progress.value = 0;
    if (_reduceMotion) {
      _progress.value = 1;
    } else {
      ChartMotion.springTo(_progress, to: 1);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  List<double?> _valuesFor(SleepInsights insights) {
    return [
      for (final stat in insights.weekdayStats)
        stat?.average.inMinutes.toDouble(),
    ];
  }

  List<double?> _displayedValues() {
    final count = math.max(_fromValues.length, _toValues.length);
    final progress = _progress.value.clamp(0.0, 1.0).toDouble();
    return [
      for (var index = 0; index < count; index++)
        if ((index < _fromValues.length ? _fromValues[index] : null) != null ||
            (index < _toValues.length ? _toValues[index] : null) != null)
          _interpolate(index, progress)
        else
          null,
    ];
  }

  double _interpolate(int index, double progress) {
    final from = index < _fromValues.length ? _fromValues[index] : null;
    final to = index < _toValues.length ? _toValues[index] : null;
    if (from == null && to == null) return 0;
    final start = from ?? to!;
    final end = to ?? from!;
    return start + (end - start) * progress;
  }

  bool _sameData(SleepInsights a, SleepInsights b) {
    if (a.range != b.range || a.weekdayStats.length != b.weekdayStats.length) {
      return false;
    }
    for (var index = 0; index < a.weekdayStats.length; index++) {
      final left = a.weekdayStats[index];
      final right = b.weekdayStats[index];
      if (left?.weekday != right?.weekday ||
          left?.nights != right?.nights ||
          left?.average != right?.average) {
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
    final l10n = context.l10n;
    final palette = ChartPalette.of(context);
    final axis = _buildAxis(context);
    final labels = [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        chartWeekdayShort(l10n, weekday),
    ];
    final bestIndex = _bestIndex(_toValues);

    return AnimatedBuilder(
      animation: Listenable.merge([_progress, _selectionController]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth,
              constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : ChartDimensions.canvasHeight,
            );
            final painter = _WeekdayChartPainter(
              palette: palette,
              axis: axis,
              fromValues: _fromValues,
              toValues: _toValues,
              progress: _progress.value,
              selectionProgress: _selectionController.value,
              selectedIndex: _selectedIndex,
              labels: labels,
              bestIndex: bestIndex,
              bestLabel: l10n.chartWeekdayBest,
            );
            final plot = painter.plotRect(size);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ChartScrubArea(
                    slotCount: 7,
                    selectionInsets: const EdgeInsets.only(
                      left: ChartDimensions.axisGutter,
                      right: ChartDimensions.plotRightInset,
                    ),
                    onSelectionChanged: _onSelectionChanged,
                    child: CustomPaint(painter: painter),
                  ),
                ),
                if (_selectedIndex case final index?)
                  _tooltipLayer(context, plot, index, painter),
              ],
            );
          },
        );
      },
    );
  }

  int? _bestIndex(List<double?> values) {
    int? best;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value == null) continue;
      if (best == null || value > values[best]!) best = index;
    }
    return best;
  }

  ChartAxis _buildAxis(BuildContext context) {
    final l10n = context.l10n;
    var maxMinutes = dailySleepGoal.inMinutes.toDouble();
    for (final value in [..._fromValues, ..._toValues]) {
      if (value != null && value > maxMinutes) maxMinutes = value;
    }
    final maxHours = math.max(8, ((maxMinutes + 60) / 60 / 2).ceil() * 2);
    final dense = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final step = dense ? 4 : 2;
    return ChartAxis(
      min: 0,
      max: maxHours * 60,
      ticks: [
        for (var hour = 0; hour <= maxHours; hour += step)
          ChartTick(value: hour * 60, label: l10n.durationHours(hour)),
      ],
    );
  }

  Widget _tooltipLayer(
    BuildContext context,
    Rect plot,
    int index,
    ChartPainter painter,
  ) {
    final l10n = context.l10n;
    final weekday = DateTime.monday + index;
    final stat = widget.insights.weekdayStats[index];
    final slotWidth = plot.width / 7;
    final value = index < _toValues.length ? _toValues[index] : null;
    final anchor = Offset(
      plot.left + (index + 0.5) * slotWidth,
      value == null ? plot.bottom : painter.yFor(value, plot),
    );

    if (stat == null) {
      return ChartTooltipLayer(
        key: ValueKey('weekday-tooltip-$index-${widget.insights.range.name}'),
        anchor: anchor,
        child: ChartTooltip.plain(
          label: l10n.chartTooltipNoData(chartWeekdayLong(l10n, weekday)),
        ),
      );
    }

    return ChartTooltipLayer(
      key: ValueKey('weekday-tooltip-$index-${widget.insights.range.name}'),
      anchor: anchor,
      child: ChartTooltip.rich(
        title: chartWeekdayLong(l10n, weekday),
        label: l10n.formatSleepDuration(stat.average),
        supporting: l10n.chartTooltipNights(stat.nights),
      ),
    );
  }
}

class _WeekdayChartPainter extends ChartPainter {
  _WeekdayChartPainter({
    required super.palette,
    required super.axis,
    required this.fromValues,
    required this.toValues,
    required this.progress,
    required this.selectionProgress,
    required this.selectedIndex,
    required this.labels,
    required this.bestIndex,
    required this.bestLabel,
  });

  final List<double?> fromValues;
  final List<double?> toValues;
  final double progress;
  final double selectionProgress;
  final int? selectedIndex;
  final List<String> labels;
  final int? bestIndex;
  final String bestLabel;

  @override
  void paintChart(Canvas canvas, Rect plot) {
    final t = progress;
    final fade = t.clamp(0.0, 1.0).toDouble();
    final count = math.max(fromValues.length, toValues.length);
    final fromSlotWidth = fromValues.isEmpty
        ? 0.0
        : plot.width / fromValues.length;
    final toSlotWidth = toValues.isEmpty ? 0.0 : plot.width / toValues.length;

    for (var index = 0; index < count; index++) {
      final from = index < fromValues.length ? fromValues[index] : null;
      final to = index < toValues.length ? toValues[index] : null;
      final fromHas = from != null;
      final toHas = to != null;
      final both = fromHas && toHas;
      final opacity = both ? 1.0 : (toHas ? fade : 1 - fade);
      if (opacity <= 0) continue;

      final fromCenter =
          plot.left + (index + 0.5) * (fromValues.isEmpty ? 0 : fromSlotWidth);
      final toCenter =
          plot.left + (index + 0.5) * (toValues.isEmpty ? 0 : toSlotWidth);
      final center = both
          ? fromCenter + (toCenter - fromCenter) * t
          : (toHas ? toCenter : fromCenter);
      final width = both
          ? fromSlotWidth + (toSlotWidth - fromSlotWidth) * t
          : (toHas ? toSlotWidth : fromSlotWidth);
      final slot = Rect.fromCenter(
        center: Offset(center, plot.center.dy),
        width: width,
        height: plot.height,
      );

      if (both) {
        paintBar(
          canvas,
          plot,
          slot,
          value: from + (to - from) * t,
          selected: selectedIndex == index,
          selectionProgress: selectionProgress,
          opacity: 1,
        );
      } else if (toHas) {
        paintBar(
          canvas,
          plot,
          slot,
          value: to,
          selected: selectedIndex == index,
          selectionProgress: selectionProgress,
          opacity: fade,
        );
      } else if (fromHas) {
        paintBar(
          canvas,
          plot,
          slot,
          value: from,
          selected: false,
          opacity: 1 - fade,
        );
      } else {
        paintNoDataMark(canvas, plot, slot, opacity: fade);
      }
    }

    _paintBestLabel(canvas, plot, t);
    paintXAxisLabels(canvas, plot, [
      for (var index = 0; index < labels.length && index < count; index++)
        ChartXLabel(
          center:
              plot.left +
              (index + 0.5) *
                  (toValues.isEmpty ? 0 : plot.width / toValues.length),
          label: labels[index],
        ),
    ]);
  }

  void _paintBestLabel(Canvas canvas, Rect plot, double progress) {
    final index = bestIndex;
    if (index == null || index >= toValues.length) return;
    final value = toValues[index];
    if (value == null) return;

    final slotWidth = plot.width / toValues.length;
    final centerX = plot.left + (index + 0.5) * slotWidth;
    final barTop = yFor(value, plot);
    final text = textPainter(
      bestLabel,
      palette.axisLabel.copyWith(color: palette.bar),
    );
    final left = (centerX - text.width / 2)
        .clamp(plot.left, plot.right - text.width)
        .toDouble();
    var top = barTop - text.height - 2;
    if (top < plot.top) top = math.min(plot.bottom - text.height, barTop + 2);
    final opacity = progress.clamp(0.0, 1.0).toDouble();

    canvas.drawRect(
      Rect.fromLTWH(left - 2, top - 1, text.width + 4, text.height + 2),
      Paint()..color = palette.surface.withValues(alpha: opacity),
    );
    final faded = textPainter(
      bestLabel,
      palette.axisLabel.copyWith(color: palette.bar.withValues(alpha: opacity)),
    );
    faded.paint(canvas, Offset(left, top));
  }

  @override
  bool shouldRepaint(covariant _WeekdayChartPainter oldDelegate) => true;
}
