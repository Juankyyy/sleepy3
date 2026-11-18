import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/sleepy3_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../application/sleep_goal_controller.dart';
import '../sleep_goal_picker.dart';
import 'bento/bento_card.dart';
import 'bento/bento_figure.dart';
import 'bento/settings_tones.dart';

/// The nightly goal card at the top of Settings.
class SleepGoalCard extends ConsumerWidget {
  const SleepGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final tone = SettingsPalette.of(context).sleepGoal;
    final goal = ref.watch(sleepGoalProvider);
    final compact = l10n.formatGoalDelta(goal);
    final unitStyle = bentoSupportStyle(
      context,
      BentoCardSize.wide,
      tone.supporting,
    );

    return BentoCard(
      key: const ValueKey('settings-goal-card'),
      tone: tone,
      size: BentoCardSize.wide,
      icon: M3EIcons.bedtime_outlined,
      figure: BentoFigureShape.arch,
      title: l10n.sleepGoal,
      semanticLabel: '${l10n.sleepGoal}. ${l10n.sleepGoalValue(compact)}',
      trailing: Icon(M3EIcons.chevron_right, size: 20, color: tone.supporting),
      minHeight: 160,
      onTap: () => unawaited(showSleepGoalPicker(context, ref, goal)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sleepGoal,
            style: bentoTitleStyle(
              context,
              BentoCardSize.wide,
              tone.onBackground,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                compact,
                style: Sleepy3Theme.clock(
                  theme.typography.emphasized.displaySmall,
                ).copyWith(color: tone.onBackground),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(l10n.sleepGoalPerNight, style: unitStyle)),
            ],
          ),
        ],
      ),
    );
  }
}
