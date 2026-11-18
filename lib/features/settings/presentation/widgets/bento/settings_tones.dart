import 'package:material_ui/material_ui.dart';

/// One tonal surface used by the Settings bento cards.
///
/// The five accents are a fixed Sleepy3 extension scoped to Settings. They are
/// not dynamic color roles: every pair is defined for light and dark by hand,
/// so the rest of the app keeps the indigo scheme and the cards keep their
/// identity. [supporting] is the lower-emphasis text color; it is opaque rather
/// than a raw opacity so the contrast can be measured.
@immutable
class SettingsTone {
  const SettingsTone({
    required this.background,
    required this.onBackground,
    required this.iconContainer,
    required this.icon,
    required this.blob,
  });

  final Color background;
  final Color onBackground;
  final Color iconContainer;
  final Color icon;

  /// The decorative M3 figure painted in the card's empty corner.
  final Color blob;

  /// Supporting text: the same text color, softened without losing 4.5:1.
  Color get supporting =>
      Color.alphaBlend(onBackground.withValues(alpha: 0.9), background);
}

/// The light and dark Settings palettes.
@immutable
class SettingsPalette {
  const SettingsPalette({
    required this.sleepGoal,
    required this.reminder,
    required this.sleepStatus,
    required this.data,
    required this.appearance,
    required this.stats,
    required this.about,
  });

  final SettingsTone sleepGoal;
  final SettingsTone reminder;
  final SettingsTone sleepStatus;
  final SettingsTone data;
  final SettingsTone appearance;
  final SettingsTone stats;
  final SettingsTone about;

  List<SettingsTone> get all => [
    sleepGoal,
    reminder,
    sleepStatus,
    data,
    appearance,
    stats,
    about,
  ];

  static SettingsPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const light = SettingsPalette(
    sleepGoal: SettingsTone(
      background: Color(0xFFE0E3FA),
      onBackground: Color(0xFF1C2266),
      iconContainer: Color(0xFFC9CFF4),
      icon: Color(0xFF252B81),
      blob: Color(0xFFD0D5F4),
    ),
    reminder: SettingsTone(
      background: Color(0xFFD9EAF7),
      onBackground: Color(0xFF143C56),
      iconContainer: Color(0xFFC2DFF0),
      icon: Color(0xFF1C5A7A),
      blob: Color(0xFFC6E0F2),
    ),
    sleepStatus: SettingsTone(
      background: Color(0xFFD9EFE3),
      onBackground: Color(0xFF15452F),
      iconContainer: Color(0xFFC2E5D1),
      icon: Color(0xFF1F6B49),
      blob: Color(0xFFC6E6D5),
    ),
    data: SettingsTone(
      background: Color(0xFFE6EAF0),
      onBackground: Color(0xFF2A3036),
      iconContainer: Color(0xFFD5DBE3),
      icon: Color(0xFF3D444B),
      blob: Color(0xFFD9DFE6),
    ),
    appearance: SettingsTone(
      background: Color(0xFFF8E4D4),
      onBackground: Color(0xFF5A2E17),
      iconContainer: Color(0xFFF4D2B8),
      icon: Color(0xFF8A4B26),
      blob: Color(0xFFF1D2BA),
    ),
    stats: SettingsTone(
      background: Color(0xFFF6DEE7),
      onBackground: Color(0xFF5B1F38),
      iconContainer: Color(0xFFEFC9D8),
      icon: Color(0xFF8A3458),
      blob: Color(0xFFEECBD9),
    ),
    about: SettingsTone(
      background: Color(0xFFE6EAF0),
      onBackground: Color(0xFF2A3036),
      iconContainer: Color(0xFFD5DBE3),
      icon: Color(0xFF3D444B),
      blob: Color(0xFFD9DFE6),
    ),
  );

  static const dark = SettingsPalette(
    sleepGoal: SettingsTone(
      background: Color(0xFF2B3160),
      onBackground: Color(0xFFE0E3FA),
      iconContainer: Color(0xFF3A4178),
      icon: Color(0xFFC9CFF4),
      blob: Color(0xFF343B70),
    ),
    reminder: SettingsTone(
      background: Color(0xFF1D3546),
      onBackground: Color(0xFFD9EAF7),
      iconContainer: Color(0xFF294A61),
      icon: Color(0xFFBFE0F2),
      blob: Color(0xFF254257),
    ),
    sleepStatus: SettingsTone(
      background: Color(0xFF1D3A2C),
      onBackground: Color(0xFFD9EFE3),
      iconContainer: Color(0xFF29503D),
      icon: Color(0xFFBFE7D2),
      blob: Color(0xFF254636),
    ),
    data: SettingsTone(
      background: Color(0xFF26282E),
      onBackground: Color(0xFFE3E1E9),
      iconContainer: Color(0xFF34373E),
      icon: Color(0xFFC7C6CD),
      blob: Color(0xFF303339),
    ),
    appearance: SettingsTone(
      background: Color(0xFF3B2A1E),
      onBackground: Color(0xFFF8E4D4),
      iconContainer: Color(0xFF533B2A),
      icon: Color(0xFFF2D2B8),
      blob: Color(0xFF4A3527),
    ),
    stats: SettingsTone(
      background: Color(0xFF3B2430),
      onBackground: Color(0xFFF6DEE7),
      iconContainer: Color(0xFF553345),
      icon: Color(0xFFF0C9D9),
      blob: Color(0xFF4A2C3C),
    ),
    about: SettingsTone(
      background: Color(0xFF26282E),
      onBackground: Color(0xFFE3E1E9),
      iconContainer: Color(0xFF34373E),
      icon: Color(0xFFC7C6CD),
      blob: Color(0xFF303339),
    ),
  );
}
