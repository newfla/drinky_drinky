# Milestones

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
