import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_insights.dart';
import '../charts/chart_format.dart';

/// The factual readings under the Stats charts.
///
/// From M3: outlined card, 12dp corners, `outlineVariant` dividers, and the
/// `bodyMedium` / `titleMedium` / `bodySmall` type roles.
/// My design decisions (not in M3): the title + row layout, the 16dp padding of
/// each row and the compact five-part distribution bar.
class StatsInsightsCard extends StatelessWidget {
  const StatsInsightsCard({super.key, required this.insights});

  final SleepInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final titleStyle = theme.typography.emphasized.titleMedium.copyWith(
      color: scheme.onSurface,
    );

    return M3ECard(
      variant: M3ECardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              header: true,
              child: Text(l10n.insightsTitle, style: titleStyle),
            ),
          ),
          if (!insights.hasData)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.noNightsInRange,
                style: theme.typography.baseline.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            _Divider(color: scheme.outlineVariant),
            for (final row in _rows(context)) ...[
              _InsightRow(row: row),
              _Divider(color: scheme.outlineVariant),
            ],
            _DistributionRow(insights: insights),
          ],
        ],
      ),
    );
  }

  List<_InsightRowData> _rows(BuildContext context) {
    final l10n = context.l10n;
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final date = DateFormat.MMMd(l10n.localeName);
    final best = insights.bestDay;
    final worst = insights.worstDay;
    final variability = insights.bedtimeVariability;

    return [
      _InsightRowData(
        label: l10n.insightBestNight,
        value: best == null ? '—' : l10n.formatSleepDuration(best.total),
        spokenValue: best == null
            ? '—'
            : l10n.formatSpokenSleepDuration(best.total),
        support: best == null ? null : date.format(best.date),
      ),
      _InsightRowData(
        label: l10n.insightShortestNight,
        value: worst == null ? '—' : l10n.formatSleepDuration(worst.total),
        spokenValue: worst == null
            ? '—'
            : l10n.formatSpokenSleepDuration(worst.total),
        support: worst == null ? null : date.format(worst.date),
      ),
      _InsightRowData(
        label: l10n.insightAverageBedtime,
        value: insights.averageBedtime == null
            ? '—'
            : chartClockLabel(
                l10n: l10n,
                time: insights.averageBedtime!,
                use24HourFormat: use24HourFormat,
              ),
      ),
      _InsightRowData(
        label: l10n.insightAverageWake,
        value: insights.averageWake == null
            ? '—'
            : chartClockLabel(
                l10n: l10n,
                time: insights.averageWake!,
                use24HourFormat: use24HourFormat,
              ),
      ),
      _InsightRowData(
        label: l10n.insightBedtimeVariability,
        value: variability == null
            ? '—'
            : l10n.metricVariability(l10n.formatGoalDelta(variability)),
        support: variability == null ? l10n.metricNeedsTwoNights : null,
      ),
      _InsightRowData(
        label: l10n.insightSplitNights,
        value: l10n.metricNights(insights.splitNights),
      ),
    ];
  }
}

class _InsightRowData {
  const _InsightRowData({
    required this.label,
    required this.value,
    this.spokenValue,
    this.support,
  });

  final String label;
  final String value;
  final String? spokenValue;
  final String? support;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.row});

  final _InsightRowData row;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = theme.typography.emphasized.titleMedium.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final supportStyle = theme.typography.baseline.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final spoken = [
      row.label,
      row.spokenValue ?? row.value,
      if (row.support != null) row.support!,
    ].join(', ');

    return Semantics(
      container: true,
      label: spoken,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Text(row.label, style: labelStyle)),
              const SizedBox(width: 16),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.value,
                      style: valueStyle,
                      textAlign: TextAlign.end,
                    ),
                    if (row.support != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.support!,
                        style: supportStyle,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.insights});

  final SleepInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final labelStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final itemStyle = theme.typography.baseline.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final buckets = insights.durationBuckets;
    final total = buckets.fold<int>(0, (sum, bucket) => sum + bucket.nights);

    if (total == 0) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: l10n.insightDistributionSpoken(
        buckets[SleepDurationBand.underSixHours.index].nights,
        buckets[SleepDurationBand.sixToSevenHours.index].nights,
        buckets[SleepDurationBand.sevenToEightHours.index].nights,
        buckets[SleepDurationBand.eightToNineHours.index].nights,
        buckets[SleepDurationBand.nineHoursPlus.index].nights,
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.insightDistribution, style: labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var index = 0; index < buckets.length; index++)
                    if (buckets[index].nights > 0) ...[
                      if (index > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: buckets[index].nights,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final bucket in buckets)
                    Text(
                      '${_bandLabel(l10n, bucket.band)} · '
                      '${l10n.metricNights(bucket.nights)}',
                      style: itemStyle,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bandLabel(AppLocalizations l10n, SleepDurationBand band) {
    return switch (band) {
      SleepDurationBand.underSixHours => l10n.sleepBandUnderSix,
      SleepDurationBand.sixToSevenHours => l10n.sleepBandSixToSeven,
      SleepDurationBand.sevenToEightHours => l10n.sleepBandSevenToEight,
      SleepDurationBand.eightToNineHours => l10n.sleepBandEightToNine,
      SleepDurationBand.nineHoursPlus => l10n.sleepBandNinePlus,
    };
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 1, child: ColoredBox(color: color));
  }
}
