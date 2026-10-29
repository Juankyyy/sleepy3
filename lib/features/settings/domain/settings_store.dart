import '../../health/domain/sleep_data_source.dart';
import 'app_theme_mode.dart';

/// Persists user preferences that are not part of a sleep session.
abstract interface class SettingsStore {
  Future<AppThemeMode> loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);

  /// The source Home and Stats read, defaulting to [SleepDataSource.local].
  Future<SleepDataSource> loadSleepDataSource();

  Future<void> saveSleepDataSource(SleepDataSource source);
}
