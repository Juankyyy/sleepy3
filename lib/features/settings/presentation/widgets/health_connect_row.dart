import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// A disabled, informational row for the Health Connect integration that is
/// not implemented yet.
///
/// It has no tap handler and no permissions request. When Health Connect ships,
/// replace this widget with the real connection and sync status.
class HealthConnectRow extends StatelessWidget {
  const HealthConnectRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const M3EListItem(
      leading: Icon(M3EIcons.monitor_heart_outlined),
      headline: 'Sleep',
      supportingText: 'Coming soon.',
      enabled: false,
    );
  }
}
