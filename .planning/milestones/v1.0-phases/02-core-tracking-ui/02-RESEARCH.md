# Phase 2: Core Tracking UI - Research

**Researched:** 2026-06-04
**Domain:** Flutter UI / GoRouter navigation / Riverpod async state / percent_indicator widget
**Confidence:** HIGH

## Summary

Phase 2 replaces three placeholder screens with a functional home screen featuring an animated circular progress ring, quick-add preset buttons with SnackBar undo, and a chronological timeline of today's water intakes. It also migrates the GoRouter from flat routes to `StatefulShellRoute.indexedStack` to support a bottom `NavigationBar` with persistent tab state across three tabs (Home, History, Settings).

The technical foundation from Phase 1 is complete: four Riverpod stream providers (`waterEntriesForDateProvider`, `totalMlForDateProvider`, `userSettingsProvider`, `drinkPresetsProvider`), two repository providers (`waterRepositoryProvider`, `settingsRepositoryProvider`), Freezed domain entities, and Drift DAOs with reactive streams. Phase 2 is purely a presentation-layer phase that consumes these existing providers. The single new dependency is `percent_indicator: ^4.2.5` which must be added to `pubspec.yaml`.

The two main complexity areas are: (1) the router migration from flat `GoRoute` list to `StatefulShellRoute.indexedStack` with a shell builder wrapping `NavigationBar`, and (2) coordinating four `AsyncValue` streams in the home screen widget without excessive loading/error state complexity.

**Primary recommendation:** Use `ConsumerStatefulWidget` for HomeScreen to support both `AppLifecycleListener` (for midnight reset detection) and `ref.watch()` for multiple stream providers. Place the `Scaffold` inside the shell builder so `ScaffoldMessenger` context is correctly scoped for SnackBar display from within shell branches.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Auto-reset at midnight -- a timer (or `AppLifecycleListener`) detects the day boundary and triggers a widget rebuild with the new `todayDateKey()`. The user's ring and timeline reset to 0 without relaunching.
- **D-02:** Reset is silent -- no animation when the counter resets at midnight. Ring jumps immediately to 0%.
- **D-03:** Logging continues after 100% -- preset buttons remain active. Additional entries are recorded and the total keeps incrementing in the center text (e.g., "2200 / 2000 ml").
- **D-04:** Progress ring visually caps at 100% and stays green -- no overflow arc. The ring stays filled and green regardless of how much over-goal the user logs.
- **D-05:** Undo always works -- SnackBar UNDO is available after every quick-add tap, including after the goal is reached. The ring reverts to blue automatically (stream-driven) if an undo drops total below 100%.
- **D-06:** Always start on Home tab -- GoRouter `initialLocation` stays at `'/'`. No tab persistence between launches.
- **D-07:** History and Settings stubs -- centered "Coming soon" text with the screen title in the AppBar. These are real NavigationBar destinations but display placeholder content until Phases 3/4.

