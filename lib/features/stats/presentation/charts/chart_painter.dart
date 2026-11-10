import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'chart_axis.dart';
import 'chart_theme.dart';

/// An X-axis label at a pixel position inside the plot.
class ChartXLabel {
  const ChartXLabel({required this.center, required this.label});

  final double center;
  final String label;
}

/// Shared painting for the Stats charts.
///
/// M3 has no chart component. This base owns only the structure the charts
/// share: the plot rectangle, the value grid, the Y labels and the helpers for
/// bars, rules and missing-data marks. Heights, widths, radii and label density
/// are Sleepy3 design decisions documented in [ChartDimensions].
abstract class ChartPainter extends CustomPainter {
  ChartPainter({required this.palette, required this.axis});

  final ChartPalette palette;
  final ChartAxis axis;

  Rect plotRect(Size size) {
    final left = yAxisGutter;
    final right = math.max(
      left + 1,
      size.width - ChartDimensions.plotRightInset,
    );
    // The canvas height is fixed, but the X labels grow with the text scale.
    // Reserve more of the bottom inset so a 200% label is not clipped.
    final bottomInset = math.max(
      ChartDimensions.plotBottomInset,
      palette.textScaler.scale(ChartDimensions.plotBottomInset),
    );
    final bottom = math.max(
      ChartDimensions.plotTopInset + 1,
      size.height - bottomInset,
    );
    return Rect.fromLTRB(left, ChartDimensions.plotTopInset, right, bottom);
  }

  /// Room for the widest Y-axis label plus its gap, never below
  /// [ChartDimensions.axisGutter].
  ///
  /// Measuring the actual labels keeps the plot wide at normal text sizes and
  /// lets the gutter grow with the system text scale instead of clipping.
  double get yAxisGutter {
    var widest = 0.0;
    for (final tick in axis.ticks) {
      final width = textPainter(tick.label, palette.axisLabel).width;
      if (width > widest) widest = width;
    }
    return math.max(
      ChartDimensions.axisGutter,
      widest + ChartDimensions.axisLabelGap,
    );
  }

  double yFor(double value, Rect plot) =>
      plot.bottom - axis.fractionFor(value) * plot.height;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = plotRect(size);
    paintGrid(canvas, plot);
    paintChart(canvas, plot);
  }

  /// Paints the chart-specific data inside [plot].
  void paintChart(Canvas canvas, Rect plot);

  /// Paints the value grid and its labels.
  void paintGrid(Canvas canvas, Rect plot) {
    final gridPaint = Paint()
      ..color = palette.grid
      ..strokeWidth = ChartDimensions.gridLineWidth;

    for (final tick in axis.ticks) {
      final y = yFor(tick.value, plot);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);

      final label = textPainter(tick.label, palette.axisLabel);
      final labelY = math.max(
        ChartDimensions.plotTopInset,
        y - label.height / 2,
      );
      label.paint(
        canvas,
        Offset(plot.left - ChartDimensions.axisLabelGap - label.width, labelY),
      );
    }
  }

  /// Draws a horizontal data rule, optionally with a label at its right end.
  void paintRule(
    Canvas canvas,
    Rect plot, {
    required double value,
    required Color color,
    String? label,
    Color? labelBackground,
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final lineColor = color.withValues(alpha: opacity);
    final y = yFor(value, plot);
    canvas.drawLine(
      Offset(plot.left, y),
      Offset(plot.right, y),
      Paint()
        ..color = lineColor
        ..strokeWidth = ChartDimensions.dataLineWidth,
    );

    if (label == null) return;

    final text = textPainter(
      label,
      palette.axisLabel.copyWith(color: lineColor),
    );
    final left = plot.right - text.width;
    final top = math.max(plot.top, y - text.height - 1);
    if (labelBackground != null) {
      canvas.drawRect(
        Rect.fromLTWH(left - 2, top - 1, text.width + 4, text.height + 2),
        Paint()..color = labelBackground.withValues(alpha: opacity),
      );
    }
    text.paint(canvas, Offset(left, top));
  }

  /// Draws one bar centered in [slot].
  ///
  /// The selected bar grows by 2% and gets a 2dp `primaryContainer` halo. The
  /// bar width is adaptive: it stays comfortable with seven buckets and never
  /// goes below 4dp with thirty.
  void paintBar(
    Canvas canvas,
    Rect plot,
    Rect slot, {
    required double value,
    bool selected = false,
    double selectionProgress = 1,
    double opacity = 1,
    Color? color,
    double widthFactor = ChartDimensions.barWidthFactor,
  }) {
    if (opacity <= 0) return;
    final height = plot.height * axis.fractionFor(value);
    if (height <= 0) return;

    final progress = selectionProgress.clamp(0.0, 1.0);
    final width = (slot.width * widthFactor)
        .clamp(ChartDimensions.barMinWidth, ChartDimensions.barMaxWidth)
        .toDouble();
    final scale = selected
        ? 1 + (ChartDimensions.selectedBarScale - 1) * progress
        : 1.0;
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;
    final centerX = slot.center.dx;
    final rect = Rect.fromLTRB(
      centerX - scaledWidth / 2,
      plot.bottom - scaledHeight,
      centerX + scaledWidth / 2,
      plot.bottom,
    );
    final radius = Radius.circular(
      math.min(ChartDimensions.barRadius, scaledHeight / 2),
    );
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: radius,
      topRight: radius,
    );

    if (selected && progress > 0) {
      canvas.drawRRect(
        rrect.inflate(ChartDimensions.selectedHaloWidth / 2),
        Paint()
          ..color = palette.selectionHalo.withValues(alpha: progress * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ChartDimensions.selectedHaloWidth,
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()..color = (color ?? palette.bar).withValues(alpha: opacity),
    );
  }

  /// Marks a slot with no data as a dashed line at the baseline.
  ///
  /// A missing night never becomes a zero-height bar.
  void paintNoDataMark(
    Canvas canvas,
    Rect plot,
    Rect slot, {
    double widthFactor = ChartDimensions.barWidthFactor,
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final width = (slot.width * widthFactor)
        .clamp(ChartDimensions.barMinWidth, ChartDimensions.barMaxWidth)
        .toDouble();
    paintDashedLine(
      canvas,
      Offset(slot.center.dx - width / 2, plot.bottom - 0.75),
      Offset(slot.center.dx + width / 2, plot.bottom - 0.75),
      Paint()
        ..color = palette.emptyMark.withValues(alpha: opacity)
        ..strokeWidth = 1.5,
    );
  }

  /// Draws the X labels under the plot, clamped to its horizontal edges.
  void paintXAxisLabels(
    Canvas canvas,
    Rect plot,
    Iterable<ChartXLabel> labels, {
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final style = palette.axisLabel.copyWith(
      color: (palette.axisLabel.color ?? palette.emptyMark).withValues(
        alpha: opacity,
      ),
    );
    for (final label in labels) {
      final text = textPainter(label.label, style);
      final left = (label.center - text.width / 2)
          .clamp(plot.left, plot.right - text.width)
          .toDouble();
      text.paint(canvas, Offset(left, plot.bottom + 4));
    }
  }

  /// A dashed line between two points, with 3dp dashes and 2dp gaps.
  void paintDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 3,
    double gap = 2,
  }) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  /// Lays out a single-line label with the current text scale.
  TextPainter textPainter(
    String text,
    TextStyle style, {
    TextAlign align = TextAlign.left,
  }) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: palette.textScaler,
    )..layout();
  }

  /// The base painter always repaints; subclasses compare their data.
  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) => true;
}
