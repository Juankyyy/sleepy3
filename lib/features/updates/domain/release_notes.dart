/// The curated release notes reduced to the blocks the update dialog shows.
///
/// GitHub release bodies are Markdown. Sleepy3 authors them as an HTML title
/// comment, a summary paragraph, `##` sections, paragraphs, bold phrases,
/// inline code, bullet lists and a full-changelog link. This model keeps that
/// subset and degrades any unknown syntax to plain text instead of dropping it.
class ReleaseNotes {
  const ReleaseNotes(this.blocks);

  static const empty = ReleaseNotes(<ReleaseNoteBlock>[]);

  final List<ReleaseNoteBlock> blocks;

  bool get isEmpty => blocks.isEmpty;

  factory ReleaseNotes.parse(String? markdown) {
    return ReleaseNotes(_parseBlocks(markdown ?? ''));
  }
}

/// Removes the release metadata comments and trims the Markdown body.
String? normalizeReleaseNotes(String? body) {
  if (body == null) return null;

  final withoutComments = body.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final trimmed = withoutComments.trim();
  return trimmed.isEmpty ? null : trimmed;
}

sealed class ReleaseNoteBlock {
  const ReleaseNoteBlock();
}

final class ReleaseNoteHeading extends ReleaseNoteBlock {
  const ReleaseNoteHeading({required this.level, required this.content});

  final int level;
  final List<ReleaseNoteInline> content;
}

final class ReleaseNoteParagraph extends ReleaseNoteBlock {
  const ReleaseNoteParagraph(this.content);

  final List<ReleaseNoteInline> content;
}

final class ReleaseNoteList extends ReleaseNoteBlock {
  const ReleaseNoteList({required this.ordered, required this.items});

  final bool ordered;
  final List<List<ReleaseNoteInline>> items;
}

final class ReleaseNoteQuote extends ReleaseNoteBlock {
  const ReleaseNoteQuote(this.content);

  final List<ReleaseNoteInline> content;
}

final class ReleaseNoteCode extends ReleaseNoteBlock {
  const ReleaseNoteCode(this.code);

  final String code;
}

final class ReleaseNoteDivider extends ReleaseNoteBlock {
  const ReleaseNoteDivider();
}

sealed class ReleaseNoteInline {
  const ReleaseNoteInline();
}

final class ReleaseNoteText extends ReleaseNoteInline {
  const ReleaseNoteText(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
}

final class ReleaseNoteLink extends ReleaseNoteInline {
  const ReleaseNoteLink({required this.label, required this.uri});

  final String label;
  final Uri uri;
}

final RegExp _headingPattern = RegExp(r'^(#{1,6})\s+(.+)$');
final RegExp _rulePattern = RegExp(r'^(?:-{3,}|\*{3,}|_{3,})$');
final RegExp _bulletPattern = RegExp(r'^\s*[-*+]\s+(.*)$');
final RegExp _orderedPattern = RegExp(r'^\s*\d+[.)]\s+(.*)$');
final RegExp _bareUrlPattern = RegExp(r'https?://[^\s<>"*]+');
final RegExp _trailingUrlPunctuation = RegExp(r'[.,;:!?\)\]\}]+$');

List<ReleaseNoteBlock> _parseBlocks(String markdown) {
  final withoutComments = markdown.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final lines = withoutComments
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');

  final blocks = <ReleaseNoteBlock>[];
  var index = 0;

  while (index < lines.length) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      index++;
      continue;
    }

