import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/sleepy3_health_source.dart';

void main() {
  test('recognizes the release and debug packages', () {
    expect(isSleepy3HealthRecord('com.sleepy3.app'), isTrue);
    expect(isSleepy3HealthRecord('com.sleepy3.app.debug'), isTrue);
  });

  test('rejects other apps and missing source ids', () {
    expect(isSleepy3HealthRecord('com.example.other'), isFalse);
    expect(isSleepy3HealthRecord('com.sleepy3.app.other'), isFalse);
    expect(isSleepy3HealthRecord(null), isFalse);
    expect(isSleepy3HealthRecord(''), isFalse);
  });
}
