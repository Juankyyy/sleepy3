import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../settings/presentation/widgets/settings_action_row.dart';
import '../../settings/presentation/widgets/settings_list.dart';
import '../application/backup_providers.dart';
import '../application/sleep_history_transfer_service.dart';
import '../domain/sleep_history_file.dart';

/// The `Data` section: export the local history to a file and import it back.
class HistoryDataSettings extends ConsumerWidget {
  const HistoryDataSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsActionRow(
          showLeading: showLeading,
          leadingIcon: M3EIcons.file_upload_outlined,
          headline: l10n.exportHistory,
          supporting: l10n.exportHistorySupport,
          onTap: () => _export(context, ref),
        ),
        // 2dp matches the gap between rows of a Settings list.
        const SizedBox(height: 2),
        SettingsActionRow(
          showLeading: showLeading,
          leadingIcon: M3EIcons.file_download_outlined,
          headline: l10n.importHistory,
          supporting: l10n.importHistorySupport,
          onTap: () => _import(context, ref),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final service = ref.read(sleepHistoryTransferServiceProvider);

    // Export exactly the history Stats shows. That list can come from the
    // local database or from Google Health, and it may still be loading when
    // Settings is opened for the first time.
    final controller = ref.read(sleepTrackingControllerProvider.notifier);
    var state = ref.read(sleepTrackingControllerProvider);
    if (state.historyStatus != SleepHistoryStatus.ready) {
      await controller.historyLoad;
      if (!context.mounted) return;
      state = ref.read(sleepTrackingControllerProvider);
    }
    if (state.historyStatus != SleepHistoryStatus.ready) {
      _showSnack(context, l10n.historyExportFailed);
      return;
    }

    final SleepHistoryExport export;
    try {
      export = service.exportHistory(
        state.closedSessions,
        source: ref.read(sleepDataSourceProvider),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the sleep history to export: '
        '$error\n$stackTrace',
      );
      if (context.mounted) {
        _showSnack(context, l10n.historyExportFailed);
      }
      return;
    }
    if (!context.mounted) return;

    if (export.sessionCount == 0) {
      _showSnack(context, l10n.historyExportEmpty);
      return;
    }

    final now = ref.read(sleepClockProvider)();
    final bool saved;
    try {
      saved = await ref
          .read(sleepHistoryFileGatewayProvider)
          .save(
            fileName: 'sleepy3-history-${_dateStamp(now)}.json',
            contents: export.contents,
            dialogTitle: l10n.historyExportDialogTitle,
          );
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not save the sleep history file: '
        '$error\n$stackTrace',
      );
      if (context.mounted) {
        _showSnack(context, l10n.historyExportFailed);
      }
      return;
    }
    if (!context.mounted || !saved) return;

