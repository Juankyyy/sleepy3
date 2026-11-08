import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
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
    final l10n = context.l10n;
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
            label: _spokenSummary(l10n, history),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.averageSleep, style: labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    average == null ? '—' : l10n.formatSleepDuration(average),
                    style: valueStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(_supportingLabel(l10n, history), style: supportStyle),
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
              child: Text(l10n.showAll),
            ),
          ],
        ],
      ),
    );
  }

  String _supportingLabel(AppLocalizations l10n, SleepHistory history) {
    if (!history.hasData) return l10n.noNightsInRange;
    return l10n.summarySupporting(
      history.nights,
      l10n.formatSleepDuration(history.total),
    );
  }

  String _spokenSummary(AppLocalizations l10n, SleepHistory history) {
    final average = history.average;
    if (average == null) {
      return l10n.summarySpokenNoNights;
    }
    return l10n.summarySpoken(
      l10n.formatSpokenSleepDuration(average),
      history.nights,
      l10n.formatSpokenSleepDuration(history.total),
    );
  }
}
