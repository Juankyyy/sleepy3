import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../stats/application/stats_summary_controller.dart';
import '../../../stats/domain/stats_summary_option.dart';
import '../../../stats/presentation/stats_summary_labels.dart';
import '../../../stats/presentation/stats_summary_picker.dart';
import 'settings_list.dart';

/// The Settings row that opens the single-block Stats summary picker.
class StatsSummarySettings extends ConsumerWidget {
  const StatsSummarySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final option = ref.watch(statsSummaryControllerProvider);
    final showLeading = showSettingsLeadingIcons(context);

    return SettingsList(
      onTap: (_) => unawaited(_choose(context, ref, option)),
      children: [
        M3EListItem(
          leading: showLeading ? const Icon(M3EIcons.insights_outlined) : null,
          headline: l10n.statsSummary,
          supportingText: statsSummaryOptionLabel(l10n, option),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
      ],
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
