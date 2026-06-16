# Milestones

## v1.5 Charts (Shipped: 2026-06-16)

**Phases completed:** 2 phases, 3 plans, 5 tasks

**Key accomplishments:**

- fl_chart bar chart widget showing daily hydration totals per month with green/red bars, dashed target line, tap tooltips, and empty-state fallback embedded in HistoryScreen
- DayDetailScreen ConsumerWidget with per-entry fl_chart BarChart (HH:mm x-axis, ml y-axis), total/target text display, empty state, and 4-locale L10N strings.
- GoRoute /day/:dateKey wired as top-level route (no NavigationBar), HistoryScreen converted to ConsumerWidget with context.push navigation replacing inline day summary.

---

## v1.4 Polish & Bug Fixes (Shipped: 2026-06-15)

**Phases completed:** 2 phases, 2 plans, 3 tasks

**Key accomplishments:**

- Home empty-state centered with 32px horizontal padding — `textAlign: center` on both Text widgets (POLISH-01)
- History screen refactored from one-shot `initState` Future to Drift `watchEarliestDateKey()` stream provider — reacts instantly when first intake is logged on fresh install (BUG-04)
- Project README replacing Flutter placeholder — 12-item feature list, iOS/Android screenshot table, 4-step build instructions including code-gen step (DOC-01)
- iOS and Android home screen screenshots committed to `docs/images/`

---

## v1.3 Multilingual Support (Shipped: 2026-06-15)

**Phases completed:** 3 phases (12-14), 6 plans, 9 requirements

**Key accomplishments:**

- Gen-l10n pipeline wired: `l10n.yaml` (synthetic-package: false), flutter_localizations SDK dep, `context.l10n` extension via `AppLocalizationsX`, `initializeDateFormatting()` before runApp() for table_calendar support
- 79-key `app_en.arb` canonical template with full `@key` metadata; ICU plural forms with explicit `=0`/`=1`/`other` for cross-language safety
- `BiologicalSex` and `ClimateLevel` enums replacing Italian display-string map keys in the calculator — prerequisite for crash-free locale switching
- Complete Italian, French, Spanish ARB translations (79 keys each) with ICU plurals; all 6 screens verified in 4 languages via human UAT
- `NotificationService` locale resolution via `PlatformDispatcher.instance.locales` + `lookupAppLocalizations()` — no BuildContext required; primary-only matching consistent with UI locale strategy
- iOS `CFBundleLocalizations` (en/it/fr/es) in Info.plist and Android `resourceConfigurations += setOf("en", "it", "fr", "es")` in build.gradle.kts for correct platform locale detection

---

## v1.2 Bug Fixes & Feature Depth (Shipped: 2026-06-15)

**Phases completed:** 3 phases, 6 plans, 11 tasks

**Key accomplishments:**

- Drift target_history table with UNIQUE effectiveDate, DAO with getTargetForDate/watchAll/insertOrReplace, and seed row in onCreate
- Confirmation tests for BUG-01/BUG-03 and 7-test TargetHistoryDao suite validating seed, getTargetForDate, upsert, and watchAll ordering
- Added `applyFromTomorrow` column to UserSettings, `watchTargetForDate(dateKey)` stream to TargetHistoryDao, and `updateTargetWithHistory(newTargetMl)` dual-write method to SettingsRepository — all propagated through entity and repository mappings with code-gen and clean analyze.
- Riverpod provider layer for per-day target tracking: TodayDateKey keepAlive Notifier with midnight Timer (BUG-02 fix), effectiveTargetForDate stream family, allTargetHistory batch stream, and streak rewritten to use per-day targets via asyncExpand.
- Wired HomeScreen to todayDateKeyProvider and effectiveTargetForDateProvider (BUG-02 fixed, TARGET-03), HistoryScreen to allTargetHistoryProvider with _findActiveTarget helper (TARGET-04), and SettingsScreen with applyFromTomorrow toggle and updateTargetWithHistory routing (TARGET-02) — all three screens now use per-day targets.
- COMPLETE

---

## v1.1 Polish & UX (Shipped: 2026-06-08)

**Phases completed:** 3 phases, 4 plans, 10 tasks

**Key accomplishments:**

- Material You dynamic theming with DynamicColorBuilder, dual light/dark themes, and static blue seed fallback
- SnackBar persist fix, locale-aware liter display in progress ring, and brightness-adaptive green/red/orange across home and history screens
- FAB replaces inline quick-add buttons; modal bottom sheet provides 3 configurable presets and custom ml input with 1-9999 validation
- Water glass motif launcher icon generated via pure-Dart CLI script and flutter_launcher_icons for all iOS/Android sizes with #1565C0 background and adaptive icon support

---

## v1.0 MVP (Shipped: 2026-06-08)

**Phases completed:** 5 phases, 7 plans, 17 tasks

**Key accomplishments:**

- Drift database with 3 tables, reactive DAOs, Freezed domain entities, Riverpod provider graph, and GoRouter navigation skeleton wired end-to-end
- 11 DAO unit tests passing against in-memory Drift database, plus human-verified app launch on device confirming end-to-end data foundation
- StatefulShellRoute.indexedStack with M3 NavigationBar (Home/History/Settings), percent_indicator 4.2.5 added, stub screens with 'Coming soon' content per D-07
- ConsumerStatefulWidget HomeScreen with CircularPercentIndicator progress ring (primary/green color toggle), 4 FilledButton quick-add presets, floating 5s SnackBar with UNDO, newest-first intake timeline, and AppLifecycleListener + Timer.periodic midnight reset
- Full settings screen with daily target slider (1000-10000 ml), 4 preset edit dialogs (50-2000 ml validated), notification interval slider (5-240 min), and DND toggle with time pickers -- all live-saving via existing SettingsRepository
- Monthly calendar with green/red day decoration via TableCalendar CalendarBuilders, streak counter card with walk-backward algorithm, and keepAlive focused-month persistence across tab switches
- Scheduled hydration reminders with rolling 64-slot window, DND-aware TZDateTime scheduling, first-launch PermissionScreen, and goal-reached auto-stop via ref.listen in HomeScreen

---
