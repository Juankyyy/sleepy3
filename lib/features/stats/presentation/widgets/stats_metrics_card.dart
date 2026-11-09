import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../../sleep_tracking/domain/sleep_insights.dart';

/// The metric tiles shown by [StatsMetricsCard].
///
/// The summary uses the first two; the advanced sheet shows all four.
enum StatsMetricType {
  goalHitRate,
  scheduleConsistency,
  sleepBalance,
  bestStreak,
}

/// The summary metrics card.
///
/// From M3: outlined card, 12dp corners, `outlineVariant` dividers, and the
/// `labelMedium` / `headlineSmall` / `bodySmall` type roles.
/// My design decisions (not in M3): a 2x2 grid on compact screens, four
/// columns from 600dp for the full set, 16dp inside each cell and tabular
/// figures in the values. The Stats summary passes only two metrics and a
/// fixed two-column layout.
class StatsMetricsCard extends StatelessWidget {
  const StatsMetricsCard({
    super.key,
    required this.insights,
    this.metrics = StatsMetricType.values,
    this.columns,
  });

  final SleepInsights insights;

  /// Which metrics to render, in order.
  final List<StatsMetricType> metrics;

  /// Overrides the responsive column count. The summary uses 2.
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final allMetrics = _buildMetrics(l10n);
    final selected = [for (final type in metrics) allMetrics[type.index]];
    if (selected.isEmpty) return const SizedBox.shrink();

    final resolvedColumns =
        (columns ??
                (MediaQuery.sizeOf(context).width >= 600
                    ? (selected.length < 4 ? selected.length : 4)
                    : 2))
            .clamp(1, selected.length)
            .toInt();
    final rows = (selected.length / resolvedColumns).ceil();

    return M3ECard(
      variant: M3ECardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        columnWidths: {
          for (var index = 0; index < resolvedColumns; index++)
            index: const FlexColumnWidth(),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: scheme.outlineVariant, width: 1),
          verticalInside: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        children: [
          for (var row = 0; row < rows; row++)
            TableRow(
              children: [
                for (var column = 0; column < resolvedColumns; column++)
                  if (row * resolvedColumns + column < selected.length)
                    _MetricCell(
                      metric: selected[row * resolvedColumns + column],
                    )
                  else
                    const SizedBox.shrink(),
              ],
            ),
        ],
      ),
    );
  }

  List<_Metric> _buildMetrics(AppLocalizations l10n) {
    final recorded = insights.recordedDays;
    final goal = l10n.formatGoalDelta(dailySleepGoal);

    final hitRate = insights.goalHitRate;
    final goalValue = hitRate == null
        ? '—'
        : l10n.metricPercent((hitRate * 100).round());
    final goalSupport = recorded == 0
        ? l10n.noNightsInRange
        : l10n.metricGoalHitSupport(insights.goalNights, recorded);

    final variability = insights.bedtimeVariability;
    final consistencyValue = variability == null
        ? '—'
        : l10n.metricVariability(l10n.formatGoalDelta(variability));
    final consistencySupport = variability != null
        ? l10n.metricBedtime
        : recorded == 0
        ? l10n.noNightsInRange
        : l10n.metricNeedsTwoNights;

    final balance = insights.sleepBalance;
    final balanceValue = balance == null
        ? '—'
        : l10n.formatSignedCompactDuration(balance);
    final balanceSupport = balance == null
        ? l10n.noNightsInRange
        : balance > Duration.zero
        ? l10n.metricBalanceSurplus(goal)
        : balance < Duration.zero
        ? l10n.metricBalanceDebt(goal)
        : l10n.metricBalanceEven(goal);

    final bestValue = recorded == 0
        ? '—'
        : l10n.metricNights(insights.longestGoalStreak);
    final bestSupport = recorded == 0
        ? l10n.noNightsInRange
        : l10n.metricBestStreakSupport(insights.currentGoalStreak);

    return [
      _Metric(
        label: l10n.metricGoalHitRate,
        value: goalValue,
        support: goalSupport,
      ),
      _Metric(
        label: l10n.metricScheduleConsistency,
        value: consistencyValue,
        support: consistencySupport,
      ),
      _Metric(
        label: l10n.metricSleepBalance,
        value: balanceValue,
        support: balanceSupport,
      ),
      _Metric(
        label: l10n.metricBestStreak,
        value: bestValue,
        support: bestSupport,
      ),
    ];
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.support,
  });

  final String label;
  final String value;
  final String support;
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.typography.baseline.labelMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = theme.typography.emphasized.headlineSmall.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final supportStyle = theme.typography.baseline.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: '${metric.label}, ${metric.value}, ${metric.support}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.label, style: labelStyle),
              const SizedBox(height: 4),
              Text(metric.value, style: valueStyle),
              const SizedBox(height: 4),
              Text(metric.support, style: supportStyle),
            ],
          ),
        ),
      ),
    );
  }
}
