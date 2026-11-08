import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/language_controller.dart';
import '../../application/theme_mode_controller.dart';
import '../../application/time_format_controller.dart';
import '../../domain/app_language.dart';
import '../../domain/app_theme_mode.dart';
import '../../domain/app_time_format.dart';
import 'settings_list.dart';

/// The appearance settings: theme, clock format and language.
///
/// The row actions live on [SettingsList]; `M3EList` routes taps at the list
/// level.
class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({
    super.key,
    required this.mode,
    required this.timeFormat,
    required this.language,
  });

  final AppThemeMode mode;
  final AppTimeFormat timeFormat;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);

    return SettingsList(
      onTap: (index) {
        switch (index) {
          case 0:
            _chooseTheme(context, ref);
          case 1:
            _chooseTimeFormat(context, ref);
          case 2:
            _chooseLanguage(context, ref);
        }
      },
      children: [
        M3EListItem(
          leading: showLeading ? const Icon(M3EIcons.palette_outlined) : null,
          headline: l10n.theme,
          supportingText: _themeLabel(l10n, mode),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
        M3EListItem(
          leading: showLeading ? const Icon(M3EIcons.schedule_outlined) : null,
          headline: l10n.timeFormat,
          supportingText: _timeFormatLabel(l10n, timeFormat),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
        M3EListItem(
          leading: showLeading ? const Icon(M3EIcons.language_outlined) : null,
          headline: l10n.language,
          supportingText: _languageLabel(l10n, language),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _chooseTheme(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: l10n.theme,
      options: [
        for (final option in AppThemeMode.values) _themeLabel(l10n, option),
      ],
      initialSelection: [_themeLabel(l10n, mode)],
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.apply,
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    for (final option in AppThemeMode.values) {
      if (_themeLabel(l10n, option) == selected.single) {
        await ref.read(themeModeControllerProvider.notifier).setMode(option);
        return;
      }
    }
  }

  Future<void> _chooseTimeFormat(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: l10n.timeFormat,
      options: [
        for (final option in AppTimeFormat.values)
          _timeFormatLabel(l10n, option),
      ],
      initialSelection: [_timeFormatLabel(l10n, timeFormat)],
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.apply,
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    for (final option in AppTimeFormat.values) {
      if (_timeFormatLabel(l10n, option) == selected.single) {
        await ref.read(timeFormatControllerProvider.notifier).setFormat(option);
        return;
      }
    }
  }

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: l10n.language,
      options: [l10n.languageEnglish, l10n.languageSpanish],
      initialSelection: [_languageLabel(l10n, language)],
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.apply,
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    final target = selected.single == l10n.languageSpanish
        ? AppLanguage.spanish
        : AppLanguage.english;
    await ref.read(languageControllerProvider.notifier).setLanguage(target);
  }

  static String _themeLabel(AppLocalizations l10n, AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };
  }

  static String _timeFormatLabel(AppLocalizations l10n, AppTimeFormat format) {
    return switch (format) {
      AppTimeFormat.twelveHour => l10n.timeFormat12,
      AppTimeFormat.twentyFourHour => l10n.timeFormat24,
    };
  }

  static String _languageLabel(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.spanish => l10n.languageSpanish,
    };
  }
}
