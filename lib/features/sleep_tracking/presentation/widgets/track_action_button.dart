import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/sleepy3_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../application/sleep_tracking_controller.dart';

/// M3 Expressive web fallbacks for the motion physics tokens.
///
/// Flutter does not expose the spring system. The saved handoff therefore uses
/// the sanctioned curves from the M3 token table: fast spatial (which may
/// overshoot) for scale and rotation, and fast effects (which never overshoots)
/// for opacity.
const _expressiveFastSpatial = Cubic(0.42, 1.67, 0.21, 0.90);
const _expressiveFastEffects = Cubic(0.31, 0.94, 0.34, 1.00);

/// The action and result labels of the control.
///
/// M3 documents `labelLarge` for button labels. Sleepy3 uses the brand title
/// face at `titleLarge` for the Sleep action and the saving/result labels, a
/// product decision. The sleeping state adds a live duration in the clock face
/// and a smaller `labelLarge` slide hint in the brand face.
TextStyle _sliderLabelStyle(M3EThemeData theme) =>
    Sleepy3Theme.brandTitle(theme.typography.emphasized.titleLarge);

/// The slide hint under the live duration while sleeping.
TextStyle _slideHintStyle(M3EThemeData theme) =>
    Sleepy3Theme.brandTitle(theme.typography.baseline.labelLarge);

/// The single primary action on Home.
///
/// Home shows only the action that fits the current state: Sleep while awake
/// and the Wake slide while a session is open. The previous layout showed both
/// and disabled the invalid one; a single visible action removes that choice.
///
/// From M3: the Sleep button is a filled `M3EButton` XL (136 dp, 40 dp leading
/// icon, 28 dp square radius). Pressing morphs the surface to the XL pressed
/// radius (16 dp) with a 10% state layer. The Wake control uses the same 136 dp
/// height, a 68 dp pill track and a 104 dp button with a 52 dp radius. The
/// saving state uses `primary` and `onPrimary`; the seal is the `sunny` shape
/// from the M3 shape library. The control is a slide-to-confirm, not an M3
/// Slider; the slider guidance that applies is the XL hero target and the
/// visual anchor at the end of the track.
///
/// My design decisions (not in M3): the 104 dp button that travels instead of
/// a stretching capsule, the 50% onPrimary trail behind it, the 80% travel
/// commit threshold (the grip still finishes the travel on release), the 1.2 s
/// minimum saving state, the loading figure on the right of
/// the saving label at the sunny's 84 dp visible size (a 106 dp outer box for
/// M3's 38:48 ratio, laid out in an 84 dp slot with the saved row's 16 dp gap),
/// the 1.2 s saved hold, the 420 ms saving-to-saved handoff (the saving row
/// fades out before the saved text enters; the seal lands with a half turn and
/// the fast spatial overshoot while the check joins at about 273 ms), the 1.5%
/// success beat of the action surface, the 16% dragged state layer, the 400 ms
/// tap guard, the live duration in the clock face, the
/// 14 sp slide hint, the 20 dp moon, the 24 dp gap between the button and the
/// label, the one-shot 5.6 s entrance cue, and the 220 ms minute crossfade.
/// The Sleep press adds a 0.98 scale and a 200 ms radius change; starting a
/// session adds a one-pass light sweep (520 ms), a 420 ms landing of the wake
/// moon and a 220 ms session-line crossfade. The curves are M3's documented web
/// fallbacks because Flutter does not expose the M3 spring system.
class TrackActionButton extends StatefulWidget {
  const TrackActionButton({
    super.key,
    required this.isSleeping,
    required this.onSleep,
    required this.onWake,
    this.sleepDuration,
  }) : assert(
         !isSleeping || sleepDuration != null,
         'sleepDuration is required while a session is open',
       );

  /// How long the Sleep/Wake switch and the shape morph take.
  static const swapDuration = Duration(milliseconds: 350);

  /// How long the Sleep surface takes to reach the M3 pressed radius.
  static const pressDuration = Duration(milliseconds: 200);

  /// How long the nightfall sheen takes to cross the surface once.
  static const nightfallDuration = Duration(milliseconds: 520);

  /// How long the wake moon takes to land after sleep starts.
  static const moonLandingDuration = Duration(milliseconds: 420);

