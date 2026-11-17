import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../application/sleep_goal_controller.dart';
import 'settings_action_row.dart';
import 'settings_list.dart';

/// The Settings row that opens the nightly goal picker.
///
/// The row uses [SettingsActionRow] instead of `M3EListItem` so the headline
/// and supporting text can wrap at large text scales.
class SleepGoalSettings extends ConsumerWidget {
  const SleepGoalSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goal = ref.watch(sleepGoalProvider);

    return SettingsActionRow(
      showLeading: showSettingsLeadingIcons(context),
      leadingIcon: M3EIcons.bedtime_outlined,
      headline: l10n.sleepGoal,
      supporting: l10n.sleepGoalValue(l10n.formatGoalDelta(goal)),
      onTap: () => unawaited(_choose(context, ref, goal)),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    Duration goal,
  ) async {
    final l10n = context.l10n;
    final options = [
      for (final option in sleepGoalOptions) l10n.formatGoalDelta(option),
    ];
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: l10n.sleepGoal,
      options: options,
      initialSelection: [l10n.formatGoalDelta(goal)],
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.apply,
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    final index = options.indexOf(selected.single);
    if (index < 0) return;
    await ref.read(sleepGoalProvider.notifier).setGoal(sleepGoalOptions[index]);
  }
}
