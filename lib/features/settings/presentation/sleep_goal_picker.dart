import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../sleep_tracking/domain/sleep_goal.dart';
import '../application/sleep_goal_controller.dart';

/// Opens the nightly goal picker. The home card and any future entry point
/// share this dialog so the validation and persistence stay in one place.
Future<void> showSleepGoalPicker(
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
