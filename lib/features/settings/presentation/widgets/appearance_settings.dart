import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/theme_mode_controller.dart';
import '../../application/time_format_controller.dart';
import '../../domain/app_theme_mode.dart';
import '../../domain/app_time_format.dart';
import 'settings_list.dart';

/// The appearance settings: one row for the theme and one for the clock.
///
/// The row actions live on [SettingsList]; `M3EList` routes taps at the list
/// level.
class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({
    super.key,
    required this.mode,
    required this.timeFormat,
  });

  final AppThemeMode mode;
  final AppTimeFormat timeFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsList(
      onTap: (index) {
        if (index == 0) {
          _chooseTheme(context, ref);
        } else {
          _chooseTimeFormat(context, ref);
        }
      },
      children: [
        M3EListItem(
          leading: const Icon(M3EIcons.palette_outlined),
          headline: 'Theme',
          supportingText: _themeLabel(mode),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
        M3EListItem(
          leading: const Icon(M3EIcons.schedule_outlined),
          headline: 'Time format',
          supportingText: _timeFormatLabel(timeFormat),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _chooseTheme(BuildContext context, WidgetRef ref) async {
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: 'Theme',
      options: [for (final option in AppThemeMode.values) _themeLabel(option)],
      initialSelection: [_themeLabel(mode)],
      cancelLabel: 'Cancel',
      confirmLabel: 'Apply',
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    for (final option in AppThemeMode.values) {
      if (_themeLabel(option) == selected.single) {
        await ref.read(themeModeControllerProvider.notifier).setMode(option);
        return;
      }
    }
  }

  Future<void> _chooseTimeFormat(BuildContext context, WidgetRef ref) async {
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: 'Time format',
      options: [
        for (final option in AppTimeFormat.values) _timeFormatLabel(option),
      ],
      initialSelection: [_timeFormatLabel(timeFormat)],
      cancelLabel: 'Cancel',
      confirmLabel: 'Apply',
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    for (final option in AppTimeFormat.values) {
      if (_timeFormatLabel(option) == selected.single) {
        await ref.read(timeFormatControllerProvider.notifier).setFormat(option);
        return;
      }
    }
  }

  static String _themeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }

  static String _timeFormatLabel(AppTimeFormat format) {
    return switch (format) {
      AppTimeFormat.twelveHour => '12-hour',
      AppTimeFormat.twentyFourHour => '24-hour',
    };
  }
}