    if (line.startsWith('```')) {
      final code = StringBuffer();
      index++;
      while (index < lines.length && !lines[index].trim().startsWith('```')) {
        code.writeln(lines[index]);
        index++;
      }
      if (index < lines.length) index++;
      blocks.add(ReleaseNoteCode(code.toString().trimRight()));
      continue;
    }

    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      final text = heading
          .group(2)!
          .replaceFirst(RegExp(r'\s+#+\s*$'), '')
          .trim();
      blocks.add(
        ReleaseNoteHeading(
          level: heading.group(1)!.length,
          content: _parseInline(text),
        ),
      );
      index++;
      continue;
    }

    if (_rulePattern.hasMatch(line)) {
      blocks.add(const ReleaseNoteDivider());
      index++;
      continue;
    }

    if (line.startsWith('>')) {
      final quote = <String>[];
      while (index < lines.length) {
        final current = lines[index].trim();
        if (!current.startsWith('>')) break;
        quote.add(current.replaceFirst(RegExp(r'^>\s?'), ''));
        index++;
      }
      blocks.add(ReleaseNoteQuote(_parseInline(quote.join(' ').trim())));
      continue;
    }

    final bullet = _bulletPattern.firstMatch(line);
    final ordered = _orderedPattern.firstMatch(line);
    if (bullet != null || ordered != null) {
      final isOrdered = ordered != null;
      final items = <String>[];

      while (index < lines.length) {
        final rawLine = lines[index];
        final current = rawLine.trim();
        if (current.isEmpty) break;

        final match = isOrdered
            ? _orderedPattern.firstMatch(current)
            : _bulletPattern.firstMatch(current);
        if (match != null) {
          items.add(match.group(1)!.trim());
          index++;
          continue;
        }

        // A soft-wrapped list item continues on the next indented line.
        if (items.isNotEmpty &&
            RegExp(r'^\s{2,}').hasMatch(rawLine) &&
            !_startsBlock(current)) {
          items[items.length - 1] = '${items.last} $current';
          index++;
          continue;
        }

        break;
      }

      blocks.add(
        ReleaseNoteList(
          ordered: isOrdered,
          items: [for (final item in items) _parseInline(item)],
        ),
      );
      continue;
    }

    final paragraph = <String>[];
    while (index < lines.length) {
      final current = lines[index].trim();
      if (current.isEmpty || _startsBlock(current)) break;
      paragraph.add(current);
      index++;
    }

    if (paragraph.isNotEmpty) {
      blocks.add(ReleaseNoteParagraph(_parseInline(paragraph.join(' '))));
    } else {
      // Defensive: never let an unrecognized line block the parser.
      index++;
    }
  }

  return blocks;
}

bool _startsBlock(String line) {
  return line.startsWith('```') ||
      line.startsWith('>') ||
      _headingPattern.hasMatch(line) ||
      _rulePattern.hasMatch(line) ||
      _bulletPattern.hasMatch(line) ||
      _orderedPattern.hasMatch(line);
}

List<ReleaseNoteInline> _parseInline(String text) {
  final spans = <ReleaseNoteInline>[];
  _parseInlineInto(text, spans, bold: false, italic: false);
  return _merge(spans);
}

void _parseInlineInto(
  String text,
  List<ReleaseNoteInline> spans, {
  required bool bold,
  required bool italic,
}) {
  final buffer = StringBuffer();
  var index = 0;

  void flush() {
    if (buffer.length == 0) return;
    spans.add(ReleaseNoteText(buffer.toString(), bold: bold, italic: italic));
    buffer.clear();
  }

  while (index < text.length) {
    final character = text[index];

    if (character == r'\' && index + 1 < text.length) {
      buffer.write(text[index + 1]);
      index += 2;
      continue;
    }

    if (character == '`') {
      final end = text.indexOf('`', index + 1);
      if (end != -1) {
        flush();
        spans.add(
          ReleaseNoteText(
            text.substring(index + 1, end),
            bold: bold,
            italic: italic,
            code: true,
          ),
        );
        index = end + 1;
        continue;
      }
    }

    if (text.startsWith('**', index) || text.startsWith('__', index)) {
      final marker = text.substring(index, index + 2);
      final canOpen = marker == '**' || _canOpenUnderscore(text, index);
      final end = canOpen ? _findClosing(text, marker, index + 2) : -1;
      if (end != -1) {
        flush();
        _parseInlineInto(
          text.substring(index + 2, end),
          spans,
          bold: true,
          italic: italic,
        );
        index = end + 2;
        continue;
      }
      if (canOpen) {
        buffer.write(marker);
        index += 2;
        continue;
      }
    }

    if (character == '*' ||
        (character == '_' && _canOpenUnderscore(text, index))) {
      final end = _findClosing(text, character, index + 1);
      if (end != -1 && end > index + 1) {
        flush();
        _parseInlineInto(
          text.substring(index + 1, end),
          spans,
          bold: bold,
          italic: true,
        );
        index = end + 1;
        continue;
      }
    }

    if (text.startsWith('![', index)) {
      final image = _parseMarkdownLink(text, index + 1);
      if (image != null) {
        flush();
        spans.add(
          ReleaseNoteLink(
            label: image.label.trim().isEmpty
                ? image.uri.toString()
                : image.label.trim(),
            uri: image.uri,
          ),
        );
        index = image.end;
        continue;
      }
    }

    if (character == '[') {
      final link = _parseMarkdownLink(text, index);
      if (link != null) {
        flush();
        spans.add(
          ReleaseNoteLink(
            label: link.label.trim().isEmpty
                ? link.uri.toString()
                : link.label.trim(),
            uri: link.uri,
          ),
        );
        index = link.end;
        continue;
      }
    }

    if (text.startsWith('http://', index) ||
        text.startsWith('https://', index)) {
      final match = _bareUrlPattern.matchAsPrefix(text, index);
      if (match != null) {
        final rawUrl = match.group(0)!;
        final url = rawUrl.replaceFirst(_trailingUrlPunctuation, '');
        final uri = _safeUri(url);
        if (uri != null && url.isNotEmpty) {
          flush();
          spans.add(ReleaseNoteLink(label: url, uri: uri));
          // Leave trailing punctuation for the next iteration.
          index += url.length;
          continue;
        }
      }
    }

    buffer.write(character);
    index++;
  }

  flush();
}

