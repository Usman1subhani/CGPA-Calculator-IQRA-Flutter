# IU GPA Calculator — Flutter app

A Flutter app for GPA and CGPA calculation that supports grading scales
published by Iqra University. It is independently developed and is not
affiliated with or endorsed by the university. It has a Material 3 navigation
layout (Home / GPA / CGPA /
History / Settings), local history you can reopen and edit, and support for
repeated/improved courses in CGPA. The GPA/CGPA results can be shared, and
the grading-scale reference is available from the calculators and Settings.

## App name & branding

- Display name: **"IU GPA Calculator"** — set at the OS level for
  every platform (Android `AndroidManifest.xml`, iOS `CFBundleDisplayName`,
  macOS `PRODUCT_NAME`, Linux window/header title, Windows window title +
  `Runner.rc`). Inside Dart code it's defined once in `lib/app_info.dart`
  (`AppInfo.appName`) and referenced everywhere it's shown (About dialog,
  share text, Home hero banner) — change it there once if
  you ever need to rename again.
- Colors: a navy blue + gold educational palette, defined in `lib/theme.dart`
  (`AppColors.primary*` / `AppColors.accent*`).
- Logo: `assets/icon.png` is the launcher-icon source. Android adaptive
  icons use a padded transparent foreground (`assets/icon_foreground.png`)
  so the artwork stays inside launcher masks. The 512×512 Play listing icon
  is `assets/play_store_icon.png`. In-app controls use Material icons.
  Launcher files are wired to `flutter_launcher_icons` — run
  `dart run flutter_launcher_icons` to (re)generate the actual Android/iOS
  launcher icons from it.

## Grading logic — Iqra University

The app offers the scale for each admission batch. These rules are based
on Iqra University's [Undergraduate Handbook, version 14.0](https://iqra.edu.pk/wp-content/uploads/2026/04/IU-UG-Handbook-11.06.2025-v14.0-2.pdf).

**Pre-Spring 2025 admissions (legacy scale):**

| Grade | Percentage | Points |
|---|---:|---:|
| A | 88–100% | 4.00 |
| B+ | 81–87% | 3.50 |
| B | 74–80% | 3.00 |
| C+ | 67–73% | 2.50 |
| C | 60–66% | 2.00 |
| F | below 60% | 0.00 |

**Newly admitted students from Spring 2025 (11-grade scale):**

| Grade | Percentage | Points |
|---|---:|---:|
| A | 90–100% | 4.00 |
| A- | 85–89% | 3.67 |
| B+ | 80–84% | 3.33 |
| B | 75–79% | 3.00 |
| B- | 70–74% | 2.67 |
| C+ | 65–69% | 2.33 |
| C | 60–64% | 2.00 |
| C- | 56–59% | 1.67 |
| D+ | 53–55% | 1.33 |
| D | 50–52% | 1.00 |
| F | below 50% | 0.00 |

Grade points are flat per letter grade: `Quality Points = grade point ×
credit hours`. A course mark is its percentage out of 100. GPA is the sum
of quality points divided by the sum of credit hours. Displayed GPA/CGPA
is **rounded** to two decimal places. Exact course quality
points are retained, and a saved GPA can be imported into CGPA to avoid
weighting an exact semester GPA.

When a course is repeated or improved, the better of the two grades is
counted. Probation is reported only for **semester GPA** below 1.70;
CGPA standing uses the separate 2.00 degree-requirement threshold.

Older saved course rows used `0` for both an unselected grade and F, so
those rows reopen without a grade selected and must be checked. Older
repeated-course adjustments also lack the repeat grade and semester; edit
those entries to complete the new repeat details.

Run `flutter test` to see the full grade-band and calculation test suite.

The calculator accepts grade selections rather than percentage inputs.
Empty grades and invalid/incomplete semester rows produce an inline error.

## CGPA + repeated/improved courses

For a repeated or improved course, the **better grade** is used in CGPA.
In the original semester card, choose "Add a repeated/improved course",
select both attempt grades and credit hours, and select the semester that
contains the repeat. The lower-grade attempt's points and hours are removed.

## Tap a history card to edit it

History cards on both the Home dashboard and History screen are tappable —
tapping one reopens the GPA or CGPA screen fully pre-filled (every course,
every semester, every repeated/improved adjustment) so you can review or
change it. Saving again updates that same entry in place.

## Visual design

- `lib/widgets/screen_header.dart`: `ScreenHeader` (bold title + muted
  subtitle), `SettingsCardTile` (a settings row as its own elevated card
  with a colored icon badge + chevron), `SectionLabel`.
- **Settings** is a list of individually-elevated cards, each with a
  distinct icon badge color.
- The theme follows the device by default; System, Light, and Dark overrides
  are available in Settings.
- **GPA**/**CGPA** screens use a transparent AppBar (so the back button
  still works when opened from History for editing) with the real
  title/subtitle in the scrollable body. Primary buttons are pill-shaped.
- The CGPA repeated-course guidance is static and dismissible.
- Global `CardThemeData` has a subtle elevation + shadow for a soft-card
  look throughout.

## Project structure

```
lib/
  app_info.dart              # App name/branding constants
  data/grading_data.dart      # Iqra grade bands + GpaEngine (pure, tested)
  models/                     # Course, SemesterInput, HistoryEntry
  storage/local_storage.dart  # SharedPreferences wrapper
  app_state.dart              # history + theme state (provider)
  theme.dart                  # AppColors (navy/gold), AppTheme
  widgets/                    # Reusable cards, screen header
  screens/                    # home, gpa, cgpa, history, settings, grading scale
  main_shell.dart, main.dart
```

## Setup

```bash
flutter pub get
flutter run
```

Run tests:

```bash
flutter test
```

Regenerate launcher icons from `assets/icon.png`:

```bash
dart run flutter_launcher_icons
```

## Before publishing

- The selected Android application ID is
  `com.usmansubhani.gpacalculator` in `android/gradle.properties`. Verify that
  it is available in Play Console before creating the listing; it cannot be
  changed after publishing. Release builds reject the template `com.example`
  ID.
- Create an upload keystore and a private, untracked
  `android/key.properties` file with `storeFile`, `storePassword`,
  `keyAlias`, and `keyPassword`. Release builds no longer use the debug key.
- The Privacy Policy link is configured as
  `https://cgpa-foriqrauni-privacy.netlify.app`; override it at build time with
  `--dart-define=PRIVACY_POLICY_URL=https://...` if it changes. Supply the Play
  Store URL with `--dart-define=PLAY_STORE_URL=https://...` after the listing
  exists.
- Set the Play developer account ID for the About Developer link with
  `--dart-define=PLAY_DEVELOPER_ID=YOUR_DEVELOPER_ACCOUNT_ID`.
- Adaptive Android launcher icons are generated from the source and padded
  foreground in `assets/`; the web manifest metadata describes the calculator.
- Store listing assets (screenshots, feature graphic, descriptions).
