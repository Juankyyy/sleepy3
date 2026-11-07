import 'dart:async';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// The single primary action on Home.
///
/// Home shows only the action that fits the current state: "Sleep" while
/// awake and "Wake" while a session is open. The previous layout showed both
/// and disabled the invalid one; a single visible action removes that choice.
///
/// From M3: a filled button is the highest-emphasis common button and a single
/// filled button is the documented choice for one important action. The XL
/// size uses a 136dp height, 64dp horizontal padding, a 40dp leading icon and
/// the square shape's 28dp corner radius.
///
/// My design decisions (not in M3): keeping the `labelLarge` label role, the
/// 350ms rise-through that moves the icon and label 28dp inside the same
/// container, and the 400ms tap guard after a state change so a double tap
/// cannot close the session it just opened. From M3 motion, the vertical travel
/// is spatial and the opacity is effects, so only the position may overshoot;
/// the curves are M3's documented web fallbacks because Flutter does not expose
/// the M3 spring system.
class TrackActionButton extends StatefulWidget {
  const TrackActionButton({
    super.key,
    required this.isSleeping,
    required this.onSleep,
    required this.onWake,
  });

  /// How long the icon and label take to rise out and back in.
  static const swapDuration = Duration(milliseconds: 350);

  /// Taps are ignored for this long after the action changes.
  static const tapGuard = Duration(milliseconds: 400);

  final bool isSleeping;
  final VoidCallback onSleep;
  final VoidCallback onWake;

  @override
  State<TrackActionButton> createState() => _TrackActionButtonState();
}

class _TrackActionButtonState extends State<TrackActionButton> {
  Timer? _guardTimer;
  bool _acceptingTaps = true;

  @override
  void didUpdateWidget(TrackActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSleeping == oldWidget.isSleeping) return;

    _acceptingTaps = false;
    _guardTimer?.cancel();
    _guardTimer = Timer(TrackActionButton.tapGuard, () {
      if (!mounted) return;
      // Nothing visual depends on this flag; the next build is not needed.
      _acceptingTaps = true;
    });
  }

  @override
  void dispose() {
    _guardTimer?.cancel();
    super.dispose();
  }

  void _handlePressed() {
    if (!_acceptingTaps) return;
    if (widget.isSleeping) {
      widget.onWake();
    } else {
      widget.onSleep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : TrackActionButton.swapDuration;

    final isSleeping = widget.isSleeping;
    final label = isSleeping ? 'Wake' : 'Sleep';
    final icon = isSleeping
        ? M3EIcons.wb_sunny_rounded
        : M3EIcons.bedtime_rounded;

    return SizedBox(
      width: double.infinity,
      child: M3EButton.icon(
        style: M3EButtonStyle.filled,
        size: M3EButtonSize.xl,
        shape: M3EButtonShape.square,
        decoration: M3EButtonDecoration(textStyle: theme.typeScale.labelLarge),
        onPressed: _handlePressed,
        icon: _RiseThrough(
          duration: duration,
          child: Icon(icon, key: ValueKey<bool>(isSleeping)),
        ),
        label: _RiseThrough(
          duration: duration,
          child: Text(label, key: ValueKey<bool>(isSleeping)),
        ),
      ),
    );
  }
}

/// Rises the outgoing child up and fades it out, then brings the new child up
/// from below with a spring-like overshoot.
class _RiseThrough extends StatelessWidget {
  const _RiseThrough({required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      // The outgoing child leaves in the first 35% of the timeline; the
      // incoming one uses the remaining 65%. The spatial curve may overshoot;
      // the opacity is clamped in [_RiseTransition] so effects never bounce.
      switchInCurve: const Interval(
        0.35,
        1,
        curve: Cubic(0.42, 1.67, 0.21, 0.90),
      ),
      switchOutCurve: const Interval(0.65, 1, curve: Cubic(0.3, 0, 0.8, 0.15)),
      transitionBuilder: (child, animation) =>
          _RiseTransition(animation: animation, child: child),
      // The outgoing child must not join the semantics tree: the action the
      // user can take is already the new one.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          ...previousChildren.map((child) => ExcludeSemantics(child: child)),
          ?currentChild,
        ],
      ),
      child: child,
    );
  }
}

class _RiseTransition extends StatelessWidget {
  const _RiseTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  /// The fixed vertical travel shared by the icon and the label, so they move
  /// as one group instead of each by its own height.
  static const _distance = 28.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;
        final isOutgoing =
            animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        final offset = _distance * (1 - value);

        return Transform.translate(
          offset: Offset(0, isOutgoing ? -offset : offset),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0).toDouble(),
            child: child,
          ),
        );
      },
    );
  }
}
