import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../sleep_tracking/domain/sleep_history.dart';

/// Single-select filter chips for the Stats range.
///
/// From M3: filter chips are 32dp tall with an 8dp corner and 8dp between
/// chips. A selected chip shows a leading checkmark as well as the selected
/// colors, so selection does not rely on color alone.
class StatsRangeSelector extends StatelessWidget {
  const StatsRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SleepHistoryRange selected;
  final ValueChanged<SleepHistoryRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return M3EChipGroup(
      groupLabel: 'Time range',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final range in SleepHistoryRange.values)
            M3EChip(
              type: M3EChipType.filter,
              label: _label(range),
              selected: range == selected,
              leading: range == selected
                  ? const Icon(M3EIcons.check, size: 18)
                  : null,
              onPressed: () {
                if (range != selected) onChanged(range);
              },
            ),
        ],
      ),
    );
  }

  String _label(SleepHistoryRange range) {
    return switch (range) {
      SleepHistoryRange.sevenDays => '7 days',
      SleepHistoryRange.thirtyDays => '30 days',
      SleepHistoryRange.all => 'All',
    };
  }
}
