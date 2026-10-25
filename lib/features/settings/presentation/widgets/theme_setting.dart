import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/theme_mode_controller.dart';
import '../../domain/app_theme_mode.dart';
import 'settings_list.dart';

/// The appearance setting: one row plus the M3 selection dialog.
///
/// The row action lives on [SettingsList]; `M3EList` routes taps at the list
/// level.
class ThemeSetting extends ConsumerWidget {
  const ThemeSetting({super.key, required this.mode});

  final AppThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsList(
      onTap: (_) => _chooseTheme(context, ref),
      children: [
        M3EListItem(
          leading: const Icon(M3EIcons.palette_outlined),
          headline: 'Theme',
          supportingText: _label(mode),
          trailing: const Icon(M3EIcons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _chooseTheme(BuildContext context, WidgetRef ref) async {
    final selected = await M3EDialog.showSelectionScreen(
      context,
      title: 'Theme',
      options: [for (final option in AppThemeMode.values) _label(option)],
      initialSelection: [_label(mode)],
      cancelLabel: 'Cancel',
      confirmLabel: 'Apply',
    );
    if (!context.mounted || selected == null || selected.length != 1) return;

    for (final option in AppThemeMode.values) {
      if (_label(option) == selected.single) {
        await ref.read(themeModeControllerProvider.notifier).setMode(option);
        return;
      }
    }
  }

  static String _label(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }
}
