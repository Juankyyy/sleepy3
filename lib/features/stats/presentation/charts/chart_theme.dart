import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Geometry shared by every Stats chart.
///
/// M3 does not define a chart component, so these measurements are Sleepy3
/// design decisions unless a comment says otherwise.
abstract final class ChartDimensions {
  /// The canvas keeps a fixed height when the text scale grows; the card grows
  /// around it and the axis label density drops instead.
  static const double canvasHeight = 180;

  /// Minimum room for the Y-axis labels; the painter grows it to fit the
  /// widest tick label plus [axisLabelGap].
  static const double axisGutter = 36;

  /// Gap between a Y-axis label and the plot.
  static const double axisLabelGap = 8;

  static const double plotTopInset = 8;
  static const double plotBottomInset = 24;
  static const double plotRightInset = 4;

  /// The top corners of a bar use this radius; the baseline stays square.
  static const double barRadius = 4;
  static const double barMinWidth = 4;
  static const double barMaxWidth = 56;

  /// Fraction of a slot the bar occupies before the min/max clamp.
  static const double barWidthFactor = 0.80;

  /// From M3: the 1.5dp goal line stays readable above the 1dp grid.
  static const double dataLineWidth = 1.5;
  static const double gridLineWidth = 1;

  /// From M3 plain tooltip: 24dp container, 8dp padding, 4dp distance.
  static const double plainTooltipHeight = 24;
  static const double plainTooltipPadding = 8;
  static const double tooltipGap = 4;

  /// The selected bar grows 2% and gets a 2dp halo.
  static const double selectedBarScale = 1.02;
  static const double selectedHaloWidth = 2;
}

/// Colors and text roles used by the chart painters and their chrome.
///
/// From M3: bars use `primary`; the grid uses `outlineVariant` at 60%; the
/// goal line uses `outline`; the plain tooltip uses `inverseSurface` /
/// `onInverseSurface`; the rich tooltip uses `surfaceContainer` /
/// `onSurfaceVariant`.
/// My design decision (not in M3): every bar starts from `primary`, but a bar
/// under the nightly goal is drawn as the 85% primary blended into the card
/// surface, and a bar that reaches the goal uses a darker primary in the light
/// theme (the full primary in the dark theme, where darkening would lose
/// contrast).
class ChartPalette {
  const ChartPalette({
    required this.surface,
    required this.bar,
    required this.barMuted,
    required this.goalMetBar,
    required this.goalLine,
    required this.grid,
    required this.emptyMark,
    required this.selectionHalo,
    required this.band,
    required this.axisLabel,
    required this.plainTooltipContainer,
    required this.plainTooltipLabel,
    required this.richTooltipContainer,
    required this.richTooltipText,
    required this.textScaler,
  });

  factory ChartPalette.of(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final tabular = <FontFeature>[const FontFeature.tabularFigures()];
    final isDark = scheme.brightness == Brightness.dark;

    return ChartPalette(
      surface: scheme.surface,
      bar: scheme.primary,
      barMuted: Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.85),
        scheme.surface,
      ),
      goalMetBar: isDark
          ? scheme.primary
          : Color.lerp(scheme.primary, Colors.black, 0.15)!,
      goalLine: scheme.outline,
      grid: scheme.outlineVariant.withValues(alpha: 0.6),
      emptyMark: scheme.outlineVariant,
      selectionHalo: scheme.primaryContainer,
      band: scheme.primaryContainer.withValues(alpha: 0.2),
      axisLabel: theme.typography.baseline.labelSmall.copyWith(
        color: scheme.onSurfaceVariant,
        fontFeatures: tabular,
      ),
      plainTooltipContainer: scheme.inverseSurface,
      plainTooltipLabel: theme.typography.baseline.labelMedium.copyWith(
        color: scheme.onInverseSurface,
      ),
      richTooltipContainer: scheme.surfaceContainer,
      richTooltipText: theme.typography.baseline.bodySmall.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      textScaler: textScaler,
    );
  }

  /// The card surface behind the chart, used for label knockouts.
  final Color surface;

  /// The base primary, also used by the `Best` label.
  final Color bar;

  /// The 85% primary blended into the card surface, for bars under the goal.
  final Color barMuted;

  /// The emphasis tone for bars that reach the nightly goal.
  final Color goalMetBar;

  final Color goalLine;
  final Color grid;
  final Color emptyMark;
  final Color selectionHalo;
  final Color band;

  final TextStyle axisLabel;

  final Color plainTooltipContainer;
  final TextStyle plainTooltipLabel;
  final Color richTooltipContainer;
  final TextStyle richTooltipText;

  /// Canvas labels scale with the system text scale.
  final TextScaler textScaler;
}
