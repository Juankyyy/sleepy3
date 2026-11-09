import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Turns a chart canvas into one scrub target.
///
/// A tap or drag selects the nearest slot along [axis]; a pointer up, a tap
/// outside the current gesture or a drag end clears the selection. Only one
/// selection exists per chart, so there is never more than one tooltip.
class ChartScrubArea extends StatefulWidget {
  const ChartScrubArea({
    super.key,
    required this.slotCount,
    required this.onSelectionChanged,
    required this.child,
    this.axis = Axis.horizontal,
    this.enabled = true,
    this.enableHaptics = true,
  });

  final int slotCount;
  final ValueChanged<int?> onSelectionChanged;
  final Widget child;
  final Axis axis;
  final bool enabled;

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
        return Listener(
          onPointerUp: (_) => _clear(),
          onPointerCancel: (_) => _clear(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.enabled
                ? (details) => _select(details.localPosition, size)
                : null,
            onHorizontalDragStart:
                widget.enabled && widget.axis == Axis.horizontal
                ? (details) => _select(details.localPosition, size)
                : null,
            onHorizontalDragUpdate:
                widget.enabled && widget.axis == Axis.horizontal
                ? (details) => _select(details.localPosition, size)
                : null,
            onHorizontalDragEnd:
                widget.enabled && widget.axis == Axis.horizontal
                ? (_) => _clear()
                : null,
            onHorizontalDragCancel:
                widget.enabled && widget.axis == Axis.horizontal
                ? _clear
                : null,
            onVerticalDragStart: widget.enabled && widget.axis == Axis.vertical
                ? (details) => _select(details.localPosition, size)
                : null,
            onVerticalDragUpdate: widget.enabled && widget.axis == Axis.vertical
                ? (details) => _select(details.localPosition, size)
                : null,
            onVerticalDragEnd: widget.enabled && widget.axis == Axis.vertical
                ? (_) => _clear()
                : null,
            onVerticalDragCancel: widget.enabled && widget.axis == Axis.vertical
                ? _clear
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

    final fraction = widget.axis == Axis.horizontal
        ? position.dx / size.width
        : position.dy / size.height;
    final index = (fraction * widget.slotCount)
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
