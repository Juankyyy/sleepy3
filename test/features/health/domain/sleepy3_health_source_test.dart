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

  test('only the running package owns a writable record', () {
    expect(isHealthRecordOwnedBy('com.sleepy3.app', 'com.sleepy3.app'), isTrue);
    expect(
      isHealthRecordOwnedBy('com.sleepy3.app.debug', 'com.sleepy3.app'),
      isFalse,
    );
    expect(
      isHealthRecordOwnedBy('com.sleepy3.app', 'com.sleepy3.app.debug'),
      isFalse,
    );
    expect(
      isHealthRecordOwnedBy('com.example.other', 'com.sleepy3.app'),
      isFalse,
    );
    expect(isHealthRecordOwnedBy(null, 'com.sleepy3.app'), isFalse);
  });

  test('recognizes a record written by the other Sleepy3 build', () {
    expect(
      isOtherSleepy3Build('com.sleepy3.app.debug', 'com.sleepy3.app'),
      isTrue,
    );
    expect(
      isOtherSleepy3Build('com.sleepy3.app', 'com.sleepy3.app.debug'),
      isTrue,
    );
    expect(isOtherSleepy3Build('com.sleepy3.app', 'com.sleepy3.app'), isFalse);
    expect(
      isOtherSleepy3Build('com.example.other', 'com.sleepy3.app'),
      isFalse,
    );
  });
}
