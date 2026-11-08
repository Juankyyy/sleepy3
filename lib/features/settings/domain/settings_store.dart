import '../../health/domain/sleep_data_source.dart';
import '../../reminders/domain/sleep_reminder.dart';
import 'app_language.dart';
import 'app_theme_mode.dart';
import 'app_time_format.dart';

/// Persists user preferences that are not part of a sleep session.
abstract interface class SettingsStore {
  Future<AppThemeMode> loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);

  /// The saved clock format, or null when the user has never chosen one.
  Future<AppTimeFormat?> loadTimeFormat();

  Future<void> saveTimeFormat(AppTimeFormat format);

  /// The saved interface language, or null when the user has never chosen one.
  Future<AppLanguage?> loadLanguage();

  Future<void> saveLanguage(AppLanguage language);

  /// The source Home and Stats read, defaulting to [SleepDataSource.local].
  Future<SleepDataSource> loadSleepDataSource();

  Future<void> saveSleepDataSource(SleepDataSource source);

  /// The nightly reminder preference, defaulting to disabled at 22:00.
  Future<SleepReminder> loadSleepReminder();

  Future<void> saveSleepReminder(SleepReminder reminder);
}
