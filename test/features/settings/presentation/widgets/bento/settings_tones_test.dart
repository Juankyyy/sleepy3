import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/features/settings/presentation/widgets/bento/settings_tones.dart';

void main() {
  test('every Settings tone meets its contrast pair', () {
    for (final palette in [SettingsPalette.light, SettingsPalette.dark]) {
      for (final tone in palette.all) {
        expect(
          _contrast(tone.onBackground, tone.background),
          greaterThanOrEqualTo(4.5),
          reason: 'Text on ${tone.background}',
        );
        expect(
          _contrast(tone.supporting, tone.background),
          greaterThanOrEqualTo(4.5),
          reason: 'Supporting text on ${tone.background}',
        );
        expect(
          _contrast(tone.onBackground, tone.blob),
          greaterThanOrEqualTo(4.5),
          reason: 'Text over the figure on ${tone.background}',
        );
        expect(
          _contrast(tone.supporting, tone.blob),
          greaterThanOrEqualTo(4.5),
          reason: 'Supporting text over the figure on ${tone.background}',
        );
        expect(
          _contrast(tone.icon, tone.iconContainer),
          greaterThanOrEqualTo(3),
          reason: 'Icon on ${tone.iconContainer}',
        );
      }
    }
  });
}

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}
