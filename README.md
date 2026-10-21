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

Sleepy3 records the exact time you fall asleep and wake up with two large buttons,
available from the main app and from a home-screen widget.

Sessions are stored locally and synced to Google Health Connect as
`SleepSessionRecord`.

## Status

- [x] Flutter project scaffold (`flutter create --empty`)
- [ ] Two-button home screen and sleep state machine
- [ ] Local persistence
- [ ] Home-screen widget (Dormir / Despertar without opening the app)
- [ ] Health Connect sync and background retry
- [ ] Recent history and 3-day summary
- [ ] Material 3 Expressive polish
- [ ] Widget, unit and integration tests

## Features

- Large Sleep / Wake actions with clear enabled-state feedback.
- Session summary line (e.g. duration slept last night).
- Recent history with a 3-day mini summary.
- Home-screen widget to log timestamps without opening the app.
- Health Connect sync with background retry.
- Material Design 3 Expressive with dynamic color (light / dark).
- Accessible: content descriptions, visible focus, minimum touch targets.

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter, Material 3 |
| State | Riverpod (planned) |
| Local storage | Drift over SQLite (planned) |
| Health | Health Connect `SleepSessionRecord` |
| Background | WorkManager for Flutter (planned) |
| Widget | `home_widget` + native Kotlin / Jetpack Glance |

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
- Large shapes, clear type hierarchy and spring-driven press feedback.
- Light and dark themes.
- Reduced motion respected.

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
