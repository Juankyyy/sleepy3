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
/// [rotation] turns only the clover; the crescent stays upright. [animateProgress]
/// draws a below-goal ring from zero on its first frame and follows later
/// duration changes, so the callers that don't pass them keep the static mark
/// used in the history list.
///
/// From M3: abstract shapes are decorative marks for visual elements, never
/// text containers, and should be used sparingly. Shape can carry progress:
/// M3 lists rotating shapes and morphs alongside waveforms.
///
/// My design decisions (not in M3): using [M3EShapeKind.clover8Leaf] as the
/// goal mark, the 41 % icon share, the sub-dp optical shift that centres the
/// crescent's ink instead of its box, the size and stroke each screen passes
/// in, and keeping the motion off the list.
class SleepGoalMark extends StatelessWidget {
  const SleepGoalMark({
    super.key,
    required this.duration,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.onColor,
    required this.trackColor,
    this.rotation,
    this.animateProgress = false,
  });

  final Duration duration;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color onColor;
  final Color trackColor;

  /// Drives the clover's turn when the goal is met; null keeps it still.
  ///
  /// The hero owns the controller so the history list never creates one.
  final Animation<double>? rotation;

  /// Whether a below-goal ring reveals itself from zero.
  final bool animateProgress;

  bool get _met => duration >= dailySleepGoal;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.41;
    final fraction = _goalFraction(duration);

    Widget clover() {
      final shape = M3EShapeContainer(
        kind: M3EShapeKind.clover8Leaf,
        width: size,
        height: size,
        color: color,
      );
      final turns = rotation;
      if (turns == null) return shape;
      return RotationTransition(turns: turns, child: shape);
    }

    Widget ring() {
      Widget indicator(double value) {
        return M3EProgressIndicator.circular(
          value: value,
          size: size,
          strokeWidth: strokeWidth,
          trackStrokeWidth: strokeWidth,
          color: color,
          trackColor: trackColor,
        );
      }

      if (!animateProgress) return indicator(fraction);
      // Hold the ring empty for the first 400 ms so the dialog entrance does
      // not swallow the reveal, then draw it in the remaining 600 ms
      // (`long4`). The head start is a design decision; M3 does not publish a
      // choreography for a ring revealing itself.
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: fraction),
        duration: M3EMotion.extraLong4,
        curve: const Interval(0.4, 1, curve: M3EMotion.emphasizedDecelerate),
        builder: (context, value, _) => indicator(value),
      );
    }

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            // A normalized Material shape fills its box edge to edge. When the
            // clover turns, its tips need about 4 % more than half the box
            // (the shape's max bounds are wider than its normalized bounds);
            // the default Stack clip would flatten them and make the details
            // mark look different from the static history badge. The hero's
            // 16 dp padding absorbs the small overhang.
            clipBehavior: Clip.none,
            children: [
              if (_met) clover() else ring(),
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
      ),
    );
  }
}

double _goalFraction(Duration duration) {
  if (duration <= Duration.zero) return 0;
  final ratio = duration.inMicroseconds / dailySleepGoal.inMicroseconds;
  return ratio >= 1 ? 1 : ratio;
}
