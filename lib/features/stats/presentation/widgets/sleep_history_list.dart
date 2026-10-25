import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../history_labels.dart';

/// The full session history as one expressive M3 list.
///
/// Each row is one session, three lines tall: wake day overline, duration
/// headline and time range supporting text. The list is non-interactive; the
/// whole row is spoken as one label. Rows grow with the system text scale
/// because [M3EListItem] uses minimum heights.
class SleepHistoryList extends StatelessWidget {
  const SleepHistoryList({
    super.key,
    required this.history,
    required this.today,
    required this.use24HourFormat,
  });

  final SleepHistory history;
  final DateTime today;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    return M3EList.sliver(
      itemCount: history.entries.length,
      semanticsLabel: 'Sleep history',
      variant: M3ECardVariant.filled,
      outerRadius: 16,
      innerRadius: 4,
      gap: 2,
      itemBuilder: (context, index) {
        final entry = history.entries[index];
        final end = entry.session.endedAt!;
        // The rows are not tappable, and M3EList only applies
        // semanticLabelBuilder to actionable cards. Provide the combined
        // label here and exclude the three visual lines so the row is
        // announced once.
        return Semantics(
          container: true,
          label: _spokenEntry(index),
          child: ExcludeSemantics(
            child: M3EListItem(
              overline: formatHistoryDay(entry.date, today),
              headline: formatSleepDuration(entry.session.duration),
              supportingText: formatHistoryTimeRange(
                entry.session.startedAt,
                end,
                use24HourFormat: use24HourFormat,
              ),
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
