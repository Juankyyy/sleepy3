import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../health/application/sleep_data_source_controller.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../sleep_tracking/application/sleep_session_edit_service.dart';
import '../../../sleep_tracking/application/sleep_tracking_controller.dart';
import 'new_session_editor.dart';

/// The Stats action for adding a session the user forgot to track.
///
/// From M3: the regular FAB is 56 dp with a 24 dp filled icon, and the filled
/// primary style pairs `primary` with `onPrimary`. This one is the trailing
/// action of the bottom navigation group, beside the glass dock; M3 allows a
/// FAB above or nested in the navigation bar.
///
/// My design decisions (not in M3): using the regular size instead of the
/// medium size M3 recommends by default, the filled primary color instead of
/// the default primary container, a 28 dp corner radius so the FAB is circular
/// like the dock, the plus icon, the centered dock + FAB group with its 12 dp
/// gap, hiding the FAB while the history is not ready, and the snackbar copy.
/// The entrance also slides in from the dock instead of the canonical M3
/// expansion; see [_FabEntrance].
class NewSessionFab extends ConsumerWidget {
  const NewSessionFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      sleepTrackingControllerProvider.select((state) => state.historyStatus),
    );
    if (status != SleepHistoryStatus.ready) return const SizedBox.shrink();

    return _FabEntrance(
      child: M3EFab(
        icon: const _AnimatedPlus(),
        size: M3EFabSize.regular,
        color: M3EFabColor.primaryFilled,
        cornerRadius: 28,
        tooltip: 'Add a sleep session',
        onPressed: () => unawaited(_open(context, ref)),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final source = ref.read(sleepDataSourceProvider);
    final result = await showNewSessionEditor(context, source: source);
    if (!context.mounted || result == null) return;

    final message = switch (result.status) {
      SleepSessionEditStatus.saved =>
        source == SleepDataSource.healthConnect
            ? 'Session added to Google Health.'
            : 'Session added.',
      SleepSessionEditStatus.savedPendingSync =>
        'Session saved locally. Google Health will update when it can.',
      SleepSessionEditStatus.permissionNeeded =>
        result.hasLocalChange
            ? 'Saved locally. Allow Google Health write access to sync it.'
            : null,
      SleepSessionEditStatus.deleted => null,
      SleepSessionEditStatus.failed => null,
    };
    if (message != null) {
      M3ESnackbar.show(context, message: message);
    }
  }
}

/// Slides the FAB in from behind the dock's trailing edge.
///
/// Position and scale use the expressive spatial fast spring (small element);
/// opacity uses the effects fast spring so it never overshoots. The canonical
/// M3 FAB appearance expands from the centre or the bottom end; tying the
/// entrance to the dock is a Sleepy3 design decision. With reduced motion the
/// FAB is placed at rest immediately, which is also a product decision.
class _FabEntrance extends StatefulWidget {
  const _FabEntrance({required this.child});

  final Widget child;

  @override
  State<_FabEntrance> createState() => _FabEntranceState();
}

class _FabEntranceState extends State<_FabEntrance>
    with TickerProviderStateMixin {
  static const _slideFrom = Offset(-0.75, 0);
  static const _scaleFrom = 0.86;

  late final AnimationController _spatial;
  late final AnimationController _effects;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _spatial = AnimationController.unbounded(vsync: this, value: 0);
    _effects = AnimationController.unbounded(vsync: this, value: 0);
    _slide = Tween<Offset>(
      begin: _slideFrom,
      end: Offset.zero,
    ).animate(_spatial);
    _scale = Tween<double>(begin: _scaleFrom, end: 1).animate(_spatial);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _spatial.value = 1;
      _effects.value = 1;
      return;
    }

    _spatial.animateWith(
      SpringSimulation(
        M3EMotion.expressiveSpatialFast.toDescription(),
        0,
        1,
        0,
      ),
    );
    _effects.animateWith(
      SpringSimulation(M3EMotion.effectsFast.toDescription(), 0, 1, 0),
    );
  }

  @override
  void dispose() {
    _spatial.dispose();
    _effects.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: ScaleTransition(
        scale: _scale,
        child: FadeTransition(opacity: _effects, child: widget.child),
      ),
    );
  }
}

/// The plus inside the FAB, slightly behind the container entrance.
///
/// The 60 ms head start is a Sleepy3 design decision: M3 publishes no stagger
/// values. It uses the same spatial fast spring for scale and the effects fast
/// spring for opacity, and stays static when animations are reduced.
class _AnimatedPlus extends StatefulWidget {
  const _AnimatedPlus();

  @override
  State<_AnimatedPlus> createState() => _AnimatedPlusState();
}

class _AnimatedPlusState extends State<_AnimatedPlus>
    with TickerProviderStateMixin {
  static const _entryDelay = Duration(milliseconds: 60);
  static const _scaleFrom = 0.8;

  late final AnimationController _spatial;
  late final AnimationController _effects;
  late final Animation<double> _scale;
  Timer? _delay;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _spatial = AnimationController.unbounded(vsync: this, value: 0);
    _effects = AnimationController.unbounded(vsync: this, value: 0);
    _scale = Tween<double>(begin: _scaleFrom, end: 1).animate(_spatial);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _spatial.value = 1;
      _effects.value = 1;
      return;
    }

    _delay = Timer(_entryDelay, () {
      if (!mounted) return;
      _spatial.animateWith(
        SpringSimulation(
          M3EMotion.expressiveSpatialFast.toDescription(),
          0,
          1,
          0,
        ),
      );
      _effects.animateWith(
        SpringSimulation(M3EMotion.effectsFast.toDescription(), 0, 1, 0),
      );
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _spatial.dispose();
    _effects.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _effects,
        child: const Icon(M3EIcons.add_rounded),
      ),
    );
  }
}
