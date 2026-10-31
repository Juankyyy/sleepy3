import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../health/application/health_sync_controller.dart';
import '../../../health/application/sleep_copy_controller.dart';
import '../../../health/presentation/sleep_copy_dialogs.dart';
import 'settings_list.dart';

/// The Google Health status row and its reconnect or install action.
///
/// Shown in Settings in both source modes, next to the copy actions, so the
/// connection state is visible without switching sources. The status is read
/// again when the row appears, so revoking permissions in Health Connect is
/// reflected without restarting the app.
class GoogleHealthStatusList extends ConsumerStatefulWidget {
  const GoogleHealthStatusList({super.key});

  @override
  ConsumerState<GoogleHealthStatusList> createState() =>
      _GoogleHealthStatusListState();
}

class _GoogleHealthStatusListState
    extends ConsumerState<GoogleHealthStatusList> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(healthSyncControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthSyncControllerProvider);
    final action = _actionFor(state.connection);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsList(
          children: [
            M3EListItem(
              leading: Icon(_iconFor(state.connection)),
              headline: 'Status',
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
                headline: action.label,
                supportingText: action.supportingText,
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
          children: const [
            M3EListItem(
              leading: Icon(M3EIcons.cloud_upload_outlined),
              headline: 'Sync',
              supportingText: 'Send the most recent local session.',
              trailing: Icon(M3EIcons.chevron_right),
            ),
            M3EListItem(
              leading: Icon(M3EIcons.library_add_outlined),
              headline: 'Add',
              supportingText:
                  "Send local sessions that aren't in Google Health.",
              trailing: Icon(M3EIcons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  String _statusText(BuildContext context, HealthSyncState state) {
    final connection = state.connection;
    if (connection != HealthConnectConnectionStatus.connected) {
      return _connectionLabel(connection);
    }

    if (state.pendingCount > 0) {
      final count = state.pendingCount;
      return 'Connected · $count pending';
    }

    final lastSyncedAt = state.lastSyncedAt;
    if (lastSyncedAt != null) {
      final time = formatSessionTime(
        lastSyncedAt,
        use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return 'Connected · Last sync $time';
    }

    return 'Connected';
  }

  Future<void> _run(_StatusAction action, BuildContext context) async {
    final controller = ref.read(healthSyncControllerProvider.notifier);
    switch (action.kind) {
      case _StatusActionKind.reconnect:
        final granted = await controller.reconnect();
        if (!context.mounted || granted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Health needs permission to read and write sleep.',
            ),
          ),
        );
      case _StatusActionKind.install:
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

  static String _connectionLabel(HealthConnectConnectionStatus status) {
    return switch (status) {
      HealthConnectConnectionStatus.connected => 'Connected',
      HealthConnectConnectionStatus.permissionNeeded => 'Permission needed',
      HealthConnectConnectionStatus.notAvailable => 'Not available',
      HealthConnectConnectionStatus.updateRequired => 'Update required',
      HealthConnectConnectionStatus.checking => 'Checking…',
    };
  }

  static _StatusAction? _actionFor(HealthConnectConnectionStatus status) {
    return switch (status) {
      HealthConnectConnectionStatus.permissionNeeded => const _StatusAction(
        kind: _StatusActionKind.reconnect,
        label: 'Connect',
        supportingText: 'Allow Sleepy3 to read and write sleep.',
      ),
      HealthConnectConnectionStatus.notAvailable ||
      HealthConnectConnectionStatus.updateRequired => const _StatusAction(
        kind: _StatusActionKind.install,
        label: 'Install',
        supportingText: 'Get or update Health Connect.',
      ),
      HealthConnectConnectionStatus.connected ||
      HealthConnectConnectionStatus.checking => null,
    };
  }
}

enum _StatusActionKind { reconnect, install }

class _StatusAction {
  const _StatusAction({
    required this.kind,
    required this.label,
    required this.supportingText,
  });

  final _StatusActionKind kind;
  final String label;
  final String supportingText;
}
