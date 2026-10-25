import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/empty_state.dart';

/// Placeholder for the Stats destination until its content is designed.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Sleepy3EmptyState(
      icon: M3EIcons.insights_rounded,
      headline: 'No stats yet',
      supportingText:
          'Your sleep history will appear here after your first night.',
    );
  }
}
