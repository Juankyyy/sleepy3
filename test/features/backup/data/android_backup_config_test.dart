import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android auto-backup wiring that keeps the local database
/// restorable after a reinstall. The XML rules are easy to drop when the
/// manifest changes, and no widget test would notice.
void main() {
  test('the manifest points at the backup rules', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('auto-backup includes the database and its journal', () {
    for (final path in [
      'android/app/src/main/res/xml/backup_rules.xml',
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ]) {
      final rules = File(path).readAsStringSync();
      for (final file in [
        'app_flutter/sleepy3.sqlite',
        'app_flutter/sleepy3.sqlite-wal',
        'app_flutter/sleepy3.sqlite-shm',
        'app_flutter/sleepy3.sqlite-journal',
      ]) {
        expect(
          rules,
          contains('domain="root" path="$file"'),
          reason: '$path does not include $file',
        );
      }
    }
  });
}
