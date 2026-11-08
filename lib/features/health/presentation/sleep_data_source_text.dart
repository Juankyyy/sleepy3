import '../../../l10n/l10n.dart';
import '../domain/sleep_data_source.dart';

/// Locale-aware labels for the sleep data source.
extension SleepDataSourceText on AppLocalizations {
  /// The user-facing name of a data source.
  String sleepDataSourceLabel(SleepDataSource source) {
    return switch (source) {
      SleepDataSource.local => sourceLocal,
      SleepDataSource.healthConnect => sourceHealth,
    };
  }

  /// The privacy line shown in Settings for the active source.
  String sleepDataSourcePrivacy(SleepDataSource source) {
    return switch (source) {
      SleepDataSource.local => privacyLocal,
      SleepDataSource.healthConnect => privacyHealth,
    };
  }
}
