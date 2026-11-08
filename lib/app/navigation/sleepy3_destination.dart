import 'package:flutter/widgets.dart' show IconData;
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../l10n/l10n.dart';

/// Top-level destinations of Sleepy3.
///
/// Each destination swaps its outlined icon for the filled one when selected
/// by the pill navigation bar.
enum Sleepy3Destination {
  home(icon: M3EIcons.home_outlined, selectedIcon: M3EIcons.home),
  stats(icon: M3EIcons.analytics_outlined, selectedIcon: M3EIcons.analytics),
  settings(icon: M3EIcons.settings_outlined, selectedIcon: M3EIcons.settings);

  const Sleepy3Destination({required this.icon, required this.selectedIcon});

  final IconData icon;
  final IconData selectedIcon;

  /// The visible and spoken label in the current language.
  String label(AppLocalizations l10n) {
    return switch (this) {
      Sleepy3Destination.home => l10n.navHome,
      Sleepy3Destination.stats => l10n.navStats,
      Sleepy3Destination.settings => l10n.navSettings,
    };
  }
}
