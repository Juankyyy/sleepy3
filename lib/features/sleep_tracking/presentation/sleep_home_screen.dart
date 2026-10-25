import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/time/clock_format.dart';
import '../../../core/time/day_phase.dart';
import '../application/sleep_tracking_controller.dart';
import '../domain/sleep_duration.dart';
import 'widgets/home_clock.dart';
import 'widgets/home_header.dart';
import 'widgets/live_clock.dart';
import 'widgets/track_buttons_row.dart';

/// The Home destination: brand, live clock, session line and tracking actions.
class SleepHomeScreen extends ConsumerWidget {
  const SleepHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepTrackingControllerProvider);
    final controller = ref.read(sleepTrackingControllerProvider.notifier);

    return Padding(
      // M3 compact layout margin.
      padding: const EdgeInsets.all(16),
      child: LiveClock(
        builder: (context, now) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(phase: dayPhaseFor(now)),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HomeClock(
                              now: now,
                              sessionLine: _sessionLine(context, state, now),
                            ),
                            // 32dp layout spacer between the clock and the
                            // actions.
                            const SizedBox(height: 32),
                            TrackButtonsRow(
                              isSleeping: state.isSleeping,
                              onSleep: () => unawaited(controller.sleep()),
                              onWake: () => unawaited(controller.wake()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _sessionLine(
    BuildContext context,
    SleepTrackingState state,
    DateTime now,
  ) {
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);

    final open = state.openSession;
    if (open != null) {
      final time = formatSessionTime(
        open.startedAt,
        use24HourFormat: use24HourFormat,
      );
      return 'Sleeping since $time';
    }

    final last = state.lastSession;
    if (last != null) {
      return 'Last session: ${formatSleepDuration(last.duration)}';
    }

    return switch (dayPhaseFor(now)) {
      DayPhase.day => 'No active session',
      DayPhase.night => 'Tap Sleep when you turn off the lights',
    };
  }
}
