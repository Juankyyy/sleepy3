import 'package:material_ui/material_ui.dart';

/// The GitHub mark used to open the project repository.
///
/// Material has no brand icons, so the mark is drawn from the official 24×24
/// path published by Simple Icons (CC0):
/// https://github.com/simple-icons/simple-icons/blob/develop/icons/github.svg
///
/// It inherits the surrounding [IconTheme], so an icon button tints it like
/// any other icon. It is a link affordance only, never a launcher icon.
class GithubMark extends StatelessWidget {
  const GithubMark({super.key, this.size = 24});

  /// The edge length of the square that contains the mark.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GithubMarkPainter(color)),
    );
  }
}

class _GithubMarkPainter extends CustomPainter {
  _GithubMarkPainter(this.color);

  static const _viewBox = 24.0;

  static final Path _path = Path()
    ..moveTo(12.000, 0.297)
    ..cubicTo(5.370, 0.297, 0.000, 5.670, 0.000, 12.297)
    ..cubicTo(0.000, 17.600, 3.438, 22.097, 8.205, 23.682)
    ..cubicTo(8.805, 23.795, 9.025, 23.424, 9.025, 23.105)
    ..cubicTo(9.025, 22.820, 9.015, 22.065, 9.010, 21.065)
    ..cubicTo(5.672, 21.789, 4.968, 19.455, 4.968, 19.455)
    ..cubicTo(4.422, 18.070, 3.633, 17.700, 3.633, 17.700)
    ..cubicTo(2.546, 16.956, 3.717, 16.971, 3.717, 16.971)
    ..cubicTo(4.922, 17.055, 5.555, 18.207, 5.555, 18.207)
    ..cubicTo(6.625, 20.042, 8.364, 19.512, 9.050, 19.205)
    ..cubicTo(9.158, 18.429, 9.467, 17.900, 9.810, 17.600)
    ..cubicTo(7.145, 17.300, 4.344, 16.268, 4.344, 11.670)
    ..cubicTo(4.344, 10.360, 4.809, 9.290, 5.579, 8.450)
    ..cubicTo(5.444, 8.147, 5.039, 6.927, 5.684, 5.274)
    ..cubicTo(5.684, 5.274, 6.689, 4.952, 8.984, 6.504)
    ..cubicTo(9.944, 6.237, 10.964, 6.105, 11.984, 6.099)
    ..cubicTo(13.004, 6.105, 14.024, 6.237, 14.984, 6.504)
    ..cubicTo(17.264, 4.952, 18.269, 5.274, 18.269, 5.274)
    ..cubicTo(18.914, 6.927, 18.509, 8.147, 18.389, 8.450)
    ..cubicTo(19.154, 9.290, 19.619, 10.360, 19.619, 11.670)
    ..cubicTo(19.619, 16.280, 16.814, 17.295, 14.144, 17.590)
    ..cubicTo(14.564, 17.950, 14.954, 18.686, 14.954, 19.810)
    ..cubicTo(14.954, 21.416, 14.939, 22.706, 14.939, 23.096)
    ..cubicTo(14.939, 23.411, 15.149, 23.786, 15.764, 23.666)
    ..cubicTo(20.565, 22.092, 24.000, 17.592, 24.000, 12.297)
    ..cubicTo(24.000, 5.670, 18.627, 0.297, 12.000, 0.297);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.shortestSide / _viewBox);
    canvas.drawPath(
      _path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GithubMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
