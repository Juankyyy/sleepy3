import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../features/settings/presentation/settings_screen.dart';
import '../features/sleep_tracking/presentation/sleep_home_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import 'navigation/sleepy3_destination.dart';

/// App shell with the three top-level destinations and the M3 navigation bar.
///
/// The destinations build lazily: Home is built for the first frame and Stats
/// or Settings join the [IndexedStack] the first time they are selected. Once
/// built they stay alive, so switching tabs preserves each screen's state and
/// scroll position. From a secondary tab the system back gesture returns to
/// Home instead of leaving the app.
class Sleepy3Shell extends StatefulWidget {
  const Sleepy3Shell({super.key});

  @override
  State<Sleepy3Shell> createState() => _Sleepy3ShellState();
}

class _Sleepy3ShellState extends State<Sleepy3Shell> {
  static const _homeIndex = 0;

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

    return PopScope<Object?>(
      canPop: _selectedIndex == _homeIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _selectDestination(_homeIndex);
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
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
        bottomNavigationBar: M3ENavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectDestination,
          size: M3ENavBarSize.small,
          destinations: [
            for (final destination in Sleepy3Destination.values)
              destination.toNavigationBarDestination(),
          ],
          semanticLabel: 'Main navigation',
        ),
      ),
    );
  }
}
