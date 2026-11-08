import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/presentation/widgets/settings_list.dart';
import '../../application/sleep_reminder_controller.dart';

/// The `Reminders` section in Settings.
///
/// The switch row uses a custom filled surface instead of `M3EListItem`: the
/// grouped item clamps its headline to one line and excludes its children from
/// semantics, which would hide the switch from screen readers.
class SleepReminderSettings extends ConsumerStatefulWidget {
  const SleepReminderSettings({super.key});

  @override
  ConsumerState<SleepReminderSettings> createState() =>
      _SleepReminderSettingsState();
}

class _SleepReminderSettingsState extends ConsumerState<SleepReminderSettings> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);
    final state = ref.watch(sleepReminderControllerProvider);
    final reminder = state.reminder;
    final time = formatSessionTime(
      DateTime(2000, 1, 1, reminder.hour, reminder.minute),
      use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      localeName: l10n.localeName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReminderToggleRow(
          showLeading: showLeading,
          enabled: reminder.enabled,
          busy: _busy,
          headline: l10n.sleepReminder,
          supporting: reminder.enabled
              ? l10n.sleepReminderEveryDay(time)
              : l10n.sleepReminderOff,
          onChanged: _setEnabled,
        ),
        if (reminder.enabled) ...[
          const SizedBox(height: 2),
          _ReminderActionRow(
            showLeading: showLeading,
            leadingIcon: M3EIcons.schedule_outlined,
            headline: l10n.reminderTime,
            supporting: time,
            onTap: _pickTime,
          ),
        ],
        if (reminder.enabled && state.systemNotificationsEnabled == false) ...[
          const SizedBox(height: 2),
          _ReminderActionRow(
            showLeading: showLeading,
            leadingIcon: M3EIcons.notifications_off_outlined,
            headline: l10n.notificationsOff,
            supporting: l10n.notificationsOffSupport,
            onTap: _openNotificationSettings,
          ),
        ],
      ],
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

/// A switch row with the same filled list surface as Settings.
///
/// It is not an [M3EListItem] because that item clamps its headline to one
/// line and excludes child semantics, which hides the switch from TalkBack.
class _ReminderToggleRow extends StatelessWidget {
  const _ReminderToggleRow({
    required this.showLeading,
    required this.enabled,
    required this.busy,
    required this.headline,
    required this.supporting,
    required this.onChanged,
  });

  final bool showLeading;
  final bool enabled;
  final bool busy;
  final String headline;
  final String supporting;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final rowStyle = theme.typography.baseline.bodyLarge.copyWith(
      color: scheme.onSurface,
    );
    final supportStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    void toggle() {
      if (!busy) onChanged(!enabled);
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      toggled: enabled,
      label: headline,
      hint: supporting,
      enabled: !busy,
      onTap: busy ? null : toggle,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : toggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (showLeading) ...[
                    Icon(
                      M3EIcons.bedtime_outlined,
                      size: 24,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline, style: rowStyle),
                        const SizedBox(height: 2),
                        Text(supporting, style: supportStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: M3ESwitch(
                        value: enabled,
                        onChanged: busy ? null : (_) {},
                      ),
                    ),
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

/// A tappable reminder row with the same filled surface as the Settings lists.
///
/// It allows the headline and supporting text to wrap at large text scales,
/// which [M3EListItem] cannot do because it clamps the headline to one line.
class _ReminderActionRow extends StatelessWidget {
  const _ReminderActionRow({
    required this.showLeading,
    required this.leadingIcon,
    required this.headline,
    required this.supporting,
    required this.onTap,
  });

  final bool showLeading;
  final IconData leadingIcon;
  final String headline;
  final String supporting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final rowStyle = theme.typography.baseline.bodyLarge.copyWith(
      color: scheme.onSurface,
    );
    final supportStyle = theme.typography.baseline.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: headline,
      hint: supporting,
      onTap: onTap,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (showLeading) ...[
                    Icon(leadingIcon, size: 24, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline, style: rowStyle),
                        const SizedBox(height: 2),
                        Text(supporting, style: supportStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    M3EIcons.chevron_right,
                    size: 24,
                    color: scheme.onSurfaceVariant,
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
