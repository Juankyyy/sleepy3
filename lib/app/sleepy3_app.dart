import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/sleepy3_theme.dart';
import '../features/sleep_tracking/presentation/sleep_home_screen.dart';

class Sleepy3App extends StatelessWidget {
  const Sleepy3App({super.key});

  @override
  Widget build(BuildContext context) {
    return M3EMaterialApp(
      title: 'Sleepy3',
      data: Sleepy3Theme.light(),
      autoTheming: true,
      dynamicColoring: true,
      drawUnderSystemBars: true,
      locale: const Locale('es', 'CO'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'CO'), Locale('en', 'US')],
      home: const SleepHomeScreen(),
    );
  }
}
