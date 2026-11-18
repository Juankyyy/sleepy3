import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../stats/application/stats_summary_controller.dart';
import '../../../stats/domain/stats_summary_option.dart';
import '../../../stats/presentation/stats_summary_labels.dart';
import '../../../stats/presentation/stats_summary_picker.dart';
import 'bento/bento_card.dart';
import 'bento/bento_figure.dart';
import 'bento/settings_tones.dart';

/// The Stats summary card. It opens the existing full-height picker.
class StatsSummaryCard extends ConsumerWidget {
  const StatsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tone = SettingsPalette.of(context).stats;
    final option = ref.watch(statsSummaryControllerProvider);
    final support = statsSummaryOptionLabel(l10n, option);

    return BentoCard(
      key: const ValueKey('settings-stats-card'),
      tone: tone,
      size: BentoCardSize.half,
      icon: M3EIcons.insights_outlined,
      figure: BentoFigureShape.puffyDiamond,
      title: l10n.statsSummary,
      supporting: support,
      semanticLabel: '${l10n.statsSummary}. $support',
      trailing: Icon(M3EIcons.chevron_right, size: 20, color: tone.supporting),
      onTap: () => unawaited(_choose(context, ref, option)),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    StatsSummaryOption option,
  ) async {
    final selected = await showStatsSummaryPicker(context, selected: option);
    if (!context.mounted || selected == null || selected == option) return;

    await ref.read(statsSummaryControllerProvider.notifier).select(selected);
  }
}
