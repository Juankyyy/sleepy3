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
///
/// [compact] is the horizontal variant used inside the Stats summary. It lays
/// the five rows out in two or three columns so the card fits above the advanced
/// button. The advanced sheet keeps the full vertical card.
class StatsInsightsCard extends StatelessWidget {
  const StatsInsightsCard({
    super.key,
    required this.insights,
    this.compact = false,
    this.showTitle = true,
  });

  final SleepInsights insights;

  /// Whether to use the horizontal summary layout.
  final bool compact;

  /// Whether to draw the inline `Key data` title.
  ///
  /// The summary picker labels the option in its own header, so its preview
  /// hides the title to avoid repeating it.
  final bool showTitle;

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
          if (showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Semantics(
                header: true,
                child: Text(l10n.insightsTitle, style: titleStyle),
              ),
            ),
          if (!insights.hasData)
            Padding(
              padding: EdgeInsets.fromLTRB(16, showTitle ? 0 : 16, 16, 16),
              child: Text(
                l10n.noNightsInRange,
                style: theme.typography.baseline.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else if (compact) ...[
            if (showTitle) _Divider(color: scheme.outlineVariant),
            _CompactInsightsGrid(rows: _rows(context)),
            _Divider(color: scheme.outlineVariant),
            _DistributionRow(insights: insights),
          ] else ...[
            if (showTitle) _Divider(color: scheme.outlineVariant),
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

  String get spoken => [label, spokenValue ?? value, ?support].join(', ');
}

/// The horizontal summary layout: a compact grid with the same five readings.
///
/// Two columns on a phone, three from 600dp. At 150% text or more it falls back
/// to one column so every label keeps its full width. A final incomplete row
/// keeps the column width and leaves the unused slots empty, without drawing a
/// bordered cell around them.
class _CompactInsightsGrid extends StatelessWidget {
  const _CompactInsightsGrid({required this.rows});

  final List<_InsightRowData> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = textScale >= 1.5
            ? 1
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        final fullRowCount = rows.length ~/ columns;
        final remainder = rows.length % columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fullRowCount > 0)
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                columnWidths: {
                  for (var index = 0; index < columns; index++)
                    index: const FlexColumnWidth(),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: scheme.outlineVariant),
                  verticalInside: BorderSide(color: scheme.outlineVariant),
                ),
                children: [
                  for (var row = 0; row < fullRowCount; row++)
                    TableRow(
                      children: [
                        for (var column = 0; column < columns; column++)
                          _CompactInsightCell(
                            row: rows[row * columns + column],
                          ),
                      ],
                    ),
                ],
              ),
            if (remainder > 0) ...[
              if (fullRowCount > 0) _Divider(color: scheme.outlineVariant),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column < remainder) ...[
                        if (column > 0)
                          SizedBox(
                            width: 1,
                            child: ColoredBox(color: scheme.outlineVariant),
                          ),
                        Expanded(
                          child: _CompactInsightCell(
                            row: rows[fullRowCount * columns + column],
                          ),
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CompactInsightCell extends StatelessWidget {
  const _CompactInsightCell({required this.row});

  final _InsightRowData row;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.typography.baseline.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = theme.typography.emphasized.titleMedium.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final supportStyle = theme.typography.baseline.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: row.spoken,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.label, style: labelStyle),
              const SizedBox(height: 2),
              Text(row.value, style: valueStyle),
              if (row.support != null) ...[
                const SizedBox(height: 2),
                Text(row.support!, style: supportStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
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

    return Semantics(
      container: true,
      label: row.spoken,
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
