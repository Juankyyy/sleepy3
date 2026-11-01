import 'app_theme_mode.dart';

/// Mirrors the in-app theme into the platform's per-app night mode.
///
/// Android 12+ uses the mode to resolve the launch (splash) window and its
/// resources with the same light or dark choice as the app. Older versions do
/// not have a per-app night mode and ignore it.
abstract interface class AppNightMode {
  Future<void> setMode(AppThemeMode mode);
}
