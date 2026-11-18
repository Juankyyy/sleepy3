import 'package:flutter/services.dart';
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
  setUpAll(() async {
    // Use the production metrics so the action row is measured with the same
    // font as the app.
    final loader = FontLoader('SpaceGrotesk');
    loader.addFont(
      rootBundle.load('assets/fonts/SpaceGrotesk-VariableFont.ttf'),
    );
    await loader.load();
  });

  Finder actionButton(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(M3EButton),
    );
  }

  Future<_DialogResult> pumpDialog(
    WidgetTester tester, {
    AppRelease? release,
    String? installedVersion = '0.3.2',
    double textScale = 1,
    Locale locale = const Locale('en'),
    Future<bool> Function(Uri uri)? onOpenLink,
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
                      installedVersion: installedVersion,
                      onOpenLink: onOpenLink ?? (_) async => true,
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
    // The version sheen loops while the dialog is open, so pumpAndSettle
    // would never finish. A fixed pump lets the route entrance settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    return state;
  }

  testWidgets('renders the version range, full notes and every action', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('New version available'), findsOneWidget);
    expect(find.text('v0.3.2'), findsOneWidget);
    expect(find.text(' → '), findsOneWidget);
    expect(find.text('v0.4.0'), findsOneWidget);
    expect(find.text(' · The Test Update'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Test release 0.4.0.'), findsOneWidget);
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('First change.'), findsOneWidget);
    expect(find.text('View on GitHub'), findsOneWidget);
    expect(find.text("Don't remind me again"), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.byIcon(M3EIcons.close), findsOneWidget);
  });

  testWidgets('mutes the installed version and emphasizes the target', (
    tester,
  ) async {
    await pumpDialog(tester);

    final previous = tester.widget<Text>(find.text('v0.3.2'));
    final arrow = tester.widget<Text>(find.text(' → '));
    final target = tester.widget<Text>(find.text('v0.4.0'));

    expect(previous.style!.color!.a, closeTo(0.8, 0.001));
    expect(arrow.style!.color!.a, closeTo(0.8, 0.001));
    expect(target.style!.color!.a, closeTo(1, 0.001));
    expect(target.style!.fontWeight, FontWeight.w500);
  });

  testWidgets('applies the sheen to the title and the glow to the target', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(
      find.ancestor(
        of: find.text('New version available'),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('v0.4.0'), matching: find.byType(ShaderMask)),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('v0.3.2'), matching: find.byType(ShaderMask)),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('update-target-version')), findsOneWidget);
  });

  testWidgets('breathes the primary glow on the target version', (
    tester,
  ) async {
    await pumpDialog(tester);

    Color? targetColor() {
      return tester
          .widget<Text>(find.byKey(const ValueKey('update-target-version')))
          .style!
          .color;
    }

    final before = targetColor();
    await tester.pump(const Duration(milliseconds: 750));
    final after = targetColor();
    final target = tester.widget<Text>(
      find.byKey(const ValueKey('update-target-version')),
    );

    expect(after, isNot(before));
    expect(target.style!.shadows, isNotNull);
    expect(target.style!.shadows!.single.color.a, greaterThan(0));
  });

  testWidgets(
    'disables the title sheen and target glow when animations are removed',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpDialog(tester);

      final target = tester.widget<Text>(
        find.byKey(const ValueKey('update-target-version')),
      );

      expect(find.byType(ShaderMask), findsNothing);
      expect(target.style!.shadows, isNull);
      expect(find.text('v0.4.0'), findsOneWidget);
    },
  );

  testWidgets('frames the notes body on the dim surface', (tester) async {
    await pumpDialog(tester);

    final theme = Sleepy3Theme.light();
    final body = tester.widget<Container>(
      find.byKey(const ValueKey('update-dialog-body')),
    );
    final decoration = body.decoration! as BoxDecoration;
    final bodyText = tester.widget<Text>(find.text('Test release 0.4.0.'));

    expect(decoration.color, theme.colorScheme.surfaceDim);
    expect(decoration.borderRadius, BorderRadius.circular(20));
    expect(
      (decoration.border! as Border).top.color,
      theme.colorScheme.outlineVariant,
    );
    expect(body.clipBehavior, Clip.antiAlias);
    expect(bodyText.style!.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('caps the dialog height while the notes scroll', (tester) async {
    final notes = [
      for (var index = 0; index < 20; index++)
        '## Section $index\n\nParagraph $index.',
    ].join('\n\n');

    await pumpDialog(tester, release: testRelease('0.4.0', notes: notes));

    final height = tester.getSize(find.byType(UpdateAvailableDialog)).height;

    expect(height, lessThanOrEqualTo(800 * 0.85 + 0.1));
    expect(find.text('New version available'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('falls back to the target version without an installed one', (
    tester,
  ) async {
    await pumpDialog(tester, installedVersion: null);

    expect(find.text('v0.4.0'), findsOneWidget);
    expect(find.text(' · The Test Update'), findsOneWidget);
  });

  testWidgets('aligns the filled download to the right of the opt-out', (
    tester,
  ) async {
    await pumpDialog(tester);

    final download = actionButton('Download');
    final optOut = actionButton("Don't remind me again");

    expect(tester.widget<M3EButton>(download).style, M3EButtonStyle.filled);
    expect(tester.widget<M3EButton>(optOut).style, M3EButtonStyle.text);
    expect(
      tester.getCenter(download).dy,
      closeTo(tester.getCenter(optOut).dy, 1),
    );
    expect(
      tester.getRect(download).right,
      greaterThan(tester.getRect(optOut).right),
    );
  });

  testWidgets('stacks the actions to the trailing edge at 200%', (
    tester,
  ) async {
    await pumpDialog(tester, textScale: 2);

    final download = actionButton('Download');
    final optOut = actionButton("Don't remind me again");
    final downloadRect = tester.getRect(download);
    final optOutRect = tester.getRect(optOut);

    expect(downloadRect.center.dy, lessThan(optOutRect.center.dy));
    expect(downloadRect.right, closeTo(optOutRect.right, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls the notes while the title and actions stay pinned', (
    tester,
  ) async {
    final notes = [
      'Intro paragraph.',
      for (var index = 0; index < 14; index++)
        '## Section $index\n\nParagraph $index.',
      '**Full changelog**: https://example.com/full',
    ].join('\n\n');

    await pumpDialog(tester, release: testRelease('0.4.0', notes: notes));

    final titleBefore = tester.getTopLeft(find.text('New version available'));
    final actionsBefore = tester.getTopLeft(find.text('Download'));
    final body = find.descendant(
      of: find.byType(UpdateAvailableDialog),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.text('Section 13'),
      200,
      scrollable: body,
    );
    await tester.pump();

    expect(tester.getTopLeft(find.text('New version available')), titleBefore);
    expect(tester.getTopLeft(find.text('Download')), actionsBefore);
    expect(find.text('Section 13'), findsOneWidget);
  });

  testWidgets('opens notes links and reports a failure inline', (tester) async {
    final opened = <Uri>[];
    var result = true;

    await pumpDialog(
      tester,
      release: testRelease(
        '0.4.0',
        notes: '**Full changelog**: https://example.com/full',
      ),
      onOpenLink: (uri) async {
        opened.add(uri);
        return result;
      },
    );

    await tester.tapOnText(
      find.textRange.ofSubstring('https://example.com/full'),
    );
    await tester.pump();

    expect(opened, [Uri.parse('https://example.com/full')]);
    expect(find.text("Couldn't open the link. Try again."), findsNothing);

    result = false;
    await tester.tapOnText(
      find.textRange.ofSubstring('https://example.com/full'),
    );
    await tester.pump();

    expect(find.text("Couldn't open the link. Try again."), findsOneWidget);
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
    expect(find.text('v0.3.2'), findsOneWidget);
    expect(find.text(' → '), findsOneWidget);
    expect(find.text('v0.4.0'), findsOneWidget);
    expect(find.text(' · The Test Update'), findsOneWidget);
    expect(find.text('Novedades'), findsOneWidget);
    expect(find.text('Ver en GitHub'), findsOneWidget);
    expect(find.text('No recordar otra vez'), findsOneWidget);
    expect(find.text('Descargar'), findsOneWidget);

    final download = actionButton('Descargar');
    final optOut = actionButton('No recordar otra vez');
    expect(
      tester.getRect(download).right,
      closeTo(tester.getRect(optOut).right, 1),
    );
    expect(tester.takeException(), isNull);
  });
}
