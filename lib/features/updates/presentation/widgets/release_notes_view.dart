import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/release_notes.dart';

/// Renders the curated release notes inside the update dialog body.
///
/// This is intentionally a small renderer for Sleepy3's release-note subset,
/// not a general Markdown engine: the app uses `material_ui` on Flutter 3.47
/// and pub Markdown renderers still target the SDK `material` library.
class ReleaseNotesView extends StatefulWidget {
  const ReleaseNotesView({
    super.key,
    required this.notes,
    required this.onOpenLink,
  });

  final ReleaseNotes notes;

  /// Opens a link from the notes. Returns false when it could not be opened.
  final Future<bool> Function(Uri uri) onOpenLink;

  @override
  State<ReleaseNotesView> createState() => _ReleaseNotesViewState();
}

class _ReleaseNotesViewState extends State<ReleaseNotesView> {
  final Map<ReleaseNoteLink, TapGestureRecognizer> _recognizers =
      <ReleaseNoteLink, TapGestureRecognizer>{};

  @override
  void didUpdateWidget(covariant ReleaseNotesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.notes, widget.notes)) {
      for (final recognizer in _recognizers.values) {
        recognizer.dispose();
      }
      _recognizers.clear();
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(ReleaseNoteLink link) {
    return _recognizers.putIfAbsent(link, () {
      final recognizer = TapGestureRecognizer();
      recognizer.onTap = () => unawaited(widget.onOpenLink(link.uri));
      return recognizer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final bodyStyle = theme.dialogTheme.appearance.resolveSupporting(theme);
    final headingStyle = theme.typography.emphasized.titleMedium.copyWith(
      color: scheme.onSurface,
    );
    final subheadingStyle = theme.typography.emphasized.titleSmall.copyWith(
      color: scheme.onSurface,
    );
    final codeBlockStyle = theme.typography.baseline.bodySmall.copyWith(
      fontFamily: 'monospace',
      color: scheme.onSurface,
      height: 1.5,
    );
    final quoteStyle = bodyStyle.copyWith(fontStyle: FontStyle.italic);

    final children = <Widget>[];
    for (var index = 0; index < widget.notes.blocks.length; index++) {
      final block = widget.notes.blocks[index];
      final isFirst = index == 0;

      switch (block) {
        case ReleaseNoteHeading(:final level, :final content):
          final style = level <= 2 ? headingStyle : subheadingStyle;
          children.add(
            Padding(
              padding: EdgeInsets.only(top: isFirst ? 0 : 20, bottom: 4),
              child: Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(children: _spans(content, style, scheme)),
                  style: style,
                ),
              ),
            ),
          );

        case ReleaseNoteParagraph(:final content):
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text.rich(
                TextSpan(children: _spans(content, bodyStyle, scheme)),
                style: bodyStyle,
              ),
            ),
          );

        case ReleaseNoteList(:final ordered, :final items):
          children.add(_buildList(ordered, items, bodyStyle, scheme));

        case ReleaseNoteQuote(:final content):
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: scheme.outlineVariant, width: 2),
                  ),
                ),
                padding: const EdgeInsets.only(left: 12),
                child: Text.rich(
                  TextSpan(children: _spans(content, quoteStyle, scheme)),
                  style: quoteStyle,
                ),
              ),
            ),
          );

        case ReleaseNoteCode(:final code):
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(code, style: codeBlockStyle),
              ),
            ),
          );

        case ReleaseNoteDivider():
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: M3EDivider(
                color: scheme.outlineVariant,
                thickness: theme.dialogTheme.dividerThickness,
              ),
            ),
          );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildList(
    bool ordered,
    List<List<ReleaseNoteInline>> items,
    TextStyle style,
    M3EColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: ordered ? 32 : 16,
                    child: Text(
                      ordered ? '${index + 1}.' : '•',
                      style: style.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: _spans(items[index], style, scheme)),
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _spans(
    List<ReleaseNoteInline> content,
    TextStyle base,
    M3EColorScheme scheme,
  ) {
    return [for (final inline in content) _span(inline, base, scheme)];
  }

  InlineSpan _span(
    ReleaseNoteInline inline,
    TextStyle base,
    M3EColorScheme scheme,
  ) {
    switch (inline) {
      case ReleaseNoteText(
        :final text,
        :final bold,
        :final italic,
        :final code,
      ):
        var style = base;
        if (bold) {
          style = style.merge(const TextStyle(fontWeight: FontWeight.w700));
        }
        if (italic) {
          style = style.merge(const TextStyle(fontStyle: FontStyle.italic));
        }
        if (code) {
          style = style.merge(
            TextStyle(
              fontFamily: 'monospace',
              fontSize: (base.fontSize ?? 14) - 1,
              letterSpacing: 0,
              color: scheme.onSurface,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          );
        }
        return TextSpan(text: text, style: style);

      case ReleaseNoteLink(:final label):
        return TextSpan(
          text: label,
          style: base.merge(
            TextStyle(
              color: scheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: scheme.primary,
            ),
          ),
          recognizer: _recognizerFor(inline),
        );
    }
  }
}
