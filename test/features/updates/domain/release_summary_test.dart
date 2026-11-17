import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/updates/domain/release_summary.dart';

void main() {
  group('extractReleaseSummary', () {
    test('uses the first prose paragraph and strips Markdown', () {
      const body = '''
<!-- title: v0.3.1 - The Test Update -->

Sleepy3 0.3.1 makes your history **yours** to keep. Read [the notes](https://example.com) and `export` it.

## What's new

- One change
''';

      expect(
        extractReleaseSummary(body),
        'Sleepy3 0.3.1 makes your history yours to keep. '
        'Read the notes and export it.',
      );
    });

    test('skips headings, lists and code blocks', () {
      const body = '''
<!-- title: v0.4.0 -->

## Highlights

- First
- Second

The first real paragraph.
''';

      expect(extractReleaseSummary(body), 'The first real paragraph.');
    });

    test('returns null without prose', () {
      expect(extractReleaseSummary(null), isNull);
      expect(extractReleaseSummary(''), isNull);
      expect(
        extractReleaseSummary(
          '<!-- title: v0.4.0 -->\n\n## What\'s new\n\n- Only a list',
        ),
        isNull,
      );
    });

    test('truncates long paragraphs at a word boundary', () {
      final summary = extractReleaseSummary('word ' * 80);

      expect(summary, isNotNull);
      expect(summary!.length, lessThanOrEqualTo(221));
      expect(summary, endsWith('…'));
    });
  });
}
