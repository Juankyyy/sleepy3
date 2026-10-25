import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Top-level destinations of Sleepy3.
///
/// Labels are short (one word), and each destination swaps its outlined icon
/// for the filled one when selected, as the M3 navigation bar requires.
enum Sleepy3Destination {
  home(
    label: 'Home',
    icon: M3EIcons.home_outlined,
    selectedIcon: M3EIcons.home,
  ),
  stats(
    label: 'Stats',
    icon: M3EIcons.bar_chart_outlined,
    selectedIcon: M3EIcons.bar_chart,
  ),
  settings(
    label: 'Settings',
    icon: M3EIcons.settings_outlined,
    selectedIcon: M3EIcons.settings,
  );

  const Sleepy3Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Builds the destination model consumed by [M3ENavigationBar].
  M3ENavigationBarDestination toNavigationBarDestination() {
    return M3ENavigationBarDestination(
      label: label,
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
    );
  }
}
