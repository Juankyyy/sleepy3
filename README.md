# Sleepy3

**Zero-friction sleep tracking for Android: two buttons, no forms.**

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Min SDK](https://img.shields.io/badge/minSdk-28-blue)
![Material 3](https://img.shields.io/badge/Material_3-Expressive-4285F4)
![License](https://img.shields.io/badge/License-GPL--3.0-blue)

Tap **Sleep** when you go to bed. Tap **Wake** when you get up. Sleepy3 records the
exact times, keeps your sessions on your phone and stays out of your way: no forms, no
accounts, no onboarding.

## Why Sleepy3

- **Two taps, nothing to fill in.** One button starts the night, the other ends it.
  Sleepy3 stores the real start and end times, not a rounded guess.
- **Your data stays yours.** Sessions live in a local SQLite database. There is no
  backend, no account and no cloud of our own.
- **Designed for 3 a.m.** Large targets, one-hand use, light and dark themes, and a
  home-screen widget is on the way so you never have to open the app.

## Status

Sleepy3 is in early development at **v0.1.0**. The core loop is already usable: start
a night, close it, and find it intact after restarting the phone.

**Working today**

- Two-button home screen with a clear awake / sleeping state.
- Exact session times with a duration line for the last night.
- Local persistence; an open session survives the app being closed or killed.
- Material 3 Expressive theme with dynamic color on Android 12+.
- Accessible labels, visible focus and a layout that adapts to large text.

**Coming next**

- Home-screen widget to log Sleep / Wake without opening the app.
- Health Connect sync with background retry.
- Recent history with a 3-day summary.
- Motion and accessibility polish, then automated releases.

The native Android prototype that came before this app is preserved at the Git tag
`archive/android-prototype` for reference.

## Install

Sleepy3 is not on Google Play yet. Build the APK from source:

**Requirements**

- An Android device or emulator running Android 9 (API 28) or newer.
- Flutter 3.47.x stable (Dart 3.13).
- JDK 17 or newer.
- Android SDK and platform tools. Android Studio is not required.

```bash
flutter pub get
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Install it with
`adb install build/app/outputs/flutter-apk/app-release.apk`, or copy it to the phone and
open it.

> Release builds are currently signed with the debug keystore. That is fine for
> sideloading, but not ready for store distribution.

## Usage

1. Open Sleepy3 and tap **Sleep** when you go to bed.
2. Tap **Wake** when you get up.
3. The line under the title tells you what is happening.

| Situation | What you see |
|---|---|
| No session yet | `Tap Sleep to start` |
| Sleeping | `Sleeping since 23:41` |
| Back awake | `Last session: 7h 45m` |

Sleep is disabled while a session is open and Wake is disabled while you are awake, so a
double tap cannot corrupt the timeline. There are no confirmation dialogs: the action
happens the moment you tap.

## Privacy and your data

- Sessions are stored in `sleepy3.sqlite`, a SQLite database in the app's documents
  directory.
- There is no account, no backend and no analytics. Sleepy3 does not upload your sessions
  anywhere.
- Health Connect sync will be optional and will require explicit permission. Denying it
  will never block local tracking.
- Timestamps are saved in milliseconds so the exact local time is preserved.
- Uninstalling the app removes the local database; if Android backup is enabled on your
  device, the system may restore it on reinstall.

## Health Connect

Health Connect support is planned. Each completed session will be written as a
`SleepSessionRecord`, with retries for transient failures and without duplicates.

- Requires Android 9 (API 28) or newer.
- On Android 13 and lower the Health Connect app must be installed.
- Permissions will be requested when the feature is first used, not at launch.
- Publishing on Play requires the Health Connect declaration.

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.47 + Material 3 Expressive (`material_3_expressive` 1.1.7) |
| State | Riverpod (`flutter_riverpod` 3.x) |
| Persistence | Drift over SQLite (`drift`, `drift_flutter`) |
| Widget | `home_widget` + native Kotlin / Jetpack Glance |
| Health | Health Connect `SleepSessionRecord` |
| Background | WorkManager for Flutter |

## Architecture

```text
lib/
├── main.dart
├── app/
│   └── sleepy3_app.dart
├── core/
│   └── theme/
└── features/
    └── sleep_tracking/
        ├── domain/        # sessions, durations, store contract
        ├── data/          # Drift database and store implementation
        ├── application/   # Riverpod controller and state
        └── presentation/  # home screen and buttons
android/
└── app/src/main/kotlin/com/sleepy3/app/
    └── MainActivity.kt    # native widget and platform bridges land here
```

On launch, Sleepy3 opens the database, loads the open session plus the last closed one,
and injects both into the Riverpod scope before the first frame. If that read fails, the
app starts with an empty state and logs the error instead of getting stuck.

The controller is a Riverpod `Notifier`: it updates in-memory state first so the buttons
answer instantly, then serializes the disk write behind it. The UI never reads the
database directly, and the clock is injected, which keeps the domain logic testable.

`SPEC.md` holds the detailed behavior, data model and roadmap.

## Development

```bash
flutter pub get      # dependencies
flutter analyze      # static analysis
flutter test         # unit, widget and persistence tests
flutter run          # run on a connected device

r                    # hot reload while `flutter run` is active
dart format .        # format
```

On Windows, use the Flutter SDK's `bin\flutter.bat` or add `bin` to `PATH`.

Project conventions worth knowing:

- UI code imports `package:material_ui/material_ui.dart` and
  `package:material_3_expressive/material_3_expressive.dart`; never
  `package:flutter/material.dart`.
- `material_ui` is pinned to **1.7.0**. Version 1.8.0 adds a `RoundedPolygon` symbol that
  conflicts with `material_new_shapes`, used by `material_3_expressive` 1.1.7. Do not bump
  it until the packages are compatible.
- Drift generated code is committed. After changing the schema, bump `schemaVersion`, add
  a migration, then run `dart run build_runner build`.
- Domain logic never calls `DateTime.now()`; the clock is injected through
  `sleepClockProvider`.

## Design

Material Design 3 Expressive with dynamic color on Android 12+ and the seed color
`#6750A4` as a fallback. Buttons are 96 dp tall and stack when the screen is narrow or
the system text size is large. Light and dark themes follow the system setting.

The local M3 spec lives in `.agent-skills/m3-expressive/`; read its `SKILL.md` before
changing UI.

## Roadmap

- [ ] Home-screen widget with Sleep / Wake actions and a pending-events queue.
- [ ] Health Connect sync with retries and idempotent writes.
- [ ] Recent history and a 3-day summary.
- [ ] Widget and Health Connect integration tests.
- [ ] Motion and accessibility polish.
- [ ] GitHub Actions release workflow with generated notes.

## Contributing

Work happens on the `dev` branch; `main` stays stable. Commits follow Conventional
Commits with a scope, in English:

```text
feat(ui): add history summary
fix(data): restore an open session
docs(spec): define the widget contract
```

A module is considered done when `flutter analyze` is clean, `flutter test` passes, the
Android debug build succeeds, new behavior has tests, and `SPEC.md` / `README.md` are
updated when the change affects behavior or the user experience.

## Troubleshooting

- **`flutter` is not recognized on Windows**: call `<flutter-sdk>\bin\flutter.bat` or add
  `<flutter-sdk>\bin` to `PATH`.
- **Dependency resolution fails after bumping `material_ui`**: the pin exists on purpose;
  stay on 1.7.0 until `material_3_expressive` supports the newer symbol.
- **Health Connect is missing**: on Android 13 or lower, install the Health Connect app
  from the Play Store.
- **The app looks empty after reinstalling**: there is no account to sign in to. If the
  system did not restore the local database from a backup, earlier sessions are gone.

## License

Sleepy3 is free software, distributed under the terms of the **GNU General Public License,
version 3**. See [LICENSE](LICENSE) for the full text.

This program comes with ABSOLUTELY NO WARRANTY. You are welcome to redistribute it and
modify it under certain conditions; the license explains them.
