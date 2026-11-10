import '../../../l10n/l10n.dart';
import '../domain/stats_summary_option.dart';

/// The localized name of a summary block.
String statsSummaryOptionLabel(
  AppLocalizations l10n,
  StatsSummaryOption option,
) {
  return switch (option) {
    StatsSummaryOption.averageSleep => l10n.averageSleep,
    StatsSummaryOption.keyMetrics => l10n.statsSummaryKeyMetrics,
    StatsSummaryOption.sleepDuration => l10n.chartSleepDurationTitle,
    StatsSummaryOption.sleepWindow => l10n.chartSleepWindowTitle,
    StatsSummaryOption.weekday => l10n.chartWeekdayTitle,
    StatsSummaryOption.keyData => l10n.statsSummaryKeyData,
  };
}
