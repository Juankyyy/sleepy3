import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../sleep_tracking/application/sleep_tracking_controller.dart';
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
  if (confirm) {
    final confirmed = await M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: _confirmTitle(action),
        content: Text(_confirmBody(action)),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            child: Text(_confirmLabel(action)),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return null;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final progress = M3EDialog.show<void>(
    context,
    barrierDismissible: false,
    autofocusFirst: false,
    onDismissRequest: () async => false,
    dialog: M3EDialog(
      title: _progressTitle(action),
      content: Row(
        children: [
          M3ELoadingIndicator(size: 24, semanticLabel: _progressTitle(action)),
          // 16dp separates the loading indicator from its message.
          const SizedBox(width: 16),
          const Expanded(child: Text('This may take a moment.')),
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

  await M3EDialog.show<void>(
    context,
    dialog: M3EDialog(
      title: _resultTitle(action, result),
      content: Text(_resultMessage(action, result)),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  return result;
}

String _confirmTitle(SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => 'Sync last session?',
    SleepCopyAction.uploadAll => 'Add all previous sessions?',
    SleepCopyAction.downloadAll => 'Download from Google Health?',
  };
}

String _confirmBody(SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast =>
      'Send the most recent local session to Google Health.',
    SleepCopyAction.uploadAll =>
      'Send every local session that is not in Google Health yet. '
          'Sessions you already added to Google Health manually may appear '
          'twice.',
    SleepCopyAction.downloadAll =>
      'Add every sleep session from Google Health to the local copy. '
          'Local sessions are not changed.',
  };
}

String _confirmLabel(SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => 'Sync',
    SleepCopyAction.uploadAll => 'Add all',
    SleepCopyAction.downloadAll => 'Download all',
  };
}

String _progressTitle(SleepCopyAction action) {
  return switch (action) {
    SleepCopyAction.syncLast => 'Syncing session…',
    SleepCopyAction.uploadAll => 'Syncing sessions…',
    SleepCopyAction.downloadAll => 'Downloading sessions…',
  };
}

String _resultTitle(SleepCopyAction action, CopyResult result) {
  if (result.failure != null) {
    return action == SleepCopyAction.downloadAll
        ? "Couldn't download"
        : "Couldn't sync";
  }
  if (result.failed > 0) return "Some sessions weren't copied";
  return action == SleepCopyAction.downloadAll
      ? 'Download complete'
      : 'Sync complete';
}

String _resultMessage(SleepCopyAction action, CopyResult result) {
  final failure = result.failure;
  if (failure != null) return _failureMessage(action, failure);

  if (result.total == 0) {
    return action == SleepCopyAction.downloadAll
        ? 'There are no sleep sessions in Google Health.'
        : 'There are no local sessions to sync.';
  }

  final parts = <String>[];
  switch (action) {
    case SleepCopyAction.syncLast:
    case SleepCopyAction.uploadAll:
      if (result.added > 0) {
        parts.add(
          _count(
            result.added,
            'session sent to Google Health',
            'sessions sent to Google Health',
          ),
        );
      }
      if (result.skipped > 0) {
        parts.add(
          _count(result.skipped, 'session skipped', 'sessions skipped'),
        );
      }
      if (result.failed > 0) {
        parts.add(_count(result.failed, 'session failed', 'sessions failed'));
      }
    case SleepCopyAction.downloadAll:
      if (result.added > 0) {
        parts.add(_count(result.added, 'session added', 'sessions added'));
      }
      if (result.updated > 0) {
        parts.add(
          _count(result.updated, 'session updated', 'sessions updated'),
        );
      }
      if (result.skipped > 0) {
        parts.add(
          _count(
            result.skipped,
            'session already up to date',
            'sessions already up to date',
          ),
        );
      }
      if (result.failed > 0) {
        parts.add(_count(result.failed, 'session failed', 'sessions failed'));
      }
  }

  return parts.join(' · ');
}

String _failureMessage(SleepCopyAction action, SleepCopyFailure failure) {
  return switch (failure) {
    SleepCopyFailure.unavailable =>
      'Google Health is not available on this device.',
    SleepCopyFailure.updateRequired =>
      'Update Health Connect to use Google Health.',
    SleepCopyFailure.permissionDenied =>
      action == SleepCopyAction.downloadAll
          ? 'Google Health needs permission to read sleep.'
          : 'Google Health needs permission to write sleep.',
    SleepCopyFailure.failed => 'Something went wrong. Try again.',
  };
}

String _count(int count, String singular, String plural) =>
    count == 1 ? '1 $singular' : '$count $plural';
