import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/sleep_insights.dart';
import '../../domain/stats_summary_option.dart';
import '../charts/sleep_duration_chart.dart';
import '../charts/sleep_window_chart.dart';
import '../charts/weekday_chart.dart';
import 'stats_hero_card.dart';
import 'stats_insights_card.dart';
import 'stats_metrics_card.dart';

/// The single customizable block above **View advanced stats**.
///
/// Each option is a real Stats block, not a reduced copy. The picker previews
/// the same widgets, so the choice always matches what the summary shows.
class StatsSummaryPanel extends StatelessWidget {
  const StatsSummaryPanel({
    super.key,
    required this.option,
    required this.insights,
    required this.historyLimited,
  });

  final StatsSummaryOption option;
  final SleepInsights insights;
  final bool historyLimited;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: Key('stats-summary-${option.name}'),
      child: switch (option) {
        StatsSummaryOption.averageSleep => StatsHeroCard(insights: insights),
        StatsSummaryOption.keyMetrics => StatsMetricsCard(insights: insights),
        StatsSummaryOption.sleepDuration => SleepDurationChart(
          insights: insights,
          historyLimited: historyLimited,
        ),
        StatsSummaryOption.sleepWindow => SleepWindowChart(
          insights: insights,
          historyLimited: historyLimited,
        ),
        StatsSummaryOption.weekday => WeekdayChart(
          insights: insights,
          historyLimited: historyLimited,
        ),
        StatsSummaryOption.keyData => StatsInsightsCard(
          insights: insights,
          compact: true,
        ),
      },
    );
  }
}
