import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/presentation/widgets/bento/bento_card.dart';
import '../../../settings/presentation/widgets/bento/bento_figure.dart';
import '../../../settings/presentation/widgets/bento/settings_tones.dart';
import '../../application/sleep_reminder_controller.dart';

/// The nightly reminder card in the Settings bento.
///
/// The whole card toggles the reminder; the time chip below is a separate
/// action and lives outside the card's switch semantics.
class SleepReminderCard extends ConsumerStatefulWidget {
  const SleepReminderCard({super.key});

  @override
  ConsumerState<SleepReminderCard> createState() => _SleepReminderCardState();
}

class _SleepReminderCardState extends ConsumerState<SleepReminderCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = SettingsPalette.of(context).reminder;
    final state = ref.watch(sleepReminderControllerProvider);
    final reminder = state.reminder;
    final time = formatSessionTime(
      DateTime(2000, 1, 1, reminder.hour, reminder.minute),
      use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      localeName: l10n.localeName,
    );
    final support = reminder.enabled
        ? l10n.sleepReminderDaily
        : l10n.sleepReminderOff;

    return BentoCard(
      key: const ValueKey('settings-reminder-card'),
      tone: tone,
      size: BentoCardSize.half,
      icon: M3EIcons.notifications_active_outlined,
      figure: BentoFigureShape.softBurst,
      title: l10n.sleepReminder,
      supporting: support,
      semanticLabel: l10n.sleepReminder,
      semanticHint: reminder.enabled
          ? l10n.sleepReminderEveryDay(time)
          : l10n.sleepReminderOff,
      toggled: reminder.enabled,
      onTap: () => unawaited(_setEnabled(!reminder.enabled)),
      trailing: IgnorePointer(
        child: M3ESwitch(
          key: const ValueKey('sleep-reminder-switch'),
          value: reminder.enabled,
          onChanged: (_) {},
        ),
      ),
      footer: reminder.enabled
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _TimeChip(
                    time: time,
                    color: tone.onBackground,
                    onTap: _pickTime,
                  ),
                ),
                if (state.systemNotificationsEnabled == false) ...[
                  const SizedBox(height: 4),
                  _NotificationWarning(
                    color: tone.onBackground,
                    onTap: _openNotificationSettings,
                  ),
                ],
              ],
            )
          : null,
    );
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await ref
        .read(sleepReminderControllerProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) _showFailure(failure);
  }

  Future<void> _pickTime() async {
    final l10n = context.l10n;
    final reminder = ref.read(sleepReminderControllerProvider).reminder;
    final picked = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(hour: reminder.hour, minute: reminder.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: l10n.reminderTime,
    );
    if (picked == null || !mounted) return;

    final failure = await ref
        .read(sleepReminderControllerProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
    if (!mounted || failure == null) return;
    _showFailure(failure);
  }

  Future<void> _openNotificationSettings() {
    return ref
        .read(sleepReminderControllerProvider.notifier)
        .openNotificationSettings();
  }

  void _showFailure(SleepReminderChangeFailure failure) {
    final l10n = context.l10n;
    final message = switch (failure) {
      SleepReminderChangeFailure.notificationsDenied =>
        l10n.notificationsPermissionNeeded,
      SleepReminderChangeFailure.schedulingFailed =>
        l10n.sleepReminderScheduleFailed,
    };
    final controller = ref.read(sleepReminderControllerProvider.notifier);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: failure == SleepReminderChangeFailure.notificationsDenied
              ? SnackBarAction(
                  label: l10n.openSettings,
                  onPressed: controller.openNotificationSettings,
                )
              : null,
        ),
      );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.color,
    required this.onTap,
  });

  final String time;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textStyle = M3ETheme.of(context).typography.baseline.labelLarge
        .copyWith(color: color);

    return Semantics(
      button: true,
      label: l10n.reminderTime,
      hint: time,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('sleep-reminder-time'),
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(M3EIcons.schedule_outlined, size: 15, color: color),
                const SizedBox(width: 5),
                Flexible(child: Text(time, style: textStyle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationWarning extends StatelessWidget {
  const _NotificationWarning({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = M3ETheme.of(context).typography;

    return Semantics(
      button: true,
      label: l10n.notificationsOff,
      hint: l10n.notificationsOffSupport,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notificationsOff,
                    style: typography.baseline.labelMedium.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l10n.notificationsOffSupport,
                    style: typography.baseline.bodySmall.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
