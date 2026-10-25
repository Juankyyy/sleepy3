import 'dart:ui' show Brightness;

import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/domain/app_theme_mode.dart';

void main() {
  group('AppThemeMode', () {
    test('system follows the platform brightness', () {
      expect(
        AppThemeMode.system.resolveBrightness(Brightness.light),
        Brightness.light,
      );
      expect(
        AppThemeMode.system.resolveBrightness(Brightness.dark),
        Brightness.dark,
      );
    });

    test('light and dark ignore the platform brightness', () {
      for (final platform in Brightness.values) {
        expect(
          AppThemeMode.light.resolveBrightness(platform),
          Brightness.light,
        );
        expect(AppThemeMode.dark.resolveBrightness(platform), Brightness.dark);
      }
    });

    test('parses stored names and falls back to system', () {
      expect(AppThemeMode.fromStorageValue('system'), AppThemeMode.system);
      expect(AppThemeMode.fromStorageValue('light'), AppThemeMode.light);
      expect(AppThemeMode.fromStorageValue('dark'), AppThemeMode.dark);
      expect(AppThemeMode.fromStorageValue('sepia'), AppThemeMode.system);
      expect(AppThemeMode.fromStorageValue(null), AppThemeMode.system);
    });
  });
}
