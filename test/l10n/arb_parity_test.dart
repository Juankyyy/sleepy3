import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Spanish ARB files contain the same messages', () {
    final en = _readArb('lib/l10n/app_en.arb');
    final es = _readArb('lib/l10n/app_es.arb');

    expect(en['@@locale'], 'en');
    expect(es['@@locale'], 'es');

    final enKeys = _messageKeys(en);
    final esKeys = _messageKeys(es);

    expect(
      esKeys,
      enKeys,
      reason: 'Every English message needs a Spanish translation',
    );
    for (final key in enKeys) {
      expect(es[key], isNotEmpty, reason: 'Empty Spanish value for $key');
      expect(en[key], isNotEmpty, reason: 'Empty English value for $key');
    }
  });
}

Map<String, dynamic> _readArb(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys
      .where((key) => key != '@@locale' && !key.startsWith('@'))
      .toSet();
}
