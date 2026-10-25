import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';

void main() {
  group('Sleepy3Theme', () {
    test('generates light and dark schemes from the same seed', () {
      final light = Sleepy3Theme.light();
      final dark = Sleepy3Theme.dark();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
      expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));

      final expectedLight = M3EColorScheme.fromSeed(Sleepy3Theme.seedColor);
      final expectedDark = M3EColorScheme.fromSeed(
        Sleepy3Theme.seedColor,
        brightness: Brightness.dark,
      );

      expect(light.colorScheme.primary, expectedLight.primary);
      expect(light.colorScheme.surface, expectedLight.surface);
      expect(dark.colorScheme.primary, expectedDark.primary);
      expect(dark.colorScheme.surface, expectedDark.surface);
    });

    test('maps the expected M3 color roles accessibly', () {
      for (final theme in [Sleepy3Theme.light(), Sleepy3Theme.dark()]) {
        final scheme = theme.colorScheme;

        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(scheme.surfaceContainer, isNot(scheme.surface));
        expect(scheme.outlineVariant, isNot(scheme.outline));
      }
    });

    test('uses the flexible navigation bar roles', () {
      for (final theme in [Sleepy3Theme.light(), Sleepy3Theme.dark()]) {
        final scheme = theme.colorScheme;
        final navigationBar = theme.navigationBarTheme;

        expect(navigationBar.containerColor(scheme), scheme.surfaceContainer);
        expect(navigationBar.activeLabelColor(scheme), scheme.secondary);
        expect(
          navigationBar.selectedColor(scheme),
          scheme.onSecondaryContainer,
        );
        expect(navigationBar.indicatorColor(scheme), scheme.secondaryContainer);
        expect(navigationBar.unselectedColor(scheme), scheme.onSurfaceVariant);
        expect(navigationBar.elevation, 0);
        expect(
          _contrast(scheme.secondary, scheme.surfaceContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onSurfaceVariant, scheme.surfaceContainer),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('uses the M3 type scale with bundled Roboto Flex', () {
      final theme = Sleepy3Theme.light();
      final baseline = theme.typography.baseline;
      final emphasized = theme.typography.emphasized;

      final styles = [
        baseline.displayLarge,
        baseline.headlineLarge,
        baseline.bodyMedium,
        baseline.labelMedium,
        emphasized.displayLarge,
        emphasized.headlineLarge,
      ];

      for (final style in styles) {
        expect(style.fontFamily, Sleepy3Theme.fontFamily);
        expect(style.fontVariations, isNotEmpty);
        // M3 tops out at 700; the prototype's 850/950 weights are not tokens.
        expect(style.fontWeight!.value, lessThanOrEqualTo(700));
      }

      expect(baseline.displayLarge.fontSize, 57);
      expect(baseline.headlineLarge.fontSize, 32);
      expect(baseline.bodyMedium.fontSize, 14);
      expect(baseline.labelMedium.fontSize, 12);
      expect(baseline.displayLarge.fontWeight, FontWeight.w400);
      expect(emphasized.displayLarge.fontWeight, FontWeight.w500);
      expect(emphasized.headlineLarge.fontWeight, FontWeight.w500);

      final variations = baseline.displayLarge.fontVariations!;
      expect(
        variations.any(
          (variation) => variation.axis == 'wght' && variation.value == 400,
        ),
        isTrue,
      );
      expect(
        variations.any(
          (variation) => variation.axis == 'opsz' && variation.value == 57,
        ),
        isTrue,
      );
    });
  });
}

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
