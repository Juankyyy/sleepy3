import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../health/application/health_sync_controller.dart';
import '../../../health/application/health_sync_store_provider.dart';
import '../../../health/application/sleep_copy_controller.dart';
import '../../../health/application/sleep_data_source_controller.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../health/presentation/sleep_copy_dialogs.dart';
import '../../../health/presentation/sleep_data_source_text.dart';
import 'settings_list.dart';

/// The `Sleep data` source and download rows and the source dialog.
class SleepDataSourceSetting extends ConsumerWidget {
  const SleepDataSourceSetting({super.key, required this.source});

  final SleepDataSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);

    return SettingsList(
      onTap: (index) {
        if (index == 0) {
          _chooseSource(context, ref);
        } else {
          showSleepCopyFlow(context, ref, SleepCopyAction.downloadAll);
        }
      },
      children: [
        M3EListItem(
          leading: showLeading ? const Icon(M3EIcons.storage_outlined) : null,
          headline: l10n.source,
          supportingText: l10n.sleepDataSourceLabel(source),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
        M3EListItem(
          leading: showLeading
              ? const Icon(M3EIcons.cloud_download_outlined)
              : null,
          headline: l10n.import,
          supportingText: l10n.importSupport,
          trailing: const Icon(M3EIcons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _chooseSource(BuildContext context, WidgetRef ref) async {
    final target = await M3EDialog.show<SleepDataSource>(
      context,
      dialog: _SourceDialog(initial: source),
    );
    if (!context.mounted || target == null || target == source) return;

    final result = await ref
        .read(sleepDataSourceProvider.notifier)
        .select(target);
    if (!context.mounted) return;

    if (!result.succeeded) {
      final message = _failureMessage(context.l10n, result.failure!);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    // The first switch to Google Health is the moment to offer the local
    // history. The same actions stay available in Settings afterwards.
    if (target == SleepDataSource.healthConnect) {
      // The status row is visible in both modes, so it was already built with
      // the previous permission state. Refresh it after the grant.
      await ref.read(healthSyncControllerProvider.notifier).refresh();
      if (!context.mounted) return;
      await _offerLocalCopy(context, ref);
    }
  }

  Future<void> _offerLocalCopy(BuildContext context, WidgetRef ref) async {
    final int pending;
    try {
      pending = await ref.read(healthSyncStoreProvider).loadPendingCount();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not count local sessions for the copy prompt: '
        '$error\n$stackTrace',
      );
      return;
    }
    if (!context.mounted || pending == 0) return;

    final action = await M3EDialog.show<SleepCopyAction>(
      context,
      dialog: _LocalCopyDialog(count: pending),
    );
    if (!context.mounted || action == null) return;

    await showSleepCopyFlow(context, ref, action, confirm: false);
  }

  String _failureMessage(
    AppLocalizations l10n,
    SleepDataSourceChangeFailure failure,
  ) {
    return switch (failure) {
      SleepDataSourceChangeFailure.unavailable => l10n.healthUnavailable,
      SleepDataSourceChangeFailure.updateRequired => l10n.healthUpdateRequired,
      SleepDataSourceChangeFailure.permissionDenied =>
        l10n.healthPermissionReadWrite,
      SleepDataSourceChangeFailure.saveFailed => l10n.sleepDataSourceSaveFailed,
    };
  }
}

/// A single-select list in an M3 dialog.
///
/// The package selection screen lays out a radio label without flex, which
/// overflows at compact widths with longer names such as Google Health. A list
/// of full-width rows keeps the same M3 visuals without clipping.
class _SourceDialog extends StatefulWidget {
  const _SourceDialog({required this.initial});

  final SleepDataSource initial;

  @override
  State<_SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<_SourceDialog> {
  late SleepDataSource _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return M3EDialog(
      title: l10n.sleepDataSourceDialogTitle,
      content: SettingsList(
        onTap: (index) {
          setState(() => _selected = SleepDataSource.values[index]);
        },
        children: [
          for (final option in SleepDataSource.values)
            M3EListItem(
              leading: Icon(
                _selected == option
                    ? M3EIcons.radio_button_checked
                    : M3EIcons.radio_button_unchecked,
              ),
              headline: l10n.sleepDataSourceLabel(option),
            ),
        ],
      ),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(l10n.apply),
        ),
      ],
    );
  }
}

/// The optional prompt shown after the first switch to Google Health.
class _LocalCopyDialog extends StatelessWidget {
  const _LocalCopyDialog({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);

    return M3EDialog(
      title: l10n.copyLocalSessionsTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.localSessionsNotInHealth(count)),
          // 8dp separates the explanation from the choices.
          const SizedBox(height: 8),
          SettingsList(
            onTap: (index) {
              Navigator.pop(
                context,
                index == 0
                    ? SleepCopyAction.syncLast
                    : SleepCopyAction.uploadAll,
              );
            },
            children: [
              M3EListItem(
                leading: showLeading
                    ? const Icon(M3EIcons.cloud_upload_outlined)
                    : null,
                headline: l10n.sync,
                supportingText: l10n.syncRecentSupport,
              ),
              M3EListItem(
                leading: showLeading
                    ? const Icon(M3EIcons.library_add_outlined)
                    : null,
                headline: l10n.add,
                supportingText: l10n.addAllSupport,
              ),
            ],
          ),
        ],
      ),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.notNow),
        ),
      ],
    );
  }
}
