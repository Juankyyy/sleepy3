<p align="center">
  <img src="assets/brand/Sleepy3-rounded.png" alt="Sleepy3 — Sleep. Wake. Done." width="700">
</p>

<p align="center">
  <a href="https://github.com/Juankyyy/sleepy3/releases"><img src="https://img.shields.io/github/v/release/Juankyyy/sleepy3?label=release&amp;color=252B81" alt="Latest stable release"></a>
  &nbsp;
  <img src="https://img.shields.io/badge/Android-9%2B-3DDC84?logo=android&amp;logoColor=white" alt="Android 9 or newer">
  &nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="GPL-3.0 license"></a>
</p>

**Sleep tracking with two buttons and nothing to fill in.** Tap **Sleep** when you go to bed and **Wake** when you get up. Sleepy3 keeps the exact times on your phone and stays out of your way.

## Why Sleepy3

- **Two taps.** One button starts the night, the other ends it. No forms, no timers, no guessing.
- **Your last nights at a glance.** Home shows today, yesterday and the day before with a three-day average and bars against an eight-hour goal.
- **Nothing leaves your phone.** There is no account, no server of ours and no analytics. Health Connect is optional.
- **Designed for 3 a.m.** Big buttons, one-hand use, a clear awake/sleeping state and light and dark themes that follow your phone.

## Download and install

