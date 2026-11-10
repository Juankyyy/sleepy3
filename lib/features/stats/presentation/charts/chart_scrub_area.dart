import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Turns a chart canvas into one scrub target.
///
/// A tap or drag selects the nearest slot along [axis] and shows its tooltip.
/// The selection stays after the pointer is released and only clears when the
/// user taps outside the chart. Only one selection exists per chart, so there
/// is never more than one tooltip.
class ChartScrubArea extends StatefulWidget {
  const ChartScrubArea({
    super.key,
    required this.slotCount,
    required this.onSelectionChanged,
    required this.child,
    this.axis = Axis.horizontal,
    this.enabled = true,
    this.dragEnabled = true,
    this.enableHaptics = true,
    this.selectionInsets = EdgeInsets.zero,
  });

  final int slotCount;
  final ValueChanged<int?> onSelectionChanged;
  final Widget child;
  final Axis axis;
  final bool enabled;

  /// Whether dragging changes the selection.
  ///
  /// Charts with one row per bucket sit inside the Stats scroll view; a
  /// vertical drag there would fight the scroll gesture, so those charts select
  /// with a tap and turn the drag off.
  final bool dragEnabled;

  /// The part of the child that maps to the slots, in widget coordinates.
  ///
  /// Charts use it to skip the Y-axis gutter and the plot insets instead of
  /// mapping taps across the whole canvas.
  final EdgeInsets selectionInsets;

  /// A product decision: a short selection click when the slot changes.
  final bool enableHaptics;

  @override
  State<ChartScrubArea> createState() => _ChartScrubAreaState();
}

class _ChartScrubAreaState extends State<ChartScrubArea> {
  int? _selection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return TapRegion(
          onTapOutside: (_) => _clear(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.enabled
                ? (details) => _select(details.localPosition, size)
                : null,
            onHorizontalDragStart:
                widget.enabled &&
                    widget.dragEnabled &&
                    widget.axis == Axis.horizontal
                ? (details) => _select(details.localPosition, size)
                : null,
            onHorizontalDragUpdate:
                widget.enabled &&
                    widget.dragEnabled &&
                    widget.axis == Axis.horizontal
                ? (details) => _select(details.localPosition, size)
                : null,
            onVerticalDragStart:
                widget.enabled &&
                    widget.dragEnabled &&
                    widget.axis == Axis.vertical
                ? (details) => _select(details.localPosition, size)
                : null,
            onVerticalDragUpdate:
                widget.enabled &&
                    widget.dragEnabled &&
                    widget.axis == Axis.vertical
                ? (details) => _select(details.localPosition, size)
                : null,
            child: widget.child,
          ),
        );
      },
    );
  }

  void _select(Offset position, Size size) {
    if (widget.slotCount <= 0) return;
    if (size.width <= 0 || size.height <= 0) return;

    final usable = Rect.fromLTRB(
      widget.selectionInsets.left,
      widget.selectionInsets.top,
      math.max(
        widget.selectionInsets.left + 1,
        size.width - widget.selectionInsets.right,
      ),
      math.max(
        widget.selectionInsets.top + 1,
        size.height - widget.selectionInsets.bottom,
      ),
    );
    final fraction = widget.axis == Axis.horizontal
        ? (position.dx - usable.left) / usable.width
        : (position.dy - usable.top) / usable.height;
    final index = (fraction.clamp(0.0, 0.999999) * widget.slotCount)
        .floor()
        .clamp(0, widget.slotCount - 1)
        .toInt();

    if (index == _selection) return;
    _selection = index;
    if (widget.enableHaptics) unawaited(HapticFeedback.selectionClick());
    widget.onSelectionChanged(index);
  }

  void _clear() {
    if (_selection == null) return;
    _selection = null;
    widget.onSelectionChanged(null);
  }
}
