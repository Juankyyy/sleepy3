import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:material_ui/material_ui.dart';

import 'bento_figure.dart';

/// The M3 shape behind a Settings card icon.
///
/// The badge uses the same [BentoFigureShape] as the card's larger background
/// figure, so the two silhouettes match. The badge stays upright even when the
/// background figure is rotated, keeping the icon stable. It is decorative:
/// the card's semantics describe the setting, so the badge is excluded from
/// TalkBack.
class BentoBadge extends StatelessWidget {
  const BentoBadge({
    super.key,
    required this.icon,
    required this.shape,
    required this.size,
    required this.containerColor,
    required this.iconColor,
  });

  final IconData icon;
  final BentoFigureShape shape;
  final double size;
  final Color containerColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _BentoBadgePainter(shape: shape, color: containerColor),
          child: Center(
            child: Icon(icon, size: size * 0.42, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _BentoBadgePainter extends CustomPainter {
  const _BentoBadgePainter({required this.shape, required this.color});

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
  bool shouldRepaint(_BentoBadgePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
