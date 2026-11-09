import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'chart_legend.dart';
import 'chart_theme.dart';

/// The M3 card that frames one Stats chart.
///
/// From M3: outlined card, 12dp corners, 16dp padding, `titleMedium`
/// emphasized for the title, `bodySmall` for the supporting line and
/// `outlineVariant` for the card outline.
/// My design decisions (not in M3): the 2dp, 16dp and 12dp vertical gaps and
/// the fixed [canvasHeight], which keeps the drawing stable while the text
/// scale and the card height grow.
class ChartScene extends StatelessWidget {
  const ChartScene({
    super.key,
    required this.title,
    required this.support,
    required this.semanticSummary,
    required this.child,
    this.legend = const [],
    this.canvasHeight = ChartDimensions.canvasHeight,
  });

  final String title;
  final String support;

  /// One spoken summary for the canvas. The history remains the accessible
  /// view for every individual night.
  final String semanticSummary;

  /// The chart canvas: a single `CustomPaint` wrapped by its scrub area.
  final Widget child;

  final List<ChartLegendEntry> legend;
  final double canvasHeight;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return M3ECard(
      variant: M3ECardVariant.outlined,
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
          Semantics(
            container: true,
            label: semanticSummary,
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: SizedBox(height: canvasHeight, child: child),
              ),
            ),
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 12),
            ChartLegend(entries: legend),
          ],
        ],
      ),
    );
  }
}
