import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_format.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  test('chartHourLabel follows the 12-hour setting in Spanish', () {
    final l10n = lookupAppLocalizations(const Locale('es'));

    expect(
      chartHourLabel(l10n: l10n, hour: 18, use24HourFormat: false),
      '6 p.\u202Fm.',
    );
    expect(
      chartHourLabel(l10n: l10n, hour: 0, use24HourFormat: false),
      '12 a.\u202Fm.',
    );
    expect(
      chartHourLabel(l10n: l10n, hour: 18, use24HourFormat: true),
      '18:00',
    );
  });

  test('chartHourLabel drops the minutes in English 12-hour labels', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(
      chartHourLabel(l10n: l10n, hour: 18, use24HourFormat: false),
      '6 PM',
    );
    expect(
      chartHourLabel(l10n: l10n, hour: 12, use24HourFormat: false),
      '12 PM',
    );
    expect(
      chartHourLabel(l10n: l10n, hour: 18, use24HourFormat: true),
      '18:00',
    );
  });
}
