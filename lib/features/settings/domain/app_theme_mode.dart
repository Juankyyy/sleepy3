import 'dart:ui' show Brightness;

/// The user's theme preference.
///
/// [system] follows the device brightness. [light] and [dark] pin the app to
/// that scheme regardless of the platform setting.
enum AppThemeMode {
  system,
  light,
  dark;

  /// The brightness to use for [platformBrightness].
  Brightness resolveBrightness(Brightness platformBrightness) {
    return switch (this) {
      AppThemeMode.system => platformBrightness,
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
    };
  }

  /// Parses a stored value, falling back to [system] for unknown data.
  static AppThemeMode fromStorageValue(String? value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return system;
  }
}
