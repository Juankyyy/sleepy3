# Agent instructions

## Project

Sleepy3 is a Flutter Android app for zero-friction sleep tracking: two large buttons
(Sleep / Wake), a home-screen widget, local session history, and Health Connect sync.

- Flutter stable 3.47.x / Dart 3.13.x, Android only, `minSdk` 28.
- The previous native Android prototype is archived at Git tag
  `archive/android-prototype`; do not restore it unless the user asks.
- The Flutter app UI lives in `lib/`. The home-screen widget is native Kotlin/Glance
  under `android/app/src/main/kotlin/com/sleepy3/app/`.
- Platform features that cannot run in Flutter (the widget, Health Connect manifest
  entries) stay in the Android layer behind small, documented bridges.
- Current state: the home screen, sleep state machine, Drift persistence, Stats history
  and Settings work. The Glance widget and Health Connect are next. Sessions and the
  theme preference are stored in `sleepy3.sqlite` (schema v2); generated Drift code is
  committed.

## Commands

Run from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run

dart format .
dart run build_runner build
```

Hot reload: run `flutter run` and press `r`; no Android Studio is required.

## Architecture

Target structure:

```text
lib/
├── main.dart
├── app/                 # MaterialApp, routing, dependency wiring
├── core/theme/          # Material 3 theme and design tokens
└── features/
    ├── sleep_tracking/  # domain, data, application, presentation
    ├── stats/           # presentation
    ├── settings/        # theme, app version, about and preferences
    ├── health/          # Health Connect permissions and sync
    └── widget/          # home_widget bridge and pending events
```

- UI imports: use `package:material_ui/material_ui.dart` and
  `package:material_3_expressive/material_3_expressive.dart`; do not import
  `package:flutter/material.dart` in app code.
- `material_ui` is pinned to 1.7.0 because 1.8.0's `RoundedPolygon` conflicts with
  `material_new_shapes` used by `material_3_expressive` 1.1.7. Do not bump it until
  the packages are compatible.
- State management: Riverpod.
- Local persistence: Drift over SQLite. The schema lives in
  `lib/features/sleep_tracking/data/sleepy3_database.dart` and the generated
  `.g.dart` file is committed. Bump `schemaVersion` and add a migration before
  changing an existing column. Settings use the same database through the
  `preferences` key/value table; do not add `shared_preferences`.
- Theme: `ThemeModeController` owns `System` / `Light` / `Dark`; `Sleepy3App`
  resolves the brightness with the fixed Sleepy3 schemes. Keep
  `M3EMaterialApp.autoTheming` disabled.
- App version: load `package_info_plus` before `runApp`; `appVersionProvider` is null
  when the platform cannot provide it and Settings hides the row.
- Background work: WorkManager for Flutter.
- The widget uses `home_widget` and native Jetpack Glance. Widget taps are written to
  a pending-events queue and reconciled by the Flutter app on launch/resume.
- Keep time-dependent logic testable by injecting a clock; never call
  `DateTime.now()` directly in domain logic that has tests.

## Material Design 3 / M3 Expressive

The M3 spec lives at `.agent-skills/m3-expressive/`.

Before writing or reviewing any Material Design UI (components, dp values, corner radii,
motion springs, type styles, color roles, adaptive layouts), read
`.agent-skills/m3-expressive/SKILL.md` and follow its "Where to look" table into the
specific reference file.

Never state a number, token name, or component name from memory. Look it up:
- exact values (type scale, radii, springs, elevation) -> `references/tokens.md`
- per-component dp geometry -> `references/component-tokens.md`
- component behavior, variants, do/don'ts -> `references/components/*.md`
- platform API availability -> `references/platforms.md`

If a value genuinely isn't in M3, say so and label it "my design decision (not in M3)"
rather than presenting it as spec.

## Convenciones

- **Idioma**: código, comentarios, mensajes de commit, la UI y notas de release en **inglés**
- **Commits**: convencionales, en inglés, con scope (`feat(ui): …`, `fix(core): …`,
  `docs(spec): …`, `chore`, `ci`, `refactor`).

## Flujo de trabajo (acordado con el usuario)

Detalle completo en `SPEC.md §1`.

1. Todo el trabajo nuevo en la rama `dev`; `main` permanece estable.
2. **Paso a paso**: espera a que el usuario pida módulos o cambios concretos; no generes la
   app entera de golpe. Al terminar, indica qué debe probar el usuario.
3. **Aviso previo**: no se hacen commits ni pushes sin avisar antes. Propón el mensaje y
   espera el OK. «Haz los commits» autoriza commit **y push a `dev`** a la vez: el trabajo
   nunca se queda solo en local.
4. **`main` y releases, solo a petición**: el merge a `main` y los tags se hacen únicamente
   cuando el usuario lo pide, tras verificar el bloque/funcionalidad en su máquina.
5. **Releases**: el usuario decide la versión; el tag `vX.Y.Z` se corta desde `main`. El
   workflow planificado de GitHub Actions (SPEC §1) publicará el instalador con notas
   autogeneradas. Las notas curadas viven solo en local (`release-notes/`, ignorado por
   git) y se aplican después con `gh release edit --notes-file`.
6. **Documentación como parte del cambio**: actualiza SPEC.md si cambia el comportamiento o
   la arquitectura, y README.md si el cambio es visible para el usuario.
