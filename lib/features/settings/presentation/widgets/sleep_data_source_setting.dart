import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../health/application/sleep_data_source_controller.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../health/presentation/sleep_data_source_text.dart';
import 'settings_list.dart';

/// The `Sleep data` source row and its Local / Google Health dialog.
class SleepDataSourceSetting extends ConsumerWidget {
  const SleepDataSourceSetting({super.key, required this.source});

  final SleepDataSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsList(
      onTap: (_) => _chooseSource(context, ref),
      children: [
        M3EListItem(
          leading: const Icon(M3EIcons.storage_outlined),
          headline: 'Source',
          supportingText: sleepDataSourceLabel(source),
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
    if (!context.mounted || result.succeeded) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_failureMessage(result.failure!))));
  }

  String _failureMessage(SleepDataSourceChangeFailure failure) {
    return switch (failure) {
      SleepDataSourceChangeFailure.unavailable =>
        'Google Health is not available on this device.',
      SleepDataSourceChangeFailure.updateRequired =>
        'Update Health Connect to use Google Health.',
      SleepDataSourceChangeFailure.permissionDenied =>
        'Google Health needs permission to read and write sleep.',
      SleepDataSourceChangeFailure.saveFailed =>
        "Couldn't save the sleep data source.",
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
    return M3EDialog(
      title: 'Sleep data source',
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
              headline: sleepDataSourceLabel(option),
            ),
        ],
      ),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
