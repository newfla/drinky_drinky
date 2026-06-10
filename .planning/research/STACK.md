# Stack Research: Drinky Drinky v1.2 (Bug Fixes & Feature Depth)

**Project:** Drinky Drinky (Hydration Tracker)
**Researched:** 2026-06-10
**Scope:** Stack additions, Drift migration API, and integration patterns for v1.2.
**Overall confidence:** HIGH

## New Packages Required

**None required.** All v1.2 features are achievable with the existing dependency set:

| v1.2 Feature Area | New Package? | Approach |
|-------------------|--------------|----------|
| Bug fixes (BUG-01/02/03) | NO | Pure Dart logic fixes in existing DAO and utility code |
| Target history (TARGET-01/02/03/04) | NO | New Drift table + DAO using existing drift ^2.33.0; migration from schema v1 to v2 |
| Hydration calculator (CALC-01/04) | NO | Stateless screen with pure arithmetic (sex + weight + climate factors) |
| First-launch onboarding (CALC-02/03) | NO | Extends existing SharedPreferences + GoRouter redirect pattern already used for PermissionScreen |

The existing `pubspec.yaml` already includes every dependency needed: `drift`, `drift_flutter`, `shared_preferences`, `go_router`, `freezed_annotation`, and `intl`.

## Drift Migration API (v2.33.0)

### Current State

The app is at `schemaVersion => 1` with three tables: `WaterEntries`, `UserSettings`, `DrinkPresets`. The `MigrationStrategy` currently only defines `onCreate` (which seeds default settings and presets) and `beforeOpen` (which enables foreign keys).

### Adding the `target_history` Table: Schema v1 -> v2

**Confidence: HIGH** -- verified via Context7 (drift.simonbinder.eu official docs).

Drift provides two migration approaches. For this project, the **simple `onUpgrade` callback** is the right choice because:

1. This is the first-ever migration (v1 -> v2), so there is no multi-step history to manage.
2. The step-by-step generated migration tooling (`drift_dev schema dump` + `drift_dev schema steps`) adds build complexity that is not justified for a single table addition.
3. The simple approach is well-documented and sufficient.

#### Required Code Changes

**Step 1: Define the new table class.**

Create `lib/data/database/tables/target_history_table.dart`:

```dart
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_target_history_date', columns: {#effectiveDate})
class TargetHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get effectiveDate => text()();  // 'YYYY-MM-DD' format, like dateKey
  IntColumn get targetMl => integer()();
}
```

**Step 2: Register the table in `@DriftDatabase`.**

```dart
@DriftDatabase(
  tables: [WaterEntries, UserSettings, DrinkPresets, TargetHistory],
  daos: [WaterEntryDao, UserSettingsDao, DrinkPresetDao, TargetHistoryDao],
)
```

**Step 3: Bump schema version and add `onUpgrade`.**

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Seed defaults (same as before)
      await into(userSettings).insert(UserSettingsCompanion.insert());
      await batch((batch) {
        batch.insertAll(drinkPresets, [
          DrinkPresetsCompanion.insert(amountMl: 150, sortOrder: 0),
          DrinkPresetsCompanion.insert(amountMl: 250, sortOrder: 1),
          DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 2),
        ]);
      });
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // v1 -> v2: Add target_history table
        await m.createTable(targetHistory);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // Seed initial target_history row for upgrading users.
      // New installs get this via onCreate -> createAll().
      // Existing v1 users need their current dailyTargetMl captured.
      if (details.hadUpgrade) {
        final existingTarget = await (select(userSettings)..limit(1))
            .getSingle();
        final today = DateTime.now();
        final dateKey = '${today.year}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
        // Only seed if no history exists yet (idempotent).
        final count = await (selectOnly(targetHistory)
              ..addColumns([targetHistory.id.count()])
            ).getSingle();
        if ((count.read(targetHistory.id.count()) ?? 0) == 0) {
          await into(targetHistory).insert(
            TargetHistoryCompanion.insert(
              effectiveDate: dateKey,
              targetMl: existingTarget.dailyTargetMl,
            ),
          );
        }
      }
    },
  );
}
```

### Key API Details (Verified)

| Migrator Method | Purpose | Used For |
|-----------------|---------|----------|
| `m.createAll()` | Creates all tables registered in `@DriftDatabase` | Fresh installs (onCreate) |
| `m.createTable(tableInstance)` | Creates a single new table | Adding `targetHistory` in onUpgrade |
| `m.addColumn(table, column)` | Adds a column to existing table | Not needed for v1.2 |
| `m.deleteTable('name')` | Drops a table | Not needed for v1.2 |

**Important:** `m.createTable(targetHistory)` uses the table instance from the database class (the generated `$TargetHistoryTable` accessor), NOT the `TargetHistory` class definition directly. Drift generates this accessor when you add the table to `@DriftDatabase.tables`.

### Migration Testing

Drift provides `SchemaVerifier` from `drift_dev/api/migrations_native.dart` for testing migrations. For v1.2, a simple test should:

1. Start a database at schema v1
2. Insert some water entries and settings
3. Run migration to v2
4. Verify `target_history` table exists
5. Verify existing data is preserved

This requires exporting schema snapshots:

```bash
# Export v1 schema (do this BEFORE changing schemaVersion)
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/

# After implementing v2, export v2
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/

# Generate test helper
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

**Recommendation:** Migration testing is valuable but optional for v1.2 because the migration is a simple `createTable` (no data transformation). If the team wants to skip the schema dump tooling, a manual integration test that opens an in-memory v1 database and verifies upgrade is sufficient.

## First-Launch Onboarding Detection Pattern

### Current Pattern (Already Established)

The app already has a first-launch gate using SharedPreferences + GoRouter redirect. This pattern is in `app_router.dart`:

