import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_theme_mode.dart';
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
