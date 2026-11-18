import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../appearance_labels.dart';
import '../appearance_page.dart';
import '../../application/language_controller.dart';
import '../../application/theme_mode_controller.dart';
import '../../application/time_format_controller.dart';
import 'bento/bento_card.dart';
import 'bento/bento_figure.dart';
import 'bento/settings_tones.dart';

/// The appearance summary card.
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tone = SettingsPalette.of(context).appearance;
    final mode = ref.watch(themeModeControllerProvider);
    final timeFormat = ref.watch(timeFormatControllerProvider);
    final language = ref.watch(languageControllerProvider);
    final support =
        '${themeModeLabel(l10n, mode)} · '
        '${timeFormatLabel(l10n, timeFormat)} · '
        '${languageLabel(l10n, language)}';

    return BentoCard(
      key: const ValueKey('settings-appearance-card'),
      tone: tone,
      size: BentoCardSize.half,
      icon: M3EIcons.palette_outlined,
      figure: BentoFigureShape.cookie7Sided,
      title: l10n.appearance,
      supporting: support,
      semanticLabel: '${l10n.appearance}. $support',
      trailing: Icon(M3EIcons.chevron_right, size: 20, color: tone.supporting),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AppearancePage()));
      },
    );
  }
}
