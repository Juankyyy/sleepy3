import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';

/// The range summary on Stats: average, nights recorded and total sleep.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `outlineVariant`
/// outline, `labelMedium`/`displaySmall`/`bodyMedium` type roles.
class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({super.key, required this.history, this.onShowAll});

  final SleepHistory history;

  /// Shown only when the selected range is empty but older history exists.
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final average = history.average;

    final labelStyle = theme.typography.baseline.labelMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = theme.typography.emphasized.displaySmall.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final supportStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: _spokenSummary(history),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Average sleep', style: labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    average == null ? '—' : formatSleepDuration(average),
                    style: valueStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(_supportingLabel(history), style: supportStyle),
                ],
              ),
            ),
          ),
          if (onShowAll != null) ...[
            const SizedBox(height: 8),
            M3EButton(
              style: M3EButtonStyle.text,
              size: M3EButtonSize.sm,
              onPressed: onShowAll,
              child: const Text('Show all'),
            ),
          ],
        ],
      ),
    );
  }

  String _supportingLabel(SleepHistory history) {
    if (!history.hasData) return 'No nights in this range';
    final nights = history.nights;
    final nightLabel = nights == 1 ? 'night' : 'nights';
    return 'Across $nights $nightLabel · '
        '${formatSleepDuration(history.total)} total';
  }

  String _spokenSummary(SleepHistory history) {
    final average = history.average;
    if (average == null) {
      return 'Average sleep, no nights in this range';
    }
    final nights = history.nights;
    final nightLabel = nights == 1 ? 'night' : 'nights';
    return 'Average sleep ${formatSpokenSleepDuration(average)}, '
        'across $nights $nightLabel, '
        '${formatSpokenSleepDuration(history.total)} total';
  }
}
