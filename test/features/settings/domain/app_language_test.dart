import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';

void main() {
  group('AppLanguage', () {
    test('exposes the locale used by MaterialApp', () {
      expect(AppLanguage.english.locale, const Locale('en'));
      expect(AppLanguage.spanish.locale, const Locale('es'));
    });

    test('resolves the first supported system language', () {
      expect(AppLanguage.forSystem(const [Locale('es')]), AppLanguage.spanish);
      expect(
        AppLanguage.forSystem(const [Locale('es', 'MX')]),
        AppLanguage.spanish,
      );
      expect(
        AppLanguage.forSystem(const [Locale('en', 'GB')]),
        AppLanguage.english,
      );
      expect(AppLanguage.forSystem(const [Locale('fr')]), AppLanguage.english);
      expect(
        AppLanguage.forSystem(const [Locale('en'), Locale('es')]),
        AppLanguage.english,
      );
      expect(
        AppLanguage.forSystem(const [Locale('fr'), Locale('es')]),
        AppLanguage.spanish,
      );
    });

    test('parses stored values', () {
      expect(AppLanguage.fromStorageValue('english'), AppLanguage.english);
      expect(AppLanguage.fromStorageValue('spanish'), AppLanguage.spanish);
      expect(AppLanguage.fromStorageValue('french'), isNull);
      expect(AppLanguage.fromStorageValue(null), isNull);
    });
  });
}
