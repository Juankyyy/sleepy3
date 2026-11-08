import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../health/presentation/sleep_data_source_text.dart';
import '../../domain/app_version.dart';
import 'settings_list.dart';

/// Privacy, version and the license page entry.
class AboutList extends StatelessWidget {
  const AboutList({
    super.key,
    this.version,
    this.dataSource = SleepDataSource.local,
  });

  final AppVersion? version;
  final SleepDataSource dataSource;

  @override
  Widget build(BuildContext context) {
    final appVersion = version;
    final l10n = context.l10n;
    final showLeading = showSettingsLeadingIcons(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsList(
          children: [
            M3EListItem(
              leading: showLeading
                  ? const Icon(M3EIcons.shield_outlined)
                  : null,
              headline: l10n.privacy,
              supportingText: l10n.sleepDataSourcePrivacy(dataSource),
            ),
            if (appVersion != null)
              M3EListItem(
                leading: showLeading ? const Icon(M3EIcons.info_outline) : null,
                headline: l10n.version,
                supportingText: appVersion.display,
              ),
          ],
        ),
        // The actionable row needs its own list because M3EList owns row taps.
        const SizedBox(height: 2),
        SettingsList(
          onTap: (_) => _showLicenses(context, appVersion),
          children: [
            M3EListItem(
              leading: showLeading
                  ? const Icon(M3EIcons.description_outlined)
                  : null,
              headline: l10n.licenses,
            ),
          ],
        ),
      ],
    );
  }

  void _showLicenses(BuildContext context, AppVersion? appVersion) {
    showLicensePage(
      context: context,
      applicationName: 'Sleepy3',
      applicationVersion: appVersion?.display,
      applicationLegalese: 'GNU General Public License v3.0',
    );
  }
}
