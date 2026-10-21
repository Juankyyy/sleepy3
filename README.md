# Sleepy3

Zero-friction sleep tracking for Android: two buttons, no forms.

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Min SDK](https://img.shields.io/badge/minSdk-28-blue)
![Material 3](https://img.shields.io/badge/Material_3-Expressive-4285F4)

> Migration in progress. The project was recreated from scratch in Flutter. The previous
> native Android prototype is preserved at the Git tag `archive/android-prototype`.

## About

Sleepy3 records the exact time you fall asleep and wake up with two large buttons
in the main app. A home-screen widget is planned.

Sessions are stored locally and restored on launch. Health Connect sync is planned.

## Status

- [x] Flutter project scaffold (`flutter create --empty`)
- [x] Two-button home screen and sleep state machine
- [x] Material 3 Expressive theme with dynamic color
- [x] Local persistence (Drift) and session restore on launch
- [x] Unit, widget and persistence tests
- [ ] Home-screen widget (Sleep / Wake without opening the app)
- [ ] Health Connect sync and background retry
- [ ] Recent history and 3-day summary
- [ ] Widget and Health Connect integration tests
- [ ] M3 Expressive motion and accessibility polish

## Features

Implemented:

- Large Sleep / Wake actions with clear enabled-state feedback.
- Session line that shows the current start time or the last duration.
- Local persistence; a sleep in progress is restored after a restart.
- Material 3 Expressive with dynamic color (light / dark).
- Accessible labels and visible focus through the M3E components.

Planned:

- Recent history with a 3-day mini summary.
- Home-screen widget to log timestamps without opening the app.
- Health Connect sync with background retry.

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter + Material 3 Expressive (`material_3_expressive`) |
| State | Riverpod |
| Local storage | Drift over SQLite |
| Health | Health Connect `SleepSessionRecord` |
| Background | WorkManager for Flutter (planned) |
| Widget | `home_widget` + native Kotlin / Jetpack Glance |

`material_ui` is pinned to 1.7.0. Version 1.8.0 introduced a `RoundedPolygon`
symbol that conflicts with `material_new_shapes`, which `material_3_expressive`
1.1.7 uses. Remove the pin once the package supports 1.8.0.

### Persistence

Sessions live in `sleepy3.sqlite` in the app documents directory, managed by
Drift. Generated code is committed; after changing the schema run:

```bash
dart run build_runner build
```

The store restores an open session on launch, so a sleep that started before the
app was killed is still shown as running. The controller updates the UI first and
serializes disk writes behind it.

The Android home-screen widget is native code: Android renders widgets with
`RemoteViews`, outside the Flutter engine. Flutter and the widget share state through
`home_widget` and a pending-events queue that the app reconciles on launch.

## Project structure

Target layout:

```text
lib/
├── main.dart
├── app/
├── core/
│   └── theme/
└── features/
    ├── sleep_tracking/
    │   ├── domain/
    │   ├── data/
    │   ├── application/
    │   └── presentation/
    ├── health/
    └── widget/
android/
└── app/src/main/kotlin/com/sleepy3/app/
    ├── MainActivity.kt
    └── widget/              # Glance widget and actions
```

## Requirements

- Flutter 3.47.x stable (Dart 3.13)
- JDK 17 or newer (JDK 21 is used locally)
- Android SDK 28+ and an Android device (API 28+)
- No Android Studio required; the Flutter CLI and Android command-line tools are enough

## Getting started

```bash
flutter pub get

# Run on a connected device or emulator
flutter run

# Hot reload while `flutter run` is active
r

# Static analysis and tests
flutter analyze
flutter test
```

On Windows, use the Flutter SDK `bin\flutter.bat` or add `bin` to `PATH`.

### Hot reload

Flutter hot reload works from the terminal or any editor, without Android Studio:

- Run `flutter run`, edit a Dart file and press `r` in the terminal.
- In VS Code, use the Flutter extension and enable hot reload on save.

### Health Connect

- Health Connect requires Android 9 (API 28) or newer.
- On Android 13 and lower the Health Connect app must be installed.
- Publishing requires the Health Connect declaration in Play Console.

## Design

Material Design 3 Expressive:

- Dynamic color on Android 12+ with a seeded fallback.
- Large shapes, clear type hierarchy and spring-driven M3E button feedback.
- Light and dark themes.

The local M3 spec lives in `.agent-skills/m3-expressive/`; read
`.agent-skills/m3-expressive/SKILL.md` before changing UI.

## Branches

| Branch | Purpose |
|---|---|
| `main` | Stable |
| `dev` | Usable release integration |
| `debug` | Testing, experiments and APKs |
| `flutter` | Flutter migration |

Flow: `flutter` → `debug` → `dev` → `main`.

## License

No license defined yet. All rights reserved by default.
