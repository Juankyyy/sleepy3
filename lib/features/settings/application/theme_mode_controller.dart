import 'package:flutter/foundation.dart';
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

/// Owns the theme preference and persists changes in order.
///
/// The state updates immediately. A failed write is logged but does not revert
/// the visible choice, matching how session writes behave.
class ThemeModeController extends Notifier<AppThemeMode> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  AppThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state) return;
    state = mode;

    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue.then((_) => store.saveThemeMode(mode)).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('Sleepy3: could not persist theme: $error\n$stackTrace');
    });
    _writeQueue = next;
    await next;
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, AppThemeMode>(
      ThemeModeController.new,
    );
