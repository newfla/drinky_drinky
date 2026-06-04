# Phase 2: Core Tracking UI - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 replaces the three placeholder screens with a functional home screen. Deliverables:

1. **Bottom navigation shell** — migrate GoRouter from flat routes to `StatefulShellRoute.indexedStack` with 3 tabs: Home, History, Settings
2. **Home screen** — animated circular progress ring, 4 quick-add preset FilledButtons, SnackBar undo, and a chronological timeline of today's intakes
3. **Tab stubs** — History and Settings tabs show "Coming soon" placeholder while awaiting Phases 3 and 4
4. **Midnight reset** — home screen auto-resets daily counter at midnight without requiring app relaunch

No settings editing, no calendar, no notifications in this phase.

</domain>

<decisions>
## Implementation Decisions

### Midnight Reset Behavior
- **D-01:** Auto-reset at midnight — a timer (or `AppLifecycleListener`) detects the day boundary and triggers a widget rebuild with the new `todayDateKey()`. The user's ring and timeline reset to 0 without relaunching.
- **D-02:** Reset is silent — no animation when the counter resets at midnight. Ring jumps immediately to 0%.

### Logging Past 100% of Daily Goal
- **D-03:** Logging continues after 100% — preset buttons remain active. Additional entries are recorded and the total keeps incrementing in the center text (e.g., "2200 / 2000 ml").
- **D-04:** Progress ring visually caps at 100% and stays green — no overflow arc. The ring stays filled and green regardless of how much over-goal the user logs.
- **D-05:** Undo always works — SnackBar UNDO is available after every quick-add tap, including after the goal is reached. The ring reverts to blue automatically (stream-driven) if an undo drops total below 100%.

### Navigation & Tab Behavior
- **D-06:** Always start on Home tab — GoRouter `initialLocation` stays at `'/'`. No tab persistence between launches.
- **D-07:** History and Settings stubs — centered "Coming soon" text with the screen title in the AppBar. These are real NavigationBar destinations but display placeholder content until Phases 3/4.

### UI Design Contract (locked in UI-SPEC)
All visual and interaction contracts are locked in `02-UI-SPEC.md`. Key locks:
- Bottom NavigationBar with `StatefulShellRoute.indexedStack` (tabs: Home / History / Settings)
- `CircularPercentIndicator` — 200px diameter, blue fill → green at 100%, center shows current / target ml
- 4 FilledButton presets (+200 ml / +300 ml / +400 ml / +500 ml) in a single row
- SnackBar pattern: "+{amount} ml added  [UNDO]", 5-second auto-dismiss, calls `deleteLastEntry`
- Simple `ListView` for today's timeline — rows: HH:mm left, +{amount} ml right
- M3 color palette: surface (60%), surfaceContainerLow (30%), primary blue (10% accent)
- 8-pt spacing scale (4/8/16/24/32/48/64px)

### Claude's Discretion
- SnackBar clearing between rapid taps (whether to call `clearSnackBars()` before showing next) — pick standard Material pattern
- Combining multiple Riverpod streams on HomeScreen (async coordination, loading state display)
- Exact timer mechanism for midnight reset (Timer.periodic vs AppLifecycleListener)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — HOME-01 through HOME-04 (the 4 requirements this phase must satisfy)
- `.planning/ROADMAP.md` — Phase 2 section: goal, success criteria, mode

### Design Contract
- `.planning/phases/02-core-tracking-ui/02-UI-SPEC.md` — locked UI design contract: spacing, typography, color, copywriting, component specs, registry. Planner MUST read this. All visual decisions defer to this file.

### Prior Phase Decisions
- `.planning/phases/01-data-foundation/01-CONTEXT.md` — D-05 (default target 2000ml), D-06 (preset defaults 200/300/400/500ml), D-12 (folder structure), D-11 (GoRouter already wired)

### Code Integration Points
- `lib/core/providers/stream_providers.dart` — the 4 stream providers (`waterEntriesForDate`, `totalMlForDate`, `userSettings`, `drinkPresets`) and `todayDateKey()` helper that Phase 2 consumes
- `lib/core/router/app_router.dart` — current flat GoRoute router; must be migrated to `StatefulShellRoute.indexedStack` for bottom nav
- `lib/presentation/screens/home_screen.dart` — placeholder to replace with full implementation
- `lib/presentation/screens/history_screen.dart` — placeholder; Phase 2 adds "Coming soon" stub only
- `lib/presentation/screens/settings_screen.dart` — placeholder; Phase 2 adds "Coming soon" stub only

### Stack Reference
- `CLAUDE.md` — Tech Stack table: `percent_indicator ^4.2.5` approved (not yet in pubspec.yaml); `flutter_riverpod`, `drift`, `go_router` versions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `todayDateKey()` in `lib/core/providers/stream_providers.dart` — returns `YYYY-MM-DD` string for today; call at widget build time to get the correct date key
- `waterEntriesForDate(ref, dateKey)` — stream of today's `WaterEntryEntity` list (has `amountMl`, `loggedAt`)
- `totalMlForDate(ref, dateKey)` — stream of today's total intake as `int`
- `userSettings(ref)` — stream of `UserSettingsEntity` (has `dailyTargetMl`)
- `drinkPresets(ref)` — stream of `List<DrinkPresetEntity>` (sorted by `sortOrder`, has `amountMl`)
- `waterRepositoryProvider` / `settingsRepositoryProvider` — for write operations (`insertEntry`, `deleteLastEntry`)

### Established Patterns
- Riverpod code-gen: all providers use `@riverpod` / `@Riverpod(keepAlive: true)` annotations + `part '*.g.dart'` — Phase 2 widgets use `ConsumerWidget` / `ConsumerStatefulWidget`
- Layer-first folders: new UI code goes in `lib/presentation/screens/home_screen.dart` (and subwidgets in `lib/presentation/widgets/` if extracted)
- GoRouter already provides the `routerConfig` to `MaterialApp.router` — Phase 2 changes the router internals only

### Integration Points
- Router migration: `appRouter` provider in `lib/core/router/app_router.dart` must wrap existing routes inside a `StatefulShellRoute.indexedStack` shell. The `HomeScreen`, `HistoryScreen`, `SettingsScreen` builders remain but become shell branches.
- `percent_indicator` must be added to `pubspec.yaml` and `flutter pub get` run before writing home screen widgets
- `ScaffoldMessenger` at the shell level must be accessible for SnackBar display from within shell branches

</code_context>

<specifics>
## Specific Ideas

- The ring caps visually at 100% (stays green/filled) even when total exceeds the target — only the center text overflows ("2200 / 2000 ml"). No overflow arc.
- The midnight reset must use `todayDateKey()` called fresh (not cached) — the timer/listener triggers a `setState` or state invalidation so the widget rebuilds with the new date string and re-subscribes the stream.
- "Coming soon" stubs are intentional — do not make them look like errors. Use the screen title in the AppBar and centered body text.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-core-tracking-ui*
*Context gathered: 2026-06-04*
