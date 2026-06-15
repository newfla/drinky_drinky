# Phase 15: Home & History Fixes - Research

**Researched:** 2026-06-15
**Domain:** Flutter UI layout + Drift/Riverpod reactive state management
**Confidence:** HIGH

## Summary

This phase addresses two isolated issues on existing screens: a layout/alignment polish fix on the home screen (POLISH-01) and a reactivity bug on the history screen (BUG-04). No new packages are required -- all work uses the existing Drift + Riverpod stack already in the codebase.

POLISH-01 is a contained 3-line change to `_buildEmptyState` in `home_screen.dart`: wrap the `Column` in `Padding(EdgeInsets.symmetric(horizontal: 32))` and add `textAlign: TextAlign.center` to both `Text` widgets. The history screen empty state (lines 86-112 of `history_screen.dart`) already uses `Padding(all: 32)` + `textAlign: TextAlign.center` -- this fix achieves visual consistency.

BUG-04 requires a small vertical slice through four files: add a `watchEarliestDateKey()` streaming query to `WaterEntryDao`, expose it via `WaterRepository`, create an `@riverpod Stream<String?>` provider in `stream_providers.dart`, and refactor `HistoryScreen` to consume the provider's `AsyncValue` instead of local `_loading`/`_noEntries`/`_firstDay` state. The root cause is that `StatefulShellRoute.indexedStack` keeps the HistoryScreen widget alive across tab switches, so `initState` runs exactly once per app session -- if the user adds their first entry while on the Home tab, the history screen never re-evaluates.

**Primary recommendation:** Implement as two sequential tasks -- POLISH-01 first (trivial, no codegen), then BUG-04 (requires `build_runner` for the new Riverpod provider codegen).

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

**POLISH-01 -- Home placeholder layout:**
- D-01: Add `Padding(EdgeInsets.symmetric(horizontal: 32))` wrapping the `Column` in `_buildEmptyState`
- D-02: Add `textAlign: TextAlign.center` to BOTH text widgets (`noDrinksLogged` and `noDrinksLoggedHint`)

**BUG-04 -- History screen reactivity:**
- D-03: Stream provider approach. Add `watchEarliestDateKey()` Drift stream query to `WaterEntryDao` -> expose via `WaterRepository` -> create `@riverpod Stream<String?> earliestDateKey(Ref ref)` provider in `stream_providers.dart`
- D-04: Full state replacement. Replace `_firstDay`, `_noEntries`, `_loading` local state with the provider's `AsyncValue`. Only `_selectedDay` remains local.
- D-05: Drift query: streaming `SELECT MIN(date_key)` on `water_entries` table. Returns `null` when empty.

### Claude's Discretion

- Provider `keepAlive` setting for `earliestDateKeyProvider` -- likely `keepAlive: false` is fine since `StatefulShellRoute` keeps the screen alive anyway
- Exact `AsyncValue.loading()` UI -- match existing `CircularProgressIndicator` pattern

### Deferred Ideas (OUT OF SCOPE)

None.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-01 | Home screen placeholder text has consistent padding and centered text alignment | Direct code pattern from history screen empty state (Padding all:32 + textAlign center); exact lines identified in `_buildEmptyState` (lines 201-219) |
| BUG-04 | History screen shows current day intakes after first insert on fresh install | Drift `selectOnly` + `min()` + `watchSingle()` streaming pattern verified; Riverpod `@riverpod Stream<String?>` pattern confirmed from existing providers; `StatefulShellRoute.indexedStack` lifecycle confirmed as root cause |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Empty state text alignment (POLISH-01) | Frontend (Flutter widget) | -- | Pure layout/styling change in widget build method |
| Earliest date streaming query (BUG-04) | Database (Drift DAO) | -- | MIN aggregate query belongs in the data access layer |
| Repository pass-through (BUG-04) | API/Repository layer | -- | Thin delegation following existing pattern |
| Stream provider (BUG-04) | State Management (Riverpod) | -- | Bridges Drift stream to widget-consumable AsyncValue |
| History screen state refactor (BUG-04) | Frontend (Flutter widget) | -- | Replace local state with provider consumption |

## Standard Stack

No new packages required. This phase uses only existing dependencies.

### Core (already installed)

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| drift | ^2.33.0 | Streaming MIN aggregate query | `selectOnly` + `min()` + `watchSingle()` pattern already used for `watchTotalForDate` |
| flutter_riverpod | ^3.3.1 | Stream provider + AsyncValue consumption | `@riverpod Stream<T>` pattern used throughout `stream_providers.dart` |
| riverpod_annotation | ^4.0.2 | `@riverpod` annotation for new provider | Required for codegen |
| riverpod_generator | ^4.0.3 | Generates `.g.dart` for new provider | Dev dependency; must run `build_runner` after adding provider |
| build_runner | ^2.15.0 | Codegen orchestrator | Required to regenerate `stream_providers.g.dart` |

