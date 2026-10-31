# Agent instructions

## Project

Sleepy3 is a Flutter Android app for zero-friction sleep tracking: two large buttons
(Sleep / Wake), a home-screen widget, local session history, and Health Connect as an
optional data source.

- Flutter stable 3.47.x / Dart 3.13.x, Android only, `minSdk` 28.
- The previous native Android prototype is archived at Git tag
  `archive/android-prototype`; do not restore it unless the user asks.
- The Flutter app UI lives in `lib/`. The home-screen widget is native Kotlin/Glance
  under `android/app/src/main/kotlin/com/sleepy3/app/`.
- Platform features that cannot run in Flutter (the widget, Health Connect manifest
  entries) stay in the Android layer behind small, documented bridges.
- Current state: the home screen, sleep state machine, Drift persistence, Stats history,
  Settings, Health Connect (Local/Google Health, pending uploads, copy actions and full
  history access) and the two-channel release workflow work. The Glance widget is next.
  Sessions, preferences and Health Connect metadata live in `sleepy3.sqlite` (schema v3);
  generated Drift code is committed.

## Commands

Run from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run

dart format .
dart run build_runner build
dart run tool/apply_release_notes.dart vX.Y.Z   # curated notes for a stable release
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
    ├── health/          # sources, Health Connect gateway, sync, copy, history access
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
- Sleep data source: `Local` (default) reads only Drift; `Google Health` reads all
  `SLEEP_SESSION` records from Health Connect. Never mix the two lists. The open
  session and every finished session are always written locally first as a safety copy.
- Health Connect: keep the platform behind `HealthConnectGateway`. Uploads use the stable
  `clientRecordId = sleepy3-<startedAtMillis>` and only send `origin='local'` rows that
  are pending. Downloads deduplicate by `healthRecordId` and exact start/end times, only
  update `origin='healthConnect'` rows and never delete or overwrite local rows. Without
  `READ_HEALTH_DATA_HISTORY`, reads stop at 30 days and the UI says so.
- Retries: pending uploads are retried on launch/resume by `Sleepy3App`; copy actions are
  explicit and never change the selected source. WorkManager is reserved for future
  background work.
- Theme: `ThemeModeController` owns `System` / `Light` / `Dark`; `Sleepy3App`
  resolves the brightness with the fixed Sleepy3 schemes. Keep
  `M3EMaterialApp.autoTheming` disabled.
- App version: load `package_info_plus` before `runApp`; `appVersionProvider` is null
  when the platform cannot provide it and Settings hides the row.
- Debug builds use `com.sleepy3.app.debug` (label `Sleepy3 Debug`, `-debug` version
  suffix) so they coexist with signed release APKs. Do not remove the suffix.
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

1. Todo el trabajo nuevo en la rama `dev`; cada push a `dev` publica una pre-release
   automática (`v0.X.Y`). `main` permanece estable y **solo se toca con autorización
   explícita del usuario**.
2. **Paso a paso**: espera a que el usuario pida módulos o cambios concretos; no generes la
   app entera de golpe. Al terminar, indica qué debe probar el usuario.
3. **Aviso previo**: no se hacen commits ni pushes sin avisar antes. Propón el mensaje y
   espera el OK. «Haz los commits» autoriza commit **y push a `dev`** a la vez: el trabajo
   nunca se queda solo en local.
4. **`main` y releases estables, solo a petición**: el merge o push a `main` se hace
   únicamente cuando el usuario lo pide, tras verificar el bloque/funcionalidad en su
   máquina. El agente nunca toca `main` por iniciativa propia, ni siquiera con «Haz los
   commits». Ese push publica automáticamente la minor estable (`v0.X.0`).
5. **Versiones y notas**: no se toca `pubspec.yaml`; el CI calcula versión y versionCode
   desde el tag más alto y crea el tag al publicar. Las notas de `dev` son automáticas. Tras
   una release estable, escribir `release-notes/vX.Y.0.md` con el título en la primera
   línea y ejecutar `dart run tool/apply_release_notes.dart vX.Y.0`. La firma usa los
   secrets del repo; si faltan, el workflow falla.
6. **Documentación como parte del cambio**: actualiza SPEC.md si cambia el comportamiento o
   la arquitectura, y README.md si el cambio es visible para el usuario.
