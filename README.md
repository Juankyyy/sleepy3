# Sleepy3

Zero-friction sleep tracking for Android: two buttons, no forms.

![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-2.0.20-7F52FF?logo=kotlin&logoColor=white)
![Compose](https://img.shields.io/badge/Jetpack_Compose-Material3-4285F4?logo=jetpackcompose&logoColor=white)
![Min SDK](https://img.shields.io/badge/minSdk-26-blue)
![Target SDK](https://img.shields.io/badge/targetSdk-34-blue)

## About

Sleepy3 records the exact time you fall asleep and wake up with two large buttons, available from the main app and from a home-screen widget.

Sessions are stored locally with Room and synced to Google Health Connect as `SleepSessionRecord`.

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
| UI | Jetpack Compose, Material3 Expressive (no XML) |
| Architecture | MVVM (`UiState` + `ViewModel` + `StateFlow`) |
| Local storage | Room |
| Health | Health Connect `SleepSessionRecord` |
| Background | Kotlin Coroutines + WorkManager |
| Widget | Jetpack Glance |

Pinned versions in `gradle/libs.versions.toml`:

- AGP 8.5.2, Kotlin 2.0.20, `compileSdk` / `targetSdk` 34, `minSdk` 26, Java 17
- Compose BOM 2024.09.00, Material3 1.3.1, lifecycle 2.8.6, activity-compose 1.9.2

## Project structure

```text
app/src/main/java/com/sleepy3/app/
├── MainActivity.kt
└── ui/
    ├── theme/Theme.kt
    └── home/
        ├── SleepHomeUiState.kt
        ├── SleepHomeViewModel.kt
        ├── TrackButtonsRow.kt
        └── SleepHomeScreen.kt
```

## Requirements

- JDK 17
- Android Studio Ladybug or newer (AGP 8.5.2)
- Android SDK 34
- Android 8.0+ device or emulator (API 26)

## Getting started

```bash
git clone https://github.com/Juankyyy/sleepy3.git
cd sleepy3

# Build debug APK
./gradlew :app:assembleDebug

# Install on a connected device / emulator
./gradlew :app:installDebug

# Run unit tests
./gradlew :app:testDebugUnitTest
```

On Windows use `gradlew.bat` instead of `./gradlew`.

## Branches

| Branch | Purpose |
|---|---|
| `main` | Stable |
| `dev` | Usable release integration |
| `debug` | Testing, experiments and APKs |

Flow: `debug` → `dev` → `main`.

## Design

Material Design 3 Expressive:

- Colors from `MaterialTheme.colorScheme` with `dynamicColor`.
- Large rounded shapes (`RoundedCornerShape`) and contrasting typography.
- Reduced motion respected, no aggressive animations.

## License

No license defined yet. All rights reserved by default.
