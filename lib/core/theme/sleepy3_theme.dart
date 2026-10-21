import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Sleepy3's Material 3 Expressive theme.
///
/// Dynamic color replaces the seed on Android 12+; the seed is the fallback
/// for older devices and for platforms without Material You.
abstract final class Sleepy3Theme {
  static const seedColor = Color(0xFF6750A4);

  static M3EThemeData light() => M3EThemeData.light(seedColor: seedColor);
}
