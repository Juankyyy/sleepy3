import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/recent_sleep_summary.dart';
import '../../domain/sleep_goal.dart';

/// The Home summary of closed sleep for the last three local days.
///
/// From M3: outlined card (12dp corner radius, 16dp padding), `titleMedium`
/// for the header, `labelMedium` for day labels, `titleMedium` for durations,
/// and `surfaceContainerHighest` / `primary` for the bars.
/// My design decisions (not in M3): the 8h reference goal ([dailySleepGoal],
/// shared with Stats), the 4dp bar height, the 2dp and 4dp gaps inside each
/// day, and the 8dp gap between days.
class RecentSleepSummaryCard extends StatelessWidget {
  const RecentSleepSummaryCard({super.key, required this.summary});

  final RecentSleepSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final labelStyle = theme.typography.baseline.labelMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = theme.typography.baseline.titleMedium.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final average = summary.average;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Semantics(
        container: true,
        label: _spokenSummary(l10n, summary),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                average == null
                    ? l10n.last3DaysNoAverage
                    : l10n.last3DaysAverage(l10n.formatSleepDuration(average)),
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
                    Text(_dayLabel(l10n, daysAgo), style: labelStyle),
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
                      _durationLabel(l10n, summary.dayBefore(daysAgo).duration),
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

String _durationLabel(AppLocalizations l10n, Duration? duration) {
  return duration == null ? '—' : l10n.formatSleepDuration(duration);
}

String _dayLabel(AppLocalizations l10n, int daysAgo) {
  return switch (daysAgo) {
    0 => l10n.today,
    1 => l10n.yesterday,
    _ => l10n.daysAgo(daysAgo),
  };
}

double _barFraction(Duration? duration) {
  if (duration == null || duration <= Duration.zero) return 0;
  final ratio = duration.inMicroseconds / dailySleepGoal.inMicroseconds;
  return ratio >= 1 ? 1 : ratio;
}

String _spokenSummary(AppLocalizations l10n, RecentSleepSummary summary) {
  final buffer = StringBuffer(l10n.last3Days);
  final average = summary.average;
  buffer.write(
    average == null
        ? l10n.noAverageSpoken
        : l10n.averageSpoken(l10n.formatSpokenSleepDuration(average)),
  );

  for (var daysAgo = 0; daysAgo < summary.days.length; daysAgo++) {
    final duration = summary.dayBefore(daysAgo).duration;
    buffer.write('. ${_dayLabel(l10n, daysAgo)}: ');
    buffer.write(
      duration == null
          ? l10n.noSessionSpoken
          : l10n.formatSpokenSleepDuration(duration),
    );
  }
  return buffer.toString();
}
