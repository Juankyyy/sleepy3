import '../../../l10n/l10n.dart';
import '../domain/app_language.dart';
import '../domain/app_theme_mode.dart';
import '../domain/app_time_format.dart';

/// The localized labels shown by the Appearance card and its page.
String themeModeLabel(AppLocalizations l10n, AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => l10n.themeSystem,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.dark => l10n.themeDark,
    AppThemeMode.amoled => l10n.themeAmoled,
  };
}

String timeFormatLabel(AppLocalizations l10n, AppTimeFormat format) {
  return switch (format) {
    AppTimeFormat.twelveHour => l10n.timeFormat12,
    AppTimeFormat.twentyFourHour => l10n.timeFormat24,
  };
}

String languageLabel(AppLocalizations l10n, AppLanguage language) {
  return switch (language) {
    AppLanguage.english => l10n.languageEnglish,
    AppLanguage.spanish => l10n.languageSpanish,
  };
}
