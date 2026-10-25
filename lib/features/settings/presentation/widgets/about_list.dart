import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/app_version.dart';
import 'settings_list.dart';

/// Privacy, version and the license page entry.
class AboutList extends StatelessWidget {
  const AboutList({super.key, this.version});

  final AppVersion? version;

  @override
  Widget build(BuildContext context) {
    final appVersion = version;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsList(
          children: [
            const M3EListItem(
              leading: Icon(M3EIcons.shield_outlined),
              headline: 'Privacy',
              supportingText: 'On-device only.',
            ),
            if (appVersion != null)
              M3EListItem(
                leading: const Icon(M3EIcons.info_outline),
                headline: 'Version',
                supportingText: appVersion.display,
              ),
          ],
        ),
        // The actionable row needs its own list because M3EList owns row taps.
        const SizedBox(height: 2),
        SettingsList(
          onTap: (_) => _showLicenses(context, appVersion),
          children: [
            const M3EListItem(
              leading: Icon(M3EIcons.description_outlined),
              headline: 'Licenses',
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
