import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/sleepy3_theme.dart';
import '../../../l10n/l10n.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../reminders/presentation/widgets/sleep_reminder_settings.dart';
import '../application/app_version_provider.dart';
import '../application/language_controller.dart';
import '../application/theme_mode_controller.dart';
import '../application/time_format_controller.dart';
import 'widgets/about_list.dart';
import 'widgets/appearance_settings.dart';
import 'widgets/google_health_status_list.dart';
import 'widgets/settings_section.dart';
import 'widgets/sleep_data_source_setting.dart';

/// The Settings destination: appearance, sleep data, Google Health and app info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final margin = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeControllerProvider);
    final timeFormat = ref.watch(timeFormatControllerProvider);
    final language = ref.watch(languageControllerProvider);
    final dataSource = ref.watch(sleepDataSourceProvider);
    final appVersion = ref.watch(appVersionProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(margin, 16, margin, 24 + bottomInset),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.settingsTitle,
            style: Sleepy3Theme.brandTitle(
              theme.typography.emphasized.headlineMedium,
            ).copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.settingsSupport,
          style: theme.typography.baseline.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: l10n.appearance,
          child: AppearanceSettings(
            mode: themeMode,
            timeFormat: timeFormat,
            language: language,
          ),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: l10n.reminders,
          child: const SleepReminderSettings(),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: l10n.sleepData,
          child: SleepDataSourceSetting(source: dataSource),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: l10n.googleHealth,
          child: const GoogleHealthStatusList(),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: l10n.about,
          child: AboutList(version: appVersion, dataSource: dataSource),
        ),
      ],
    );
  }
}
