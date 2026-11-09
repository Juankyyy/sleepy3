import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'chart_theme.dart';

/// The sample mark drawn before a legend label.
enum ChartLegendMark { bar, line, dashed, band }

/// One entry in a chart legend.
///
/// The sample is decorative and the text carries the meaning, so the legend
/// never relies on color alone.
class ChartLegendEntry {
  const ChartLegendEntry({
    required this.label,
    required this.mark,
    required this.color,
  });

  final String label;
  final ChartLegendMark mark;
  final Color color;
}

/// A wrapping legend with a small drawn sample and a text label.
///
/// From M3: labels use `labelSmall` / `onSurfaceVariant`. The 16x8 sample and
/// the 6dp gap are Sleepy3 design decisions.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.entries});

  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.typography.baseline.labelSmall.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(16, 8),
                painter: _LegendMarkPainter(
                  mark: entry.mark,
                  color: entry.color,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(entry.label, style: style)),
            ],
          ),
      ],
    );
  }
}

class _LegendMarkPainter extends CustomPainter {
  const _LegendMarkPainter({required this.mark, required this.color});

  final ChartLegendMark mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    switch (mark) {
      case ChartLegendMark.line:
        _line(canvas, centerY, size.width);
      case ChartLegendMark.dashed:
        _dashed(canvas, centerY, size.width);
      case ChartLegendMark.bar:
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: 6,
          height: size.height,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()..color = color,
        );
      case ChartLegendMark.band:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
          Paint()..color = color.withValues(alpha: 0.2),
        );
    }
  }

  void _line(Canvas canvas, double y, double width) {
    canvas.drawLine(
      Offset(0, y),
      Offset(width, y),
      Paint()
        ..color = color
        ..strokeWidth = ChartDimensions.dataLineWidth,
    );
  }

  void _dashed(Canvas canvas, double y, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = ChartDimensions.dataLineWidth;
    const dash = 3.0;
    const gap = 2.0;
    for (var x = 0.0; x < width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LegendMarkPainter oldDelegate) =>
      oldDelegate.mark != mark || oldDelegate.color != color;
}
