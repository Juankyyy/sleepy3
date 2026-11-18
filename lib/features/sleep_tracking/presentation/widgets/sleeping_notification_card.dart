import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../settings/presentation/widgets/bento/bento_card.dart';
import '../../../settings/presentation/widgets/bento/bento_figure.dart';
import '../../../settings/presentation/widgets/bento/settings_tones.dart';
import '../../application/sleep_tracking_controller.dart';
import '../../application/sleeping_notification_controller.dart';
import '../../application/sleeping_notification_enabled_controller.dart';

/// The `Sleep in progress` switch as a Settings bento card.
class SleepingNotificationCard extends ConsumerStatefulWidget {
  const SleepingNotificationCard({super.key});

  @override
  ConsumerState<SleepingNotificationCard> createState() =>
      _SleepingNotificationCardState();
}

class _SleepingNotificationCardState
    extends ConsumerState<SleepingNotificationCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = SettingsPalette.of(context).sleepStatus;
    final enabled = ref.watch(sleepingNotificationEnabledProvider);

    return BentoCard(
      key: const ValueKey('settings-sleep-status-card'),
      tone: tone,
      size: BentoCardSize.half,
      icon: M3EIcons.timer_outlined,
      figure: BentoFigureShape.puffy,
      title: l10n.sleepStatusNotification,
      supporting: enabled
          ? l10n.sleepStatusNotificationSupport
          : l10n.sleepStatusNotificationOff,
      semanticLabel: l10n.sleepStatusNotification,
      semanticHint: enabled
          ? l10n.sleepStatusNotificationSupport
          : l10n.sleepStatusNotificationOff,
      toggled: enabled,
      onTap: () => unawaited(_setEnabled(!enabled)),
      trailing: IgnorePointer(
        child: M3ESwitch(
          key: const ValueKey('sleep-status-switch'),
          value: enabled,
          onChanged: (_) {},
        ),
      ),
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
