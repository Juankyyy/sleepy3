import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/updates/domain/app_release.dart';
import 'package:sleepy3/features/updates/domain/update_prompt_action.dart';
import 'package:sleepy3/features/updates/presentation/update_available_dialog.dart';
import 'package:sleepy3/l10n/l10n.dart';

import '../fakes.dart';

class _DialogResult {
  UpdatePromptAction? result;
  bool completed = false;
}

void main() {
  Future<_DialogResult> pumpDialog(
    WidgetTester tester, {
    AppRelease? release,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final state = _DialogResult();
    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      M3EMaterialApp(
        title: 'Sleepy3',
        data: data,
        theme: data.toThemeData(),
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  state.result = await M3EDialog.show<UpdatePromptAction>(
                    context,
                    dialog: UpdateAvailableDialog(
                      release: release ?? testRelease('0.4.0'),
                    ),
                  );
                  state.completed = true;
                },
                child: const Text('Open update'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open update'));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('renders the release, summary and every action', (tester) async {
    await pumpDialog(tester);

    expect(find.text('New version available'), findsOneWidget);
    expect(find.text('Sleepy3 0.4.0 · The Test Update'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Test release 0.4.0.'), findsOneWidget);
    expect(find.text('View on GitHub'), findsOneWidget);
    expect(find.text("Don't remind me again"), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.byIcon(M3EIcons.close), findsOneWidget);
  });

  testWidgets('the close button snoozes the dialog', (tester) async {
    final state = await pumpDialog(tester);

    await tester.tap(find.byIcon(M3EIcons.close));
    await tester.pumpAndSettle();

    expect(state.completed, isTrue);
    expect(state.result, UpdatePromptAction.snooze);
  });

  testWidgets('No recordar dismisses the version', (tester) async {
    final state = await pumpDialog(tester);

    await tester.tap(find.text("Don't remind me again"));
    await tester.pumpAndSettle();

    expect(state.completed, isTrue);
    expect(state.result, UpdatePromptAction.dismissVersion);
  });

  testWidgets('Download and GitHub return their actions', (tester) async {
    final download = await pumpDialog(tester);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(download.completed, isTrue);
    expect(download.result, UpdatePromptAction.download);

    final github = await pumpDialog(tester);
    await tester.tap(find.text('View on GitHub'));
    await tester.pumpAndSettle();
    expect(github.completed, isTrue);
    expect(github.result, UpdatePromptAction.openRelease);
  });

  testWidgets('a barrier tap returns null so the caller snoozes', (
    tester,
  ) async {
    final state = await pumpDialog(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(state.completed, isTrue);
    expect(state.result, isNull);
  });

  testWidgets('fits at 200% text and renders in Spanish', (tester) async {
    await pumpDialog(tester, textScale: 2, locale: const Locale('es'));

    expect(find.text('Nueva versión disponible'), findsOneWidget);
    expect(find.text('Sleepy3 0.4.0 · The Test Update'), findsOneWidget);
    expect(find.text('Novedades'), findsOneWidget);
    expect(find.text('Ver en GitHub'), findsOneWidget);
    expect(find.text('No recordar otra vez'), findsOneWidget);
    expect(find.text('Descargar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
