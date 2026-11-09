import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
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

/// The Sleep window chart on Stats.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `titleMedium`
/// emphasized, `bodySmall` support, `labelSmall` axes and `onSurfaceVariant`
/// for the secondary text.
/// My design decisions (not in M3): the 24dp minimum row, the 8dp capsule, the
/// 6dp range bands and the tap-only selection. The row count follows the range
/// buckets, so the card grows instead of squeezing thirty nights into 180dp.
class SleepWindowChart extends StatelessWidget {
  const SleepWindowChart({
    super.key,
    required this.insights,
    this.historyLimited = false,
  });

  final SleepInsights insights;

  /// Whether the selected range is wider than the Health Connect history
  /// permission allows. The card then names the 30 available days instead of
  /// the range the chips show.
  final bool historyLimited;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = ChartPalette.of(context);
    final range = chartRangeLabel(l10n, insights.range);
    final supportRange = historyLimited
        ? l10n.historyLast30DaysAvailable
        : range;
    final spokenRange = historyLimited ? l10n.historyLast30DaysRange : range;
    final scaler = MediaQuery.textScalerOf(context);
    final rowHeight = math.max(24.0, scaler.scale(12) + 10);
    final bottomInset = math.max(
      ChartDimensions.plotBottomInset,
      scaler.scale(ChartDimensions.plotBottomInset),
    );
    final hasData = insights.chartBuckets.any(_hasWindowData);
    // An empty range keeps the compact 180dp canvas; only a chart with rows
    // grows to fit every bucket.
    final canvasHeight = hasData
        ? ChartDimensions.plotTopInset +
              insights.chartBuckets.length * rowHeight +
              bottomInset
        : ChartDimensions.canvasHeight;

    return ChartScene(
      title: l10n.chartSleepWindowTitle,
      support: l10n.chartSleepWindowSupport(supportRange),
      semanticSummary: _spokenSummary(context, spokenRange),
      canvasHeight: canvasHeight,
      legend: hasData
          ? [
              ChartLegendEntry(
                label: l10n.chartLegendWindow,
                mark: ChartLegendMark.bar,
                color: palette.bar,
              ),
              ChartLegendEntry(
                label: l10n.chartLegendRange,
                mark: ChartLegendMark.band,
                color: palette.selectionHalo,
              ),
              ChartLegendEntry(
                label: l10n.chartLegendAverage,
                mark: ChartLegendMark.line,
                color: palette.averageLine,
              ),
            ]
          : const [],
      child: hasData
          ? _SleepWindowChartBody(insights: insights)
          : ChartEmptyState(message: l10n.noNightsInRange),
    );
  }

  bool _hasWindowData(SleepChartBucket bucket) {
    final bedtime = bucket.averageBedtime;
    final wake = bucket.averageWake;
    return bucket.hasData && bedtime != null && wake != null;
  }

  String _spokenSummary(BuildContext context, String range) {
    final l10n = context.l10n;
    final bedtime = insights.averageBedtime;
    final wake = insights.averageWake;
    if (bedtime == null || wake == null) return l10n.noNightsInRange;

    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final missing = math.max(0, insights.windowDays - insights.recordedDays);
    return l10n.chartWindowSpoken(
      range,
      chartClockLabel(
        l10n: l10n,
        time: bedtime,
        use24HourFormat: use24HourFormat,
      ),
      chartClockLabel(l10n: l10n, time: wake, use24HourFormat: use24HourFormat),
      missing,
    );
  }
}

class _SleepWindowChartBody extends StatefulWidget {
  const _SleepWindowChartBody({required this.insights});

  final SleepInsights insights;

  @override
  State<_SleepWindowChartBody> createState() => _SleepWindowChartBodyState();
}

