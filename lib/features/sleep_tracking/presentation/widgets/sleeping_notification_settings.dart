import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../settings/presentation/widgets/settings_list.dart';
import '../../../settings/presentation/widgets/settings_toggle_row.dart';
import '../../application/sleep_tracking_controller.dart';
import '../../application/sleeping_notification_controller.dart';
import '../../application/sleeping_notification_enabled_controller.dart';

/// The sleep-status switch in the `Reminders` section of Settings.
///
/// Enabling it asks for notification permission first; a denial leaves the
/// switch off and offers the Android notification settings. Changing the
/// switch immediately shows or hides the card when a session is open.
class SleepingNotificationSettings extends ConsumerStatefulWidget {
  const SleepingNotificationSettings({super.key});

  @override
  ConsumerState<SleepingNotificationSettings> createState() =>
      _SleepingNotificationSettingsState();
}

class _SleepingNotificationSettingsState
    extends ConsumerState<SleepingNotificationSettings> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = ref.watch(sleepingNotificationEnabledProvider);

    return SettingsToggleRow(
      showLeading: showSettingsLeadingIcons(context),
      leadingIcon: M3EIcons.notifications_active_outlined,
      switchKey: const ValueKey('sleep-status-switch'),
      enabled: enabled,
      busy: _busy,
      headline: l10n.sleepStatusNotification,
      supporting: enabled
          ? l10n.sleepStatusNotificationSupport
          : l10n.sleepStatusNotificationOff,
      onChanged: _setEnabled,
    );
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);

    final controller = ref.read(sleepingNotificationControllerProvider);
    if (enabled) {
      final granted = await controller.requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _busy = false);
        _showPermissionFailure();
        return;
      }
    }

    await ref
        .read(sleepingNotificationEnabledProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    setState(() => _busy = false);

    await controller.sync(
      openSession: ref.read(sleepTrackingControllerProvider).openSession,
    );
  }

  void _showPermissionFailure() {
    final l10n = context.l10n;
    final controller = ref.read(sleepingNotificationControllerProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.sleepStatusNotificationPermissionNeeded),
          action: SnackBarAction(
            label: l10n.openSettings,
            onPressed: controller.openNotificationSettings,
          ),
        ),
      );
  }
}
