import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../backup/presentation/history_data_settings.dart';
import '../../health/application/sleep_data_source_controller.dart';
import 'settings_page.dart';
import 'widgets/google_health_status_list.dart';
import 'widgets/settings_section.dart';
import 'widgets/sleep_data_source_setting.dart';

/// The sleep data page: source, Google Health and local backup.
///
/// The page keeps the grouped list pattern for the detailed actions, while the
/// home uses the bento cards.
class SleepDataPage extends ConsumerWidget {
  const SleepDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(sleepDataSourceProvider);
    final l10n = context.l10n;

    return SettingsPage(
      key: const ValueKey('sleep-data-page'),
      title: l10n.sleepData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SleepDataSourceSetting(source: source),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.googleHealth,
            child: const GoogleHealthStatusList(),
          ),
          const SizedBox(height: 24),
          SettingsSection(title: l10n.data, child: const HistoryDataSettings()),
        ],
      ),
    );
  }
}
