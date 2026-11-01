import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Sleepy3's fixed Material 3 Expressive theme.
///
/// The brand anchors are exact: light uses [lightBackground] with [brandIndigo]
/// as `primary`, and dark uses [darkBackground] with [darkPrimary] as `primary`.
/// Secondary, tertiary, error and the accent containers are generated from
/// [brandIndigo] as the only source color. The neutral surface roles follow
/// M3's surface tone steps, shifted so `surface` is exactly the brand body.
/// Dynamic color is intentionally off.
///
/// Type role mapping used by the screens:
/// - brand: emphasized `headlineLarge`;
/// - live clock: emphasized `displayLarge`, tabular figures;
/// - date and supporting copy: `bodyMedium`;
/// - session line: emphasized `bodyMedium`;
/// - day/night chip: `labelMedium`;
/// - summary card: `titleMedium` and `labelMedium`.
abstract final class Sleepy3Theme {
  /// Sleepy3 indigo, taken from the logo.
  ///
  /// This is the light `primary` and the single source color for the generated
  /// secondary, tertiary, error and accent-container roles.
  static const brandIndigo = Color(0xFF252B81);

  /// The exact light body color.
  static const lightBackground = Color(0xFFEFF4F9);

  /// The exact dark body color.
  static const darkBackground = Color(0xFF121318);

  /// The dark `primary`, the lavender accent from the brand palette.
  static const darkPrimary = Color(0xFFC6CCF7);

  /// Bundled Roboto Flex family, declared in `pubspec.yaml`.
  static const fontFamily = 'RobotoFlex';

  static final _light = _build(Brightness.light);
  static final _dark = _build(Brightness.dark);

  /// The light scheme.
  static M3EThemeData light() => _light;

  /// The dark scheme.
  static M3EThemeData dark() => _dark;

  /// The scheme that follows [brightness].
  static M3EThemeData forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static M3EThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaces = isDark ? _Sleepy3Surfaces.dark : _Sleepy3Surfaces.light;
    final accent = isDark ? darkPrimary : brandIndigo;
    final onAccent = isDark ? _darkOnPrimary : _lightOnPrimary;

    final base = ColorScheme.fromSeed(
      seedColor: brandIndigo,
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      surface: surfaces.surface,
      surfaceDim: surfaces.dim,
      surfaceBright: surfaces.bright,
      surfaceContainerLowest: surfaces.lowest,
      surfaceContainerLow: surfaces.low,
      surfaceContainer: surfaces.container,
      surfaceContainerHigh: surfaces.high,
      surfaceContainerHighest: surfaces.highest,
      onSurface: surfaces.onSurface,
      onSurfaceVariant: surfaces.onSurfaceVariant,
      outline: surfaces.outline,
      outlineVariant: surfaces.outlineVariant,
      inverseSurface: surfaces.inverseSurface,
      onInverseSurface: surfaces.onInverseSurface,
      surfaceTint: accent,
    );

    return M3EThemeData(
      colorScheme: M3EColorScheme.fromColorScheme(base),
    ).copyWith(
      fontFamily: fontFamily,
      variableFont: const M3EVariableFontConfig(
        // Keep the M3 weights and tracking. The package's optional grade bump
        // would push emphasized styles off the published scale.
        emphasizedGrad: 0,
      ),
      navigationBarTheme: const _Sleepy3NavigationBarTheme(),
    );
  }
}

/// The exact `onPrimary` pair for each accent.
const _lightOnPrimary = Color(0xFFFFFFFF);
const _darkOnPrimary = Color(0xFF272B60);

/// The neutral roles for one theme.
///
/// M3 assigns surfaces to fixed tones: in light, surface 98, lowest 100, low
/// 96, container 94, high 92, highest 90, dim 87 and bright 98; in dark,
/// surface 6, lowest 4, low 10, container 12, high 17, highest 22, dim 6 and
/// bright 24. Sleepy3's light body is tone 96 instead of 98, so its container
/// and dim roles are shifted two tones darker; the brightest roles keep 98 and
/// 100. The dark body is already tone 6, so the dark steps are unchanged.
/// Foreground tones stay at M3's 10/30/50/80 (light) and 90/80/60/30 (dark).
class _Sleepy3Surfaces {
  const _Sleepy3Surfaces({
    required this.surface,
    required this.dim,
    required this.bright,
    required this.lowest,
    required this.low,
    required this.container,
    required this.high,
    required this.highest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  static const light = _Sleepy3Surfaces(
    surface: Color(0xFFEFF4F9),
    dim: Color(0xFFD0D5DA),
    bright: Color(0xFFF5FAFF),
    lowest: Color(0xFFFFFFFF),
    low: Color(0xFFE9EEF3),
    container: Color(0xFFE4E9EE),
    high: Color(0xFFDEE3E8),
    highest: Color(0xFFD8DDE2),
    onSurface: Color(0xFF13181C),
    onSurfaceVariant: Color(0xFF3D4347),
    outline: Color(0xFF6D7377),
    outlineVariant: Color(0xFFBCC2C6),
    inverseSurface: Color(0xFF272D31),
    onInverseSurface: Color(0xFFE7ECF1),
  );

  static const dark = _Sleepy3Surfaces(
    surface: Color(0xFF121318),
    dim: Color(0xFF121318),
    bright: Color(0xFF38393E),
    lowest: Color(0xFF0D0E13),
    low: Color(0xFF1A1B20),
    container: Color(0xFF1E1F25),
    high: Color(0xFF292A2F),
    highest: Color(0xFF34343A),
    onSurface: Color(0xFFE3E1E9),
    onSurfaceVariant: Color(0xFFC7C6CD),
    outline: Color(0xFF909097),
    outlineVariant: Color(0xFF46464C),
    inverseSurface: Color(0xFFE3E1E9),
    onInverseSurface: Color(0xFF2F3036),
  );

  final Color surface;
  final Color dim;
  final Color bright;
  final Color lowest;
  final Color low;
  final Color container;
  final Color high;
  final Color highest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color onInverseSurface;
}

/// Flexible navigation bar roles from the M3 Expressive spec.
///
/// The package defaults to the baseline bar's `surfaceContainerHigh` container
/// and `onSurface` active label. The flexible bar uses `surfaceContainer` for
/// the container and `secondary` for the active label.
class _Sleepy3NavigationBarTheme extends M3ENavigationBarTheme {
  const _Sleepy3NavigationBarTheme();

  @override
  Color containerColor(M3EColorScheme scheme) => scheme.surfaceContainer;

  @override
  Color activeLabelColor(M3EColorScheme scheme) => scheme.secondary;
}
