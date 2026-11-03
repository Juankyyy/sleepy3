import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../health/domain/sleep_data_source.dart';
import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';
import '../history_labels.dart';
import '../history_session_source.dart';

/// The full session history as tonal M3 cards.
///
/// Each card is one session. The seven-day range uses three lines: the wake
/// day and source, the duration and the time range. The 30-day and all-history
/// ranges use a two-line compact layout so more nights fit on screen. Every
/// card opens the session; read-only sessions open a details view instead of
/// the editor. Cards grow with the system text scale because they use content
/// heights, not fixed heights.
class SleepHistoryList extends StatelessWidget {
  const SleepHistoryList({
    super.key,
    required this.history,
    required this.today,
    required this.use24HourFormat,
    required this.source,
    required this.compact,
    required this.onEdit,
  });

  final SleepHistory history;
  final DateTime today;
  final bool use24HourFormat;

  /// The data source selected in Settings, used to label each card's origin.
  final SleepDataSource source;

  /// Whether to use the two-line compact card (30 days and All).
  final bool compact;

  /// Called for every tapped card. The session editor decides whether the
  /// session is editable.
  final ValueChanged<SleepSession> onEdit;

  @override
  Widget build(BuildContext context) {
    final entries = history.entries;
    // Highlight the most recent session of the newest day. A day can hold
    // several sessions (a nap and a night); the last entry of the first day is
    // the latest one.
    final highlightedIndex = entries.isEmpty
        ? -1
        : entries.lastIndexWhere((entry) => entry.date == entries.first.date);

    return SliverList.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => SizedBox(height: compact ? 6 : 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HistoryCard(
          key: ValueKey(entry.session.startedAt),
          entry: entry,
          today: today,
          use24HourFormat: use24HourFormat,
          source: historySessionSource(entry.session, source),
          compact: compact,
          highlighted: index == highlightedIndex,
          onTap: () => onEdit(entry.session),
        );
      },
    );
  }
}

