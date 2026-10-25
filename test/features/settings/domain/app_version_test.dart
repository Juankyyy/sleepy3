import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/domain/app_version.dart';

void main() {
  group('AppVersion', () {
    test('shows the build number when present', () {
      const version = AppVersion(version: '0.1.0', buildNumber: '1');
      expect(version.display, '0.1.0 (1)');
    });

    test('omits an empty build number', () {
      const version = AppVersion(version: '0.1.0');
      expect(version.display, '0.1.0');
      expect(
        const AppVersion(version: '0.1.0', buildNumber: '').display,
        '0.1.0',
      );
    });
  });
}
