import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/session_edit.dart';
import 'package:sleepy3/features/stats/presentation/session_edit_error_text.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations es;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    es = await AppLocalizations.delegate.load(const Locale('es'));
  });

  test('every validation error has English and Spanish copy', () {
    for (final error in SessionEditError.values) {
      expect(en.sessionEditError(error), isNotEmpty);
      expect(es.sessionEditError(error), isNotEmpty);
      expect(es.sessionEditError(error), isNot(en.sessionEditError(error)));
    }
  });
}