    _showSnack(context, l10n.historyExported(export.sessionCount));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    final String? raw;
    try {
      raw = await ref
          .read(sleepHistoryFileGatewayProvider)
          .pick(dialogTitle: l10n.historyImportDialogTitle);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the selected history file: '
        '$error\n$stackTrace',
      );
      if (context.mounted) {
        await _showReadFailure(context, SleepHistoryFileError.unreadable);
      }
      return;
    }
    if (!context.mounted || raw == null) return;

    final SleepHistoryFile file;
    try {
      file = SleepHistoryFile.decode(raw);
    } on SleepHistoryFileException catch (error) {
      if (!context.mounted) return;
      await _showReadFailure(context, error.error);
      return;
    }
    if (!context.mounted) return;

    if (file.sessions.isEmpty) {
      await _showReadFailure(context, null);
      return;
    }

    final SleepHistoryImportPreview preview;
    try {
      preview = await ref
          .read(sleepHistoryTransferServiceProvider)
          .preview(file);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not compare the history file with the local data: '
        '$error\n$stackTrace',
      );
      if (context.mounted) {
        await _showReadFailure(context, SleepHistoryFileError.unreadable);
      }
      return;
    }
    if (!context.mounted) return;

    final confirmed = await M3EDialog.show<bool>(
      context,
      dialog: _ImportPreviewDialog(preview: preview),
    );
    if (!context.mounted || confirmed != true || !preview.hasNewSessions) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = M3EDialog.show<void>(
      context,
      barrierDismissible: false,
      autofocusFirst: false,
      onDismissRequest: () async => false,
      dialog: M3EDialog(
        title: context.l10n.historyImporting,
        content: Row(
          children: [
            M3ELoadingIndicator(
              size: 24,
              semanticLabel: context.l10n.historyImporting,
            ),
            // 16dp separates the loading indicator from its message.
            const SizedBox(width: 16),
            Expanded(child: Text(context.l10n.copyPleaseWait)),
          ],
        ),
      ),
    );

    final SleepHistoryImportResult result;
    try {
      result = await ref
          .read(sleepHistoryTransferServiceProvider)
          .import(preview);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not import the sleep history: '
        '$error\n$stackTrace',
      );
      if (navigator.mounted) {
        navigator.pop();
        await progress;
      }
      if (context.mounted) {
        await _showImportError(context, l10n);
      }
      return;
    }

    if (result.added > 0) {
      await ref
          .read(sleepTrackingControllerProvider.notifier)
          .reloadAfterHistoryImport();
    }

    if (navigator.mounted) {
      navigator.pop();
      await progress;
    }
    if (!context.mounted) return;

    await _showImportResult(context, result);
  }

  String _dateStamp(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showReadFailure(
    BuildContext context,
    SleepHistoryFileError? error,
  ) {
    final l10n = context.l10n;
    final message = switch (error) {
      SleepHistoryFileError.newerVersion => l10n.historyImportNewerVersion,
      SleepHistoryFileError.unreadable ||
      SleepHistoryFileError.notSleepy3 => l10n.historyImportInvalidFile,
      null => l10n.historyImportNoSessions,
    };
    return M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: l10n.historyImportCouldNotRead,
        content: Text(message),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportError(BuildContext context, AppLocalizations l10n) {
    return M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: l10n.historyImportFailedTitle,
        content: Text(l10n.historyImportFailed),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportResult(
    BuildContext context,
    SleepHistoryImportResult result,
  ) {
    final l10n = context.l10n;
    final parts = <String>[
      if (result.added > 0) l10n.historyImportAdded(result.added),
      if (result.skipped > 0) l10n.historyImportSkipped(result.skipped),
      if (result.failed > 0) l10n.historyImportFailedCount(result.failed),
    ];
    final failed = result.failed > 0;
    final title = failed
        ? l10n.historyImportSomeFailed
        : l10n.historyImportComplete;
    final body = parts.isEmpty
        ? l10n.historyImportNothingNew
        : parts.join(' · ');

    return M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: title,
        content: Text(body),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

/// Shows what the file contains before anything is written.
class _ImportPreviewDialog extends StatelessWidget {
  const _ImportPreviewDialog({required this.preview});

  final SleepHistoryImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessions = preview.file.sessions;
    final first = sessions.first.startedAt;
    final last = sessions.last.endedAt;
    final dates = DateFormat.yMMMd(l10n.localeName);
    final range = l10n.historyImportSummary(
      sessions.length,
      dates.format(first),
      dates.format(last),
    );

    return M3EDialog(
      title: l10n.historyImportPreviewTitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(range),
            // 8dp separates each fact from the previous one.
            const SizedBox(height: 8),
            Text(
              preview.hasNewSessions
                  ? l10n.historyImportNew(preview.newSessions)
                  : l10n.historyImportNothingNew,
            ),
            if (preview.duplicates > 0) ...[
              const SizedBox(height: 8),
              Text(l10n.historyImportDuplicates(preview.duplicates)),
            ],
            if (preview.invalidEntries > 0) ...[
              const SizedBox(height: 8),
              Text(l10n.historyImportInvalid(preview.invalidEntries)),
            ],
            if (preview.hasNewSessions) ...[
              const SizedBox(height: 16),
              Text(l10n.historyImportStaysLocal),
              if (preview.hasLocalSessions) ...[
                const SizedBox(height: 8),
                Text(l10n.historyImportAddLater),
              ],
              if (preview.hasDownloadedSessions) ...[
                const SizedBox(height: 8),
                Text(l10n.historyImportReadOnlyCopies),
              ],
            ],
          ],
        ),
      ),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: preview.hasNewSessions
              ? () => Navigator.pop(context, true)
              : null,
          child: Text(l10n.import),
        ),
      ],
    );
  }
}