/// One history session as a tonal card.
///
/// The fill and text use the paired `secondaryContainer` / `onSecondaryContainer`
/// roles. The most recent session of the newest day uses `primaryContainer` /
/// `onPrimaryContainer`. The 44 dp (or 36 dp compact) ring compares the night
/// with [dailySleepGoal]; the ring is decorative because the spoken label
/// already carries the duration. The whole card is the button.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    super.key,
    required this.entry,
    required this.today,
    required this.use24HourFormat,
    required this.source,
    required this.compact,
    required this.highlighted,
    required this.onTap,
  });

  final SleepHistoryEntry entry;
  final DateTime today;
  final bool use24HourFormat;
  final HistorySessionSource source;
  final bool compact;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final fill = highlighted
        ? scheme.primaryContainer
        : scheme.secondaryContainer;
    final onColor = highlighted
        ? scheme.onPrimaryContainer
        : scheme.onSecondaryContainer;
    final end = entry.session.endedAt!;

    return Semantics(
      container: true,
      button: true,
      label: _spokenLabel(),
      hint: 'Opens the session',
      onTap: onTap,
      child: ExcludeSemantics(
        child: M3ECard(
          variant: M3ECardVariant.filled,
          color: fill,
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.all(compact ? 12 : 16),
          onPressed: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GoalRing(
                size: compact ? 36 : 44,
                strokeWidth: compact ? 3 : 4,
                value: _goalFraction(entry.session.duration),
                color: scheme.primary,
                trackColor: onColor.withValues(
                  alpha: highlighted ? 0.22 : 0.18,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: _HistoryCardContent(
                  day: formatHistoryDay(entry.date, today),
                  duration: formatSleepDuration(entry.session.duration),
                  range: formatHistoryTimeRange(
                    entry.session.startedAt,
                    end,
                    use24HourFormat: use24HourFormat,
                  ),
                  source: source,
                  onColor: onColor,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Icon(
                M3EIcons.chevron_right,
                size: compact ? 18 : 20,
                color: onColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _spokenLabel() {
    final session = entry.session;
    final sourceLabel = historySessionSourceLabel(source);
    final day = formatHistoryDaySpoken(entry.date, today);
    final duration = formatSpokenSleepDuration(session.duration);
    final range = formatHistoryTimeRangeSpoken(
      session.startedAt,
      session.endedAt!,
      use24HourFormat: use24HourFormat,
    );
    return '$sourceLabel, $day, $duration, $range';
  }
}

/// The day pill, duration and time range inside a history card.
///
/// The comfortable layout stacks the duration and range on separate lines. The
/// compact layout puts them on one line with the range at the trailing edge;
/// when the text scale makes them not fit, the range wraps to a third line.
class _HistoryCardContent extends StatelessWidget {
  const _HistoryCardContent({
    required this.day,
    required this.duration,
    required this.range,
    required this.source,
    required this.onColor,
    required this.compact,
  });

  final String day;
  final String duration;
  final String range;
  final HistorySessionSource source;
  final Color onColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final durationStyle =
        (compact
                ? theme.typography.emphasized.titleLarge
                : theme.typography.emphasized.headlineSmall)
            .copyWith(
              color: onColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final rangeStyle =
        (compact
                ? theme.typography.baseline.bodySmall
                : theme.typography.baseline.bodyMedium)
            .copyWith(color: onColor);

    final durationText = Text(duration, style: durationStyle);
    final rangeText = Text(range, style: rangeStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HistoryMeta(
          day: day,
          source: source,
          onColor: onColor,
          compact: compact,
        ),
        SizedBox(height: compact ? 1 : 2),
        if (compact)
          Wrap(
            spacing: 8,
            runSpacing: 2,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [durationText, rangeText],
          )
        else ...[
          durationText,
          const SizedBox(height: 1),
          rangeText,
        ],
      ],
    );
  }
}

/// The wake-day pill and the session source icon.
///
/// The pill is a 10 % tint of the card's paired `on*` color, so it blends with
/// the tonal container instead of being the brightest surface on the card. The
/// text and the source icon use the full `on*` color. The tint is a design
/// decision: M3 has no on-color tint container role.
class _HistoryMeta extends StatelessWidget {
  const _HistoryMeta({
    required this.day,
    required this.source,
    required this.onColor,
    required this.compact,
  });

  final String day;
  final HistorySessionSource source;
  final Color onColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final dayStyle =
        (compact
                ? theme.typography.baseline.labelSmall
                : theme.typography.baseline.labelMedium)
            .copyWith(color: onColor);

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 1 : 2,
          ),
          decoration: ShapeDecoration(
            color: onColor.withValues(alpha: 0.10),
            shape: M3EShapes.stadium,
          ),
          child: Text(day, style: dayStyle),
        ),
        _SessionSourceIcon(
          source: source,
          color: onColor,
          size: compact ? 16 : 18,
        ),
      ],
    );
  }
}

/// The duration ring, measured against [dailySleepGoal].
///
/// The value is capped at 1 so a night longer than the goal paints a full ring;
/// the duration text still carries the exact time.
class _GoalRing extends StatelessWidget {
  const _GoalRing({
    required this.size,
    required this.strokeWidth,
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double size;
  final double strokeWidth;
  final double value;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          M3EProgressIndicator.circular(
            value: value,
            size: size,
            strokeWidth: strokeWidth,
            trackStrokeWidth: strokeWidth,
            color: color,
            trackColor: trackColor,
          ),
          Icon(M3EIcons.bedtime_rounded, size: size * 0.41, color: color),
        ],
      ),
    );
  }
}

/// The leading icon that tells where a history card came from.
///
/// The tooltip explains the icon to sighted users; the card's spoken label
/// carries the same information for screen readers.
class _SessionSourceIcon extends StatelessWidget {
  const _SessionSourceIcon({
    required this.source,
    required this.color,
    required this.size,
  });

  final HistorySessionSource source;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return M3ETooltip(
      message: historySessionSourceLabel(source),
      child: Icon(
        switch (source) {
          HistorySessionSource.local => M3EIcons.smartphone,
          HistorySessionSource.googleHealth => M3EIcons.cloud_outlined,
        },
        size: size,
        color: color,
      ),
    );
  }
}

double _goalFraction(Duration duration) {
  if (duration <= Duration.zero) return 0;
  final ratio = duration.inMicroseconds / dailySleepGoal.inMicroseconds;
  return ratio >= 1 ? 1 : ratio;
}
