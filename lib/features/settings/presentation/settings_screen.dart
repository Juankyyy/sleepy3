import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/sleepy3_theme.dart';
import '../../../l10n/l10n.dart';
import '../../reminders/presentation/widgets/sleep_reminder_card.dart';
import '../../sleep_tracking/presentation/widgets/sleeping_notification_card.dart';
import 'widgets/about_card.dart';
import 'widgets/appearance_card.dart';
import 'widgets/sleep_data_card.dart';
import 'widgets/sleep_goal_card.dart';
import 'widgets/stats_summary_card.dart';

/// The Settings destination: a bento of tonal cards plus the About card.
///
/// The detailed controls live in the Appearance and Sleep data pages. The
/// home keeps only the settings that are worth seeing at a glance.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final margin = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;

    return ListView(
      key: const ValueKey('settings-home-list'),
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
        const SizedBox(height: 16),
        const SleepGoalCard(),
        const SizedBox(height: 12),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SleepReminderCard()),
              SizedBox(width: 12),
              Expanded(child: SleepingNotificationCard()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SleepDataCard(),
        const SizedBox(height: 12),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AppearanceCard()),
              SizedBox(width: 12),
              Expanded(child: StatsSummaryCard()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const AboutCard(),
      ],
    );
  }
}