## Architecture Patterns

### System Architecture Diagram

```
[User adds water intake on Home tab]
        |
        v
[WaterRepository.insertEntry()]
        |
        v
[Drift water_entries table INSERT]
        |
        v
[Drift internal notification: water_entries table changed]
        |
        +---> [watchEarliestDateKey() stream emits new MIN(date_key)]
        |              |
        |              v
        |     [earliestDateKeyProvider emits AsyncValue<String?>]
        |              |
        |              v
        |     [HistoryScreen rebuilds via ref.watch()]
        |     [AsyncValue.when() shows calendar OR empty state]
        |
        +---> [calendarMonthProvider re-emits (already existing)]
        +---> [totalMlForDateProvider re-emits (already existing)]
```

### Recommended Project Structure

No new files or directories. Changes to existing files only:

```
lib/
├── data/
│   ├── database/
│   │   └── daos/
│   │       └── water_entry_dao.dart       # ADD watchEarliestDateKey()
│   └── repositories/
│       └── water_repository.dart          # ADD watchEarliestDateKey()
├── core/
│   └── providers/
│       ├── stream_providers.dart          # ADD earliestDateKeyProvider
│       └── stream_providers.g.dart        # REGENERATE via build_runner
└── presentation/
    └── screens/
        ├── home_screen.dart               # MODIFY _buildEmptyState (padding + textAlign)
        └── history_screen.dart            # REFACTOR: replace local state with provider
```

### Pattern 1: Drift Streaming Aggregate Query

**What:** Use `selectOnly` with `min()` aggregate and `watchSingle()` to create a reactive stream of a single scalar value.

**When to use:** When you need a reactive stream of a computed aggregate (MIN, MAX, SUM, AVG) from a Drift table.

**Existing codebase precedent (water_entry_dao.dart lines 26-32):**
```dart
// Source: lib/data/database/daos/water_entry_dao.dart
Stream<int> watchTotalForDate(String dateKey) {
  final totalMl = waterEntries.amountMl.sum();
  final query = selectOnly(waterEntries)
    ..addColumns([totalMl])
    ..where(waterEntries.dateKey.equals(dateKey));
  return query.watchSingle().map((row) => row.read(totalMl) ?? 0);
}
```

**New method follows the same pattern:**
```dart
// New method in WaterEntryDao
Stream<String?> watchEarliestDateKey() {
  final minDateKey = waterEntries.dateKey.min();
  final query = selectOnly(waterEntries)
    ..addColumns([minDateKey]);
  return query.watchSingle().map((row) => row.read(minDateKey));
}
```