### Claude's Discretion
- SnackBar clearing between rapid taps (whether to call `clearSnackBars()` before showing next) -- pick standard Material pattern
- Combining multiple Riverpod streams on HomeScreen (async coordination, loading state display)
- Exact timer mechanism for midnight reset (Timer.periodic vs AppLifecycleListener)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOME-01 | User can see their daily water intake progress via an animated circular progress bar showing current intake vs daily target | CircularPercentIndicator API section: `percent` clamped to 1.0, `animateFromLastPercent: true`, `progressColor` toggled between blue/green at 100%. Center child shows "current / target ml" text. |
| HOME-02 | User can log water intake with a single tap via quick-add preset buttons showing the amount in ml | Quick-add FilledButtons consume `drinkPresetsProvider` for amounts, call `waterRepository.insertEntry()`. Stream providers auto-update ring + timeline. |
| HOME-03 | User can undo the last water entry from the home screen | SnackBar with 5-second duration and UNDO action calling `waterRepository.deleteLastEntry(dateKey)`. `clearSnackBars()` before each new SnackBar prevents queue buildup. |
| HOME-04 | User can see a chronological timeline of today's individual intakes with timestamp and amount below the progress bar | `waterEntriesForDateProvider(dateKey)` drives a `ListView.builder` showing newest-first entries with HH:mm timestamp and amount. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack locked:** Flutter + Riverpod + Drift -- no deviation
- **Platform:** iOS and Android only
- **Offline-first:** No backend or cloud sync
- **Riverpod style:** Use `flutter_riverpod`, not `hooks_riverpod`; all providers use `@riverpod` code-gen annotations
- **Layer-first folder structure:** New UI code in `lib/presentation/screens/` and `lib/presentation/widgets/`
- **Database setup:** `drift_flutter` (not `sqlite3_flutter_libs` which is EOL)
- **Packages NOT to use:** GetX, provider (standalone), hive/isar, awesome_notifications, flutter_native_timezone
- **percent_indicator ^4.2.5:** Approved in CLAUDE.md but not yet in pubspec.yaml -- must be added

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Progress ring display | Frontend (Flutter widget) | -- | Pure presentation: reads `totalMlForDate` stream, computes percentage, renders CircularPercentIndicator |
| Quick-add logging | Frontend (Flutter widget) | Database (Drift) | Button tap triggers repository write; Drift stream auto-emits updated data back to widget |
| Undo last entry | Frontend (SnackBar action) | Database (Drift) | SnackBar UNDO action calls `deleteLastEntry`; Drift stream auto-reverts UI |
| Timeline display | Frontend (Flutter widget) | -- | Reads `waterEntriesForDate` stream, renders ListView |
| Bottom navigation | Frontend (GoRouter shell) | -- | `StatefulShellRoute.indexedStack` manages tab state; `NavigationBar` widget renders tabs |
| Midnight reset | Frontend (lifecycle listener) | -- | `AppLifecycleListener.onResume` or `Timer.periodic` triggers `setState` to refresh `todayDateKey()` |
| Data persistence | Database (Drift) | -- | Already implemented in Phase 1; Phase 2 only consumes via repository providers |

## Standard Stack

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | 3.3.1 | Widget-level state management | Installed in Phase 1; provides `ConsumerWidget`/`ConsumerStatefulWidget` for `ref.watch()` |
| go_router | 17.3.0 | Declarative routing with shell support | Installed in Phase 1; `StatefulShellRoute.indexedStack` is the standard pattern for bottom nav |
| drift | 2.33.0 | Reactive SQLite ORM | Installed in Phase 1; streams auto-update UI via Riverpod |
| freezed_annotation | 3.1.0 | Immutable domain entities | Installed in Phase 1; entities already defined |

### New for Phase 2
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| percent_indicator | 4.2.5 | Circular progress ring widget | CLAUDE.md approved; provides `CircularPercentIndicator` with animation, color, center child, stroke cap customization |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| percent_indicator | CustomPainter | Requires ~100 lines of boilerplate for animation, gradient, child layout that percent_indicator provides out of the box. CLAUDE.md explicitly notes this. |
| NavigationBar (M3) | BottomNavigationBar | BottomNavigationBar is M2; project uses `useMaterial3: true`. NavigationBar is the M3 successor. |

**Installation:**
```bash
# Add to pubspec.yaml dependencies section:
# percent_indicator: ^4.2.5
flutter pub get  # (via fvm: fvm flutter pub get)
```

## Package Legitimacy Audit

> slopcheck was unavailable at research time. All packages are tagged `[ASSUMED]` per protocol.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| percent_indicator | pub.dev | ~6 yrs | Very high (established) | github.com/diegoveloper/flutter_percent_indicator | N/A | Approved [ASSUMED] -- listed in CLAUDE.md tech stack |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. The single new package (`percent_indicator`) is listed in the project's CLAUDE.md tech stack table and has been on pub.dev for ~6 years, which provides reasonable confidence. The planner should still gate the install behind a checkpoint.*

## Architecture Patterns

### System Architecture Diagram

```
User Tap (FilledButton)
        |
        v
+-------------------+      +--------------------+
| HomeScreen        |      | WaterRepository    |
| (ConsumerStateful |----->| .insertEntry()     |
|  Widget)          |      | .deleteLastEntry() |
+-------------------+      +--------------------+
        |  ref.watch()              |
        v                           v
+-------------------+      +--------------------+
| Stream Providers  |<-----| Drift DAOs         |
| totalMlForDate    |      | .watchTotalForDate |
| waterEntriesFor   |      | .watchEntriesFor   |
| userSettings      |      | Date()             |
| drinkPresets      |      +--------------------+
+-------------------+
        |
        v
+-------------------+
| UI Widgets        |
| CircularPercent   |
| Indicator         |
| ListView.builder  |
| FilledButtons     |
| SnackBar (undo)   |
+-------------------+

Navigation Shell:
+----------------------------------------------+
| StatefulShellRoute.indexedStack               |
|  +------------------+                        |
|  | Scaffold         |                        |
|  |  body: shell     |                        |
|  |  bottomNav: Bar  |                        |
|  +------------------+                        |
|  Branches: [Home] [History stub] [Settings]  |
+----------------------------------------------+
```

