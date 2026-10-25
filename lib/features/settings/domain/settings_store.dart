import 'app_theme_mode.dart';

/// Persists user preferences that are not part of a sleep session.
abstract interface class SettingsStore {
  Future<AppThemeMode> loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);
}
