import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/empty_state.dart';

/// Placeholder for the Settings destination until its content is designed.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Sleepy3EmptyState(
      icon: M3EIcons.settings_rounded,
      headline: 'Settings are coming soon',
      supportingText:
          'Theme, Health Connect and privacy options will live here.',
    );
  }
}
