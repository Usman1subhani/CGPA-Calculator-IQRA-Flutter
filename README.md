# GPA Calculator ( IUIC ) — Flutter app

A Flutter app for GPA and CGPA calculation, following **Iqra University's**
official grading scheme, with a bottom-nav layout (Home / GPA / CGPA /
History / Settings), local history you can reopen and edit, and support for
repeated/improved courses in CGPA.

## App name & branding

- Display name: **"GPA Calculator ( IUIC )"** — set at the OS level for
  every platform (Android `AndroidManifest.xml`, iOS `CFBundleDisplayName`,
  macOS `PRODUCT_NAME`, Linux window/header title, Windows window title +
  `Runner.rc`). Inside Dart code it's defined once in `lib/app_info.dart`
  (`AppInfo.appName`) and referenced everywhere it's shown (splash screen,
  About dialog, share text, Home hero banner) — change it there once if
  you ever need to rename again.
- Colors: navy blue + gold, sampled directly from the provided Iqra
  University icon/logo (`assets/icon.png`), defined in `lib/theme.dart`
  (`AppColors.primary*` / `AppColors.accent*`).
- Logo: `assets/icon.png` is used as the splash screen image, a small
  Home AppBar icon, and is wired to `flutter_launcher_icons` — run
  `dart run flutter_launcher_icons` to (re)generate the actual Android/iOS
  launcher icons from it.

## Grading logic — Iqra University (Spring 2025 scheme)

Implemented in `lib/data/grading_data.dart`, sourced from Iqra University's
own **"New Grading Scheme and Assessment Models — Implementation from
Spring 2025"** circular, cross-checked against an independent, actively
maintained 2026 guide that reproduces the identical table:

| Grade | Percentage | Points | Remarks |
|---|---|---|---|
| A | 90–100% | 4.00 | Outstanding |
| A- | 85–89% | 3.67 | Excellent |
| B+ | 80–84% | 3.33 | Very Good |
| B | 75–79% | 3.00 | Good |
| B- | 70–74% | 2.67 | Fairly Good |
| C+ | 65–69% | 2.33 | Above Average |
| C | 60–64% | 2.00 | Average (minimum degree requirement) |
| C- | 56–59% | 1.67 | Below Average |
| D+ | 53–55% | 1.33 | Poor |
| D | 50–52% | 1.00 | Unsatisfactory (minimum passing grade) |
| F | below 50% | 0.00 | Fail (course repeat) |

**Important difference from a formula/table-lookup scheme:** Iqra's grade
points are a flat value per letter grade (no interpolation table like some
other universities use) — `Quality Points = grade point × credit hours`.
A course's percentage is also its own mark out of 100 (not scaled by
credit hours), so the input field is simply **"Percentage (%)"**, not
"marks out of X".

`GPA = Σ(quality points) / Σ(credit hours)`. `CGPA` is the same formula
applied across semesters (`Σ(semester GPA × semester credit hours) /
Σ(credit hours)`).

**Note on an older scheme still floating around online:** several
third-party sites (scholaro, campusaxis, meershair) quote an *older* Iqra
scale (A = 4.0 at 88%+, B+ = 3.5, B = 3.0, C+ = 2.5, C = 2.0, no +/-
grades). That predates the Spring 2025 revision and is **not** what this
app implements — the table above is the current, official one.

**Rounding:** unlike a university where we've verified real transcripts
truncate the GPA, we don't have a real Iqra transcript to confirm rounding
behavior, so this app uses standard rounding (round-half-up) to 2
decimals. Flag this if you find an official transcript showing otherwise.

**Probation threshold:** the Spring 2025 scheme also revised the academic
probation threshold to a semester GPA below **1.70** — reflected in the
CGPA screen's standing label.

Run `flutter test` to see the full grade-band and calculation test suite.

## CGPA + repeated/improved courses

If a course was repeated after failing, or improved for a better grade,
only the **new** attempt counts toward CGPA — the original attempt's
quality points AND credit hours are dropped entirely (not averaged in).
In the CGPA screen, open the semester that had the *original* attempt and
tap "Add repeated/improved course", entering that attempt's percentage and
credit hours — the app looks up its quality points and excludes both from
the CGPA total.

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
- **GPA**/**CGPA** screens use a transparent AppBar (so the back button
  still works when opened from History for editing) with the real
  title/subtitle in the scrollable body. Primary buttons are pill-shaped.
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
  screens/                    # home, gpa, cgpa, history, settings
  main_shell.dart, splash_screen.dart, main.dart
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

- `applicationId` is still the project default — update before publishing
  anywhere public.
- Real Privacy Policy URL and Play Store URL are placeholders in
  `lib/screens/settings_screen.dart`.
- Store listing assets (screenshots, feature graphic, descriptions).
