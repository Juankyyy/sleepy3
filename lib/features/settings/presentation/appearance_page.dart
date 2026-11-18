import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/language_controller.dart';
import '../application/theme_mode_controller.dart';
import '../application/time_format_controller.dart';
import 'settings_page.dart';
import 'widgets/appearance_settings.dart';

/// The appearance page: theme, clock format and language.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final timeFormat = ref.watch(timeFormatControllerProvider);
    final language = ref.watch(languageControllerProvider);
    final l10n = context.l10n;

    return SettingsPage(
      key: const ValueKey('appearance-page'),
      title: l10n.appearance,
      child: AppearanceSettings(
        mode: themeMode,
        timeFormat: timeFormat,
        language: language,
      ),
    );
  }
}
