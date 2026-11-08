import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../health/application/health_sync_controller.dart';
import '../../../health/application/sleep_copy_controller.dart';
import '../../../health/presentation/sleep_copy_dialogs.dart';
import 'settings_list.dart';

/// The Google Health status row and its reconnect or install action.
///
/// Shown in Settings in both source modes, next to the copy actions, so the
/// connection state is visible without switching sources. The app-level launch
/// and resume refresh owns the status, so the row does not start a platform
/// check while the splash is still on screen.
class GoogleHealthStatusList extends ConsumerStatefulWidget {
  const GoogleHealthStatusList({super.key});

  @override
  ConsumerState<GoogleHealthStatusList> createState() =>
      _GoogleHealthStatusListState();
}

class _GoogleHealthStatusListState
    extends ConsumerState<GoogleHealthStatusList> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);
    final state = ref.watch(healthSyncControllerProvider);
    final action = _actionFor(state.connection);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsList(
          children: [
            M3EListItem(
              leading: showLeading ? Icon(_iconFor(state.connection)) : null,
              headline: l10n.status,
              supportingText: _statusText(context, state),
            ),
          ],
        ),
        if (action != null) ...[
          // 2dp keeps the action visually connected to the status row.
          const SizedBox(height: 2),
          SettingsList(
            onTap: (_) => _run(action, context),
            children: [
              M3EListItem(
                headline: _actionLabel(l10n, action),
                supportingText: _actionSupport(l10n, action),
                trailing: const Icon(M3EIcons.chevron_right),
              ),
            ],
          ),
        ],
        // 2dp separates the status from the copy actions, which are available
        // in both Local and Google Health modes.
        const SizedBox(height: 2),
        SettingsList(
          onTap: (index) => _runCopy(
            index == 0 ? SleepCopyAction.syncLast : SleepCopyAction.uploadAll,
            context,
          ),
          children: [
            M3EListItem(
              leading: showLeading
                  ? const Icon(M3EIcons.cloud_upload_outlined)
                  : null,
              headline: l10n.sync,
              supportingText: l10n.syncSupport,
              trailing: const Icon(M3EIcons.chevron_right),
            ),
            M3EListItem(
              leading: showLeading
                  ? const Icon(M3EIcons.library_add_outlined)
                  : null,
              headline: l10n.add,
              supportingText: l10n.addSupport,
              trailing: const Icon(M3EIcons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  String _statusText(BuildContext context, HealthSyncState state) {
    final l10n = context.l10n;
    final connection = state.connection;
    if (connection != HealthConnectConnectionStatus.connected) {
      return _connectionLabel(l10n, connection);
    }

    if (state.pendingCount > 0) {
      return l10n.connectedPending(state.pendingCount);
    }

    final lastSyncedAt = state.lastSyncedAt;
    if (lastSyncedAt != null) {
      final time = formatSessionTime(
        lastSyncedAt,
        use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        localeName: l10n.localeName,
      );
      return l10n.connectedLastSync(time);
    }

    return l10n.connected;
  }

  Future<void> _run(_StatusAction action, BuildContext context) async {
    final controller = ref.read(healthSyncControllerProvider.notifier);
    switch (action) {
      case _StatusAction.reconnect:
        final granted = await controller.reconnect();
        if (!context.mounted || granted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.healthPermissionReadWrite)),
        );
      case _StatusAction.install:
        await controller.install();
    }
  }

  Future<void> _runCopy(SleepCopyAction action, BuildContext context) =>
      showSleepCopyFlow(context, ref, action);

  static IconData _iconFor(HealthConnectConnectionStatus status) {
    return switch (status) {
      HealthConnectConnectionStatus.connected => M3EIcons.cloud_done_outlined,
      HealthConnectConnectionStatus.permissionNeeded => M3EIcons.link_off,
      HealthConnectConnectionStatus.notAvailable => M3EIcons.cloud_off_outlined,
      HealthConnectConnectionStatus.updateRequired => M3EIcons.update,
      HealthConnectConnectionStatus.checking => M3EIcons.cloud_sync_outlined,
    };
  }

  static String _connectionLabel(
    AppLocalizations l10n,
    HealthConnectConnectionStatus status,
  ) {
    return switch (status) {
      HealthConnectConnectionStatus.connected => l10n.connected,
      HealthConnectConnectionStatus.permissionNeeded => l10n.permissionNeeded,
      HealthConnectConnectionStatus.notAvailable => l10n.notAvailable,
      HealthConnectConnectionStatus.updateRequired => l10n.updateRequired,
      HealthConnectConnectionStatus.checking => l10n.checking,
    };
  }

  static _StatusAction? _actionFor(HealthConnectConnectionStatus status) {
    return switch (status) {
      HealthConnectConnectionStatus.permissionNeeded => _StatusAction.reconnect,
      HealthConnectConnectionStatus.notAvailable ||
      HealthConnectConnectionStatus.updateRequired => _StatusAction.install,
      HealthConnectConnectionStatus.connected ||
      HealthConnectConnectionStatus.checking => null,
    };
  }

  static String _actionLabel(AppLocalizations l10n, _StatusAction action) {
    return switch (action) {
      _StatusAction.reconnect => l10n.connect,
      _StatusAction.install => l10n.install,
    };
  }

  static String _actionSupport(AppLocalizations l10n, _StatusAction action) {
    return switch (action) {
      _StatusAction.reconnect => l10n.connectSupport,
      _StatusAction.install => l10n.installSupport,
    };
  }
}

enum _StatusAction { reconnect, install }