### Recommended Project Structure
```
lib/
├── core/
│   ├── providers/       # Existing: stream_providers, repository_providers, database_provider
│   └── router/
│       └── app_router.dart  # MODIFIED: migrate to StatefulShellRoute.indexedStack
├── data/                # Existing: unchanged in Phase 2
├── domain/              # Existing: unchanged in Phase 2
└── presentation/
    ├── screens/
    │   ├── home_screen.dart      # REWRITTEN: ConsumerStatefulWidget with full UI
    │   ├── history_screen.dart   # MODIFIED: "Coming soon" stub with AppBar title
    │   └── settings_screen.dart  # MODIFIED: "Coming soon" stub with AppBar title
    └── widgets/                  # NEW: optional extraction of home screen sub-widgets
        ├── progress_ring.dart    # Optional: extracted CircularPercentIndicator wrapper
        ├── quick_add_row.dart    # Optional: extracted preset buttons row
        └── intake_timeline.dart  # Optional: extracted timeline ListView
```

### Pattern 1: StatefulShellRoute.indexedStack with NavigationBar

**What:** GoRouter `StatefulShellRoute.indexedStack` wraps three branches in a shell builder that renders a `Scaffold` with a `NavigationBar` at the bottom. Each branch maintains its own navigator state.

**When to use:** Any app with bottom navigation that needs persistent tab state.

**Example:**
```dart
// Source: go_router official example (github.com/flutter/packages)
// Verified via pub.dev/documentation/go_router/latest StatefulShellRoute API docs

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) =>
                  navigationShell.goBranch(index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```

