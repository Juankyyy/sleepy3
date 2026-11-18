import 'dart:math' as math;

import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:material_ui/material_ui.dart';

/// The M3 shape drawn behind each Settings card.
///
/// Every card uses a different shape from the Material shape library. The
/// mapping is visual only: M3 shapes are not semantic, so these do not mean
/// sleep, data or appearance.
enum BentoFigureShape {
  arch,
  softBurst,
  puffy,
  clamShell,
  cookie7Sided,
  puffyDiamond,
  clover4Leaf,
}

extension BentoFigureShapeDetails on BentoFigureShape {
  RoundedPolygon get polygon {
    return switch (this) {
      BentoFigureShape.arch => MaterialShapes.arch,
      BentoFigureShape.softBurst => MaterialShapes.softBurst,
      BentoFigureShape.puffy => MaterialShapes.puffy,
      BentoFigureShape.clamShell => MaterialShapes.clamShell,
      BentoFigureShape.cookie7Sided => MaterialShapes.cookie7Sided,
      BentoFigureShape.puffyDiamond => MaterialShapes.puffyDiamond,
      BentoFigureShape.clover4Leaf => MaterialShapes.clover4Leaf,
    };
  }

  /// Degrees. A different angle per card keeps the corners from repeating.
  double get rotation {
    return switch (this) {
      BentoFigureShape.arch => 0,
      BentoFigureShape.softBurst => -12,
      BentoFigureShape.puffy => 8,
      BentoFigureShape.clamShell => -6,
      BentoFigureShape.cookie7Sided => 15,
      BentoFigureShape.puffyDiamond => -10,
      BentoFigureShape.clover4Leaf => 6,
    };
  }
}

/// Where the figure sits past the card's bottom-right corner.
///
/// Wide cards sit a little higher and further left than the half cards, so the
/// figure does not feel pinned to the very edge of the wider surface.
enum BentoFigurePlacement {
  /// The wide card default, used by About.
  wide(offsetX: 0.16, offsetY: 0.24),

  /// The Sleep goal and Sleep data cards sit a little further in.
  wideRaised(offsetX: 0.08, offsetY: 0.16),

  half(offsetX: 0.3, offsetY: 0.4);

  const BentoFigurePlacement({required this.offsetX, required this.offsetY});

  final double offsetX;
  final double offsetY;
}

/// The decorative figure painted in a card's empty corner.
///
/// The shape is clipped by the card, ignored by the pointer and excluded from
/// the semantics tree. It never contributes to layout.
class BentoFigure extends StatelessWidget {
  const BentoFigure({
    super.key,
    required this.shape,
    required this.color,
    required this.placement,
    this.widthFactor = 0.7,
  });

  final BentoFigureShape shape;
  final Color color;
  final BentoFigurePlacement placement;

  /// Fraction of the card width occupied by the shape.
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * widthFactor;
        return Align(
          alignment: Alignment.bottomRight,
          child: Transform.translate(
            offset: Offset(
              width * placement.offsetX,
              width * placement.offsetY,
            ),
            child: Transform.rotate(
              angle: shape.rotation * math.pi / 180,
              child: SizedBox.square(
                dimension: width,
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BentoFigurePainter(shape: shape, color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BentoFigurePainter extends CustomPainter {
  const _BentoFigurePainter({required this.shape, required this.color});

  final BentoFigureShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    canvas.drawPath(
      shape.polygon.toPath(),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BentoFigurePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
