import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';

void main() {
  group('Sleepy3Theme', () {
    test('uses the exact brand anchors', () {
      final light = Sleepy3Theme.light();
      final dark = Sleepy3Theme.dark();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      expect(light.colorScheme.surface, Sleepy3Theme.lightBackground);
      expect(light.colorScheme.primary, Sleepy3Theme.brandIndigo);
      expect(light.colorScheme.onPrimary, const Color(0xFFFFFFFF));

      expect(dark.colorScheme.surface, Sleepy3Theme.darkBackground);
      expect(dark.colorScheme.primary, Sleepy3Theme.darkPrimary);
      expect(dark.colorScheme.onPrimary, const Color(0xFF272B60));

      expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });

    test('builds the neutral ramp around the exact body color', () {
      final light = Sleepy3Theme.light().colorScheme;

      expect(light.surface, const Color(0xFFEFF4F9));
      expect(light.surfaceDim, const Color(0xFFD0D5DA));
      expect(light.surfaceBright, const Color(0xFFF5FAFF));
      expect(light.surfaceContainerLowest, const Color(0xFFFFFFFF));
      expect(light.surfaceContainerLow, const Color(0xFFE9EEF3));
      expect(light.surfaceContainer, const Color(0xFFE4E9EE));
      expect(light.surfaceContainerHigh, const Color(0xFFDEE3E8));
      expect(light.surfaceContainerHighest, const Color(0xFFD8DDE2));
      expect(light.onSurface, const Color(0xFF13181C));
      expect(light.onSurfaceVariant, const Color(0xFF3D4347));
      expect(light.outline, const Color(0xFF6D7377));
      expect(light.outlineVariant, const Color(0xFFBCC2C6));
      expect(light.inverseSurface, const Color(0xFF272D31));
      expect(light.onInverseSurface, const Color(0xFFE7ECF1));

      // Light containers are darker than the body, in M3 emphasis order.
      expect(
        light.surfaceContainerLowest.computeLuminance(),
        greaterThan(light.surface.computeLuminance()),
      );
      expect(
        light.surface.computeLuminance(),
        greaterThan(light.surfaceContainerLow.computeLuminance()),
      );
      expect(
        light.surfaceContainerLow.computeLuminance(),
        greaterThan(light.surfaceContainer.computeLuminance()),
      );
      expect(
        light.surfaceContainer.computeLuminance(),
        greaterThan(light.surfaceContainerHigh.computeLuminance()),
      );
      expect(
        light.surfaceContainerHigh.computeLuminance(),
        greaterThan(light.surfaceContainerHighest.computeLuminance()),
      );
      expect(
        light.surfaceContainerHighest.computeLuminance(),
        greaterThan(light.surfaceDim.computeLuminance()),
      );

      final dark = Sleepy3Theme.dark().colorScheme;

      expect(dark.surface, const Color(0xFF121318));
      expect(dark.surfaceDim, const Color(0xFF121318));
      expect(dark.surfaceBright, const Color(0xFF38393E));
      expect(dark.surfaceContainerLowest, const Color(0xFF0D0E13));
      expect(dark.surfaceContainerLow, const Color(0xFF1A1B20));
      expect(dark.surfaceContainer, const Color(0xFF1E1F25));
      expect(dark.surfaceContainerHigh, const Color(0xFF292A2F));
      expect(dark.surfaceContainerHighest, const Color(0xFF34343A));
      expect(dark.onSurface, const Color(0xFFE3E1E9));
      expect(dark.onSurfaceVariant, const Color(0xFFC7C6CD));
      expect(dark.outline, const Color(0xFF909097));
      expect(dark.outlineVariant, const Color(0xFF46464C));
      expect(dark.inverseSurface, const Color(0xFFE3E1E9));
      expect(dark.onInverseSurface, const Color(0xFF2F3036));

      // Dark containers are lighter than the body, in M3 emphasis order.
      expect(
        dark.surfaceContainerLowest.computeLuminance(),
        lessThan(dark.surface.computeLuminance()),
      );
      expect(
        dark.surface.computeLuminance(),
        lessThan(dark.surfaceContainerLow.computeLuminance()),
      );
      expect(
        dark.surfaceContainerLow.computeLuminance(),
        lessThan(dark.surfaceContainer.computeLuminance()),
      );
      expect(
        dark.surfaceContainer.computeLuminance(),
        lessThan(dark.surfaceContainerHigh.computeLuminance()),
      );
      expect(
        dark.surfaceContainerHigh.computeLuminance(),
        lessThan(dark.surfaceContainerHighest.computeLuminance()),
      );
      expect(
        dark.surfaceContainerHighest.computeLuminance(),
        lessThan(dark.surfaceBright.computeLuminance()),
      );
    });

    test('maps the expected M3 color roles accessibly', () {
      for (final theme in [Sleepy3Theme.light(), Sleepy3Theme.dark()]) {
        final scheme = theme.colorScheme;
        final textPairs = <(Color, Color)>[
          (scheme.onSurface, scheme.surface),
          (scheme.onSurfaceVariant, scheme.surface),
          (scheme.onSurface, scheme.surfaceContainer),
          (scheme.onSurfaceVariant, scheme.surfaceContainer),
          (scheme.onPrimary, scheme.primary),
          (scheme.onPrimaryContainer, scheme.primaryContainer),
          (scheme.onSecondaryContainer, scheme.secondaryContainer),
          (scheme.secondary, scheme.surfaceContainer),
          (scheme.primary, scheme.surface),
        ];

        for (final (foreground, background) in textPairs) {
          expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
        }

        expect(
          _contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(3),
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

    test('uses the M3 type scale with bundled Space Grotesk', () {
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
      // Space Grotesk has no optical-size axis.
      expect(variations.any((variation) => variation.axis == 'opsz'), isFalse);
    });

    test('the clock uses Space Grotesk at 700 with tabular figures', () {
      final theme = Sleepy3Theme.light();
      final clock = Sleepy3Theme.clock(
        theme.typography.emphasized.displayLarge,
      );

      expect(clock.fontFamily, Sleepy3Theme.fontFamily);
      expect(clock.fontWeight, FontWeight.w700);
      expect(clock.fontVariations!.single.axis, 'wght');
      expect(clock.fontVariations!.single.value, 700);
      expect(
        clock.fontFeatures!.any(
          (feature) =>
              feature.feature == FontFeature.tabularFigures().feature &&
              feature.value == FontFeature.tabularFigures().value,
        ),
        isTrue,
      );
    });

    test('brand titles use the instanced Google Sans Flex face', () {
      final theme = Sleepy3Theme.light();
      final large = Sleepy3Theme.brandTitle(
        theme.typography.emphasized.headlineLarge,
      );
      final medium = Sleepy3Theme.brandTitle(
        theme.typography.emphasized.headlineMedium,
      );

      expect(large.fontFamily, Sleepy3Theme.brandFontFamily);
      expect(medium.fontFamily, Sleepy3Theme.brandFontFamily);

      // The instanced asset bakes the 900 weight in, so the role keeps its M3
      // tokens and only the optical size varies.
      expect(large.fontWeight, FontWeight.w500);
      expect(large.fontSize, 32);
      expect(medium.fontSize, 28);
      expect(large.fontVariations!.single.axis, 'opsz');
      expect(large.fontVariations!.single.value, 32);
      expect(medium.fontVariations!.single.axis, 'opsz');
      expect(medium.fontVariations!.single.value, 28);

      // Everything else stays on Space Grotesk.
      expect(
        theme.typography.emphasized.displayLarge.fontFamily,
        Sleepy3Theme.fontFamily,
      );
      expect(
        theme.typography.baseline.bodyMedium.fontFamily,
        Sleepy3Theme.fontFamily,
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
