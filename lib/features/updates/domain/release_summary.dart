/// Extracts the first prose paragraph from a GitHub release body.
///
/// Release notes are curated Markdown: an HTML title comment, a summary
/// paragraph, then sections. The update dialog shows only that first paragraph;
/// the full notes stay on GitHub. Returns null when the body has no usable
/// prose.
String? extractReleaseSummary(String? body) {
  if (body == null) return null;

  final withoutComments = body.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final blocks = withoutComments.split(RegExp(r'\n\s*\n'));

  String? paragraph;
  for (final block in blocks) {
    final trimmed = block.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('#')) continue;
    if (trimmed.startsWith('```')) continue;
    if (trimmed.startsWith('|')) continue;
    if (trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
      continue;
    }
    paragraph = trimmed;
    break;
  }
  if (paragraph == null) return null;

  final plain = paragraph
      .replaceAllMapped(
        RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]*\)'),
        (match) => match.group(1) ?? '',
      )
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'[*_~`]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (plain.isEmpty) return null;
  return _truncate(plain, 220);
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;

  final cut = value.substring(0, maxLength);
  final lastSpace = cut.lastIndexOf(' ');
  final end = lastSpace > maxLength ~/ 2 ? lastSpace : maxLength;
  return '${value.substring(0, end).trimRight()}…';
}
