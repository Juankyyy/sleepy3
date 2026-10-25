import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/recent_sleep_summary.dart';
import '../../domain/sleep_duration.dart';

/// The Home summary of closed sleep for the last three local days.
///
/// From M3: outlined card (12dp corner radius, 16dp padding), `titleMedium`
/// for the header, `labelMedium` for day labels, `titleMedium` for durations,
/// and `surfaceContainerHighest` / `primary` for the bars.
/// My design decisions (not in M3): the 8h reference goal, the 4dp bar height,
/// the 2dp and 4dp gaps inside each day, and the 8dp gap between days.
class RecentSleepSummaryCard extends StatelessWidget {
  const RecentSleepSummaryCard({super.key, required this.summary});

  /// Bars are measured against this nightly goal and capped at 100%.
  static const dailyGoal = Duration(hours: 8);

  final RecentSleepSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.typography.baseline.labelMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = theme.typography.baseline.titleMedium.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Semantics(
        container: true,
        label: _spokenSummary(summary),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Last 3 days · ${_averageLabel(summary)} avg',
                style: theme.typography.emphasized.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              // 8dp separates the header from the day columns.
              const SizedBox(height: 8),
              _DayRow(
                cells: [
                  for (
                    var daysAgo = 0;
                    daysAgo < summary.days.length;
                    daysAgo++
                  )
                    Text(_dayLabel(daysAgo), style: labelStyle),
                ],
              ),
              const SizedBox(height: 2),
              _DayRow(
                cells: [
                  for (
                    var daysAgo = 0;
                    daysAgo < summary.days.length;
                    daysAgo++
                  )
                    Text(
                      _durationLabel(summary.dayBefore(daysAgo).duration),
                      style: valueStyle,
                    ),
                ],
              ),
              // 4dp sits between the value and its bar.
              const SizedBox(height: 4),
              _DayRow(
                cells: [
                  for (
                    var daysAgo = 0;
                    daysAgo < summary.days.length;
                    daysAgo++
                  )
                    _SleepBar(
                      key: ValueKey('sleep-summary-bar-$daysAgo'),
                      fraction: _barFraction(
                        summary.dayBefore(daysAgo).duration,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three equal columns with an 8dp gap between them.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < cells.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: cells[index]),
        ],
      ],
    );
  }
}

/// A 4dp bar with full corners.
class _SleepBar extends StatelessWidget {
  const _SleepBar({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;

    return Container(
      height: 4,
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: M3EShapes.stadium,
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: fraction,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: scheme.primary,
            shape: M3EShapes.stadium,
          ),
        ),
      ),
    );
  }
}

String _averageLabel(RecentSleepSummary summary) {
  final average = summary.average;
  return average == null ? '—' : formatSleepDuration(average);
}

String _durationLabel(Duration? duration) {
  return duration == null ? '—' : formatSleepDuration(duration);
}

String _dayLabel(int daysAgo) {
  return switch (daysAgo) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => '$daysAgo days ago',
  };
}

double _barFraction(Duration? duration) {
  if (duration == null || duration <= Duration.zero) return 0;
  final ratio =
      duration.inMicroseconds / RecentSleepSummaryCard.dailyGoal.inMicroseconds;
  return ratio >= 1 ? 1 : ratio;
}

String _spokenSummary(RecentSleepSummary summary) {
  final buffer = StringBuffer('Last 3 days');
  final average = summary.average;
  buffer.write(
    average == null
        ? ', no average'
        : ', average ${formatSpokenSleepDuration(average)}',
  );

  for (var daysAgo = 0; daysAgo < summary.days.length; daysAgo++) {
    final duration = summary.dayBefore(daysAgo).duration;
    buffer.write('. ${_dayLabel(daysAgo)}: ');
    buffer.write(
      duration == null ? 'no session' : formatSpokenSleepDuration(duration),
    );
  }
  return buffer.toString();
}
