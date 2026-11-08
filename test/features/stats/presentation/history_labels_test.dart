import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sleepy3/features/stats/presentation/history_labels.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  final today = DateTime(2026, 10, 21);
  late AppLocalizations en;
  late AppLocalizations es;

  setUpAll(() async {
    await initializeDateFormatting();
    en = await AppLocalizations.delegate.load(const Locale('en'));
    es = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('formatHistoryDay', () {
    test('uses Today and Yesterday for adjacent calendar days', () {
      expect(en.formatHistoryDay(today, today), 'Today');
      expect(en.formatHistoryDay(DateTime(2026, 10, 20), today), 'Yesterday');
    });

    test('abbreviates older dates and includes another year', () {
      expect(en.formatHistoryDay(DateTime(2026, 10, 19), today), 'Mon, Oct 19');
      expect(
        en.formatHistoryDay(DateTime(2025, 12, 29), today),
        'Mon, Dec 29, 2025',
      );
    });

    test('uses Spanish day labels and abbreviations', () {
      expect(es.formatHistoryDay(today, today), 'Hoy');
      expect(es.formatHistoryDay(DateTime(2026, 10, 20), today), 'Ayer');
      expect(es.formatHistoryDay(DateTime(2026, 10, 19), today), 'lun, 19 oct');
      expect(
        es.formatHistoryDay(DateTime(2025, 12, 29), today),
        'lun, 29 dic 2025',
      );
    });
  });

  group('formatHistoryDaySpoken', () {
    test('spells out adjacent and older dates', () {
      expect(en.formatHistoryDaySpoken(today, today), 'Today');
      expect(
        en.formatHistoryDaySpoken(DateTime(2026, 10, 20), today),
        'Yesterday',
      );
      expect(
        en.formatHistoryDaySpoken(DateTime(2026, 10, 19), today),
        'Monday, October 19',
      );
      expect(
        en.formatHistoryDaySpoken(DateTime(2025, 12, 29), today),
        'Monday, December 29, 2025',
      );
    });

    test('spells out Spanish dates', () {
      expect(
        es.formatHistoryDaySpoken(DateTime(2026, 10, 19), today),
        'lunes, 19 de octubre',
      );
      expect(
        es.formatHistoryDaySpoken(DateTime(2025, 12, 29), today),
        'lunes, 29 de diciembre de 2025',
      );
    });
  });

  group('formatExternalSessionLabel', () {
    test('uses the resolved app label', () {
      expect(en.formatExternalSessionLabel('Samsung Health'), 'Samsung Health');
      expect(es.formatExternalSessionLabel('Samsung Health'), 'Samsung Health');
    });

    test('falls back when the label cannot be resolved', () {
      expect(en.formatExternalSessionLabel(null), 'Another app');
      expect(es.formatExternalSessionLabel(null), 'Otra app');
    });
  });

  group('formatExternalSessionSpokenLabel', () {
    test('spells out the read-only state and the app', () {
      expect(
        en.formatExternalSessionSpokenLabel('Samsung Health'),
        'Read-only, from Samsung Health',
      );
      expect(
        es.formatExternalSessionSpokenLabel('Samsung Health'),
        'Solo lectura, de Samsung Health',
      );
    });

    test('uses the generic fallback for an unknown app', () {
      expect(
        en.formatExternalSessionSpokenLabel(null),
        'Read-only, from another app',
      );
      expect(
        es.formatExternalSessionSpokenLabel(null),
        'Solo lectura, de otra app',
      );
    });
  });

  group('formatHistoryTimeRange', () {
    final start = DateTime(2026, 10, 21, 22, 32);
    final end = DateTime(2026, 10, 22, 6, 45);

    test('uses the 12-hour system', () {
      expect(
        en.formatHistoryTimeRange(start, end, use24HourFormat: false),
        '10:32 PM – 6:45 AM',
      );
      expect(
        es.formatHistoryTimeRange(start, end, use24HourFormat: false),
        '10:32 p.\u202Fm. – 6:45 a.\u202Fm.',
      );
    });

    test('uses the 24-hour system', () {
      expect(
        en.formatHistoryTimeRange(start, end, use24HourFormat: true),
        '22:32 – 06:45',
      );
      expect(
        es.formatHistoryTimeRange(start, end, use24HourFormat: true),
        '22:32 – 06:45',
      );
    });

    test('spells the range for screen readers', () {
      expect(
        en.formatHistoryTimeRangeSpoken(start, end, use24HourFormat: false),
        '10:32 PM to 6:45 AM',
      );
      expect(
        es.formatHistoryTimeRangeSpoken(start, end, use24HourFormat: false),
        '10:32 p.\u202Fm. a 6:45 a.\u202Fm.',
      );
    });
  });
}
