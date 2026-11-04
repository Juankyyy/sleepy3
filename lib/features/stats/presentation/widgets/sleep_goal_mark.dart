import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/sleep_goal.dart';

/// The leading mark that compares a night with [dailySleepGoal].
///
/// At or above the goal it is the eight-leaf clover from the Material shape
/// library, filled with [color] and carrying an [onColor] crescent. Below the
/// goal it is a circular progress ring in [color] over [trackColor], with the
/// crescent in [color]. The percent is capped at 1, so a longer night paints a
/// full ring.
///
/// From M3: abstract shapes are decorative marks for visual elements, never
/// text containers, and should be used sparingly.
///
/// My design decisions (not in M3): using [M3EShapeKind.clover8Leaf] as the
/// goal mark, the 41 % icon share, the sub-dp optical shift that centres the
/// crescent's ink instead of its box, and the size and stroke each screen
/// passes in.
class SleepGoalMark extends StatelessWidget {
  const SleepGoalMark({
    super.key,
    required this.duration,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.onColor,
    required this.trackColor,
  });

  final Duration duration;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color onColor;
  final Color trackColor;

  bool get _met => duration >= dailySleepGoal;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.41;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_met)
              M3EShapeContainer(
                kind: M3EShapeKind.clover8Leaf,
                width: size,
                height: size,
                color: color,
              )
            else
              M3EProgressIndicator.circular(
                value: _goalFraction(duration),
                size: size,
                strokeWidth: strokeWidth,
                trackStrokeWidth: strokeWidth,
                color: color,
                trackColor: trackColor,
              ),
            Transform.translate(
              // The crescent's ink sits left of its 24 dp box, so the box
              // centre looks off inside the shape. 2.8 % of the icon size is
              // the ink offset of the rounded bedtime glyph.
              offset: Offset(iconSize * 0.028, 0),
              child: Icon(
                M3EIcons.bedtime_rounded,
                size: iconSize,
                color: _met ? onColor : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _goalFraction(Duration duration) {
  if (duration <= Duration.zero) return 0;
  final ratio = duration.inMicroseconds / dailySleepGoal.inMicroseconds;
  return ratio >= 1 ? 1 : ratio;
}
