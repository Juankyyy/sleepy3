import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations es;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    es = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('formatSleepDuration', () {
    test('formats minutes only', () {
      expect(en.formatSleepDuration(const Duration(minutes: 35)), '35m');
      expect(es.formatSleepDuration(const Duration(minutes: 35)), '35 min');
    });

    test('formats hours and minutes', () {
      expect(
        en.formatSleepDuration(const Duration(hours: 7, minutes: 45)),
        '7h 45m',
      );
      expect(
        es.formatSleepDuration(const Duration(hours: 7, minutes: 45)),
        '7 h 45 min',
      );
    });

    test('keeps zero minutes visible when hours exist', () {
      expect(en.formatSleepDuration(const Duration(hours: 8)), '8h 0m');
      expect(es.formatSleepDuration(const Duration(hours: 8)), '8 h 0 min');
    });

    test('formats zero and negative durations as zero', () {
      expect(en.formatSleepDuration(Duration.zero), '0m');
      expect(en.formatSleepDuration(const Duration(minutes: -10)), '0m');
      expect(es.formatSleepDuration(Duration.zero), '0 min');
      expect(es.formatSleepDuration(const Duration(minutes: -10)), '0 min');
    });
  });

  group('formatSpokenSleepDuration', () {
    test('uses singular hour and minute', () {
      expect(
        en.formatSpokenSleepDuration(const Duration(hours: 1, minutes: 1)),
        '1 hour 1 minute',
      );
      expect(
        es.formatSpokenSleepDuration(const Duration(hours: 1, minutes: 1)),
        '1 hora 1 minuto',
      );
    });

    test('speaks minutes only', () {
      expect(
        en.formatSpokenSleepDuration(const Duration(minutes: 35)),
        '35 minutes',
      );
      expect(
        es.formatSpokenSleepDuration(const Duration(minutes: 35)),
        '35 minutos',
      );
    });

    test('keeps zero minutes when hours exist', () {
      expect(
        en.formatSpokenSleepDuration(const Duration(hours: 8)),
        '8 hours 0 minutes',
      );
      expect(
        es.formatSpokenSleepDuration(const Duration(hours: 8)),
        '8 horas 0 minutos',
      );
    });

    test('speaks zero and negative durations as zero', () {
      expect(en.formatSpokenSleepDuration(Duration.zero), '0 minutes');
      expect(
        en.formatSpokenSleepDuration(const Duration(minutes: -10)),
        '0 minutes',
      );
      expect(es.formatSpokenSleepDuration(Duration.zero), '0 minutos');
      expect(
        es.formatSpokenSleepDuration(const Duration(minutes: -10)),
        '0 minutos',
      );
    });
  });

  group('formatGoalDelta', () {
    test('omits a zero minute part', () {
      expect(en.formatGoalDelta(const Duration(minutes: 13)), '13m');
      expect(en.formatGoalDelta(const Duration(hours: 1)), '1h');
      expect(
        en.formatGoalDelta(const Duration(hours: 1, minutes: 12)),
        '1h 12m',
      );
      expect(es.formatGoalDelta(const Duration(minutes: 13)), '13 min');
      expect(es.formatGoalDelta(const Duration(hours: 1)), '1 h');
      expect(
        es.formatGoalDelta(const Duration(hours: 1, minutes: 12)),
        '1 h 12 min',
      );
    });
  });
}
