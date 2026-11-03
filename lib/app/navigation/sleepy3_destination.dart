import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Top-level destinations of Sleepy3.
///
/// Labels are short (one word), and each destination swaps its outlined icon
/// for the filled one when selected by the pill navigation bar.
enum Sleepy3Destination {
  home(
    label: 'Home',
    icon: M3EIcons.home_outlined,
    selectedIcon: M3EIcons.home,
  ),
  stats(
    label: 'Stats',
    icon: M3EIcons.analytics_outlined,
    selectedIcon: M3EIcons.analytics,
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
}
