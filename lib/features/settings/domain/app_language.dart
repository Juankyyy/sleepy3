import 'dart:ui' show Locale;

/// The language the app interface is shown in.
///
/// There is no visible `System` option. When the user has never chosen a
/// language, the loader in `main` resolves the phone's language once and
/// stores it, so the choice stays fixed afterwards, matching the time format.
enum AppLanguage {
  english('en'),
  spanish('es');

  const AppLanguage(this.languageCode);

  /// The locale used by `MaterialApp` and by date formatting.
  final String languageCode;

  Locale get locale => Locale(languageCode);

  /// The first supported language in the device's preferred locales.
  ///
  /// This matches Flutter's locale resolution: unsupported locales are
  /// skipped, and a device with no supported language falls back to English.
  static AppLanguage forSystem(Iterable<Locale> locales) {
    for (final locale in locales) {
      if (locale.languageCode == english.languageCode) return english;
      if (locale.languageCode == spanish.languageCode) return spanish;
    }
    return english;
  }

  /// Parses a stored value, returning null for missing or unknown data.
  ///
  /// Null means the caller should fall back to the phone's language.
  static AppLanguage? fromStorageValue(String? value) {
    for (final language in values) {
      if (language.name == value) return language;
    }
    return null;
  }
}
