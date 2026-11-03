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
  entries, app labels) stay in the Android layer behind small, documented bridges.
- Current state: v0.1.0 is the first stable release (without the home-screen widget). The
  home screen, sleep state machine, Drift persistence, Stats history with session
  editing/deleting, Settings, Health Connect (Local/Google Health, pending uploads, copy
  actions and full history access), the branded launcher icon and splash, and the
  manual release workflow work. The Glance widget is the next milestone (0.2.0).
  Sessions, preferences and Health Connect metadata live in `sleepy3.sqlite` (schema v5);
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
dart run tool/generate_brand_assets.dart         # launcher icons and splash mark
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
- Type: Space Grotesk (`wght` 300–700 only) covers the M3 scale. The live clock uses it
  at 700 through `Sleepy3Theme.clock`; M3's emphasized `displayLarge` is 500, so the
  weight is a design decision. The home brand and the Stats/Settings page titles use
  `GoogleSansFlexTitles`, an instanced Google Sans Flex with `wght` 900, `wdth` 112.5
  and `ROND` 35 baked in and only `opsz` live (28–32). Apply it through
  `Sleepy3Theme.brandTitle`; those axes are also a design decision outside M3
  (emphasized styles top out at 700). See `assets/fonts/README.md`.
- Brand assets live in `assets/brand/`. The launcher mipmaps, the adaptive icon XML, the
  Android 12+ `drawable*/launch_mark.png` sprites and `Sleepy3-mark.png` are generated with
  `dart run tool/generate_brand_assets.dart`; the splash itself is
  `lib/app/splash_gate.dart`. Keep the native launch colors in `values/colors.xml` and
  `values-night/colors.xml` equal to `Sleepy3Theme.lightBackground` and
  `Sleepy3Theme.darkBackground`.
- The native splash follows the app theme on Android 12+ through
  `UiModeManager.setApplicationNightMode`. `AppNightModeBridge` (Kotlin) and
  `AndroidAppNightMode` (Dart) keep it in sync at startup and whenever the theme changes;
  do not replace it with a system-only check.
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
  In Local, only rows owned by Sleepy3 can be edited or deleted; downloaded copies are
  read-only. In Google Health, Sleepy3 records are editable with or without a local copy.
  Other apps' records are read-only. Every row opens the session; read-only sessions open
  a details view with locked fields and a card that names the source app.
- Health Connect: keep the platform behind `HealthConnectGateway`. Uploads and edits use
  the stable `clientRecordId = sleepy3-<startedAtMillis>` with an increasing
  `clientRecordVersion`; only `origin='local'` rows are written. Editing a synced session
  updates the same record, never a duplicate. Without a local copy, the native
  `HealthConnectBridge` reads the record's client id and version first; records from other
  packages stay read-only. Downloads deduplicate by `healthRecordId` and exact start/end
  times, only update `origin='healthConnect'` rows, never delete or overwrite local rows
  and store the writer package in `source_id`. Without `READ_HEALTH_DATA_HISTORY`, reads
  stop at 30 days and the UI says so.
- Editing: `sleep_session_edit_service.dart` decides whether Health Connect or the local
  row goes first, validates the draft through `session_edit.dart` and returns an explicit
  result for the editor. In Google Health, a record without a local copy goes through
  `HealthConnectGateway.updateSleepSession`. The editor lives in
  `lib/features/stats/presentation/widgets/session_editor.dart`; the tracking controller
  updates `closedSessions` in memory without reloading the history. Read-only sessions
  reuse the editor content with static fields, no Save/Delete and a `Read-only session`
  card above `Fell asleep`; `AppInfoBridge` resolves the source app label and falls back
  to `another app`.
- Retries: pending uploads are retried on launch/resume by `Sleepy3App`; copy actions are
  explicit and never change the selected source. In Local, automatic retries only update
  sessions that already have a Health Connect record and never upload new ones. In Google
  Health, all pending sessions are retried. WorkManager is reserved for future background
  work.
