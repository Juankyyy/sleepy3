import 'package:flutter/physics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Motion helpers for the Stats charts.
///
/// From M3 Expressive: geometry takes a spatial spring with a slight
/// overshoot; color and opacity take a critically damped effects spring. M3
/// does not publish a stagger value, so [staggerStep] is a Sleepy3 design
/// decision used only by the first entry of the duration chart.
abstract final class ChartMotion {
  /// 16ms between bars on first entry. A design decision, not an M3 token.
  static const Duration staggerStep = Duration(milliseconds: 16);

  static bool isReduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Retargets [controller] from its current value to [to] with [spring].
  ///
  /// The controller must be unbounded (or [to] must fit its bounds) because
  /// spatial springs intentionally overshoot their target.
  static void springTo(
    AnimationController controller, {
    required double to,
    M3ESpring spring = M3EMotion.expressiveSpatialDefault,
    double velocity = 0,
  }) {
    if (controller.isAnimating) controller.stop();
    controller.animateWith(
      SpringSimulation(spring.toDescription(), controller.value, to, velocity),
    );
  }
}

/// A 0..1 progress value driven by an M3 spring.
///
/// Charts use it to interpolate bar heights and positions. Restarting it uses
/// `from` as the new start, so an interrupted range change continues from the
/// values on screen instead of jumping back to zero.
class ChartSpringProgress {
  ChartSpringProgress({
    required TickerProvider vsync,
    required this.reduceMotion,
    this.spring = M3EMotion.expressiveSpatialDefault,
  }) : _controller = AnimationController.unbounded(vsync: vsync, value: 0);

  final bool reduceMotion;
  final M3ESpring spring;
  final AnimationController _controller;

  Animation<double> get animation => _controller;
  double get value => _controller.value;
  bool get isAnimating => _controller.isAnimating;

  void restart({double from = 0}) {
    if (reduceMotion) {
      jumpTo(1);
      return;
    }
    _controller.stop();
    _controller.value = from;
    _controller.animateWith(
      SpringSimulation(spring.toDescription(), from, 1, 0),
    );
  }

  void jumpTo(double value) {
    _controller.stop();
    _controller.value = value;
  }

  void dispose() => _controller.dispose();
}

/// Fades its child with the M3 effects spring.
///
/// Reduced motion jumps to the final opacity instead of animating. The first
/// build also animates when [visible] is true, which is what makes a chart
/// tooltip fade in with `effectsFast`.
class ChartFade extends StatefulWidget {
  const ChartFade({
    super.key,
    required this.visible,
    required this.child,
    this.spring = M3EMotion.effectsFast,
  });

  final bool visible;
  final Widget child;
  final M3ESpring spring;

  @override
  State<ChartFade> createState() => _ChartFadeState();
}

class _ChartFadeState extends State<ChartFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
  );

  bool? _lastVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lastVisible == widget.visible) return;
    _lastVisible = widget.visible;
    _animate();
  }

  @override
  void didUpdateWidget(ChartFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastVisible != widget.visible) {
      _lastVisible = widget.visible;
      _animate();
    }
  }

  void _animate() {
    final target = widget.visible ? 1.0 : 0.0;
    if (ChartMotion.isReduced(context)) {
      _controller.value = target;
      return;
    }
    ChartMotion.springTo(_controller, to: target, spring: widget.spring);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
