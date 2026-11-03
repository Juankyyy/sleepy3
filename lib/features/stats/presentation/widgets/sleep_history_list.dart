import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../health/domain/sleep_data_source.dart';
import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';
import '../history_labels.dart';
import '../history_session_source.dart';

/// The full session history as one expressive M3 list.
///
/// Each row is one session, three lines tall: wake day overline, duration
/// headline and time range supporting text. A leading icon marks where the
/// session came from. Every row opens the session; read-only sessions open a
/// details view instead of the editor. Rows grow with the system text scale
/// because [M3EListItem] uses minimum heights.
class SleepHistoryList extends StatelessWidget {
  const SleepHistoryList({
    super.key,
    required this.history,
    required this.today,
    required this.use24HourFormat,
    required this.source,
    required this.onEdit,
  });

  final SleepHistory history;
  final DateTime today;
  final bool use24HourFormat;

  /// The data source selected in Settings, used to label each row's origin.
  final SleepDataSource source;

  /// Called for every tapped row. The session editor decides whether the
  /// session is editable.
  final ValueChanged<SleepSession> onEdit;

  @override
  Widget build(BuildContext context) {
    return M3EList.sliver(
      itemCount: history.entries.length,
      semanticsLabel: 'Sleep history',
      variant: M3ECardVariant.filled,
      outerRadius: 16,
      innerRadius: 4,
      gap: 2,
      // Every row is a button. The session editor locks its fields when the
      // selected source cannot change the session.
      onTap: (index) => onEdit(history.entries[index].session),
      itemBuilder: (context, index) {
        final entry = history.entries[index];
        final end = entry.session.endedAt!;
        final item = _SleepHistoryItem(
          spokenText: _spokenEntry(index),
          source: historySessionSource(entry.session, source),
          // The icon itself is overlaid and centered by _SleepHistoryItem.
          // The spacer keeps the same leading inset in the row's content.
          leading: const SizedBox(width: 20),
          overline: formatHistoryDay(entry.date, today),
          headline: formatSleepDuration(entry.session.duration),
          supportingText: formatHistoryTimeRange(
            entry.session.startedAt,
            end,
            use24HourFormat: use24HourFormat,
          ),
        );

        // The row is actionable, so the whole card is a button. The custom
        // label carries the source and the trailing icon is gone.
        return Semantics(
          label: _spokenEntry(index),
          hint: 'Opens the session',
          child: ExcludeSemantics(child: item),
        );
      },
    );
  }

  String _spokenEntry(int index) {
    final entry = history.entries[index];
    final end = entry.session.endedAt!;
    final sourceLabel = historySessionSourceLabel(
      historySessionSource(entry.session, source),
    );
    final day = formatHistoryDaySpoken(entry.date, today);
    final duration = formatSpokenSleepDuration(entry.session.duration);
    final range = formatHistoryTimeRangeSpoken(
      entry.session.startedAt,
      end,
      use24HourFormat: use24HourFormat,
    );
    return '$sourceLabel, $day, $duration, $range';
  }
}

/// The leading icon that tells where a history row came from.
///
/// It uses 20 dp and the `onSurfaceVariant` color at 50% opacity so the source
/// stays secondary metadata. The tooltip explains the icon to sighted users;
/// the row's spoken label carries the same information for screen readers.
class _SessionSourceIcon extends StatelessWidget {
  const _SessionSourceIcon(this.source);

  final HistorySessionSource source;

  @override
  Widget build(BuildContext context) {
    return M3ETooltip(
      message: historySessionSourceLabel(source),
      child: Opacity(
        opacity: 0.5,
        child: Icon(
          switch (source) {
            HistorySessionSource.local => M3EIcons.smartphone,
            HistorySessionSource.googleHealth => M3EIcons.cloud_outlined,
          },
          size: 20,
          color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Adds the spoken source, wake day, duration and time range to the item label.
///
/// [M3EListItem] top-aligns its leading slot on a three-line row. The source
/// icon must sit in the middle of the card, so the item keeps an empty leading
/// spacer for the inset and overlays the icon centered against its full height.
/// The subclass stays an [M3EListItem] so [M3EList] recognizes the row.
class _SleepHistoryItem extends M3EListItem {
  const _SleepHistoryItem({
    required this.spokenText,
    required this.source,
    required super.headline,
    super.overline,
    super.supportingText,
    super.leading,
  });

  final String spokenText;
  final HistorySessionSource source;

  @override
  String get spokenLabel => spokenText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        super.build(context),
        Positioned(
          top: 0,
          left: 16,
          bottom: 0,
          child: Center(child: _SessionSourceIcon(source)),
        ),
      ],
    );
  }
}