- Theme: `ThemeModeController` owns `System` / `Light` / `Dark`; `Sleepy3App`
  resolves the brightness with the fixed Sleepy3 schemes. The palette is fixed:
  light body `#EFF4F9` with `#252B81` primary, dark body `#121318` with `#C6CCF7`
  primary. Keep `M3EMaterialApp.autoTheming` disabled and do not add dynamic color.
- App version: load `package_info_plus` before `runApp`; `appVersionProvider` is null
  when the platform cannot provide it and Settings hides the row.
- Debug builds use `com.sleepy3.app.debug` (label `Sleepy3 Debug`, `-debug` version
  suffix) so they coexist with signed release APKs. Do not remove the suffix.
- The widget uses `home_widget` and native Jetpack Glance. Widget taps are written to
  a pending-events queue and reconciled by the Flutter app on launch/resume.
- Keep time-dependent logic testable by injecting a clock; never call
  `DateTime.now()` directly in domain logic that has tests.

## Material Design 3 / M3 Expressive

The M3 spec lives at `.agent-skills/m3-expressive/`. It is not auto-loaded: open it on
every task that touches UI, even a one-line change.

Before writing, reviewing or proposing any Material Design UI (components, dp values,
corner radii, motion springs, type styles, color roles, adaptive layouts, transitions),
do all three:

1. Read `.agent-skills/m3-expressive/SKILL.md` and follow its "Where to look" table into
   the specific reference file.
2. Read `references/visuals.md` and search `visuals/INDEX.tsv` **by caption, not by
   filename** for the component, pattern or layout at hand; open the resulting images
   (plain PNG/JPG files) before deciding composition, size or state styling.
3. Leave the trail: in the reply, name the reference files read and the image
   paths/captions used. A UI change without that trail is not finished.

Minimum images to open, by kind of work:

| Work | Images |
|---|---|
| using or restyling a component | anatomy + state grid in `visuals/components_<name>/` |
| any sizing/spacing decision | measurement spec in `components_*` or `styles_*` |
| new screen or layout change | `visuals/foundations_layout_canonical-examples/` or `foundations_layout_layout-overview/` |
| type scale or emphasis | `visuals/styles_typography/` |
| color role or contrast | `visuals/styles_color_roles/`, `styles_color_system/` |
| reviewing an existing design | do/don't pairs (`grep -i "don't" visuals/INDEX.tsv`) |

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

1. Todo el trabajo nuevo en la rama `dev`. Hacer push a `dev` **no publica nada**: las
   releases son manuales. `main` permanece estable y **solo se toca con autorización
   explícita del usuario**.
2. **Paso a paso**: espera a que el usuario pida módulos o cambios concretos; no generes la
   app entera de golpe. Al terminar, indica qué debe probar el usuario.
3. **Aviso previo**: no se hacen commits ni pushes sin avisar antes. Propón el mensaje y
   espera el OK. «Haz los commits» autoriza commit **y push a `dev`** a la vez, sin lanzar
   ninguna release: el trabajo nunca se queda solo en local.
4. **`main` y releases, solo a petición**: el merge o push a `main` se hace únicamente
   cuando el usuario lo pide, tras verificar el bloque/funcionalidad en su máquina. El
   agente nunca toca `main` por iniciativa propia, ni siquiera con «Haz los commits». Ese
   push **no publica nada**. La release se lanza después, solo cuando el usuario lo pide y
   elige la versión: `minor` (`v0.X.0`) o `patch` (`v0.X.Y`). Antes de ejecutar, el agente
   confirma el tag calculado; en minors, también propone el `<Tema>` y espera el OK (y en
   patches con notas curadas).
5. **Versiones y notas**: no se toca `pubspec.yaml`; el CI calcula versión y versionCode
   desde el tag más alto y crea el tag al publicar. Las releases se lanzan a mano desde
   `main` con `.github/workflows/release.yml` (`bump=minor` o `bump=patch`). Tras publicar,
   escribir `release-notes/vX.Y.Z.md` con el título en la primera línea y ejecutar
   `dart run tool/apply_release_notes.dart vX.Y.Z`. La firma usa los secrets del repo; si
   faltan, el workflow falla.
6. **Documentación como parte del cambio**: actualiza SPEC.md si cambia el comportamiento o
   la arquitectura, y README.md si el cambio es visible para el usuario.
