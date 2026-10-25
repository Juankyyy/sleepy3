import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/sleep_tracking_controller.dart';

/// Rebuilds [builder] once a second with the current time.
///
/// The time comes from [sleepClockProvider], so tests can advance it
/// deterministically. The timer stops while the app is in the background and
/// the clock catches up as soon as the app resumes, instead of waking the CPU
/// every second behind a locked screen.
class LiveClock extends ConsumerStatefulWidget {
  const LiveClock({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  ConsumerState<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends ConsumerState<LiveClock>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = _readClock();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      _startTimer();
      return;
    }
    _timer?.cancel();
    _timer = null;
  }

  DateTime _readClock() => ref.read(sleepClockProvider)();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final now = _readClock();
    // A frozen test clock must not schedule a frame every second.
    if (now.millisecondsSinceEpoch ~/ 1000 ==
        _now.millisecondsSinceEpoch ~/ 1000) {
      return;
    }
    setState(() => _now = now);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