```dart
redirect: (BuildContext context, GoRouterState state) async {
  if (state.matchedLocation == '/permission') return null;
  final prefs = await SharedPreferences.getInstance();
  final shown = prefs.getBool('drinky_permissionScreenShown') ?? false;
  if (!shown) return '/permission';
  return null;
},
```

### Recommended Approach for Onboarding Calculator

**Use the same pattern.** Add a second SharedPreferences key and extend the redirect chain:

```dart
redirect: (BuildContext context, GoRouterState state) async {
  final prefs = await SharedPreferences.getInstance();

  // Gate 1: Permission screen (existing)
  if (state.matchedLocation == '/permission') return null;
  final permShown = prefs.getBool('drinky_permissionScreenShown') ?? false;
  if (!permShown) return '/permission';

  // Gate 2: Onboarding calculator (new for v1.2)
  if (state.matchedLocation == '/onboarding-calculator') return null;
  final calcShown = prefs.getBool('drinky_onboardingCalculatorShown') ?? false;
  if (!calcShown) return '/onboarding-calculator';

  return null;
},
```

**Order matters:** Permission screen comes first (user needs to decide on notifications), then the hydration calculator (user sees recommended target). This mirrors the UX flow: permission is a system concern, calculator is a personalization concern.

### Why SharedPreferences Over Alternatives

| Alternative | Why Not |
|-------------|---------|
| Drift table | Over-engineered for a boolean flag; adds a migration for no benefit |
| `isFirstInstall` from package_info | Detects first install but not "has the user completed onboarding" -- what if they kill the app mid-onboarding? |
| Riverpod state | Not persisted; would reset on app restart |

SharedPreferences is the correct choice because:
- Already in the dependency graph
- Already proven in the same pattern (PermissionScreen)
- Persists across app restarts
- Simple boolean read; fast (cached after first access)
- Key-value semantics match the use case exactly

### Onboarding Route Registration

Add `/onboarding-calculator` as a top-level GoRoute (like `/permission`), outside the `StatefulShellRoute.indexedStack` so it renders without the bottom NavigationBar:

```dart
GoRoute(
  path: '/onboarding-calculator',
  builder: (context, state) => const HydrationCalculatorScreen(isOnboarding: true),
),
```

The same `HydrationCalculatorScreen` should be reusable from Settings (CALC-03) via a different route or by navigating to `/calculator` within the Settings branch. Pass an `isOnboarding` flag to control whether the screen shows "Skip" / navigation behavior vs. a simple back button.

## Hydration Calculator -- No Package Needed

The calculator is pure arithmetic. A common hydration formula:

```
Base (ml) = weight_kg * 30
Climate adjustment:
  - Sedentary/Cool: 0%
  - Temperate: +10%
  - Warm: +20%
  - Hot: +30%
  - Very Hot/Active: +40%
Sex adjustment (optional):
  - Male: +0 ml (base is calibrated for males)
  - Female: -200 ml (or use weight_kg * 28)
```

This is a stateless computation. No external API, no package, no persistence (the result is passed to the existing `updateSettings` flow via the "Use as target" button).

## Version Conflicts to Watch

**None identified for v1.2.**

The only operation is adding a Drift table and a new screen. All existing dependencies remain unchanged. Specific considerations:

| Concern | Status |
|---------|--------|
| drift ^2.33.0 + drift_dev ^2.33.0 | No change; createTable API is stable since drift 2.x |
| drift_flutter ^0.3.0 | No change; database setup unchanged |
| shared_preferences ^2.5.5 | No change; adding a new key does not affect compatibility |
| go_router ^17.3.0 | No change; redirect pattern unchanged |
| build_runner ^2.15.0 | No change; required for code-gen after adding new table |
| freezed ^3.2.5 | Optional: could use for a TargetHistoryEntity domain class |
| riverpod_lint + custom_lint | Still excluded due to analyzer conflict (noted in pubspec.yaml). No change for v1.2 |

**Build step reminder:** After adding `TargetHistory` table and its DAO, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates `app_database.g.dart` to include the new table accessors.

## Integration Points Summary

| Component | Touches | Details |
|-----------|---------|---------|
| `app_database.dart` | `@DriftDatabase.tables`, `schemaVersion`, `migration` | Add TargetHistory table, bump to v2, add onUpgrade |
| `target_history_table.dart` | New file | Table definition with effectiveDate + targetMl |
| `target_history_dao.dart` | New file | CRUD operations: insert, watchForDate, getTargetForDate |
| `app_router.dart` | `redirect`, `routes` | Add onboarding gate + /onboarding-calculator route |
| `settings_repository.dart` | Possibly extend | Add method to update target + insert target_history row |
| `home_screen.dart` | Provider usage | Use target from target_history instead of userSettings.dailyTargetMl |
| `history_screen.dart` | Provider usage | Calendar green/red uses per-day target from target_history |
| `water_entry_dao.dart` | Bug fix only | Fix deleteLastEntry date filter, dateKey validation |

## Sources

- Drift official documentation (Context7, drift.simonbinder.eu): Migration API, `createTable`, `addColumn`, `MigrationStrategy.onUpgrade`, schema versioning -- HIGH confidence
- Drift official documentation (Context7, drift.simonbinder.eu): Migration testing with `SchemaVerifier`, `drift_dev schema dump` -- HIGH confidence
- Existing codebase: `app_database.dart` (schema v1), `app_router.dart` (GoRouter redirect pattern), `permission_screen.dart` (SharedPreferences pattern), `pubspec.yaml` and `pubspec.lock` (dependency versions) -- HIGH confidence
- pub.dev package pages for drift, shared_preferences, go_router (verified via lock file) -- HIGH confidence