**Key detail:** The `Scaffold` is in the shell builder, NOT inside individual screen widgets. Each screen (HomeScreen, HistoryScreen, SettingsScreen) should NOT have its own `Scaffold` -- they should return their content directly (with an `AppBar` if needed via a nested `Scaffold`, or better: the shell builder's Scaffold gets the AppBar from the active branch). 

**Important architectural choice:** Each branch screen CAN have its own `Scaffold` with its own `AppBar`. The shell builder's `Scaffold` provides the `NavigationBar`. This nested-Scaffold pattern is standard in GoRouter shell routes -- the shell Scaffold handles the bottom nav, and each branch Scaffold handles its own AppBar. `ScaffoldMessenger` will find the nearest Scaffold ancestor, which for SnackBars inside branch screens will be the branch's Scaffold (not the shell's).

### Pattern 2: CircularPercentIndicator with Dynamic Color

**What:** Use `percent_indicator`'s `CircularPercentIndicator` with `animateFromLastPercent: true` so the ring animates smoothly between values. Change `progressColor` based on whether the goal is met.

**When to use:** Displaying a clamped progress value with visual feedback at the goal threshold.

**Example:**
```dart
// Source: github.com/diegoveloper/flutter_percent_indicator (verified constructor API)

final percentage = (totalMl / dailyTargetMl).clamp(0.0, 1.0);
final isGoalMet = totalMl >= dailyTargetMl;

CircularPercentIndicator(
  radius: 100.0,  // 200px diameter = 100 radius
  lineWidth: 12.0,
  percent: percentage,
  animation: true,
  animationDuration: 600,
  animateFromLastPercent: true,
  circularStrokeCap: CircularStrokeCap.round,
  progressColor: isGoalMet
      ? Colors.green.shade600
      : Theme.of(context).colorScheme.primary,
  backgroundColor: Theme.of(context)
      .colorScheme
      .surfaceContainerHighest
      .withOpacity(0.3),
  center: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        isGoalMet ? 'Goal reached!' : '$totalMl / $dailyTargetMl ml',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isGoalMet ? Colors.green.shade600 : null,
            ),
      ),
    ],
  ),
)
```

**Critical note on `radius` parameter:** The `percent_indicator` package uses `radius` as the distance from center to the outer edge -- so a `radius: 100.0` produces a 200px diameter widget. This matches the UI-SPEC requirement of "200px diameter". [CITED: github.com/diegoveloper/flutter_percent_indicator source code]

### Pattern 3: Multi-Stream AsyncValue Coordination in Riverpod

**What:** When a widget needs data from multiple async providers, watch them all and handle the combined loading/error state.

**When to use:** HomeScreen needs `userSettings`, `totalMlForDate`, `waterEntriesForDate`, and `drinkPresets` simultaneously.

**Example:**
```dart
// Source: Riverpod pattern for combining AsyncValues [ASSUMED]

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late String _dateKey;

  @override
  void initState() {
    super.initState();
    _dateKey = todayDateKey();
    // Set up midnight reset mechanism here
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final totalAsync = ref.watch(totalMlForDateProvider(_dateKey));
    final entriesAsync = ref.watch(waterEntriesForDateProvider(_dateKey));
    final presetsAsync = ref.watch(drinkPresetsProvider);

    // Guard on the two critical values: settings + total
    // Settings and presets are keepAlive so they load once.
    // Total and entries are date-keyed and autoDispose.
    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (settings) {
        final totalMl = totalAsync.valueOrNull ?? 0;
        final entries = entriesAsync.valueOrNull ?? [];
        final presets = presetsAsync.valueOrNull ?? [];

        return Column(
          children: [
            // Progress ring uses settings.dailyTargetMl and totalMl
            // Quick-add row uses presets
            // Timeline uses entries
          ],
        );
      },
    );
  }
}
```

**Rationale for `valueOrNull` fallback:** Settings is the critical dependency (determines the denominator). Total and entries can safely default to 0 / empty list during their brief initial load because they share the same Drift database stream subscription lifecycle. This avoids a nested `when()` chain that would flash loading states unnecessarily. [ASSUMED]

### Pattern 4: Midnight Reset via AppLifecycleListener + Timer

**What:** Detect day boundary crossing so the progress ring and timeline reset to the new day's data.

**When to use:** When the app may be open across midnight, or resumed from background after midnight.

**Recommended approach (Claude's discretion):** Use a dual strategy:

1. **`AppLifecycleListener.onResume`** -- catches the most common case: user opens app the next morning. On resume, compare the stored `_dateKey` against a fresh `todayDateKey()`. If different, call `setState` to update `_dateKey`, which causes all date-keyed providers to re-subscribe.

2. **`Timer.periodic` (60-second interval)** -- catches the edge case where the user is actively using the app at midnight. Every 60 seconds, check if `todayDateKey()` has changed. If so, `setState` to update `_dateKey`.

**Example:**
```dart
// Source: Flutter AppLifecycleListener API docs (api.flutter.dev) [CITED]

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late String _dateKey;
  late AppLifecycleListener _lifecycleListener;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _dateKey = todayDateKey();
    
    _lifecycleListener = AppLifecycleListener(
      onResume: _checkDateChange,
    );
    
    _midnightTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkDateChange(),
    );
  }

  void _checkDateChange() {
    final newKey = todayDateKey();
    if (newKey != _dateKey) {
      setState(() {
        _dateKey = newKey;
      });
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }
}
```

**Why both mechanisms:** `AppLifecycleListener.onResume` alone misses the case where the user has the app in the foreground at midnight. `Timer.periodic` alone wastes CPU if the app is backgrounded (though Flutter pauses timers in background, so the timer fires on resume anyway -- making the lifecycle listener redundant in theory). Using both is belt-and-suspenders at negligible cost. [ASSUMED]

### Pattern 5: SnackBar with Undo in Shell Context

**What:** Show a floating SnackBar after each quick-add with an UNDO action. Clear previous SnackBars before showing new ones to prevent queue buildup.

**When to use:** After every `insertEntry()` call.

**Claude's discretion recommendation:** Call `ScaffoldMessenger.of(context).clearSnackBars()` before showing each new SnackBar. This is the standard Material pattern for rapid-fire actions -- it prevents a queue of 5+ SnackBars stacking up.

**Example:**
```dart
// Source: Flutter ScaffoldMessengerState API (api.flutter.dev) [CITED]

void _onQuickAdd(int amountMl) async {
  final repo = ref.read(waterRepositoryProvider);
  await repo.insertEntry(amountMl, DateTime.now(), _dateKey);
  
  if (!mounted) return;
  
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('+$amountMl ml added'),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await repo.deleteLastEntry(_dateKey);
        },
      ),
    ),
  );
}
```

**SnackBar context in StatefulShellRoute:** Since each branch screen has its own `Scaffold`, `ScaffoldMessenger.of(context)` from within the HomeScreen will find the HomeScreen's Scaffold. The SnackBar will appear above the shell's `NavigationBar` because the branch Scaffold is nested inside the shell Scaffold. The `SnackBarBehavior.floating` with margin ensures it does not overlap the NavigationBar. [ASSUMED -- needs runtime verification]

### Anti-Patterns to Avoid
- **Nested `when()` chains:** Do NOT write `settingsAsync.when(data: (s) => totalAsync.when(data: (t) => ...))`. This creates deeply nested code and flashes loading states for each stream independently. Use `valueOrNull` with safe defaults for non-critical streams.
- **Scaffold in shell builder AND branch screens without understanding context:** Each branch screen SHOULD have its own Scaffold if it needs its own AppBar. The shell builder's Scaffold provides the NavigationBar. This nested pattern is intentional and correct.
- **Caching `todayDateKey()` without refresh mechanism:** If `_dateKey` is set in `initState` and never updated, the app shows yesterday's data after midnight. Always pair with AppLifecycleListener + Timer.
- **Using `CircularPercentIndicator(percent: totalMl / target)` without clamp:** If totalMl exceeds target, percent > 1.0 may cause rendering issues. Always `clamp(0.0, 1.0)`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Circular progress ring with animation | Custom `CustomPainter` with `AnimationController` | `CircularPercentIndicator` from `percent_indicator` | ~100 lines of boilerplate for animation, gradient, child layout; edge cases with stroke caps and arc math |
| Bottom navigation with persistent tab state | Manual `IndexedStack` + route management | `StatefulShellRoute.indexedStack` from `go_router` | GoRouter handles navigator keys, state preservation, deep linking, and back button behavior automatically |
| Reactive data streams to widgets | Manual `StreamBuilder` nesting | Riverpod `ref.watch()` on stream providers | Riverpod handles subscription lifecycle, caching, auto-dispose, and error propagation |

**Key insight:** Phase 2 is a pure consumer of Phase 1's data layer. Every write operation goes through existing repositories, and every read comes through existing stream providers. The only new code is presentation-layer widgets and the router migration.

## Common Pitfalls

### Pitfall 1: CircularPercentIndicator percent > 1.0
**What goes wrong:** Passing a `percent` value greater than 1.0 can cause visual artifacts or assertion errors in the paint method.
**Why it happens:** When user logs past their daily goal (e.g., 2200ml / 2000ml = 1.1), the raw division exceeds 1.0.
**How to avoid:** Always clamp: `(totalMl / dailyTargetMl).clamp(0.0, 1.0)`. Decision D-04 explicitly requires this.
**Warning signs:** Ring arc extends past full circle, or assertion error in debug mode.

### Pitfall 2: Division by zero in percentage calculation
**What goes wrong:** If `dailyTargetMl` is 0, dividing by it causes infinity or NaN.
**Why it happens:** Edge case if database seed fails or settings are corrupted.
**How to avoid:** Guard: `final percentage = dailyTargetMl > 0 ? (totalMl / dailyTargetMl).clamp(0.0, 1.0) : 0.0;`. The repository already validates `dailyTargetMl > 0` on writes, but defensive coding in the UI is cheap insurance.
**Warning signs:** NaN in the progress ring, or infinite loop in animation.

### Pitfall 3: SnackBar UNDO after date rolls over
**What goes wrong:** User taps UNDO at 00:01 for an entry logged at 23:59. The `_dateKey` may have already changed to the new day, but `deleteLastEntry` uses the old date key captured at log time.
**Why it happens:** The SnackBar closure captures `_dateKey` at the time of the quick-add, but the midnight reset changes `_dateKey` in state.
**How to avoid:** Capture the date key in a local variable at the time of the quick-add, not by reading `_dateKey` in the SnackBar action closure. Use: `final capturedKey = _dateKey;` before the async call, then `repo.deleteLastEntry(capturedKey)` in the UNDO action.
**Warning signs:** UNDO silently fails (deletes 0 rows from wrong date) or deletes from wrong day.

### Pitfall 4: ScaffoldMessenger context not found in StatefulShellRoute
**What goes wrong:** `ScaffoldMessenger.of(context)` throws "No ScaffoldMessenger widget found" if called from a context that is above the Scaffold.
**Why it happens:** In the shell route pattern, the Scaffold is in the shell builder. If branch screens don't have their own Scaffold, the context inside the branch builder is below the shell builder's Scaffold, which should work. But if the screen tries to show a SnackBar from a callback that doesn't have the right context, it fails.
**How to avoid:** Each branch screen has its own Scaffold (for AppBar). `ScaffoldMessenger.of(context)` from within the screen's build tree will find this Scaffold. Alternatively, use `rootScaffoldMessengerKey` pattern, but the nested Scaffold approach is simpler.
**Warning signs:** Assertion error about missing ScaffoldMessenger ancestor in debug mode.

### Pitfall 5: Timer.periodic not cancelled on dispose
**What goes wrong:** Memory leak and potential `setState()` called after dispose.
**Why it happens:** If the HomeScreen is disposed (e.g., app is terminated) while the timer is still active.
**How to avoid:** Cancel the timer in `dispose()`. Use `_midnightTimer?.cancel()`. Also check `mounted` before calling `setState()` in the timer callback.
**Warning signs:** "setState() called after dispose()" error in debug console.

### Pitfall 6: go_router StatefulShellRoute branch must have exactly one root route starting with '/'
**What goes wrong:** Each `StatefulShellBranch` must have route paths that form a valid hierarchy. If a branch's root route path doesn't match the expected pattern, navigation fails silently or throws.
**Why it happens:** Misconfigured branch route paths (e.g., missing leading slash, or nested paths without parent).
**How to avoid:** Each branch has exactly one root `GoRoute` with an absolute path: `/`, `/history`, `/settings`. The `initialLocation: '/'` matches branch 0.
**Warning signs:** App shows blank screen or assertion error on launch.

## Code Examples

### Complete HomeScreen Structure (verified patterns)

```dart
// Source: Combination of verified APIs:
// - ConsumerStatefulWidget: flutter_riverpod [CITED: pub.dev]
// - AppLifecycleListener: api.flutter.dev [CITED]
// - CircularPercentIndicator: github.com/diegoveloper/flutter_percent_indicator [CITED]
// - ScaffoldMessengerState.clearSnackBars: api.flutter.dev [CITED]

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late String _dateKey;
  late AppLifecycleListener _lifecycleListener;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _dateKey = todayDateKey();
    _lifecycleListener = AppLifecycleListener(onResume: _checkDateChange);
    _midnightTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkDateChange(),
    );
  }

  void _checkDateChange() {
    final newKey = todayDateKey();
    if (newKey != _dateKey && mounted) {
      setState(() => _dateKey = newKey);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final totalAsync = ref.watch(totalMlForDateProvider(_dateKey));
    final entriesAsync = ref.watch(waterEntriesForDateProvider(_dateKey));
    final presetsAsync = ref.watch(drinkPresetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Drinky Drinky')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong loading your data.')),
        data: (settings) {
          final totalMl = totalAsync.valueOrNull ?? 0;
          final entries = entriesAsync.valueOrNull ?? <WaterEntryEntity>[];
          final presets = presetsAsync.valueOrNull ?? <DrinkPresetEntity>[];

          return _buildContent(context, settings, totalMl, entries, presets);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserSettingsEntity settings,
    int totalMl,
    List<WaterEntryEntity> entries,
    List<DrinkPresetEntity> presets,
  ) {
    final target = settings.dailyTargetMl;
    final percentage = target > 0 ? (totalMl / target).clamp(0.0, 1.0) : 0.0;
    final isGoalMet = totalMl >= target;
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 48), // 2xl top padding
        // Progress Ring
        CircularPercentIndicator(
          radius: 100.0,
          lineWidth: 12.0,
          percent: percentage,
          animation: true,
          animationDuration: 600,
          animateFromLastPercent: true,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: isGoalMet
              ? Colors.green.shade600
              : theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerHighest
              .withOpacity(0.3),
          center: Text(
            isGoalMet ? 'Goal reached!' : '$totalMl / $target ml',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isGoalMet ? Colors.green.shade600 : null,
            ),
          ),
        ),
        const SizedBox(height: 24), // lg spacing
        // Quick-Add Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: presets.map((preset) {
              return FilledButton(
                onPressed: () => _onQuickAdd(preset.amountMl),
                child: Text('+${preset.amountMl} ml'),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32), // xl spacing
        // Timeline Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Today's Intake",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Timeline List
        Expanded(
          child: entries.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final time =
                        '${entry.loggedAt.hour.toString().padLeft(2, '0')}:'
                        '${entry.loggedAt.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      tileColor: theme.colorScheme.surfaceContainerLow,
                      leading: Text(
                        time,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '+${entry.amountMl} ml',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No drinks logged yet',
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text('Tap a button above to log your first drink today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }

  void _onQuickAdd(int amountMl) async {
    final capturedKey = _dateKey; // Capture before async gap
    final repo = ref.read(waterRepositoryProvider);
    await repo.insertEntry(amountMl, DateTime.now(), capturedKey);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('+$amountMl ml added'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await repo.deleteLastEntry(capturedKey);
          },
        ),
      ),
    );
  }
}
```

### Router Migration (before/after)

```dart
// BEFORE (Phase 1 -- current code in app_router.dart):
GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
)

// AFTER (Phase 2 -- StatefulShellRoute.indexedStack):
GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.water_drop_outlined),
                selectedIcon: Icon(Icons.water_drop),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
)
```

### Stub Screen Pattern (History and Settings)

```dart
// Source: UI-SPEC copywriting contract [CITED: 02-UI-SPEC.md]

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `BottomNavigationBar` (M2) | `NavigationBar` (M3) | Flutter 3.7+ | M3 default with `useMaterial3: true`; different API (uses `NavigationDestination` not `BottomNavigationBarItem`) |
| `ShellRoute` (single navigator) | `StatefulShellRoute.indexedStack` | go_router 7.0+ | Persistent tab state across branches; each tab maintains its own navigator stack |
| Manual `StreamBuilder` nesting | Riverpod `ref.watch()` with code-gen providers | Riverpod 2.0+ | Declarative, auto-disposing, cached stream subscriptions |
| `WidgetsBindingObserver` mixin | `AppLifecycleListener` class | Flutter 3.13+ | Cleaner API; no mixin boilerplate; callback-based instead of override-based |

**Deprecated/outdated:**
- `WidgetsBindingObserver.didChangeAppLifecycleState`: Still works but `AppLifecycleListener` is the modern replacement with more granular callbacks (`onResume`, `onHide`, `onShow`, etc.) [CITED: api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html]
- `BottomNavigationBar`: Still available but `NavigationBar` is the M3 replacement; using M2 widget with `useMaterial3: true` produces visual inconsistencies

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `valueOrNull` with safe defaults is preferable to nested `when()` chains for non-critical streams | Architecture Patterns (Pattern 3) | If Riverpod's `valueOrNull` behaves differently than expected, could show stale/default data briefly. LOW risk -- well-documented Riverpod API. |
| A2 | SnackBar with `SnackBarBehavior.floating` and margin correctly positions above the NavigationBar in nested Scaffold pattern | Architecture Patterns (Pattern 5) | If SnackBar overlaps NavigationBar, need to adjust margin or use `ScaffoldMessenger` from shell level. MEDIUM risk -- needs runtime verification. |
| A3 | Timer.periodic pauses when app is backgrounded on iOS/Android and fires immediately on resume | Architecture Patterns (Pattern 4) | If timer continues in background, it wastes battery (minor). If it doesn't fire on resume, the AppLifecycleListener covers it (no risk due to belt-and-suspenders). LOW risk. |
| A4 | `percent_indicator`'s `radius` parameter represents the actual radius (half of diameter), producing a 200px diameter widget at `radius: 100.0` | Architecture Patterns (Pattern 2) | If `radius` means diameter, the ring would be 200px radius / 400px diameter -- too large. Verified via GitHub source: parameter IS radius. LOW risk. |
| A5 | Package `percent_indicator ^4.2.5` is legitimate | Package Legitimacy Audit | Listed in project's CLAUDE.md, 6+ years on pub.dev, verified publisher. Very LOW risk. |

## Open Questions

1. **SnackBar positioning above NavigationBar**
   - What we know: `SnackBarBehavior.floating` with margin should float above bottom obstacles. The branch screen's Scaffold is inside the shell Scaffold.
   - What's unclear: Whether the floating SnackBar correctly accounts for the shell's NavigationBar height, or if it gets clipped/overlapped.
   - Recommendation: Test during implementation. If overlap occurs, use `ScaffoldMessenger` from the shell builder's context or add bottom padding to SnackBar margin equal to NavigationBar height (~80px).

2. **`withOpacity(0.3)` deprecation**
   - What we know: In newer Flutter versions, `Color.withOpacity()` may be deprecated in favor of `Color.withValues(alpha: 0.3)`.
   - What's unclear: Whether Flutter 3.44.1 has already deprecated `withOpacity`.
   - Recommendation: Check during implementation. If deprecated, use `withValues(alpha: 0.3)` or `Color.fromARGB()`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Entire phase | Yes (via fvm) | 3.44.1 | -- |
| Dart SDK | Entire phase | Yes (via fvm) | 3.12.1 | -- |
| build_runner | Code generation after router changes | Yes | 2.15.0 | -- |
| percent_indicator | Progress ring widget | No (not yet in pubspec.yaml) | -- | Must be added: `percent_indicator: ^4.2.5` |

**Missing dependencies with no fallback:**
- `percent_indicator` must be added to `pubspec.yaml` before writing HomeScreen code

**Missing dependencies with fallback:**
- None

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- offline app, no auth |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single user, local only |
| V5 Input Validation | Yes | Repository-level validation already in place (Phase 1): `amountMl > 0`, `dateKey` format check. UI buttons use preset values from DB, so no free-form user input reaches the repository. |
| V6 Cryptography | No | N/A -- no encryption needed |

### Known Threat Patterns for Flutter UI Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Negative/zero amount injection via preset tampering | Tampering | Repository validates `amountMl > 0` (already implemented). UI reads preset amounts from DB (trusted source). |
| Invalid date key after midnight race | Tampering | `todayDateKey()` called fresh at each interaction; `dateKey` captured before async gap in UNDO handler (Pitfall 3). |

This phase has minimal security surface because it is a read/write UI for local data with no network calls, no user-provided free text, and no authentication. The primary defense is the input validation already in place in the Phase 1 repository layer.

## Sources

### Primary (HIGH confidence)
- [go_router StatefulShellRoute API] - pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html -- constructor signature, indexedStack factory, branches parameter
- [go_router StatefulShellBranch API] - pub.dev/documentation/go_router/latest/go_router/StatefulShellBranch-class.html -- routes, navigatorKey, initialLocation
- [go_router StatefulNavigationShell API] - pub.dev/documentation/go_router/latest/go_router/StatefulNavigationShell-class.html -- currentIndex, goBranch()
- [go_router official example] - github.com/flutter/packages/.../stateful_shell_route.dart -- shell builder + NavigationBar pattern
- [percent_indicator source] - github.com/diegoveloper/flutter_percent_indicator -- CircularPercentIndicator full constructor API
- [Flutter AppLifecycleListener] - api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html -- onResume callback, constructor
- [Flutter NavigationBar] - api.flutter.dev/flutter/material/NavigationBar-class.html -- M3 bottom nav constructor
- [Flutter NavigationDestination] - api.flutter.dev/flutter/material/NavigationDestination-class.html -- icon, selectedIcon, label
- [Flutter ScaffoldMessengerState] - api.flutter.dev/flutter/material/ScaffoldMessengerState-class.html -- showSnackBar, clearSnackBars, hideCurrentSnackBar, removeCurrentSnackBar

### Secondary (MEDIUM confidence)
- [pub.dev percent_indicator package page] - pub.dev/packages/percent_indicator -- version 4.2.5, 14 months old, stable
- [pub.dev go_router versions] - pub.dev/packages/go_router/versions -- v17.3.0 latest (39 hours ago)
- [Existing codebase] - lib/core/providers/stream_providers.dart, lib/core/router/app_router.dart, lib/data/repositories/water_repository.dart -- verified provider names, repository API, entity shapes

### Tertiary (LOW confidence)
- None -- all key claims verified via official documentation or codebase inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages verified on pub.dev; percent_indicator API verified via source code
- Architecture: HIGH -- StatefulShellRoute pattern verified via official go_router API docs and example; Riverpod patterns based on established codebase conventions
- Pitfalls: HIGH -- pitfalls derived from API constraints (clamp, division by zero) and runtime behavior (midnight reset, SnackBar context); well-understood failure modes

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable -- all packages are mature with infrequent breaking changes)
