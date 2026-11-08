import '../../health/domain/sleep_data_source.dart';
import '../../sleep_tracking/data/sleepy3_database.dart';
import '../domain/app_language.dart';
import '../domain/app_theme_mode.dart';
import '../domain/app_time_format.dart';
import '../domain/settings_store.dart';

/// Stores settings in the app's single Drift database.
class DriftSettingsStore implements SettingsStore {
  DriftSettingsStore(this._db);

  final Sleepy3Database _db;

  static const _themeModeKey = 'theme_mode';
  static const _timeFormatKey = 'time_format';
  static const _languageKey = 'language';
  static const _sleepDataSourceKey = 'sleep_data_source';

  @override
  Future<AppThemeMode> loadThemeMode() async {
    return AppThemeMode.fromStorageValue(await _read(_themeModeKey));
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) {
    return _write(_themeModeKey, mode.name);
  }

  @override
  Future<AppTimeFormat?> loadTimeFormat() async {
    return AppTimeFormat.fromStorageValue(await _read(_timeFormatKey));
  }

  @override
  Future<void> saveTimeFormat(AppTimeFormat format) {
    return _write(_timeFormatKey, format.name);
  }

  @override
  Future<AppLanguage?> loadLanguage() async {
    return AppLanguage.fromStorageValue(await _read(_languageKey));
  }

  @override
  Future<void> saveLanguage(AppLanguage language) {
    return _write(_languageKey, language.name);
  }

  @override
  Future<SleepDataSource> loadSleepDataSource() async {
    return SleepDataSource.fromStorageValue(await _read(_sleepDataSourceKey));
  }

  @override
  Future<void> saveSleepDataSource(SleepDataSource source) {
    return _write(_sleepDataSourceKey, source.storageValue);
  }

  Future<String?> _read(String key) async {
    final query = _db.select(_db.preferences)
      ..where((row) => row.settingKey.equals(key));
    final row = await query.getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> _write(String key, String value) async {
    await _db
        .into(_db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(settingKey: key, settingValue: value),
        );
  }
}
