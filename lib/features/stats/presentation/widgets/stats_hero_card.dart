import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_history.dart';
import '../../../sleep_tracking/domain/sleep_insights.dart';

/// The Stats hero: average sleep for the selected range.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `outlineVariant`
/// outline, `labelMedium` / `displaySmall` / `bodyMedium` / `bodySmall` type
/// roles and `onSurfaceVariant` for supporting text.
/// My design decisions (not in M3): the 16dp inline icon, the 4dp and 8dp gaps
/// inside the card, and the arrow that pairs the comparison with its value.
class StatsHeroCard extends StatelessWidget {
  const StatsHeroCard({
    super.key,
    required this.insights,
    this.showLabel = true,
  });

  final SleepInsights insights;

  /// Whether to show the inline `Average sleep` label.
  ///
  /// The summary picker labels the option in its own header, so its preview
  /// hides the label to avoid repeating it.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final average = insights.average;
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
    final metaStyle = theme.typography.baseline.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final coverage = _coverageLabel(l10n);
    final comparison = _comparisonLabel(l10n);

    return M3ECard(
      variant: M3ECardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: _spokenSummary(
              l10n,
              coverage: coverage,
              comparison: comparison,
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLabel) ...[
                    Text(l10n.averageSleep, style: labelStyle),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    average == null ? '—' : l10n.formatSleepDuration(average),
                    style: valueStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    average == null
                        ? l10n.noNightsInRange
                        : l10n.summarySupporting(
                            insights.recordedDays,
                            l10n.formatSleepDuration(insights.total),
                          ),
                    style: supportStyle,
                  ),
                  if (comparison != null) ...[
                    const SizedBox(height: 4),
                    _ComparisonLine(
                      text: comparison,
                      delta: insights.comparison!.averageDelta,
                      style: supportStyle,
                    ),
                  ],
                  if (average != null) ...[
                    const SizedBox(height: 4),
                    Text(coverage, style: metaStyle),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `5 of 7 nights` for fixed windows, or `X nights recorded` in All, where
  /// a percentage would punish a large historical window.
  String _coverageLabel(AppLocalizations l10n) {
    if (insights.range == SleepHistoryRange.all) {
      return l10n.heroCoverageAll(insights.recordedDays);
    }
    return l10n.heroCoverageWindow(insights.recordedDays, insights.windowDays);
  }

  String? _comparisonLabel(AppLocalizations l10n) {
    final comparison = insights.comparison;
    if (comparison == null) return null;
    return l10n.heroComparison(
      _previousRangeLabel(l10n, insights.range),
      l10n.formatSignedCompactDuration(comparison.averageDelta),
    );
  }

  /// Single spoken label so the hero reads as one summary instead of five
  /// separate lines.
  String _spokenSummary(
    AppLocalizations l10n, {
    required String coverage,
    required String? comparison,
  }) {
    final average = insights.average;
    if (average == null) return l10n.summarySpokenNoNights;

    return [
      l10n.summarySpoken(
        l10n.formatSpokenSleepDuration(average),
        insights.recordedDays,
        l10n.formatSpokenSleepDuration(insights.total),
      ),
      ?comparison,
      coverage,
    ].join('. ');
  }
}

/// The comparison text with an arrow that repeats its direction without color.
class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({
    required this.text,
    required this.delta,
    required this.style,
  });

  final String text;
  final Duration delta;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The icon shares the body line; 16dp is a design decision.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(_icon(delta), size: 16, color: style.color),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }

  IconData _icon(Duration delta) {
    if (delta > Duration.zero) return M3EIcons.arrow_upward_rounded;
    if (delta < Duration.zero) return M3EIcons.arrow_downward_rounded;
    return M3EIcons.trending_flat;
  }
}

String _previousRangeLabel(AppLocalizations l10n, SleepHistoryRange range) {
  return switch (range) {
    SleepHistoryRange.week => l10n.previousRangeWeek,
    SleepHistoryRange.month => l10n.previousRangeMonth,
    SleepHistoryRange.threeMonths => l10n.previousRangeThreeMonths,
    SleepHistoryRange.year => l10n.previousRangeYear,
    // All never has a comparison; the label is unreachable.
    SleepHistoryRange.all => l10n.rangeAll,
  };
}
