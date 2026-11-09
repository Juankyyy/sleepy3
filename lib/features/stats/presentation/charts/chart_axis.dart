/// One labelled tick on a chart value axis.
class ChartTick {
  const ChartTick({required this.value, required this.label});

  final double value;
  final String label;
}

/// A linear value axis shared by the Stats charts.
///
/// The axis is deliberately unit-agnostic: the duration chart uses minutes and
/// the sleep-window chart can use minutes since 18:00. The painter only needs
/// [fractionFor] to place a value between the plot baseline and its top.
class ChartAxis {
  const ChartAxis({required this.min, required this.max, required this.ticks});

  final double min;
  final double max;

  /// Grid lines and their labels, from the baseline up.
  final List<ChartTick> ticks;

  /// Where [value] sits between [min] and [max], clamped to 0..1.
  double fractionFor(double value) {
    if (max <= min) return 0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}