class _SleepWindowChartBodyState extends State<_SleepWindowChartBody>
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

  List<_WindowRow> _fromRows = const [];
  List<_WindowRow> _toRows = const [];
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
      _toRows = _rowsFor(widget.insights);
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
  void didUpdateWidget(_SleepWindowChartBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameData(oldWidget.insights, widget.insights)) return;

    final current = _currentRows();
    setState(() {
      _fromRows = current;
      _toRows = _rowsFor(widget.insights);
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

  List<_WindowRow> _rowsFor(SleepInsights insights) {
    final l10n = context.l10n;
    final buckets = insights.chartBuckets;
    final span = _spanFor(buckets);
    final locale = l10n.localeName;
    final weekday = DateFormat.E(locale);
    final monthDay = DateFormat.MMMd(locale);
    final month = DateFormat.MMM(locale);

    return [
      for (final bucket in buckets)
        _WindowRow(
          bucket: bucket,
          label: switch (span) {
            _WindowSpan.day =>
              insights.range == SleepHistoryRange.week
                  ? weekday.format(bucket.start)
                  : monthDay.format(bucket.start),
            _WindowSpan.week => monthDay.format(bucket.start),
            _WindowSpan.month => month.format(bucket.start),
          },
          bedtime: sleepWindowAxisMinutes(bucket.averageBedtime),
          wake: sleepWindowAxisMinutes(bucket.averageWake),
          bedtimeEarliest: sleepWindowAxisMinutes(bucket.earliestBedtime),
          bedtimeLatest: sleepWindowAxisMinutes(bucket.latestBedtime),
          wakeEarliest: sleepWindowAxisMinutes(bucket.earliestWake),
          wakeLatest: sleepWindowAxisMinutes(bucket.latestWake),
        ),
    ];
  }

  /// Snapshots the rows currently on screen so a second range change continues
  /// from them instead of jumping back to the start.
  List<_WindowRow> _currentRows() {
    final count = math.max(_fromRows.length, _toRows.length);
    final progress = _progress.value.clamp(0.0, 1.0).toDouble();
    return [
      for (var index = 0; index < count; index++)
        if (index < _fromRows.length && index < _toRows.length)
          _lerpRow(_fromRows[index], _toRows[index], progress)
        else if (index < _toRows.length)
          _toRows[index]
        else
          _fromRows[index],
    ];
  }

  bool _sameData(SleepInsights a, SleepInsights b) {
    if (a.range != b.range ||
        a.windowDays != b.windowDays ||
        a.chartBuckets.length != b.chartBuckets.length) {
      return false;
    }

    for (var index = 0; index < a.chartBuckets.length; index++) {
      final left = a.chartBuckets[index];
      final right = b.chartBuckets[index];
      if (left.start != right.start ||
          left.recordedDays != right.recordedDays ||
          left.sessionsCount != right.sessionsCount ||
          left.averageBedtime != right.averageBedtime ||
          left.averageWake != right.averageWake ||
          left.earliestBedtime != right.earliestBedtime ||
          left.latestBedtime != right.latestBedtime ||
          left.earliestWake != right.earliestWake ||
          left.latestWake != right.latestWake) {
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
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final dense = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final ticks = _axisTicks(l10n, use24HourFormat, dense);
    final bottomInset = math.max(
      ChartDimensions.plotBottomInset,
      MediaQuery.textScalerOf(context).scale(ChartDimensions.plotBottomInset),
    );

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
            final painter = _WindowChartPainter(
              palette: palette,
              axis: const ChartAxis(min: 0, max: 1, ticks: []),
              fromRows: _fromRows,
              toRows: _toRows,
              progress: _progress.value,
              selectionProgress: _selectionController.value,
              selectedIndex: _selectedIndex,
              ticks: ticks,
            );
            final plot = painter.plotRect(size);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ChartScrubArea(
                    slotCount: _toRows.length,
                    axis: Axis.vertical,
                    dragEnabled: false,
                    selectionInsets: EdgeInsets.only(
                      top: ChartDimensions.plotTopInset,
                      bottom: bottomInset,
                    ),
                    onSelectionChanged: _onSelectionChanged,
                    child: CustomPaint(painter: painter),
                  ),
                ),
                if (_selectedIndex case final index?)
                  if (index < _toRows.length)
                    _tooltipLayer(context, plot, index, use24HourFormat),
              ],
            );
          },
        );
      },
    );
  }

  Widget _tooltipLayer(
    BuildContext context,
    Rect plot,
    int index,
    bool use24HourFormat,
  ) {
    final l10n = context.l10n;
    final row = _toRows[index];
    final slot = _rowSlot(plot, index, _toRows.length);
    final left = row.bedtime == null
        ? plot.center.dx
        : _xFor(row.bedtime!, plot);
    final right = row.wake == null ? plot.center.dx : _xFor(row.wake!, plot);
    final anchor = Offset((left + right) / 2, slot.center.dy);
    final bucket = row.bucket;
    final span = _spanFor([bucket]);
    final dateLabel = _tooltipDateLabel(context, bucket, span);
    final timeRange = _timeRange(l10n, bucket, use24HourFormat);

    return ChartTooltipLayer(
      key: ValueKey(
        'sleep-window-tooltip-$index-${widget.insights.range.name}',
      ),
      anchor: anchor,
      child: switch ((row.hasData, timeRange, span)) {
        (false, _, _) => ChartTooltip.plain(
          label: l10n.chartTooltipNoData(dateLabel),
        ),
        (true, final range?, _WindowSpan.day) when bucket.sessionsCount > 1 =>
          ChartTooltip.plain(
            label: l10n.chartTooltipSessions(
              dateLabel,
              range,
              bucket.sessionsCount,
            ),
          ),
        (true, final range?, _WindowSpan.day) => ChartTooltip.plain(
          label: l10n.chartTooltipDate(dateLabel, range),
        ),
        (true, final range?, _) => ChartTooltip.rich(
          title: dateLabel,
          label: range,
          supporting: l10n.chartTooltipNights(bucket.recordedDays),
        ),
        (true, null, _) => ChartTooltip.plain(
          label: l10n.chartTooltipNoData(dateLabel),
        ),
      },
    );
  }

  String _tooltipDateLabel(
    BuildContext context,
    SleepChartBucket bucket,
    _WindowSpan span,
  ) {
    final locale = context.l10n.localeName;
    if (span == _WindowSpan.day) {
      return DateFormat.MMMEd(locale).format(bucket.start);
    }
    final end = bucket.endExclusive.subtract(const Duration(days: 1));
    final dates = DateFormat.MMMd(locale);
    return '${dates.format(bucket.start)} – ${dates.format(end)}';
  }

  String? _timeRange(
    AppLocalizations l10n,
    SleepChartBucket bucket,
    bool use24HourFormat,
  ) {
    final bedtime = bucket.averageBedtime;
    final wake = bucket.averageWake;
    if (bedtime == null || wake == null) return null;
    return l10n.timeRangeSeparator(
      chartClockLabel(
        l10n: l10n,
        time: bedtime,
        use24HourFormat: use24HourFormat,
      ),
      chartClockLabel(l10n: l10n, time: wake, use24HourFormat: use24HourFormat),
    );
  }
}