Sleepy3 is not on Google Play yet. Download the latest stable build from [Releases](https://github.com/Juankyyy/sleepy3/releases). Releases are published manually; development builds are not distributed.

1. Open Releases on your phone.
2. Download the latest `sleepy3-vX.Y.Z.apk`.
3. Open the file and allow installs from your browser or file manager when Android asks.

Sleepy3 runs on **Android 9 or newer**. Version **0.1.7** is the latest stable release; the home-screen widget is planned for a later update.

## How to use it

1. Tap **Sleep** when you go to bed. The header switches to a sleeping state and the clock keeps running.
2. Tap **Wake** when you get up. Sleepy3 saves the night and shows how long you slept.
3. Open **Stats** to review or fix your history, and **Settings** for the theme and Health Connect.

Use the floating glass dock at the bottom to move between **Home**, **Stats** and **Settings**; the selected destination shows its label, and the content stays visible behind the dock.

Settings is split into **Appearance** (System, Light or Dark), **Sleep data** (Local or Google Health, and Import), **Google Health** (connection status, Sync and Add) and **About** (privacy, version and open-source licenses).

The header always tells you what is happening:

| Situation | What you see |
|---|---|
| Awake during the day | `No active session` |
| Awake at night | `Tap Sleep when you turn off the lights` |
| Sleeping | `Sleeping since 10:30 PM` |
| Just woke up | `Last session: 7h 45m` |

Day is 07:00–18:59 and night is 19:00–06:59, in local time, and the clock follows your phone's 12- or 24-hour setting. Sleep is disabled while a night is open and Wake is disabled while you are awake, so a double tap cannot break the timeline.

Health Connect only accepts sleep sessions between 10 minutes and 24 hours. If a night falls outside that range, Sleepy3 asks first: you can keep sleeping, discard the session or move its start time.

## Stats

Stats groups nights by the day you woke up and offers 7-day, 30-day and all-history filters, with the average, total and number of nights. Each night is a tonal card with a ring that compares it with the 8-hour goal, replaced by a Material 3 Expressive clover badge once the goal is met; the 30-day and all-history views use a denser two-line card so more nights fit on screen. Sessions written by another app show an external-app arrow and that app's name, or **Another app** when Android cannot resolve it; your own sessions stay unmarked.

Pull down on Stats to refresh. The list stays in place while an M3 Expressive loader descends from the top; pending Google Health uploads are retried first, then the selected source is read again. In Local mode a refresh never uploads a new session.

Tap any card to open it. Sessions written by the app you are using open in a detail view with the night's duration against the 8-hour goal, where you can change the start or end time or delete the session after confirming. If Google Health needs write access, the delete dialog offers **Allow** and tries again. Sessions created by another app open read-only, with locked fields and a card that names the app when Android can resolve it (otherwise it says another app). In Local mode, sessions downloaded from Health Connect are read-only too. In Google Health mode, your own records stay editable even without a local copy. A record written by the other Sleepy3 build (release vs debug) is read-only from the build you are using, because Health Connect only lets the app that wrote it change it.

## Local or Google Health?

Choose the source in **Settings → Sleep data**.

| | **Local** (default) | **Google Health** |
|---|---|---|
| Where sessions are stored | Only in Sleepy3 | Health Connect, plus a local safety copy |
| What Stats shows | Only Sleepy3 sessions | Every sleep session in Health Connect, including other apps' |
| Editing | Only your Sleepy3 sessions | Records written by this build; other apps' records and the other Sleepy3 build are read-only |
| Good for | Keeping everything in one private app | Seeing all your sleep data together |

In Local mode Sleepy3 never touches Health Connect on its own. If you already sent a session there, editing it updates that record too.

In Google Health mode, the app asks for permission the first time. If you decline, it stays on Local. When a write fails, the session stays pending, a banner offers **Retry**, and Sleepy3 tries again when you reopen the app or pull down on Stats.

**Copy actions** in Settings:

- **Sync** sends your most recent pending session.
- **Add** sends every pending session.
- **Import** copies every Health Connect session into Sleepy3.

They never change the selected source, and repeating one does not create duplicates.

Health Connect hides records older than 30 days unless you give Sleepy3 the history permission. The app asks when you choose **All** in Stats or start **Import**. If you decline, Stats shows the last 30 days with an **Allow full history** button, and Import reports that it only copied 30 days.

## Your data

- Sessions, the theme and the data source are stored in a local database on your phone.
- There is no account, no backend and no analytics. Nothing is sent to us.
- Local mode works completely offline. Health Connect is optional, and denying permission never blocks local tracking.
- Uninstalling Sleepy3 deletes the local database. If Android backup is enabled, the system may restore it when you reinstall.
- Sleepy3 talks to Health Connect on your phone, not to Google's cloud. A record that exists only in the Google Health cloud appears once Google Health syncs it to Health Connect.

## Common questions

**I reinstalled the app and my history is gone.** There is no account to sign in to. If Android did not restore the local database from a backup, earlier sessions cannot be recovered.

**Android won't install the APK over my old copy.** Android requires the same signing key. Uninstall the old app first; that also deletes its local database.

**Stats "All" stops at 30 days.** Allow full history for Sleepy3 in Health Connect, then tap **Allow full history** in Stats or reopen the app.

**Health Connect is missing.** On Android 13 or lower, install the Health Connect app from the Play Store, then try again.

## What's next

- [x] Local tracking, Stats history and Settings.
- [x] Health Connect sync, history access and session editing.
- [x] First stable release (0.1.0).
- [x] Floating dock, new type and read-only session details (0.1.6).
- [x] Tonal Stats history, goal marks and the session panel (0.1.7).
- [ ] Home-screen widget with Sleep and Wake buttons.
- [ ] Motion and accessibility polish.

## For developers

<details>
<summary><strong>Build, architecture, design and release process</strong></summary>

### Requirements

- An Android device or emulator running Android 9 (API 28) or newer.
- Flutter 3.47.x stable (Dart 3.13).
- JDK 17 or newer.
- Android SDK and platform tools. Android Studio is not required.

### Build and run

```bash
flutter pub get
flutter analyze
flutter test
flutter run

flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Install it with `adb install build/app/outputs/flutter-apk/app-release.apk`, or copy it to the phone and open it. On Windows, use the Flutter SDK's `bin\flutter.bat` or add `bin` to `PATH`.

`flutter run` installs **Sleepy3 Debug** (`com.sleepy3.app.debug`, version suffix `-debug`), which can coexist with a signed release APK and keeps a separate local database. Release APKs are signed with the project's release key; uninstall a debug-signed copy of `com.sleepy3.app` before installing a release build.

### Architecture

```text
lib/
├── main.dart
├── app/
│   ├── sleepy3_app.dart
│   └── splash_gate.dart  # zoom-out brand splash over the shell
├── core/
│   ├── theme/         # Material 3 Expressive theme and tokens
│   └── time/          # clock formatting, day/night rule and LocalDayBuilder
└── features/
    ├── sleep_tracking/
    │   ├── domain/        # sessions, durations, history, edit draft, store contract
    │   ├── data/          # Drift database and store implementation
    │   ├── application/   # Riverpod controllers, edit service and state
    │   └── presentation/  # home screen, header, live clock and buttons
    ├── stats/
    │   └── presentation/  # stats screen, chips, summary, history list, session editor
    ├── health/
    │   ├── domain/        # gateway, source, history access, sync store and stored session
    │   ├── data/          # Health Connect gateway, repositories and Drift sync store
    │   ├── application/   # source, history, history permission, sync, upload and copy
    │   └── presentation/  # copy dialogs, sync and history banners, source text
    └── settings/
        ├── domain/        # theme mode, app version and store contract
        ├── data/          # Drift settings store
        ├── application/   # theme controller and providers
        └── presentation/  # settings screen, theme dialog and about list
assets/
├── brand/             # logo sources, splash mark and launcher icon sources
└── fonts/             # Space Grotesk, the instanced Google Sans Flex titles face, OFL licenses
android/
└── app/src/main/kotlin/com/sleepy3/app/
    └── MainActivity.kt    # native widget and platform bridges land here
```

On launch, Sleepy3 opens the database, loads the open session, the saved theme, the selected data source and the installed version, then injects them into the Riverpod scope before the first frame. The closed history loads asynchronously from the selected source; a failed read falls back to an empty/default value instead of blocking startup.

The controller is a Riverpod `Notifier`: it updates in-memory state first so the buttons answer instantly, then serializes the disk write behind it. The UI never reads the database directly, and the clock is injected, which keeps the domain logic testable.

### Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.47 + Material 3 Expressive (`material_3_expressive` 1.1.7) |
| Type | Space Grotesk for the M3 scale; instanced Google Sans Flex for the page titles (both OFL) |
| State | Riverpod (`flutter_riverpod` 3.x) |
| Persistence | Drift over SQLite (`drift`, `drift_flutter`) |
| App info | `package_info_plus` |
| Widget | `home_widget` + native Kotlin / Jetpack Glance (planned) |
| Health | Health Connect `SleepSessionRecord` |
| Background | WorkManager for Flutter |

### Project conventions

- UI code imports `package:material_ui/material_ui.dart` and `package:material_3_expressive/material_3_expressive.dart`; never `package:flutter/material.dart`.
- `material_ui` is pinned to **1.7.0**. Version 1.8.0 adds a `RoundedPolygon` symbol that conflicts with `material_new_shapes`, used by `material_3_expressive` 1.1.7. Do not bump it until the packages are compatible.
- Drift generated code is committed. After changing the schema, bump `schemaVersion`, add a migration, then run `dart run build_runner build`.
- Domain logic never calls `DateTime.now()`; the clock is injected through `sleepClockProvider`.
- Health Connect internals (stable client record ids, versions and deduplication) are documented in `SPEC.md §9`.
- `SPEC.md` holds the detailed behavior, data model and roadmap.

### Design and brand

Sleepy3 uses a fixed Material 3 Expressive palette taken from its logo: light body `#EFF4F9` with `#252B81` primary, and dark body `#121318` with `#C6CCF7` primary. Dynamic color (Material You) is intentionally off, so the app looks the same on every device.

Type is **Space Grotesk** for the M3 scale, bundled in the APK; the live clock uses it at weight 700. The home brand and the Stats/Settings page titles use **Google Sans Flex**, instanced at weight 900, width 112.5 and roundness 35, with only the optical-size axis left live. Both families are distributed under the SIL Open Font License (`assets/fonts/OFL-SpaceGrotesk.txt` and `assets/fonts/OFL-GoogleSansFlex.txt`); `assets/fonts/README.md` documents both assets. The launcher icon, the adaptive layers, the Android 12+ launch marks and the splash mark are generated from `assets/brand/` with:

```bash
dart run tool/generate_brand_assets.dart
```

Keep the native launch colors in `values/colors.xml` and `values-night/colors.xml` equal to `Sleepy3Theme.lightBackground` and `Sleepy3Theme.darkBackground`. The local M3 spec lives in `.agent-skills/m3-expressive/`; read its `SKILL.md` before changing UI.

### Releasing

Releases are created manually from `main` with `.github/workflows/release.yml`; there is no version bump commit.

- Pushes to `dev` or `main` publish nothing. The workflow only runs when the maintainer dispatches it from `main`.
- Choose `minor` (`v0.X.0`), `patch` (`v0.X.Y`) or `exact` (the version in `version`, e.g. `0.1.6`). `minor` and `patch` are computed from the highest existing tag; `exact` must be greater than it.
- The workflow runs `flutter analyze` and `flutter test`, builds a signed release, creates the tag and attaches `sleepy3-vX.Y.Z.apk` with a `.sha256`.
- Notes are generated from conventional commits since the previous tag. The curated body and `vX.Y.Z - The <Theme> Update` title are applied afterwards from `release-notes/vX.Y.Z.md` (ignored by Git):

```bash
dart run tool/apply_release_notes.dart v0.1.7
```

- Development builds are not published; use `flutter run` or a local APK to test `dev`.

Maintainers configure four repository secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Without them the workflow fails instead of publishing a debug-signed APK. See `SPEC.md §1`.

### Contributing

Work happens on `dev`; `main` stays stable. Commits follow Conventional Commits with a scope, in English:

```text
feat(ui): add history summary
fix(data): restore an open session
docs(spec): define the widget contract
```

A module is done when `flutter analyze` is clean, `flutter test` passes, the Android debug build succeeds, new behavior has tests, and `SPEC.md` / `README.md` are updated when the change affects behavior or the user experience.

### Development troubleshooting

- **`flutter` is not recognized on Windows**: call `<flutter-sdk>\bin\flutter.bat` or add `<flutter-sdk>\bin` to `PATH`.
- **Dependency resolution fails after bumping `material_ui`**: the pin exists on purpose; stay on 1.7.0 until `material_3_expressive` supports the newer symbol.

</details>

## License

Sleepy3 is free software, distributed under the terms of the **GNU General Public License, version 3**. See [LICENSE](LICENSE) for the full text.

This program comes with ABSOLUTELY NO WARRANTY. You are welcome to redistribute it and modify it under certain conditions; the license explains them.
