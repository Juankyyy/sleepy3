import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';

void main() {
  group('AppTimeFormat', () {
    test('resolves the phone format', () {
      expect(AppTimeFormat.forSystem(true), AppTimeFormat.twentyFourHour);
      expect(AppTimeFormat.forSystem(false), AppTimeFormat.twelveHour);
    });

    test('reports whether it uses a 24-hour clock', () {
      expect(AppTimeFormat.twentyFourHour.uses24HourFormat, isTrue);
      expect(AppTimeFormat.twelveHour.uses24HourFormat, isFalse);
    });

    test('parses stored values', () {
      expect(
        AppTimeFormat.fromStorageValue('twelveHour'),
        AppTimeFormat.twelveHour,
      );
      expect(
        AppTimeFormat.fromStorageValue('twentyFourHour'),
        AppTimeFormat.twentyFourHour,
      );
      expect(AppTimeFormat.fromStorageValue('military'), isNull);
      expect(AppTimeFormat.fromStorageValue(null), isNull);
    });
  });
}