enum _WindowSpan { day, week, month }

_WindowSpan _spanFor(List<SleepChartBucket> buckets) {
  if (buckets.isEmpty) return _WindowSpan.day;
  final days = buckets.first.endExclusive
      .difference(buckets.first.start)
      .inDays;
  if (days <= 1) return _WindowSpan.day;
  if (days <= 8) return _WindowSpan.week;
  return _WindowSpan.month;
}

class _WindowRow {
  const _WindowRow({
    required this.bucket,
    required this.label,
    required this.bedtime,
    required this.wake,
    required this.bedtimeEarliest,
    required this.bedtimeLatest,
    required this.wakeEarliest,
    required this.wakeLatest,
  });

  final SleepChartBucket bucket;
  final String label;
  final double? bedtime;
  final double? wake;
  final double? bedtimeEarliest;
  final double? bedtimeLatest;
  final double? wakeEarliest;
  final double? wakeLatest;

  bool get hasData => bucket.hasData && bedtime != null && wake != null;
}

_WindowRow _lerpRow(_WindowRow from, _WindowRow to, double progress) {
  return _WindowRow(
    bucket: progress < 0.5 ? from.bucket : to.bucket,
    label: progress < 0.5 ? from.label : to.label,
    bedtime: _lerpNullable(from.bedtime, to.bedtime, progress),
    wake: _lerpNullable(from.wake, to.wake, progress),
    bedtimeEarliest: _lerpNullable(
      from.bedtimeEarliest,
      to.bedtimeEarliest,
      progress,
    ),
    bedtimeLatest: _lerpNullable(
      from.bedtimeLatest,
      to.bedtimeLatest,
      progress,
    ),
    wakeEarliest: _lerpNullable(from.wakeEarliest, to.wakeEarliest, progress),
    wakeLatest: _lerpNullable(from.wakeLatest, to.wakeLatest, progress),
  );
}

double? _lerpNullable(double? from, double? to, double progress) {
  if (from == null && to == null) return null;
  final start = from ?? to!;
  final end = to ?? from!;
  return start + (end - start) * progress;
}

double _xFor(double minutes, Rect plot) {
  final fraction =
      ((minutes - sleepWindowAxisStart) /
              (sleepWindowAxisEnd - sleepWindowAxisStart))
          .clamp(0.0, 1.0)
          .toDouble();
  return plot.left + fraction * plot.width;
}

Rect _rowSlot(Rect plot, int index, int count) {
  if (count == 0) return plot;
  final height = plot.height / count;
  return Rect.fromLTWH(
    plot.left,
    plot.top + index * height,
    plot.width,
    height,
  );
}

