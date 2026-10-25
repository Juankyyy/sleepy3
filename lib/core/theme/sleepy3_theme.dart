import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Sleepy3's fixed Material 3 Expressive theme.
///
/// Dynamic color is intentionally off. Light and dark schemes are generated
/// independently from the same Sleepy3 blue seed, so the dark theme keeps the
/// brand hue instead of being derived from the light scheme's primary.
///
/// Type role mapping used by the screens:
/// - brand: emphasized `headlineLarge`;
/// - live clock: emphasized `displayLarge`, tabular figures;
/// - date and supporting copy: `bodyMedium`;
/// - session line: emphasized `bodyMedium`;
/// - day/night chip: `labelMedium`;
/// - summary card: `titleMedium`, `labelMedium`, `bodyMedium`.
abstract final class Sleepy3Theme {
  /// Sleepy3 blue: the single source color for both schemes.
  static const seedColor = Color(0xFF2B3A8F);

  /// Bundled Roboto Flex family, declared in `pubspec.yaml`.
  static const fontFamily = 'RobotoFlex';

  static final _light = _build(Brightness.light);
  static final _dark = _build(Brightness.dark);

  /// The light scheme, generated from [seedColor].
  static M3EThemeData light() => _light;

  /// The dark scheme, generated from the same [seedColor].
  static M3EThemeData dark() => _dark;

  /// The scheme that follows [brightness].
  static M3EThemeData forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static M3EThemeData _build(Brightness brightness) {
    return M3EThemeData(
      colorScheme: M3EColorScheme.fromSeed(seedColor, brightness: brightness),
    ).copyWith(
      fontFamily: fontFamily,
      variableFont: const M3EVariableFontConfig(
        // Keep the M3 weights and tracking. The package's optional grade bump
        // would push emphasized styles off the published scale.
        emphasizedGrad: 0,
      ),
    );
  }
}
