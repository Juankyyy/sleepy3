import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// The two primary actions. At most one is enabled at a time: when the user is
/// awake only "Sleep" is available, and while sleeping only "Wake" is.
class TrackButtonsRow extends StatelessWidget {
  const TrackButtonsRow({
    super.key,
    required this.isSleeping,
    required this.onSleep,
    required this.onWake,
  });

  final bool isSleeping;
  final VoidCallback onSleep;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 320 || textScale > 1.3;

        final sleepButton = _TrackButton(
          label: 'Sleep',
          icon: M3EIcons.bedtime_rounded,
          enabled: !isSleeping,
          onPressed: onSleep,
        );
        final wakeButton = _TrackButton(
          label: 'Wake',
          icon: M3EIcons.wb_sunny_rounded,
          enabled: isSleeping,
          onPressed: onWake,
        );

        if (stack) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: sleepButton),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: wakeButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: sleepButton),
            // 12dp gap: a layout decision, not a component token.
            const SizedBox(width: 12),
            Expanded(child: wakeButton),
          ],
        );
      },
    );
  }
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return M3EButton.icon(
      style: M3EButtonStyle.filled,
      // M3 Expressive large button: 96dp tall. The lg token's 48dp side
      // padding leaves too little label room when two buttons share a 360dp
      // phone row; reducing it is a layout decision, not an M3 token.
      size: M3EButtonSize.lg.copyWith(hPadding: 16, iconGap: 8),
      enabled: enabled,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
