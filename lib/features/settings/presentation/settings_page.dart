import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/sleepy3_theme.dart';

/// A secondary Settings page with a back button and the page title.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final margin = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(margin, 8, margin, 24 + bottomInset),
          children: [
            Row(
              children: [
                M3EIconButton(
                  key: const ValueKey('settings-page-back'),
                  icon: const Icon(M3EIcons.arrow_back),
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.md,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  semanticLabel: MaterialLocalizations.of(context)
                      .backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Sleepy3Theme.brandTitle(
                        theme.typography.emphasized.headlineMedium,
                      ).copyWith(color: scheme.onSurface),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
