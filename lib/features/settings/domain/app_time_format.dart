/// The user's clock preference: 12-hour or 24-hour.
///
/// The app has no visible `System` option. When the user has never chosen a
/// format, the caller resolves the phone's setting once and stores it, so the
/// choice stays fixed afterwards.
enum AppTimeFormat {
  twelveHour,
  twentyFourHour;

  /// Whether times should render with a 24-hour clock.
  bool get uses24HourFormat => this == AppTimeFormat.twentyFourHour;

  /// The format that matches the phone's current 24-hour setting.
  static AppTimeFormat forSystem(bool alwaysUse24HourFormat) {
    return alwaysUse24HourFormat
        ? AppTimeFormat.twentyFourHour
        : AppTimeFormat.twelveHour;
  }

  /// Parses a stored value, returning null for missing or unknown data.
  ///
  /// Null means the caller should fall back to the phone's format.
  static AppTimeFormat? fromStorageValue(String? value) {
    for (final format in values) {
      if (format.name == value) return format;
    }
    return null;
  }
}
