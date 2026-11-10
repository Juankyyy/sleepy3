import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'chart_theme.dart';

/// The M3 text inset inside a card.
const _cardPadding = 16.0;

/// The chart canvas keeps only this much air from the card edge.
///
/// My design decision (not in M3): the header keeps the 16dp card inset while
/// the plot bleeds to 4dp, so the chart reads wider than the text block.
const _chartHorizontalInset = 4.0;

/// The M3 card that frames one Stats chart.
///
/// From M3: outlined card, 12dp corners, 16dp text padding, `titleMedium`
/// emphasized for the title, `bodySmall` for the supporting line and
/// `outlineVariant` for the card outline.
/// My design decisions (not in M3): the 2dp, 16dp and 12dp vertical gaps, the
/// fixed [canvasHeight], which keeps the drawing stable while the text scale
/// and the card height grow, and the canvas bleeding to 4dp from the card edge
/// so the plot uses almost the whole card width while the header stays at the
/// M3 16dp inset.
class ChartScene extends StatelessWidget {
  const ChartScene({
    super.key,
    required this.title,
    required this.support,
    required this.semanticSummary,
    required this.child,
    this.canvasHeight = ChartDimensions.canvasHeight,
    this.showHeader = true,
  });

  final String title;
  final String support;

  /// Whether to draw the title and supporting line inside the card.
  ///
  /// The summary picker labels each option in its own header, so its chart
  /// thumbnails omit this block and use the space for the drawing.
  final bool showHeader;

  /// One spoken summary for the canvas. The history remains the accessible
  /// view for every individual night.
  final String semanticSummary;

  /// The chart canvas: a single `CustomPaint` wrapped by its scrub area.
  final Widget child;

  final double canvasHeight;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _cardPadding,
                _cardPadding,
                _cardPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.typography.emphasized.titleMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    support,
                    style: theme.typography.baseline.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _chartHorizontalInset,
              showHeader ? 0 : _cardPadding,
              _chartHorizontalInset,
              _cardPadding,
            ),
            child: Semantics(
              container: true,
              label: semanticSummary,
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: SizedBox(height: canvasHeight, child: child),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
