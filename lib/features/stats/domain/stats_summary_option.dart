/// The block shown above **View advanced stats** on the Stats tab.
///
/// Only one block is shown at a time. The four small metrics count as one
/// option, and the advanced sheet keeps showing every block regardless of this
/// preference.
enum StatsSummaryOption {
  /// The average-sleep hero card.
  averageSleep,

  /// The four small metric tiles.
  keyMetrics,

  /// The sleep-duration chart.
  sleepDuration,

  /// The bedtime-to-wake window chart.
  sleepWindow,

  /// The average sleep by weekday chart.
  weekday,

  /// The compact horizontal version of the key-data card.
  keyData;

  /// The block shown before the user chooses one.
  ///
  /// Sleep duration is the default so the summary opens on the chart the user
  /// asked for.
  static const defaultOption = StatsSummaryOption.sleepDuration;

  /// Parses the stored preference, falling back to [defaultOption] for a
  /// missing or unknown value.
  static StatsSummaryOption fromStorageValue(String? value) {
    for (final option in values) {
      if (option.name == value) return option;
    }
    return defaultOption;
  }
}
