import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] when the local calendar day changes.
///
/// Screens that group data by day ("Today", "Yesterday", a 7-day range) only
/// need to rebuild at midnight, not every second. The timer is cancelled while
/// the app is in the background and the day is checked again on resume, so a
/// night in the background does not leave the screen on yesterday's date.
///
/// [clock] is injected by the caller, keeping the widget deterministic in
/// tests.
class LocalDayBuilder extends StatefulWidget {
  const LocalDayBuilder({
    super.key,
    required this.clock,
    required this.builder,
  });

  final DateTime Function() clock;

  /// Receives local midnight of the current day.
  final Widget Function(BuildContext context, DateTime day) builder;

  @override
  State<LocalDayBuilder> createState() => _LocalDayBuilderState();
}

class _LocalDayBuilderState extends State<LocalDayBuilder>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = _readDay();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void didUpdateWidget(covariant LocalDayBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock) {
      _day = _readDay();
      _schedule();
    }
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
      return;
    }
    _timer?.cancel();
    _timer = null;
  }

  DateTime _readDay() {
    final now = widget.clock().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  void _schedule() {
    _timer?.cancel();
    final now = widget.clock().toLocal();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    var delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    if (delay <= Duration.zero) {
      delay = const Duration(seconds: 1);
    }
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;
    final day = _readDay();
    if (day != _day) {
      setState(() => _day = day);
    }
    _schedule();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _day);
}
