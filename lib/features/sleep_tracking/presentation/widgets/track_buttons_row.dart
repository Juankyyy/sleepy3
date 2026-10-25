import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// The two primary actions. At most one is enabled at a time: when the user is
/// awake only "Sleep" is available, and while sleeping only "Wake" is.
///
/// From M3: extra-large buttons (136dp) in the square shape (28dp radius) with
/// a 40dp leading icon and the `filled` color mapping (`primary` /
/// `onPrimary`). Disabled buttons use the M3EButton disabled tokens.
/// My design decisions (not in M3): `labelLarge` text (14sp) instead of the
/// XL size's larger type role, and 16dp horizontal padding instead of the XL
/// token's 64dp, so two buttons fit side by side on a 360dp phone.
class TrackButtonsRow extends StatelessWidget {
  const TrackButtonsRow({
    super.key,
    required this.isSleeping,
    required this.onSleep,
    required this.onWake,
  });

  /// XL geometry with the layout padding adaptation described above.
  static final M3EButtonSize _buttonSize = M3EButtonSize.xl.copyWith(
    hPadding: 16,
  );

  final bool isSleeping;
  final VoidCallback onSleep;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        // M3 buttons keep their label whole. When the window is narrow or the
        // system text size is large, both actions stack so neither label is
        // truncated. The 320dp / 130% thresholds are layout decisions, not M3
        // tokens.
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
              // 12dp gap: a layout decision, not a component token.
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
      size: TrackButtonsRow._buttonSize,
      shape: M3EButtonShape.square,
      // Keep the standard button label role; M3EButton would otherwise apply
      // the larger type role that comes with the XL size.
      decoration: M3EButtonDecoration(
        textStyle: M3ETheme.of(context).typeScale.labelLarge,
      ),
      enabled: enabled,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
