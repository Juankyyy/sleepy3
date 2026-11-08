import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_app_night_mode.dart';
import '../domain/app_language.dart';
import '../domain/app_night_mode.dart';
import '../domain/app_theme_mode.dart';
import '../domain/app_time_format.dart';
import '../domain/settings_store.dart';

/// Overridden in `main` with the Drift-backed store.
final settingsStoreProvider = Provider<SettingsStore>((ref) {
  throw UnimplementedError(
    'settingsStoreProvider must be overridden with a SettingsStore',
  );
});

/// Overridden in `main` with the mode loaded before the first frame.
final initialThemeModeProvider = Provider<AppThemeMode>(
  (ref) => AppThemeMode.system,
);

/// Overridden in `main` with the format resolved before the first frame.
///
/// The fallback follows the phone so widgets that read this provider without
/// an explicit override still get the platform's 12/24-hour setting.
final initialTimeFormatProvider = Provider<AppTimeFormat>(
  (ref) => AppTimeFormat.forSystem(
    PlatformDispatcher.instance.alwaysUse24HourFormat,
  ),
);

/// Overridden in `main` with the language resolved before the first frame.
///
/// The fallback follows the phone so widgets that read this provider without
/// an explicit override still get a supported language.
final initialLanguageProvider = Provider<AppLanguage>(
  (ref) => AppLanguage.forSystem(PlatformDispatcher.instance.locales),
);

/// Keeps Android's per-app night mode aligned with the in-app theme.
///
/// The platform persists it and uses it to resolve the next launch splash.
final appNightModeProvider = Provider<AppNightMode>(
  (ref) => const AndroidAppNightMode(),
);
