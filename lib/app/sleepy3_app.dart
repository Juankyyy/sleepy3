import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/sleepy3_theme.dart';
import '../features/sleep_tracking/presentation/sleep_home_screen.dart';

/// Runs the app with the Sleepy3 scheme for the current system brightness.
///
/// Brightness is resolved here instead of through `M3EMaterialApp.autoTheming`
/// because that path derives its dark template from the light primary. Sleepy3
/// generates light and dark independently from the same seed, so the resolved
/// scheme is handed to `M3EMaterialApp` as both the expressive data and the
/// Material theme.
class Sleepy3App extends StatefulWidget {
  const Sleepy3App({super.key});

  @override
  State<Sleepy3App> createState() => _Sleepy3AppState();
}

class _Sleepy3AppState extends State<Sleepy3App> with WidgetsBindingObserver {
  late Brightness _brightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness != _brightness) {
      setState(() => _brightness = brightness);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Sleepy3Theme.forBrightness(_brightness);

    return M3EMaterialApp(
      title: 'Sleepy3',
      data: data,
      theme: data.toThemeData(),
      darkTheme: data.toThemeData(),
      autoTheming: false,
      dynamicColoring: false,
      drawUnderSystemBars: true,
      locale: const Locale('en', 'US'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en', 'US')],
      home: const SleepHomeScreen(),
    );
  }
}
