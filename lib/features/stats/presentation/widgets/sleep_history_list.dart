import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../health/application/app_info_provider.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';
import '../history_labels.dart';
import '../history_session_source.dart';
import 'sleep_goal_mark.dart';

/// The full session history as tonal M3 cards.
///
/// Each card is one session. The seven-day range uses three lines: the wake
/// day and, for sessions from another app, their source; the duration and the
/// time range. The 30-day and all-history ranges use a two-line compact layout
/// so more nights fit on screen. Every card opens the session; read-only
/// sessions open a details view instead of the editor. Cards grow with the
/// system text scale because they use content heights, not fixed heights.
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

  /// The data source selected in Settings. It decides which rows were written
  /// by another app and therefore show their source.
  final SleepDataSource source;

  /// Whether to use the two-line compact card (30 days and All).
  final bool compact;

  /// Called for every tapped card. The session editor decides whether the
  /// session is editable.
  final ValueChanged<SleepSession> onEdit;

  @override
  Widget build(BuildContext context) {
    final entries = history.entries;

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
          external: isSessionFromAnotherApp(entry.session, source),
          compact: compact,
          emphasis: _historyEmphasis(index),
          onTap: () => onEdit(entry.session),
        );
      },
    );
  }
}

/// How strongly a card shows the accent.
///
/// The newest session is 1, the next two cards fade to 2/3 and 1/3, and every
/// card from the fourth on uses the neutral base (0). Entries are newest first,
/// so the highlighted session is always the first card.
///
/// The intermediate values are a Sleepy3 design decision: M3 has no recency
/// gradient role, so the stops blend two standard container roles.
double _historyEmphasis(int index) {
  if (index >= 3) return 0;
  return (3 - index) / 3;
}

/// One history session as a tonal card.
///
/// The highlighted session uses the accent pair `primaryContainer` /
/// `onPrimaryContainer`; the next two cards blend the accent with the neutral
/// `surfaceContainerHighest` base at 2/3 and 1/3, and every card from the fourth
/// on uses the base with `onSurface`. Only the highlighted card uses the accent
/// on-color; the faded cards keep the neutral text. Sessions written by another
/// app add an external-app arrow and the app's label next to the day. The 44 dp
/// (or 36 dp compact) leading mark compares the night with [dailySleepGoal]:
/// below the goal it is a ring, and at or above it becomes the eight-leaf
/// clover from the M3 shape library. Both are decorative because the spoken
/// label already carries the duration and the goal state. The whole card is
/// the button.
class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({
    super.key,
    required this.entry,
    required this.today,
    required this.use24HourFormat,
    required this.external,
    required this.compact,
    required this.emphasis,
    required this.onTap,
  });

  final SleepHistoryEntry entry;
  final DateTime today;
  final bool use24HourFormat;

  /// Whether the session was written by an app other than Sleepy3.
  final bool external;

  final bool compact;

  /// 1 for the highlighted session, 2/3 and 1/3 for the next two, 0 for the
  /// neutral cards.
  final double emphasis;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final fill = Color.lerp(
      scheme.surfaceContainerHighest,
      scheme.primaryContainer,
      emphasis,
    )!;
    final onColor = emphasis >= 1
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final end = entry.session.endedAt!;
    final badgeSize = compact ? 36.0 : 44.0;
    final sourceId = entry.session.sourceId;
    // Resolve the writer app only for rows that show it. The family caches one
    // lookup per package, so several sessions from the same app share it.
    final appLabel = external && sourceId != null
        ? ref.watch(appLabelProvider(sourceId)).asData?.value
        : null;

    return Semantics(
      container: true,
      button: true,
      label: _spokenLabel(l10n, appLabel: appLabel),
      hint: l10n.opensSession,
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
              SleepGoalMark(
                duration: entry.session.duration,
                size: badgeSize,
                strokeWidth: compact ? 3 : 4,
                color: scheme.primary,
                onColor: scheme.onPrimary,
                trackColor: onColor.withValues(
                  alpha: emphasis >= 1 ? 0.22 : 0.18,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: _HistoryCardContent(
                  day: l10n.formatHistoryDay(entry.date, today),
                  duration: l10n.formatSleepDuration(entry.session.duration),
                  range: l10n.formatHistoryTimeRange(
                    entry.session.startedAt,
                    end,
                    use24HourFormat: use24HourFormat,
                  ),
                  externalLabel: external
                      ? l10n.formatExternalSessionLabel(appLabel)
                      : null,
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

  String _spokenLabel(AppLocalizations l10n, {required String? appLabel}) {
    final session = entry.session;
    final day = l10n.formatHistoryDaySpoken(entry.date, today);
    final duration = l10n.formatSpokenSleepDuration(session.duration);
    final goal = session.duration >= dailySleepGoal
        ? ', ${l10n.goalMetLower}'
        : '';
    final range = l10n.formatHistoryTimeRangeSpoken(
      session.startedAt,
      session.endedAt!,
      use24HourFormat: use24HourFormat,
    );
    final prefix = external
        ? '${l10n.formatExternalSessionSpokenLabel(appLabel)}, '
        : '';
    return '$prefix$day, $duration$goal, $range';
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
    required this.externalLabel,
    required this.onColor,
    required this.compact,
  });

  final String day;
  final String duration;
  final String range;

  /// The source pill text when another app wrote the session, or null.
  final String? externalLabel;

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
          externalLabel: externalLabel,
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

/// The wake-day pill and, for sessions from another app, the source pill.
///
/// Both pills are a 10 % tint of the card's paired `on*` color, so they blend
/// with the tonal container instead of being the brightest surface on the card.
/// The text uses the full `on*` color. The tint is a design decision: M3 has no
/// on-color tint container role.
class _HistoryMeta extends StatelessWidget {
  const _HistoryMeta({
    required this.day,
    required this.externalLabel,
    required this.onColor,
    required this.compact,
  });

  final String day;

  /// The app that wrote the session, or null when Sleepy3 did.
  final String? externalLabel;

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
        _MetaPill(
          color: onColor,
          compact: compact,
          child: Text(day, style: dayStyle),
        ),
        if (externalLabel != null)
          _ExternalSourcePill(
            label: externalLabel!,
            color: onColor,
            compact: compact,
          ),
      ],
    );
  }
}

/// The stadium container shared by the day and source pills.
class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.color,
    required this.compact,
    required this.child,
  });

  final Color color;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1 : 2,
      ),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.10),
        shape: M3EShapes.stadium,
      ),
      child: child,
    );
  }
}

/// The external-app arrow and app label on a session written by another app.
///
/// The arrow says the session came from another app; the label names it. The
/// read-only state stays in the card's spoken label and in the details view,
/// not in this pill. The stadium and the tint match the day pill; this is a
/// Sleepy3 design decision because M3 has no non-interactive status pill.
class _ExternalSourcePill extends StatelessWidget {
  const _ExternalSourcePill({
    required this.label,
    required this.color,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final style =
        (compact
                ? theme.typography.baseline.labelSmall
                : theme.typography.baseline.labelMedium)
            .copyWith(color: color);

    return _MetaPill(
      color: color,
      compact: compact,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            M3EIcons.open_in_new_outlined,
            size: compact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: compact ? 3 : 4),
          Flexible(child: Text(label, style: style)),
        ],
      ),
    );
  }
}
