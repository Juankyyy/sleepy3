import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../application/health_history_permission_controller.dart';
import '../application/sleep_copy_controller.dart';
import '../application/sleep_copy_service.dart';

/// Confirms, runs and reports one copy action from Settings.
///
/// The confirmation is skipped when the action comes from the first-switch
/// prompt, because that prompt already asked what to copy.
Future<CopyResult?> showSleepCopyFlow(
  BuildContext context,
  WidgetRef ref,
  SleepCopyAction action, {
  bool confirm = true,
}) async {
  final l10n = context.l10n;

  if (confirm) {
    final confirmed = await M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: _confirmTitle(l10n, action),
        content: Text(_confirmBody(l10n, action)),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            child: Text(_confirmLabel(l10n, action)),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return null;
  }

  // Ask for full history before downloading. Denying is not a failure: the
  // service falls back to the last 30 days and the result says so.
  if (action == SleepCopyAction.downloadAll) {
    await ref.read(healthHistoryPermissionProvider.notifier).ensureAuthorized();
    if (!context.mounted) return null;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final progress = M3EDialog.show<void>(
    context,
    barrierDismissible: false,
    autofocusFirst: false,
    onDismissRequest: () async => false,
    dialog: M3EDialog(
      title: _progressTitle(l10n, action),
      content: Row(
        children: [
          M3ELoadingIndicator(
            size: 24,
            semanticLabel: _progressTitle(l10n, action),
          ),
          // 16dp separates the loading indicator from its message.
          const SizedBox(width: 16),
          Expanded(child: Text(l10n.copyPleaseWait)),
        ],
      ),
    ),
  );

  final controller = ref.read(sleepCopyControllerProvider.notifier);
  final result = switch (action) {
    SleepCopyAction.syncLast => await controller.syncLastSession(),
    SleepCopyAction.uploadAll => await controller.uploadAllPreviousSessions(),
    SleepCopyAction.downloadAll =>
      await controller.downloadAllFromHealthConnect(),
  };

  // A copy changes the visible history in at least one mode: an upload adds a
  // record to Google Health, a download adds rows to the local copy.
  if (result.hasChanges) {
    await ref.read(sleepTrackingControllerProvider.notifier).reloadHistory();
  }

  if (navigator.mounted) {
    navigator.pop();
    await progress;
  }
  if (!context.mounted) return result;

  final resultL10n = context.l10n;
  await M3EDialog.show<void>(
    context,
    dialog: M3EDialog(
      title: _resultTitle(resultL10n, action, result),
      content: Text(_resultMessage(resultL10n, action, result)),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context),
          child: Text(resultL10n.close),
        ),
      ],
    ),
  );

  return result;
}

String _confirmTitle(AppLocalizations l10n, SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => l10n.copySyncLastTitle,
    SleepCopyAction.uploadAll => l10n.copyAddAllTitle,
    SleepCopyAction.downloadAll => l10n.copyDownloadTitle,
  };
}

String _confirmBody(AppLocalizations l10n, SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => l10n.copySyncLastBody,
    SleepCopyAction.uploadAll => l10n.copyAddAllBody,
    SleepCopyAction.downloadAll => l10n.copyDownloadBody,
  };
}

String _confirmLabel(AppLocalizations l10n, SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => l10n.copySyncAction,
    SleepCopyAction.uploadAll => l10n.copyAddAllAction,
    SleepCopyAction.downloadAll => l10n.copyDownloadAction,
  };
}

String _progressTitle(AppLocalizations l10n, SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => l10n.copySyncingSession,
    SleepCopyAction.uploadAll => l10n.copySyncingSessions,
    SleepCopyAction.downloadAll => l10n.copyDownloadingSessions,
  };
}

String _resultTitle(
  AppLocalizations l10n,
  SleepCopyAction action,
  CopyResult result,
) {
  if (result.failure != null) {
    return action == SleepCopyAction.downloadAll
        ? l10n.copyCouldNotDownload
        : l10n.copyCouldNotSync;
  }
  if (result.failed > 0) return l10n.copySomeFailed;
  return action == SleepCopyAction.downloadAll
      ? l10n.copyDownloadComplete
      : l10n.copySyncComplete;
}

String _resultMessage(
  AppLocalizations l10n,
  SleepCopyAction action,
  CopyResult result,
) {
  final failure = result.failure;
  if (failure != null) return _failureMessage(l10n, action, failure);

  if (result.total == 0) {
    if (action == SleepCopyAction.downloadAll) {
      return result.historyLimited
          ? l10n.copyNoSessions30Days
          : l10n.copyNoSessionsHealth;
    }
    return l10n.copyNoLocalSessions;
  }

  final parts = <String>[];
  switch (action) {
    case SleepCopyAction.syncLast:
    case SleepCopyAction.uploadAll:
      if (result.added > 0) {
        parts.add(l10n.copySessionsSent(result.added));
      }
      if (result.skipped > 0) {
        parts.add(l10n.copySessionsSkipped(result.skipped));
      }
      if (result.failed > 0) {
        parts.add(l10n.copySessionsFailed(result.failed));
      }
    case SleepCopyAction.downloadAll:
      if (result.added > 0) {
        parts.add(l10n.copySessionsAdded(result.added));
      }
      if (result.updated > 0) {
        parts.add(l10n.copySessionsUpdated(result.updated));
      }
      if (result.skipped > 0) {
        parts.add(l10n.copySessionsUpToDate(result.skipped));
      }
      if (result.failed > 0) {
        parts.add(l10n.copySessionsFailed(result.failed));
      }
  }

  final summary = parts.join(' · ');
  if (action == SleepCopyAction.downloadAll && result.historyLimited) {
    return l10n.copyHistoryLimited(summary);
  }
  return summary;
}

String _failureMessage(
  AppLocalizations l10n,
  SleepCopyAction action,
  SleepCopyFailure failure,
) {
  return switch (failure) {
    SleepCopyFailure.unavailable => l10n.healthUnavailable,
    SleepCopyFailure.updateRequired => l10n.healthUpdateRequired,
    SleepCopyFailure.permissionDenied =>
      action == SleepCopyAction.downloadAll
          ? l10n.healthPermissionRead
          : l10n.healthPermissionWrite,
    SleepCopyFailure.failed => l10n.copyFailed,
  };
}
