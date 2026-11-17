import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/updates/domain/app_version_number.dart';

void main() {
  group('AppVersionNumber.tryParse', () {
    test('parses GitHub tags and package versions', () {
      expect(
        AppVersionNumber.tryParse('v0.4.0'),
        const AppVersionNumber(0, 4, 0),
      );
      expect(
        AppVersionNumber.tryParse('0.3.1-debug'),
        const AppVersionNumber(0, 3, 1),
      );
      expect(
        AppVersionNumber.tryParse('0.3.1+30'),
        const AppVersionNumber(0, 3, 1),
      );
      expect(
        AppVersionNumber.tryParse('  V1.2.3 '),
        const AppVersionNumber(1, 2, 3),
      );
      expect(
        AppVersionNumber.tryParse('01.002.0003'),
        const AppVersionNumber(1, 2, 3),
      );
    });

    test('rejects values without a three-part numeric core', () {
      for (final value in ['', '0.3', 'v1', 'release']) {
        expect(
          AppVersionNumber.tryParse(value),
          isNull,
          reason: 'Accepted $value',
        );
      }
    });
  });

  group('comparison', () {
    test('orders each component numerically', () {
      const older = AppVersionNumber(0, 9, 9);
      const newer = AppVersionNumber(0, 10, 0);

      expect(newer.isNewerThan(older), isTrue);
      expect(older.isNewerThan(newer), isFalse);
      expect(newer.compareTo(older), greaterThan(0));
      expect(older.compareTo(newer), lessThan(0));
      expect(older.compareTo(older), 0);
    });

    test('compares major before minor and patch', () {
      expect(
        const AppVersionNumber(
          1,
          0,
          0,
        ).isNewerThan(const AppVersionNumber(0, 99, 99)),
        isTrue,
      );
      expect(
        const AppVersionNumber(
          0,
          4,
          2,
        ).isNewerThan(const AppVersionNumber(0, 4, 1)),
        isTrue,
      );
    });

    test('formats the normalized version', () {
      expect(AppVersionNumber.tryParse('v0.4.0')!.toString(), '0.4.0');
      expect(AppVersionNumber.tryParse('0.3.1-debug')!.toString(), '0.3.1');
    });
  });
}
