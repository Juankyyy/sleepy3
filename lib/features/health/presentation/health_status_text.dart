import 'package:material_ui/material_ui.dart';

import '../../../core/time/clock_format.dart';
import '../../../l10n/l10n.dart';
import '../application/health_sync_controller.dart';

/// The localized connection status shown by the Google Health list and the
/// Sleep data card.
String healthStatusText(BuildContext context, HealthSyncState state) {
  final l10n = context.l10n;
  final connection = state.connection;
  if (connection != HealthConnectConnectionStatus.connected) {
    return healthConnectionLabel(l10n, connection);
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

/// The short connection label without the pending or last-sync detail.
String healthConnectionLabel(
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
