import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../health/application/health_sync_controller.dart';
import '../../../health/application/sleep_data_source_controller.dart';
import '../../../health/presentation/health_status_text.dart';
import '../../../health/presentation/sleep_data_source_text.dart';
import '../sleep_data_page.dart';
import 'bento/bento_card.dart';
import 'bento/bento_figure.dart';
import 'bento/settings_tones.dart';

/// The wide Sleep data card: current source and Google Health state.
class SleepDataCard extends ConsumerWidget {
  const SleepDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tone = SettingsPalette.of(context).data;
    final source = ref.watch(sleepDataSourceProvider);
    final health = ref.watch(healthSyncControllerProvider);
    final support =
        '${l10n.sleepDataSourceLabel(source)} · '
        '${healthStatusText(context, health)}';

    return BentoCard(
      key: const ValueKey('settings-data-card'),
      tone: tone,
      size: BentoCardSize.wide,
      icon: M3EIcons.storage_outlined,
      figure: BentoFigureShape.clamShell,
      title: l10n.sleepData,
      supporting: support,
      semanticLabel: '${l10n.sleepData}. $support',
      trailing: Icon(M3EIcons.chevron_right, size: 20, color: tone.supporting),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SleepDataPage()));
      },
    );
  }
}
