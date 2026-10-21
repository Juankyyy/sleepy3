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

## Commands

Run from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run

dart format .
dart run build_runner build --delete-conflicting-outputs
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
    ├── health/          # Health Connect permissions and sync
    └── widget/          # home_widget bridge and pending events
```

- State management: Riverpod.
- Local persistence: Drift over SQLite.
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
