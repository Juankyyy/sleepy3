import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/updates/domain/release_notes.dart';

void main() {
  group('normalizeReleaseNotes', () {
    test('removes the title comment and trims the body', () {
      expect(
        normalizeReleaseNotes('<!-- title: v0.4.0 -->\n\nSleepy3 0.4.0.\n'),
        'Sleepy3 0.4.0.',
      );
    });

    test('returns null without usable content', () {
      expect(normalizeReleaseNotes(null), isNull);
      expect(normalizeReleaseNotes(''), isNull);
      expect(normalizeReleaseNotes('<!-- title: v0.4.0 -->\n\n'), isNull);
    });
  });

  group('ReleaseNotes.parse', () {
    test('parses headings, paragraphs, lists and inline styles', () {
      const body = '''
<!-- title: v0.4.1 -->

Sleepy3 0.4.1 makes **strong** text, uses `code` and a [link](https://example.com/docs).

## A section

- First item
- Second item with https://example.com/compare.

**Full changelog**: https://example.com/full.
''';

      final notes = ReleaseNotes.parse(body);

      expect(notes.blocks, hasLength(4));
      expect(notes.blocks[0], isA<ReleaseNoteParagraph>());
      expect(notes.blocks[1], isA<ReleaseNoteHeading>());
      expect(notes.blocks[2], isA<ReleaseNoteList>());
      expect(notes.blocks[3], isA<ReleaseNoteParagraph>());

      final paragraph = notes.blocks[0] as ReleaseNoteParagraph;
      expect(
        paragraph.content.whereType<ReleaseNoteText>().map((text) => text.text),
        containsAll(['Sleepy3 0.4.1 makes ', 'strong', ' text, uses ']),
      );
      expect(
        paragraph.content
            .whereType<ReleaseNoteText>()
            .where((text) => text.bold)
            .map((text) => text.text),
        ['strong'],
      );
      expect(
        paragraph.content
            .whereType<ReleaseNoteText>()
            .where((text) => text.code)
            .map((text) => text.text),
        ['code'],
      );
      final link = paragraph.content.whereType<ReleaseNoteLink>().single;
      expect(link.label, 'link');
      expect(link.uri, Uri.parse('https://example.com/docs'));

      final heading = notes.blocks[1] as ReleaseNoteHeading;
      expect(heading.level, 2);
      expect(
        heading.content.whereType<ReleaseNoteText>().map((text) => text.text),
        ['A section'],
      );

      final list = notes.blocks[2] as ReleaseNoteList;
      expect(list.ordered, isFalse);
      expect(list.items, hasLength(2));
      final secondItemLink = list.items[1].whereType<ReleaseNoteLink>().single;
      expect(secondItemLink.label, 'https://example.com/compare');
      expect(secondItemLink.uri, Uri.parse('https://example.com/compare'));

      final footer = notes.blocks[3] as ReleaseNoteParagraph;
      expect(
        footer.content
            .whereType<ReleaseNoteText>()
            .where((text) => text.bold)
            .map((text) => text.text),
        ['Full changelog'],
      );
      expect(
        footer.content.whereType<ReleaseNoteLink>().single.uri,
        Uri.parse('https://example.com/full'),
      );
    });

    test('joins soft-wrapped paragraphs and normalizes CRLF', () {
      final notes = ReleaseNotes.parse(
        '## Title\r\n\r\nLine one\r\nline two\r\n\r\nNext paragraph.',
      );

      expect(notes.blocks, hasLength(3));
      final paragraph = notes.blocks[1] as ReleaseNoteParagraph;
      final text = paragraph.content.whereType<ReleaseNoteText>().single;
      expect(text.text, 'Line one line two');
    });

    test('parses ordered lists, quotes and code fences', () {
      final notes = ReleaseNotes.parse('''
1. First
2. Second

> A quote

```text
line one
line two
```
''');

      expect(notes.blocks, hasLength(3));
      final list = notes.blocks[0] as ReleaseNoteList;
      expect(list.ordered, isTrue);
      expect(list.items, hasLength(2));

      expect(notes.blocks[1], isA<ReleaseNoteQuote>());
      expect(notes.blocks[2], isA<ReleaseNoteCode>());
      expect((notes.blocks[2] as ReleaseNoteCode).code, 'line one\nline two');
    });

    test('returns an empty set for missing or comment-only notes', () {
      expect(ReleaseNotes.parse(null).isEmpty, isTrue);
      expect(ReleaseNotes.parse('').isEmpty, isTrue);
      expect(ReleaseNotes.parse('<!-- title: v0.4.0 -->\n\n').isEmpty, isTrue);
    });

    test('keeps unmatched emphasis markers as literal text', () {
      final notes = ReleaseNotes.parse('A *literal star and **two markers.');

      final paragraph = notes.blocks.single as ReleaseNoteParagraph;
      expect(
        paragraph.content.whereType<ReleaseNoteText>().single.text,
        'A *literal star and **two markers.',
      );
    });
  });
}