  /// Taps and drags are ignored for this long after the action changes.
  static const tapGuard = Duration(milliseconds: 400);

  /// The minimum time the saving state stays visible.
  static const savingMinimum = Duration(milliseconds: 1200);

  /// How long the saved/discarded result stays on screen.
  static const savedHold = Duration(milliseconds: 1200);

  final bool isSleeping;
  final VoidCallback onSleep;

  /// Closes the session after the user completes the slide.
  ///
  /// [onSaving] must be called when the actual write starts, after any
  /// confirmation dialog, so the saving state never appears behind a dialog.
  /// The returned outcome is null when the user keeps sleeping.
  final Future<SleepWakeOutcome?> Function(VoidCallback onSaving) onWake;

  /// How long the open session has been running while [isSleeping] is true.
  ///
  /// Home computes it from the live clock. The control caches the last value so
  /// the saving and saved states keep their accessible label after Home flips
  /// to awake and stops passing a duration.
  final Duration? sleepDuration;

  @override
  State<TrackActionButton> createState() => _TrackActionButtonState();
}

/// The internal phase of the Wake side of the control.
enum _WakePhase { idle, saving, saved, discarded, failed }

class _TrackActionButtonState extends State<TrackActionButton>
    with TickerProviderStateMixin {
  static const _successBeatDuration = Duration(milliseconds: 350);
  static const _nightfallCurve = Cubic(0.34, 0.80, 0.34, 1.00);

  Timer? _guardTimer;
  Timer? _resultTimer;
  bool _acceptingTaps = true;
  bool _completed = false;
  bool _sleepPressed = false;
  DateTime? _savingStarted;
  _WakePhase _phase = _WakePhase.idle;
  int _resetSignal = 0;
  int _landingSignal = 0;
  Duration? _lastSleepDuration;
  late final AnimationController _successBeat;
  late final Animation<double> _successScale;
  late final AnimationController _nightfall;
  late final Animation<double> _nightfallAnimation;

  /// Whether the Wake confirmation owns the control.
  ///
  /// [_completed] is set as soon as the slide commits, before the dialogs and
  /// the write, so the confirmation stays on screen while the state is already
  /// awake. The phase covers a control that remounts during a result.
  bool get _isCompleting => _completed || _phase != _WakePhase.idle;

  @override
  void initState() {
    super.initState();
    _lastSleepDuration = widget.sleepDuration;
    _successBeat = AnimationController(
      vsync: this,
      duration: _successBeatDuration,
    );
    // A subtle success beat: the pill grows 1.5% and settles. Scale is a
    // spatial property, so the ease-out/in sequence keeps it smooth; the sun
    // carries the expressive overshoot.
    _successScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.015,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.015,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_successBeat);

    _nightfall = AnimationController(
      vsync: this,
      duration: TrackActionButton.nightfallDuration,
    );
    _nightfallAnimation = CurvedAnimation(
      parent: _nightfall,
      curve: _nightfallCurve,
    );
  }

  @override
  void didUpdateWidget(TrackActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sleepDuration != null) {
      _lastSleepDuration = widget.sleepDuration;
    }
    if (widget.isSleeping == oldWidget.isSleeping) return;

    // The pressed shape belongs to the awake action only. Clearing it here
    // lets the surface continue from 16 dp straight into the 68 dp pill.
    _sleepPressed = false;
    _guardTimer?.cancel();
    setState(() => _acceptingTaps = false);
    _guardTimer = Timer(TrackActionButton.tapGuard, () {
      if (!mounted) return;
      setState(() => _acceptingTaps = true);
    });

    if (widget.isSleeping) {
      _landingSignal++;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _nightfall.reset();
      } else {
        _nightfall.forward(from: 0);
      }
    } else {
      _nightfall.reset();
    }
  }

  @override
  void dispose() {
    _guardTimer?.cancel();
    _resultTimer?.cancel();
    _successBeat.dispose();
    _nightfall.dispose();
    super.dispose();
  }

  void _handleSleep() {
    if (!_acceptingTaps || _isCompleting) return;
    widget.onSleep();
  }

  void _onSaving() {
    if (!mounted || _phase != _WakePhase.idle) return;
    _savingStarted = DateTime.now();
    setState(() => _phase = _WakePhase.saving);
  }

  Future<void> _handleSlideComplete() async {
    if (!_acceptingTaps || _isCompleting) return;

    _completed = true;
    setState(() {});
    try {
      final outcome = await widget.onWake(_onSaving);
      if (!mounted) return;
      if (outcome == null) {
        _reset();
        return;
      }

      final started = _savingStarted;
      if (started != null) {
        final remaining =
            TrackActionButton.savingMinimum -
            DateTime.now().difference(started);
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
          if (!mounted) return;
        }
      }
      _finish(outcome);
    } catch (_) {
      if (!mounted) return;
      _finishFailed();
    }
  }

  void _reset() {
    _resultTimer?.cancel();
    _savingStarted = null;
    _successBeat.reset();
    setState(() {
      _phase = _WakePhase.idle;
      _completed = false;
      _resetSignal++;
    });
  }

  void _finish(SleepWakeOutcome outcome) {
    _resultTimer?.cancel();
    if (outcome == SleepWakeOutcome.closed &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _successBeat.forward(from: 0);
    } else {
      _successBeat.reset();
    }
    setState(() {
      _phase = outcome == SleepWakeOutcome.discarded
          ? _WakePhase.discarded
          : _WakePhase.saved;
    });
    _startResultTimer();
  }

  void _finishFailed() {
    _resultTimer?.cancel();
    _successBeat.reset();
    setState(() => _phase = _WakePhase.failed);
    _startResultTimer();
  }

  void _startResultTimer() {
    _resultTimer = Timer(TrackActionButton.savedHold, () {
      if (!mounted) return;
      _successBeat.reset();
      setState(() {
        _phase = _WakePhase.idle;
        _completed = false;
        _savingStarted = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isError =
        _phase == _WakePhase.discarded || _phase == _WakePhase.failed;
    final showSlide = widget.isSleeping || _isCompleting;
    final isPressed = _sleepPressed && !showSlide;
    // The pressed shape is M3's XL square radius (16 dp). The surface keeps
    // the 28 dp square at rest and the 68 dp pill while sleeping.
    final radius = showSlide ? 68.0 : (isPressed ? 16.0 : 28.0);
    final duration = reduceMotion
        ? Duration.zero
        : showSlide
        ? TrackActionButton.swapDuration
        : TrackActionButton.pressDuration;

    return SizedBox(
      width: double.infinity,
      height: 136,
      child: ScaleTransition(
        key: const Key('track-action-beat'),
        scale: _successScale,
        child: AnimatedScale(
          key: const Key('track-action-press-scale'),
          scale: isPressed ? 0.98 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          child: AnimatedContainer(
            key: const Key('track-action-surface'),
            duration: duration,
            curve: const Cubic(0.2, 0.8, 0.2, 1),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isError ? scheme.error : scheme.primary,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: const Interval(
                    0.35,
                    1,
                    curve: Cubic(0.2, 0.8, 0.2, 1),
                  ),
                  switchOutCurve: const Interval(
                    0.65,
                    1,
                    curve: Cubic(0.3, 0, 0.8, 0.15),
                  ),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.center,
                    children: [
                      ...previousChildren.map(
                        (child) => ExcludeSemantics(child: child),
                      ),
                      ?currentChild,
                    ],
                  ),
                  child: showSlide
                      ? _WakeSlide(
                          key: const ValueKey<String>('wake'),
                          phase: _phase,
                          enabled: _acceptingTaps && !_completed,
                          resetSignal: _resetSignal,
                          landingSignal: _landingSignal,
                          sleepDuration: _lastSleepDuration ?? Duration.zero,
                          onComplete: _handleSlideComplete,
                        )
                      : _SleepAction(
                          key: const ValueKey<String>('sleep'),
                          onPressed: _handleSleep,
                          onPressedChanged: _onSleepPressedChanged,
                        ),
                ),
                if (!reduceMotion)
                  _NightfallSheen(
                    key: const Key('track-action-sheen'),
                    animation: _nightfallAnimation,
                    color: scheme.onPrimary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSleepPressedChanged(bool pressed) {
    if (pressed == _sleepPressed) return;
    if (widget.isSleeping || _isCompleting) return;
    setState(() => _sleepPressed = pressed);
  }
}

/// The awake action: the familiar XL filled Sleep button.
///
/// The fill lives on the shared surface so the control can morph between the
/// square button and the pill. The button itself is transparent and keeps the
/// M3E press/hover/focus states.
///
/// The pressed state is forwarded to the surface because the visible fill is
/// painted there: that is the only way the M3 16 dp pressed radius can show.
class _SleepAction extends StatefulWidget {
  const _SleepAction({
    super.key,
    required this.onPressed,
    required this.onPressedChanged,
  });

  final VoidCallback onPressed;
  final ValueChanged<bool> onPressedChanged;

  @override
  State<_SleepAction> createState() => _SleepActionState();
}

class _SleepActionState extends State<_SleepAction> {
  late final WidgetStatesController _statesController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
    _statesController.addListener(_handleStatesChanged);
  }

  void _handleStatesChanged() {
    final pressed = _statesController.value.contains(WidgetState.pressed);
    if (pressed == _pressed) return;
    _pressed = pressed;
    if (!mounted) return;
    if (pressed) unawaited(HapticFeedback.lightImpact());
    widget.onPressedChanged(pressed);
  }

  @override
  void dispose() {
    _statesController
      ..removeListener(_handleStatesChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: M3EButton.icon(
        style: M3EButtonStyle.filled,
        size: M3EButtonSize.xl,
        shape: M3EButtonShape.square,
        statesController: _statesController,
        enableFeedback: false,
        decoration: M3EButtonDecoration(
          backgroundColor: const WidgetStatePropertyAll<Color?>(
            Colors.transparent,
          ),
          foregroundColor: WidgetStatePropertyAll<Color?>(scheme.onPrimary),
          textStyle: _sliderLabelStyle(theme),
        ),
        onPressed: widget.onPressed,
        icon: Icon(M3EIcons.bedtime_rounded),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(l10n.sleepAction, maxLines: 1),
        ),
      ),
    );
  }
}

/// The sleeping action: the button that travels to the end of the track.
class _WakeSlide extends StatefulWidget {
  const _WakeSlide({
    super.key,
    required this.phase,
    required this.enabled,
    required this.resetSignal,
    required this.landingSignal,
    required this.sleepDuration,
    required this.onComplete,
  });

  final _WakePhase phase;
  final bool enabled;
  final int resetSignal;

  /// Increments only when the app goes from awake to sleeping.
  ///
  /// It is zero on a cold start with an open session, so the moon does not
  /// replay its landing when Home is restored.
  final int landingSignal;
  final Duration sleepDuration;
  final VoidCallback onComplete;

  @override
  State<_WakeSlide> createState() => _WakeSlideState();
}

class _WakeSlideState extends State<_WakeSlide>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _inset = 16.0;
  static const _grip = 104.0;
  static const _labelGap = 24.0;
  static const _height = 136.0;
  static const _resultDuration = Duration(milliseconds: 420);
  static const _idleCueDuration = Duration(milliseconds: 5600);
  static const _durationSwapDuration = Duration(milliseconds: 220);

  /// Fraction of the travel that commits the Wake on release.
  ///
  /// My design decision (not in M3): the last 20% is a forgiving commit zone,
  /// because the thumb cannot always reach the end of the track. Releasing
  /// here still animates the grip to the end before the saving state.
  static const _commitThreshold = 0.8;

  /// Matches the 84 dp sunny. M3 keeps a 38:48 active/outer ratio, so the
  /// loading indicator's outer box is 106 dp. The extra padding is laid out
  /// outside the 84 dp figure slot so the 16 dp text gap stays the same as in
  /// the saved row.
  static const _savingFigureSize = 84.0;
  static const _savingIndicatorSize = 106.0;

  /// Point of the result handoff where the saving row is gone and the result
  /// text starts to enter.
  static const _resultHandoffStart = 0.36;

  late final AnimationController _result;
  late final Animation<double> _savingOpacity;
  late final Animation<double> _savingScale;
  late final Animation<double> _savedTextOpacity;
  late final Animation<double> _sunOpacity;
  late final Animation<Offset> _savedTextSlide;
  late final AnimationController _idle;
  late final AnimationController _landing;
  late final Animation<double> _landingScale;
  late final Animation<double> _landingTurn;
  final FocusNode _focusNode = FocusNode(debugLabel: 'TrackActionButton');
  double _offset = 0;
  double _maxTravel = 1;
  bool _dragging = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _result = AnimationController(vsync: this, duration: _resultDuration);
    // A control that remounts during a result must show it instead of the
    // saving row that starts the handoff.
    if (widget.phase == _WakePhase.saved ||
        widget.phase == _WakePhase.discarded ||
        widget.phase == _WakePhase.failed) {
      _result.value = 1;
    }
    _savingOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _result,
        curve: const Interval(
          0,
          _resultHandoffStart,
          curve: _expressiveFastEffects,
        ),
      ),
    );
    _savingScale = Tween<double>(begin: 1, end: 0.6).animate(
      CurvedAnimation(
        parent: _result,
        curve: const Interval(
          0,
          _resultHandoffStart,
          curve: _expressiveFastSpatial,
        ),
      ),
    );
    _savedTextOpacity = CurvedAnimation(
      parent: _result,
      curve: const Interval(
        _resultHandoffStart,
        0.72,
        curve: _expressiveFastEffects,
      ),
    );
    // The seal is the persistent figure: it starts appearing while the saving
    // row is still fading, so the handoff leaves no empty pill. The text waits
    // until the saving copy is gone.
    _sunOpacity = CurvedAnimation(
      parent: _result,
      curve: const Interval(0.18, 0.5, curve: _expressiveFastEffects),
    );
    _savedTextSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _result,
            curve: const Interval(
              _resultHandoffStart,
              0.72,
              curve: _expressiveFastSpatial,
            ),
          ),
        );
    _idle = AnimationController(vsync: this, duration: _idleCueDuration);
    _landing = AnimationController(
      vsync: this,
      duration: TrackActionButton.moonLandingDuration,
    );
    _landingScale = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _landing, curve: _expressiveFastSpatial));
    _landingTurn = Tween<double>(
      begin: -0.5,
      end: 0,
    ).animate(CurvedAnimation(parent: _landing, curve: _expressiveFastSpatial));
    if (widget.landingSignal > 0) {
      _landing.forward(from: 0);
    } else {
      _landing.value = 1;
    }
    _focusNode.addListener(_onFocusChange);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChange);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybePlayIdleCue();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _stopIdleCue();
      if (_landing.value < 1) _landing.value = 1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybePlayIdleCue();
  }

  void _maybePlayIdleCue() {
    if (!mounted || _dragging || widget.phase != _WakePhase.idle) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    _idle.forward(from: 0);
  }

  void _stopIdleCue() {
    if (!_idle.isAnimating && _idle.value == 1) return;
    _idle
      ..stop()
      ..value = 1;
  }

  /// Two triangular nudges over the entrance cue.
  double _arrowNudge(double t) {
    double pulse(double start, double end) {
      if (t <= start || t >= end) return 0;
      final p = (t - start) / (end - start);
      return p < 0.5 ? p * 2 : (1 - p) * 2;
    }

    return 5 * math.max(pulse(0.12, 0.24), pulse(0.52, 0.64));
  }

  @override
  void didUpdateWidget(_WakeSlide oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.landingSignal != oldWidget.landingSignal) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _landing.value = 1;
      } else {
        _landing.forward(from: 0);
      }
    }

    // A cancelled Wake (a dialog that keeps the session open) never changes
    // the phase, so the reset has its own signal. Without it the button
    // would stay at the end, seen as a full primary track.
    if (widget.resetSignal != oldWidget.resetSignal) {
      _offset = 0;
      _dragging = false;
      _result.reset();
      _stopIdleCue();
    }

    if (widget.phase == oldWidget.phase) return;
    _stopIdleCue();

    final fromSaving = oldWidget.phase == _WakePhase.saving;
    switch (widget.phase) {
      case _WakePhase.saving:
        _offset = _maxTravel;
        _dragging = false;
        _result.reset();
      case _WakePhase.saved:
        _playResult(fromSaving: fromSaving);
      case _WakePhase.idle:
        _offset = 0;
        _dragging = false;
        _result.reset();
      case _WakePhase.discarded:
      case _WakePhase.failed:
        _playResult(fromSaving: fromSaving);
    }
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _onHighlightModeChange(FocusHighlightMode mode) {
    if (!mounted) return;
    setState(() {});
  }

  /// Runs the saving-to-result handoff.
  ///
  /// A discard that never showed the saving state starts at the point where
  /// the saving row is gone, so "Saving session" does not flash before the
  /// result.
  void _playResult({bool fromSaving = true}) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _result.value = 1;
    } else {
      _result.forward(from: fromSaving ? 0 : _resultHandoffStart);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChange);
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _result.dispose();
    _idle.dispose();
    _landing.dispose();
    super.dispose();
  }

  void _complete() {
    if (!widget.enabled || widget.phase != _WakePhase.idle) return;
    _stopIdleCue();
    setState(() {
      _dragging = false;
      _offset = _maxTravel;
    });
    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled || widget.phase != _WakePhase.idle) return;
    _stopIdleCue();
    // A pointer drag must not focus the control: the focus ring belongs to
    // keyboard navigation, not to touching the slide.
    setState(() => _dragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(0.0, _maxTravel);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    if (_offset >= _maxTravel * _commitThreshold) {
      _complete();
      return;
    }
    setState(() {
      _dragging = false;
      _offset = 0;
    });
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    setState(() {
      _dragging = false;
      _offset = 0;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || widget.phase != _WakePhase.idle) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.end) {
      _complete();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _offset = math.min(_maxTravel, _offset + _maxTravel / 10);
      });
      if (_offset >= _maxTravel - 1) _complete();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _offset = math.max(0, _offset - _maxTravel / 10);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.escape) {
      setState(() => _offset = 0);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _statusLabel(AppLocalizations l10n) {
    return switch (widget.phase) {
      _WakePhase.saving => l10n.savingSession,
      _WakePhase.saved => l10n.sessionSaved,
      _WakePhase.discarded => l10n.sessionDiscarded,
      _WakePhase.failed => l10n.sessionSaveFailed,
      _WakePhase.idle => '',
    };
  }

  Duration get _safeSleepDuration =>
      widget.sleepDuration.isNegative ? Duration.zero : widget.sleepDuration;

  String _durationText(AppLocalizations l10n) {
    final duration = _safeSleepDuration;
    if (duration < const Duration(minutes: 1)) return l10n.wakeSlideJustNow;
    return l10n.formatSleepDuration(duration);
  }

  String _semanticsLabel(AppLocalizations l10n) {
    final duration = _safeSleepDuration;
    if (duration < const Duration(minutes: 1)) {
      return l10n.wakeSlideJustNowSemantics;
    }
    return l10n.wakeSlideSemantics(l10n.formatSleepDuration(duration));
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final textStyle = _sliderLabelStyle(theme);
    final isError =
        widget.phase == _WakePhase.discarded ||
        widget.phase == _WakePhase.failed;
    final contentColor = isError ? scheme.onError : scheme.onPrimary;
    final statusLabel = _statusLabel(l10n);
    final durationText = _durationText(l10n);
    final semanticsLabel = _semanticsLabel(l10n);
    final durationStyle = Sleepy3Theme.clock(
      theme.typography.emphasized.headlineSmall,
    ).copyWith(color: contentColor);
    final hintStyle = _slideHintStyle(theme)
        .copyWith(color: contentColor.withValues(alpha: 0.9));

    return LayoutBuilder(
      builder: (context, constraints) {
        final max = math.max(0.0, constraints.maxWidth - _inset * 2 - _grip);
        _maxTravel = max;
        final progress = max > 0 ? (_offset / max).clamp(0.0, 1.0) : 0.0;
        final isSaving = widget.phase == _WakePhase.saving;
        final isSaved = widget.phase == _WakePhase.saved;
        final resultIcon = widget.phase == _WakePhase.discarded
            ? M3EIcons.cancel_outlined
            : M3EIcons.error_outline_rounded;
        final showDone = isSaved || isError;
        final labelOpacity = widget.phase == _WakePhase.idle
            ? math.max(0.0, 0.9 - progress * 1.6)
            : 0.0;
        final movementDuration = _dragging || reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 280);
        final fadeDuration = reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180);
        final showFocusRing =
            _focused &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional &&
            widget.phase == _WakePhase.idle;

        final content = Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: _inset + _grip + _labelGap,
              top: 0,
              right: 16,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: labelOpacity,
                  child: Align(
                    key: const Key('track-action-label'),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RotationTransition(
                              key: const Key('track-action-moon-landing-turn'),
                              turns: _landingTurn,
                              child: ScaleTransition(
                                key: const Key('track-action-moon-landing'),
                                scale: _landingScale,
                                child: _BreathingMoon(
                                  animation: _idle,
                                  color: contentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: AnimatedSwitcher(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : _durationSwapDuration,
                                  switchInCurve: const Cubic(0.2, 0.8, 0.2, 1),
                                  switchOutCurve: const Cubic(
                                    0.3,
                                    0,
                                    0.8,
                                    0.15,
                                  ),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.12),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  layoutBuilder:
                                      (currentChild, previousChildren) => Stack(
                                        alignment: Alignment.centerLeft,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      ),
                                  child: Text(
                                    durationText,
                                    key: ValueKey<String>(durationText),
                                    maxLines: 1,
                                    style: durationStyle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.slideToWake,
                            maxLines: 1,
                            style: hintStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isSaving || showDone ? 0 : 1,
              duration: fadeDuration,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: _inset,
                    top: _inset,
                    child: AnimatedContainer(
                      key: const Key('track-action-trail'),
                      duration: movementDuration,
                      curve: const Cubic(0.2, 0.8, 0.2, 1),
                      width: _grip + _offset,
                      height: _grip,
                      decoration: BoxDecoration(
                        color: scheme.onPrimary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(52),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: movementDuration,
                    curve: const Cubic(0.2, 0.8, 0.2, 1),
                    left: _inset + _offset,
                    top: _inset,
                    width: _grip,
                    height: _grip,
                    child: DecoratedBox(
                      key: const Key('track-action-grip'),
                      decoration: BoxDecoration(
                        color: scheme.onPrimary,
                        borderRadius: BorderRadius.circular(52),
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _idle,
                          builder: (context, child) => Transform.translate(
                            key: const Key('track-action-arrow-nudge'),
                            offset: Offset(_arrowNudge(_idle.value), 0),
                            child: child,
                          ),
                          child: Icon(
                            M3EIcons.arrow_forward_rounded,
                            size: 40,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _result,
              builder: (context, _) {
                final showSavingRow =
                    isSaving ||
                    (showDone && _result.value < _resultHandoffStart);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (showSavingRow)
                      FadeTransition(
                        key: const Key('track-action-saving-row'),
                        opacity: _savingOpacity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _inset,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      l10n.savingSession,
                                      maxLines: 1,
                                      style: textStyle.copyWith(
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  key: const Key('track-action-saving-figure'),
                                  width: _savingFigureSize,
                                  height: _savingFigureSize,
                                  child: ScaleTransition(
                                    key: const Key('track-action-saving-scale'),
                                    scale: _savingScale,
                                    child: OverflowBox(
                                      minWidth: _savingIndicatorSize,
                                      maxWidth: _savingIndicatorSize,
                                      minHeight: _savingIndicatorSize,
                                      maxHeight: _savingIndicatorSize,
                                      alignment: Alignment.center,
                                      child: ExcludeSemantics(
                                        child: M3ELoadingIndicator(
                                          key: const Key(
                                            'track-action-saving-indicator',
                                          ),
                                          size: _savingIndicatorSize,
                                          color: scheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      key: const Key('track-action-saved-row'),
                      padding: const EdgeInsets.symmetric(horizontal: _inset),
                      child: Center(
                        child: Row(
                          key: const Key('track-action-result'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SlideTransition(
                                position: _savedTextSlide,
                                child: FadeTransition(
                                  key: const Key('track-action-saved-text'),
                                  opacity: _savedTextOpacity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isError
                                          ? (widget.phase ==
                                                    _WakePhase.discarded
                                                ? l10n.sessionDiscarded
                                                : l10n.sessionSaveFailed)
                                          : l10n.sessionSaved,
                                      maxLines: 1,
                                      style: textStyle.copyWith(
                                        color: contentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (isSaved)
                              FadeTransition(
                                key: const Key('track-action-sun'),
                                opacity: _sunOpacity,
                                child: _Figure(
                                  animation: _result,
                                  color: scheme,
                                ),
                              )
                            else
                              FadeTransition(
                                key: const Key('track-action-result-icon'),
                                opacity: _savedTextOpacity,
                                child: Icon(
                                  resultIcon,
                                  size: 40,
                                  color: scheme.onError,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (showFocusRing)
              Positioned.fill(
                key: const Key('track-action-focus'),
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: contentColor, width: 2),
                        borderRadius: BorderRadius.circular(64),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: _height,
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: Semantics(
              key: const Key('track-action-semantics'),
              container: true,
              button: true,
              enabled: widget.enabled && widget.phase == _WakePhase.idle,
              label: semanticsLabel,
              hint: l10n.slideToWakeHint,
              onTap: widget.enabled && widget.phase == _WakePhase.idle
                  ? _complete
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: GestureDetector(
                      key: const Key('track-action-slide'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: widget.enabled
                          ? _handleDragStart
                          : null,
                      onHorizontalDragUpdate: widget.enabled
                          ? _handleDragUpdate
                          : null,
                      onHorizontalDragEnd: widget.enabled
                          ? _handleDragEnd
                          : null,
                      onHorizontalDragCancel: widget.enabled
                          ? _handleDragCancel
                          : null,
                      child: content,
                    ),
                  ),
                  if (statusLabel.isNotEmpty)
                    Semantics(
                      container: true,
                      liveRegion: true,
                      label: statusLabel,
                      child: const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A single soft band that crosses the action once when sleep starts.
///
/// This is not an M3 component. It is a translucent pass of `onPrimary` over
/// the filled surface: opacity is an effect, so its curve never overshoots.
/// The 520 ms sweep is a product decision; M3 publishes no choreography timing.
class _NightfallSheen extends StatelessWidget {
  const _NightfallSheen({
    super.key,
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final start = -2.4 + 4.8 * animation.value;
            return DecoratedBox(
              key: const Key('track-action-sheen-band'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(start, 0),
                  end: Alignment(start + 1.2, 0),
                  colors: [
                    color.withValues(alpha: 0),
                    color.withValues(alpha: 0.14),
                    color.withValues(alpha: 0),
                  ],
                  stops: const [0.3, 0.5, 0.7],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The moon beside the live duration; it breathes twice on the entrance cue.
class _BreathingMoon extends StatelessWidget {
  const _BreathingMoon({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final breath = 0.5 + 0.5 * math.cos(animation.value * 4 * math.pi);
        return Transform.scale(
          key: const Key('track-action-moon-breath'),
          scale: 0.92 + 0.08 * breath,
          child: Opacity(opacity: 0.55 + 0.45 * breath, child: child),
        );
      },
      child: Icon(M3EIcons.bedtime_rounded, size: 20, color: color),
    );
  }
}

/// The saved seal: the M3 `sunny` shape landing with a spatial overshoot, then
/// its check.
///
/// The sun scales from 0.5 and turns a half turn with the expressive fast
/// spatial fallback. The check fades and scales in at 65% of the result
/// controller, once the sun is almost settled. The saved row owns the opacity,
/// so the seal is not faded twice.
class _Figure extends StatelessWidget {
  const _Figure({required this.animation, required this.color});

  final Animation<double> animation;
  final M3EColorScheme color;

  @override
  Widget build(BuildContext context) {
    final sunScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.85, curve: _expressiveFastSpatial),
      ),
    );
    final sunTurn = Tween<double>(begin: -0.5, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.85, curve: _expressiveFastSpatial),
      ),
    );
    final checkOpacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.65, 0.92, curve: _expressiveFastEffects),
    );
    final checkScale = Tween<double>(begin: 0.4, end: 1).animate(checkOpacity);

    return SizedBox(
      key: const Key('track-action-figure'),
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            key: const Key('track-action-sun-scale'),
            scale: sunScale,
            child: RotationTransition(
              key: const Key('track-action-sun-turn'),
              turns: sunTurn,
              child: M3EShapeContainer(
                kind: M3EShapeKind.sunny,
                width: 84,
                height: 84,
                color: color.onPrimary,
              ),
            ),
          ),
          FadeTransition(
            key: const Key('track-action-check'),
            opacity: checkOpacity,
            child: ScaleTransition(
              scale: checkScale,
              child: Icon(
                M3EIcons.check_rounded,
                size: 28,
                color: color.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
