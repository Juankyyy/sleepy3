import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../features/reminders/application/reminder_providers.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/sleep_tracking/presentation/sleep_home_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/stats/presentation/widgets/new_session_fab.dart';
import '../l10n/l10n.dart';
import 'navigation/pill_navigation_bar.dart';
import 'navigation/sleepy3_destination.dart';

/// App shell with the three top-level destinations and the pill navigation bar.
///
/// The destinations build lazily: Home is built for the first frame and Stats
/// or Settings join the [IndexedStack] the first time they are selected. Once
/// built they stay alive, so switching tabs preserves each screen's state and
/// scroll position. From a secondary tab the system back gesture returns to
/// Home instead of leaving the app.
class Sleepy3Shell extends ConsumerStatefulWidget {
  const Sleepy3Shell({super.key});

  @override
  ConsumerState<Sleepy3Shell> createState() => _Sleepy3ShellState();
}

class _Sleepy3ShellState extends ConsumerState<Sleepy3Shell> {
  static const _homeIndex = 0;
  static const _statsIndex = 1;

  int _selectedIndex = _homeIndex;
  final _built = <int>{_homeIndex};

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _built.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    ref.listen(reminderHomeRequestProvider, (previous, next) {
      if (previous == next) return;
      _selectDestination(_homeIndex);
    });

    return PopScope<Object?>(
      canPop: _selectedIndex == _homeIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _selectDestination(_homeIndex);
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        // The glass bar floats over the content. The screens add the bottom
        // MediaQuery padding so their last item can scroll above it.
        extendBody: true,
        body: SafeArea(
          // The navigation bar owns the bottom system inset.
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              const SleepHomeScreen(),
              if (_built.contains(1))
                const StatsScreen()
              else
                const SizedBox.shrink(),
              if (_built.contains(2))
                const SettingsScreen()
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final insets = M3ESafeArea.paddingOf(context);
            return Padding(
              padding: EdgeInsets.only(
                left: insets.left,
                top: PillNavigationBar.topGap,
                right: insets.right,
                bottom: insets.bottom + PillNavigationBar.bottomGap,
              ),
              child: PillNavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
                destinations: Sleepy3Destination.values,
                semanticLabel: l10n.mainNavigation,
                // The FAB decides internally whether the history is ready. It
                // stays mounted in the bar so the snackbar still has a context
                // while a Google Health upload reloads the history.
                trailing: _selectedIndex == _statsIndex
                    ? const NewSessionFab()
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
