import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';
import '../history_labels.dart';

/// The full session history as one expressive M3 list.
///
/// Each row is one session, three lines tall: wake day overline, duration
/// headline and time range supporting text. Editable rows open the session
/// editor with a trailing edit icon; read-only rows stay non-interactive.
/// Rows grow with the system text scale because [M3EListItem] uses minimum
/// heights.
class SleepHistoryList extends StatelessWidget {
  const SleepHistoryList({
    super.key,
    required this.history,
    required this.today,
    required this.use24HourFormat,
    required this.onEdit,
    required this.isEditable,
  });

  final SleepHistory history;
  final DateTime today;
  final bool use24HourFormat;

  /// Called for a row the current source can edit or delete.
  final ValueChanged<SleepSession> onEdit;

  /// Whether the selected source offers any action for this session.
  final bool Function(SleepSession session) isEditable;

  @override
  Widget build(BuildContext context) {
    return M3EList.sliver(
      itemCount: history.entries.length,
      semanticsLabel: 'Sleep history',
      variant: M3ECardVariant.filled,
      outerRadius: 16,
      innerRadius: 4,
      gap: 2,
      // The list only enables rows whose item is enabled. Read-only rows are
      // built as a disabled M3EListItem, so they get no tap and no ripple.
      onTap: (index) {
        final session = history.entries[index].session;
        if (isEditable(session)) onEdit(session);
      },
      itemBuilder: (context, index) {
        final entry = history.entries[index];
        final end = entry.session.endedAt!;
        final editable = isEditable(entry.session);
        final item = _SleepHistoryItem(
          enabled: editable,
          spokenText: _spokenEntry(index),
          overline: formatHistoryDay(entry.date, today),
          headline: formatSleepDuration(entry.session.duration),
          supportingText: formatHistoryTimeRange(
            entry.session.startedAt,
            end,
            use24HourFormat: use24HourFormat,
          ),
        );

        if (!editable) {
          // Keep the item as the direct list child so M3EList can disable the
          // row surface. Read-only rows still speak the same label as before.
          return item;
        }

        // The row is actionable, so the whole card is a button and the edit
        // icon stays out of the semantics tree. A three-line M3EListItem
        // top-aligns its trailing slot, so the icon is overlaid and centered
        // against the full card height instead.
        return Semantics(
          label: _spokenEntry(index),
          hint: 'Opens the session editor',
          child: ExcludeSemantics(
            child: Stack(
              children: [
                // Leave room for the icon and its trailing inset without
                // letting the supporting text run underneath it.
                Padding(padding: const EdgeInsets.only(right: 32), child: item),
                Positioned(
                  top: 0,
                  right: 16,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Icon(
                        M3EIcons.edit_outlined,
                        size: 20,
                        color: M3ETheme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _spokenEntry(int index) {
    final entry = history.entries[index];
    final end = entry.session.endedAt!;
    final day = formatHistoryDaySpoken(entry.date, today);
    final duration = formatSpokenSleepDuration(entry.session.duration);
    final range = formatHistoryTimeRangeSpoken(
      entry.session.startedAt,
      end,
      use24HourFormat: use24HourFormat,
    );
    return '$day, $duration, $range';
  }
}

/// Adds the spoken wake day, duration and time range to the item label.
class _SleepHistoryItem extends M3EListItem {
  const _SleepHistoryItem({
    required this.spokenText,
    required super.headline,
    super.overline,
    super.supportingText,
    super.enabled,
  });

  final String spokenText;

  @override
  String get spokenLabel => spokenText;
}
