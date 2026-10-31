import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../health/application/sleep_data_source_controller.dart';
import '../application/app_version_provider.dart';
import '../application/theme_mode_controller.dart';
import 'widgets/about_list.dart';
import 'widgets/google_health_status_list.dart';
import 'widgets/settings_section.dart';
import 'widgets/sleep_data_source_setting.dart';
import 'widgets/theme_setting.dart';

/// The Settings destination: appearance, sleep data, Google Health and app info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final margin = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    final themeMode = ref.watch(themeModeControllerProvider);
    final dataSource = ref.watch(sleepDataSourceProvider);
    final appVersion = ref.watch(appVersionProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(margin, 16, margin, 24),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Settings',
            style: theme.typography.emphasized.headlineMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Theme, sleep data and app info.',
          style: theme.typography.baseline.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Appearance',
          child: ThemeSetting(mode: themeMode),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'Sleep data',
          child: SleepDataSourceSetting(source: dataSource),
        ),
        const SizedBox(height: 24),
        const SettingsSection(
          title: 'Google Health',
          child: GoogleHealthStatusList(),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'About',
          child: AboutList(version: appVersion, dataSource: dataSource),
        ),
      ],
    );
  }
}