List<_WindowTick> _axisTicks(
  AppLocalizations l10n,
  bool use24HourFormat,
  bool dense,
) {
  final hours = dense ? [18, 0, 12] : [18, 0, 6, 12];
  return [
    for (final hour in hours)
      _WindowTick(
        minutes: sleepWindowAxisMinutes(Duration(hours: hour))!.round(),
        label: chartHourLabel(
          l10n: l10n,
          hour: hour,
          use24HourFormat: use24HourFormat,
        ),
      ),
  ];
}

class _WindowTick {
  const _WindowTick({required this.minutes, required this.label});

  final int minutes;
  final String label;
}

class _WindowChartPainter extends ChartPainter {
  _WindowChartPainter({
    required super.palette,
    required super.axis,
    required this.fromRows,
    required this.toRows,
    required this.progress,
    required this.selectionProgress,
    required this.selectedIndex,
    required this.ticks,
  });

  final List<_WindowRow> fromRows;
  final List<_WindowRow> toRows;
  final double progress;
  final double selectionProgress;
  final int? selectedIndex;
  final List<_WindowTick> ticks;

  @override
  Rect plotRect(Size size) {
    final left = math.max(
      ChartDimensions.axisGutter,
      palette.textScaler.scale(34) + 12,
    );
    final right = math.max(
      left + 1,
      size.width - ChartDimensions.plotRightInset,
    );
    final bottomInset = math.max(
      ChartDimensions.plotBottomInset,
      palette.textScaler.scale(ChartDimensions.plotBottomInset),
    );
    final bottom = math.max(
      ChartDimensions.plotTopInset + 1,
      size.height - bottomInset,
    );
    return Rect.fromLTRB(left, ChartDimensions.plotTopInset, right, bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = plotRect(size);
    _paintTimeGrid(canvas, plot);
    paintChart(canvas, plot);
    _paintTimeLabels(canvas, plot);
  }

  void _paintTimeGrid(Canvas canvas, Rect plot) {
    final grid = Paint()
      ..color = palette.grid
      ..strokeWidth = ChartDimensions.gridLineWidth;
    for (final tick in ticks) {
      final x = _xFor(tick.minutes.toDouble(), plot);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }
  }

  void _paintTimeLabels(Canvas canvas, Rect plot) {
    paintXAxisLabels(canvas, plot, [
      for (final tick in ticks)
        ChartXLabel(
          center: _xFor(tick.minutes.toDouble(), plot),
          label: tick.label,
        ),
    ]);
  }

  @override
  void paintChart(Canvas canvas, Rect plot) {
    final t = progress;
    final fade = t.clamp(0.0, 1.0).toDouble();
    final count = math.max(fromRows.length, toRows.length);

    for (var index = 0; index < count; index++) {
      final from = index < fromRows.length ? fromRows[index] : null;
      final to = index < toRows.length ? toRows[index] : null;
      final fromHas = from?.hasData ?? false;
      final toHas = to?.hasData ?? false;
      final both = fromHas && toHas;
      final opacity = both ? 1.0 : (toHas ? fade : 1 - fade);
      if (opacity <= 0) continue;

      final slot = _slotFor(plot, index, from, to, both, t);
      final selected = selectedIndex == index && to != null;

      if (both) {
        _paintRow(
          canvas,
          plot,
          slot,
          _lerpRow(from!, to!, t),
          opacity: 1,
          selected: selected,
        );
      } else if (toHas) {
        _paintRow(canvas, plot, slot, to!, opacity: fade, selected: selected);
      } else if (fromHas) {
        _paintRow(
          canvas,
          plot,
          slot,
          from!,
          opacity: 1 - fade,
          selected: false,
        );
      } else {
        _paintNoDataRow(
          canvas,
          plot,
          slot,
          opacity: to != null ? fade : 1 - fade,
        );
      }

      _paintRowLabel(
        canvas,
        plot,
        slot,
        from,
        to,
        opacity: opacity,
        progress: t,
      );
    }
  }

  Rect _slotFor(
    Rect plot,
    int index,
    _WindowRow? from,
    _WindowRow? to,
    bool both,
    double progress,
  ) {
    final toSlot = _rowSlot(plot, index, toRows.length);
    final fromSlot = _rowSlot(plot, index, fromRows.length);
    if (!both) return to != null ? toSlot : fromSlot;

    final centerY =
        fromSlot.center.dy + (toSlot.center.dy - fromSlot.center.dy) * progress;
    final height =
        fromSlot.height + (toSlot.height - fromSlot.height) * progress;
    return Rect.fromCenter(
      center: Offset(plot.center.dx, centerY),
      width: plot.width,
      height: height,
    );
  }

  void _paintRowLabel(
    Canvas canvas,
    Rect plot,
    Rect slot,
    _WindowRow? from,
    _WindowRow? to, {
    required double opacity,
    required double progress,
  }) {
    final fade = progress.clamp(0.0, 1.0).toDouble();
    if (from != null && to != null && from.label != to.label) {
      _paintLabel(canvas, plot, slot, from.label, 1 - fade);
      _paintLabel(canvas, plot, slot, to.label, fade);
      return;
    }
    final label = to?.label ?? from?.label;
    if (label == null) return;
    _paintLabel(canvas, plot, slot, label, opacity);
  }

  void _paintLabel(
    Canvas canvas,
    Rect plot,
    Rect slot,
    String label,
    double opacity,
  ) {
    if (opacity <= 0) return;
    final style = palette.axisLabel.copyWith(
      color: (palette.axisLabel.color ?? palette.emptyMark).withValues(
        alpha: opacity,
      ),
    );
    final text = textPainter(label, style);
    final left = (plot.left - 8 - text.width).clamp(0.0, plot.left).toDouble();
    final top = math.max(slot.top, slot.center.dy - text.height / 2);
    text.paint(canvas, Offset(left, top));
  }

  void _paintRow(
    Canvas canvas,
    Rect plot,
    Rect slot,
    _WindowRow row, {
    required double opacity,
    required bool selected,
  }) {
    final selection = selected ? selectionProgress.clamp(0.0, 1.0) : 0.0;
    final centerY = slot.center.dy;

    if (selection > 0) {
      final highlight = RRect.fromRectAndRadius(
        Rect.fromLTRB(plot.left, slot.top + 1, plot.right, slot.bottom - 1),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        highlight,
        Paint()
          ..color = palette.selectionHalo.withValues(alpha: 0.10 * selection),
      );
    }

    final bedtime = row.bedtime;
    final wake = row.wake;
    if (bedtime == null || wake == null) return;

    _paintBand(
      canvas,
      plot,
      centerY,
      row.bedtimeEarliest,
      row.bedtimeLatest,
      opacity,
    );
    _paintBand(
      canvas,
      plot,
      centerY,
      row.wakeEarliest,
      row.wakeLatest,
      opacity,
    );

    final left = _xFor(math.min(bedtime, wake), plot);
    final right = _xFor(math.max(bedtime, wake), plot);
    final height = 8 + (2 * selection);
    final rect = Rect.fromLTRB(
      left,
      centerY - height / 2,
      right < left + 2 ? left + 2 : right,
      centerY + height / 2,
    );
    final capsule = RRect.fromRectAndRadius(rect, Radius.circular(height / 2));

    if (selection > 0) {
      canvas.drawRRect(
        capsule.inflate(ChartDimensions.selectedHaloWidth / 2),
        Paint()
          ..color = palette.selectionHalo.withValues(alpha: selection)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ChartDimensions.selectedHaloWidth,
      );
    }

    canvas.drawRRect(
      capsule,
      Paint()..color = palette.bar.withValues(alpha: opacity),
    );

    _paintAverageTick(canvas, plot, centerY, bedtime, opacity);
    _paintAverageTick(canvas, plot, centerY, wake, opacity);
  }

  void _paintBand(
    Canvas canvas,
    Rect plot,
    double centerY,
    double? start,
    double? end,
    double opacity,
  ) {
    if (start == null || end == null) return;
    final left = _xFor(math.min(start, end), plot);
    final right = _xFor(math.max(start, end), plot);
    final rect = Rect.fromLTRB(
      left,
      centerY - 3,
      right < left + 1 ? left + 1 : right,
      centerY + 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = palette.band.withValues(alpha: opacity),
    );
  }

  void _paintAverageTick(
    Canvas canvas,
    Rect plot,
    double centerY,
    double minutes,
    double opacity,
  ) {
    final x = _xFor(minutes, plot);
    canvas.drawLine(
      Offset(x, centerY - 7),
      Offset(x, centerY + 7),
      Paint()
        ..color = palette.averageLine.withValues(alpha: opacity)
        ..strokeWidth = ChartDimensions.dataLineWidth,
    );
  }

  void _paintNoDataRow(
    Canvas canvas,
    Rect plot,
    Rect slot, {
    required double opacity,
  }) {
    if (opacity <= 0) return;
    paintDashedLine(
      canvas,
      Offset(plot.left, slot.center.dy),
      Offset(plot.right, slot.center.dy),
      Paint()
        ..color = palette.emptyMark.withValues(alpha: opacity * 0.6)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WindowChartPainter oldDelegate) => true;
}