Key points:
- `waterEntries.dateKey.min()` returns a `GeneratedColumn` expression for `MIN(date_key)` [VERIFIED: existing `sum()` usage in same DAO confirms the API pattern]
- `watchSingle()` on a `selectOnly` with an aggregate always returns exactly one row (aggregates produce one row even on empty tables -- the value is `null` when no rows match) [CITED: drift.simonbinder.eu/dart_api/expressions/#aggregate]
- `row.read(minDateKey)` returns `String?` -- `null` when the table is empty, which maps directly to "no entries exist" state

### Pattern 2: Riverpod Stream Provider with Nullable Return

**What:** Declare a `@riverpod` annotated function returning `Stream<String?>` for the planner to follow.

**Existing codebase precedent (stream_providers.dart):**
```dart
// Source: lib/core/providers/stream_providers.dart — non-family, non-keepAlive stream
@riverpod
Stream<int> totalMlForDate(Ref ref, String dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchTotalForDate(dateKey);
}
```

**New provider (no parameters, auto-dispose):**
```dart
@riverpod
Stream<String?> earliestDateKey(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchEarliestDateKey();
}
```

This generates `earliestDateKeyProvider` in the `.g.dart` file. The consumer accesses it as:
```dart
final earliestAsync = ref.watch(earliestDateKeyProvider);
// earliestAsync is AsyncValue<String?>
```

### Pattern 3: AsyncValue.when Consumption in History Screen

**What:** Replace imperative `_loading`/`_noEntries`/`_firstDay` local state with declarative `AsyncValue.when()`.

**Existing codebase precedent (history_screen.dart lines 121-307):**
```dart
// Already used for targetsAsync
body: targetsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
  data: (targets) { /* calendar UI */ },
),
```

**New pattern wraps the outer build:**
```dart
final earliestAsync = ref.watch(earliestDateKeyProvider);
// ...existing providers (focusedMonthProvider, allTargetHistoryProvider)...

return Scaffold(
  appBar: AppBar(title: Text(context.l10n.historyTitle)),
  body: earliestAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
    data: (earliestDateKey) {
      if (earliestDateKey == null) {
        // Empty state — no entries ever logged
        return _buildEmptyState(context);
      }
      final firstDay = DateTime.parse(earliestDateKey);
      // ... existing targetsAsync.when() with calendar UI ...
      // Replace all _firstDay! references with firstDay local variable
    },
  ),
);
```

### Anti-Patterns to Avoid

- **One-time Future in initState for reactive data:** The current BUG-04 root cause. `initState` runs once; if the underlying data changes, the widget never knows. Always use a stream/provider for data that can change during the widget's lifetime.
- **Mixing local state with provider state for the same concern:** After the refactor, `_firstDay`, `_noEntries`, and `_loading` must be fully removed -- not left as fallbacks. Only `_selectedDay` stays local because it is pure UI interaction state (not data-derived).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Aggregate MIN streaming | Manual `select().watch().map(entries => entries.first.dateKey)` | `selectOnly` + `min()` + `watchSingle()` | Drift's aggregate functions produce correct SQL (`SELECT MIN(date_key)`); manual approach wastes bandwidth fetching all rows |
| Widget reactivity to DB changes | `initState` Future + `setState` | Riverpod `@riverpod Stream<T>` + `ref.watch` | Provider approach auto-disposes, auto-resubscribes, handles loading/error states declaratively |

**Key insight:** The entire BUG-04 fix is about replacing a one-time imperative fetch with a reactive stream -- a pattern the codebase already uses everywhere else. The fix makes HistoryScreen consistent with HomeScreen's reactive approach.

## Common Pitfalls

### Pitfall 1: Forgetting to Run build_runner After Adding @riverpod Provider

**What goes wrong:** Adding the `earliestDateKey` function with `@riverpod` annotation to `stream_providers.dart` but not regenerating `stream_providers.g.dart` causes compile errors -- the `earliestDateKeyProvider` symbol won't exist.

**Why it happens:** The `@riverpod` annotation relies on `riverpod_generator` via `build_runner` to produce the provider class in the `.g.dart` file.

**How to avoid:** Run `dart run build_runner build --delete-conflicting-outputs` after modifying `stream_providers.dart`. The DAO change (`water_entry_dao.dart`) does NOT require codegen because adding methods to the DAO class body doesn't affect the generated mixin.

**Warning signs:** `Undefined name 'earliestDateKeyProvider'` compile error.

### Pitfall 2: Nested AsyncValue.when Blocks

**What goes wrong:** After wrapping the outer build in `earliestAsync.when()`, the inner `targetsAsync.when()` creates deeply nested code that is hard to read.

**Why it happens:** Two independent async data sources both need `.when()` handling.

**How to avoid:** Keep the nesting -- it is the correct pattern (the targets are only needed when there ARE entries). The nesting is at most 2 levels deep, matching the existing code structure. Do not try to combine the two AsyncValues into a single provider -- they are semantically independent.

**Warning signs:** Temptation to create a "combined" provider that merges earliestDateKey + targets.

### Pitfall 3: StatefulShellRoute.indexedStack Keeps Widget Alive

**What goes wrong:** Developers might think the HistoryScreen is recreated on each tab switch and add setup logic to `initState` expecting it to re-run.

**Why it happens:** `StatefulShellRoute.indexedStack` preserves the widget state across tab switches -- `initState` runs once per app session, not per tab visit. [VERIFIED: confirmed in `lib/core/router/app_router.dart` line 57]

**How to avoid:** This is the ROOT CAUSE of BUG-04. The fix (stream provider) eliminates the dependency on `initState` for data loading. After the fix, `initState` can be removed entirely if `_selectedDay` is initialized inline.

**Warning signs:** Any `initState` code that fetches data which could change.

### Pitfall 4: watchSingle vs watchSingleOrNull for Aggregate

**What goes wrong:** Using `watchSingleOrNull()` instead of `watchSingle()` for an aggregate query returns `TypedResult?` instead of `TypedResult`.

**Why it happens:** Confusion about when SQL aggregates return rows. An aggregate like `MIN(column)` ALWAYS returns exactly one row (with NULL value if table is empty). It never returns zero rows.

**How to avoid:** Use `watchSingle()` (not `watchSingleOrNull()`). The nullability is in the column value (`row.read(minDateKey)` returns `String?`), not in the row itself. This matches the existing `watchTotalForDate` pattern which also uses `watchSingle()`.

**Warning signs:** Unnecessary null-checking on the `TypedResult` level rather than the column value level.

## Code Examples

### Example 1: watchEarliestDateKey in WaterEntryDao

```dart
// Source: follows exact pattern of watchTotalForDate (water_entry_dao.dart:26-32)
/// Watch the earliest dateKey in the water_entries table as a reactive stream.
/// Returns null when the table is empty (no entries ever logged).
Stream<String?> watchEarliestDateKey() {
  final minDateKey = waterEntries.dateKey.min();
  final query = selectOnly(waterEntries)
    ..addColumns([minDateKey]);
  return query.watchSingle().map((row) => row.read(minDateKey));
}
```

### Example 2: Repository Pass-Through

```dart
// Source: follows pattern of watchTotalForDate in water_repository.dart:63-65
/// Watch the earliest dateKey as a reactive stream. Returns null when empty.
Stream<String?> watchEarliestDateKey() =>
    _db.waterEntryDao.watchEarliestDateKey();
```

### Example 3: Riverpod Stream Provider

```dart
// Source: follows pattern of totalMlForDate in stream_providers.dart:36-40
/// Watch the earliest dateKey in the database as a reactive stream.
/// Returns null when no water entries exist (fresh install / all deleted).
@riverpod
Stream<String?> earliestDateKey(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchEarliestDateKey();
}
```

### Example 4: POLISH-01 Fix (_buildEmptyState)

```dart
// Source: current _buildEmptyState at home_screen.dart:201-219
// Fix: add Padding wrapper + textAlign to both Text widgets
Widget _buildEmptyState(ThemeData theme) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.noDrinksLogged,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.noDrinksLoggedHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `initState` + Future + `setState` for one-time data fetch | `@riverpod Stream<T>` + `ref.watch` + `AsyncValue.when` | Established pattern in this codebase since Phase 4 | All screens except HistoryScreen already use the reactive pattern; this fix brings consistency |
| `sqlite3_flutter_libs` | `drift_flutter` | drift_flutter 0.1.0 (2024) | Already migrated; no action needed |

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation (this phase uses all three, no new packages)
- **Platform**: iOS and Android only
- **Offline-first**: No backend (this fix is entirely local)
- **Riverpod codegen**: Use `@riverpod` annotation (not manual provider declarations) -- the new provider must use `@riverpod`
- **flutter_riverpod not hooks_riverpod**: No hooks usage
- **build_runner**: Must run after adding new `@riverpod` annotated function
- **drift_flutter not sqlite3_flutter_libs**: Already in place

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| -- | -- | -- | -- |

**All claims in this research were verified against the existing codebase or official documentation -- no user confirmation needed.**

## Open Questions

1. **keepAlive for earliestDateKeyProvider**
   - What we know: `StatefulShellRoute.indexedStack` keeps HistoryScreen alive across tab switches, so the widget's `ref.watch` subscription persists regardless of `keepAlive`. Auto-dispose (`keepAlive: false`, the default for `@riverpod`) means the provider is disposed when no widget watches it -- but that only happens if HistoryScreen is fully removed from the tree, which `indexedStack` prevents.
   - What's unclear: Nothing materially unclear -- `keepAlive: false` (default) is functionally equivalent to `keepAlive: true` in this navigation structure.
   - Recommendation: Use the default (`@riverpod` without `keepAlive: true`) -- it is simpler and matches `streakProvider` which also serves the history screen without `keepAlive`. If the navigation structure ever changes, auto-dispose is the safer default.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- no auth in app |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single-user local app |
| V5 Input Validation | No | No new user input in this phase (layout + reactive state only) |
| V6 Cryptography | No | N/A |

### Known Threat Patterns

No security-relevant changes in this phase. POLISH-01 is a layout fix. BUG-04 replaces a Future-based fetch with a Stream-based fetch of the same data -- no new data exposure, no new input vectors, no new permissions.

## Sources

### Primary (HIGH confidence)
- Codebase: `lib/data/database/daos/water_entry_dao.dart` -- existing `watchTotalForDate` pattern (lines 26-32) confirms `selectOnly` + `sum()` + `watchSingle()` API
- Codebase: `lib/core/providers/stream_providers.dart` -- existing `@riverpod Stream<T>` patterns confirm provider declaration approach
- Codebase: `lib/presentation/screens/history_screen.dart` -- full source read confirms BUG-04 root cause (one-time `initState` Future at lines 55-73)
- Codebase: `lib/core/router/app_router.dart` -- `StatefulShellRoute.indexedStack` at line 57 confirms widget-alive lifecycle
- Drift official docs (drift.simonbinder.eu/dart_api/expressions/#aggregate) -- confirms `min()` aggregate expression API

### Secondary (MEDIUM confidence)
- None needed -- all findings verified from codebase or official docs

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new packages; all existing
- Architecture: HIGH -- exact code patterns verified in codebase with line numbers
- Pitfalls: HIGH -- root cause confirmed by reading the actual code and router configuration

**Research date:** 2026-06-15
**Valid until:** 2026-07-15 (stable; no external dependencies or version-sensitive patterns)