int _findClosing(String text, String marker, int from) {
  var index = from;
  while (index < text.length) {
    final found = text.indexOf(marker, index);
    if (found == -1) return -1;

    if (found > 0 && text[found - 1] == r'\') {
      index = found + marker.length;
      continue;
    }

    if (marker == '*' && text.startsWith('**', found)) {
      index = found + 2;
      continue;
    }
    if (marker == '_' && text.startsWith('__', found)) {
      index = found + 2;
      continue;
    }

    return found;
  }
  return -1;
}

bool _canOpenUnderscore(String text, int index) {
  bool isWord(int? codeUnit) {
    if (codeUnit == null) return false;
    return (codeUnit >= 48 && codeUnit <= 57) ||
        (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122) ||
        codeUnit == 95;
  }

  final before = index == 0 ? null : text.codeUnitAt(index - 1);
  final after = index + 1 < text.length ? text.codeUnitAt(index + 1) : null;
  return !isWord(before) && after != null && !_isWhitespace(after);
}

bool _isWhitespace(int codeUnit) {
  return codeUnit == 32 || codeUnit == 9 || codeUnit == 10 || codeUnit == 13;
}

({String label, Uri uri, int end})? _parseMarkdownLink(String text, int start) {
  if (start >= text.length || text[start] != '[') return null;

  final labelEnd = text.indexOf(']', start + 1);
  if (labelEnd == -1 ||
      labelEnd + 1 >= text.length ||
      text[labelEnd + 1] != '(') {
    return null;
  }

  final urlEnd = text.indexOf(')', labelEnd + 2);
  if (urlEnd == -1) return null;

  final uri = _safeUri(text.substring(labelEnd + 2, urlEnd).trim());
  if (uri == null) return null;

  return (
    label: text.substring(start + 1, labelEnd),
    uri: uri,
    end: urlEnd + 1,
  );
}

Uri? _safeUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}

List<ReleaseNoteInline> _merge(List<ReleaseNoteInline> spans) {
  final merged = <ReleaseNoteInline>[];

  for (final span in spans) {
    if (span is ReleaseNoteText && span.text.isEmpty) continue;

    if (span is ReleaseNoteText && merged.isNotEmpty) {
      final last = merged.last;
      if (last is ReleaseNoteText &&
          last.bold == span.bold &&
          last.italic == span.italic &&
          last.code == span.code) {
        merged[merged.length - 1] = ReleaseNoteText(
          '${last.text}${span.text}',
          bold: last.bold,
          italic: last.italic,
          code: last.code,
        );
        continue;
      }
    }

    merged.add(span);
  }

  return merged;
}
