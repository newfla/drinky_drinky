# Features Research: Drinky Drinky v1.2

**Domain:** Flutter hydration tracker -- feature depth additions
**Researched:** 2026-06-10
**Overall confidence:** HIGH (formula based on well-established health authority values; data model and query patterns verified against existing codebase and Drift docs)

---

## Hydration Calculator Formula

### Background: What Health Authorities Recommend

There is no single universally accepted formula for daily water intake. The three major health authorities provide **fixed Adequate Intake (AI) values by sex**, not per-kg formulas:

| Authority | Males (total water/day) | Females (total water/day) | Basis |
|-----------|------------------------|--------------------------|-------|
| **EFSA** (Europe) | 2,500 ml | 2,000 ml | Observed intakes in populations with desirable urine osmolality |
| **IOM/NASEM** (US/Canada) | 3,700 ml | 2,700 ml | Median intakes from national dietary surveys |

These figures include **all water sources** (beverages + food). Approximately 20% comes from food, so the **beverage-only** figures are:

| Authority | Males (beverages) | Females (beverages) |
|-----------|-------------------|---------------------|
| **EFSA** | 2,000 ml | 1,600 ml |
| **IOM** | 2,960 ml | 2,160 ml |

**Important:** These are population-level recommendations assuming moderate temperature and moderate physical activity (PAL ~1.6). They are explicitly stated as NOT applicable to hot climates or high activity levels.

**Confidence:** HIGH -- values confirmed via EFSA Journal 2010;8(3):1459, IOM 2005 DRI for Water, and corroborated by multiple secondary sources (Wikipedia DRI table, Medical News Today, Healthline, Omnicalculator).

### Baseline (sex + weight)

Since the app focuses on European users (Italian interface elements visible in the codebase -- "Freddo/Mite/Caldo/Molto caldo/Afoso") and needs a **weight-based** calculation, the approach is:

**Use the EFSA baseline values as anchor points, then scale by body weight relative to a reference weight.**

**Core formula:**

```
baselineMl = mlPerKg * weightKg
```

Where `mlPerKg` is derived from the EFSA AI values:

| Sex | EFSA AI (beverages) | Reference weight | Derived ml/kg |
|-----|---------------------|------------------|---------------|
| Male | 2,000 ml | 70 kg | ~28.6 ml/kg |
| Female | 1,600 ml | 60 kg | ~26.7 ml/kg |

**Recommended constants (rounded for simplicity and consistency with common hydration apps):**

| Sex | ml/kg constant | Source rationale |
|-----|---------------|-----------------|
| Male | **30 ml/kg** | EFSA-derived ~28.6 rounded up slightly; aligns with the commonly cited "30-35 ml/kg" range in clinical nutrition |
| Female | **28 ml/kg** | EFSA-derived ~26.7 rounded up; slightly below male to reflect the EFSA sex differential |
| Other | **29 ml/kg** | Midpoint between male and female constants |

**Example outputs:**
- Male, 80 kg: 80 * 30 = 2,400 ml
- Female, 55 kg: 55 * 28 = 1,540 ml (clamped to minimum 1,540 -> 1,550 after rounding)
- Female, 70 kg: 70 * 28 = 1,960 ml -> 1,950 ml
- Male, 65 kg: 65 * 30 = 1,950 ml

These align well with the EFSA AI ranges and produce sensible results across normal body weights.

**Confidence:** MEDIUM -- The per-kg derivation is a practical simplification. The exact constants (30/28/29) are an opinionated choice based on EFSA anchoring. No single authority publishes exact per-kg values for the general population; clinical nutrition commonly uses "30-35 ml/kg" as a rule of thumb (verified in multiple secondary sources). The chosen values sit at the conservative end of this range.

### Climate Adjustments (5 levels with multipliers)

EFSA and IOM both state their AI values apply only to "moderate environmental temperatures." Quantified climate adjustments are not published by health authorities because water loss through sweating is highly variable (0.3 L/h sedentary to 2.0+ L/h active in heat, per Popkin et al. 2010 in *Nutrition Reviews*).

**Recommended multipliers (opinionated, conservative):**

| Level | Italian label | Approx. temp range | Multiplier | Rationale |
|-------|---------------|-------------------|------------|-----------|
| 1 | Freddo | < 10 C | **1.00** | Baseline; AI was set at moderate temp; cold weather does not reduce needs below baseline |
| 2 | Mite | 10-20 C | **1.00** | Still within the "moderate temperature" range assumed by EFSA |
| 3 | Caldo | 20-30 C | **1.10** | +10% accounts for mild increase in insensible perspiration |
| 4 | Molto caldo | 30-35 C | **1.20** | +20% for noticeable sweating; consistent with sports science guidance of 500-750 ml/hour additional fluid for heat stress |
| 5 | Afoso | > 35 C (humid heat) | **1.30** | +30% for significant sweat loss; humid heat impairs evaporative cooling, increasing sweat volume |

**Confidence:** LOW-MEDIUM -- These multipliers are an opinionated estimate. No health authority publishes exact percentage increases by temperature band. The chosen values are conservative: even at the highest level (1.30x), a 70 kg male would get 2,730 ml (well within EFSA's range). Sports science literature suggests water needs can increase 50-100% during sustained exercise in heat, but the app's climate factor represents ambient living conditions, not exercise. The 10/20/30% increments are a reasonable simplification.

### Combined Formula (Implementation Reference)

```dart
int calculateRecommendedIntake({
  required String sex,       // 'M', 'F', 'other'
  required double weightKg,
  required int climateLevel, // 1-5
}) {
  // Step 1: Base ml/kg by sex
  final double mlPerKg;
  switch (sex) {
    case 'M':
      mlPerKg = 30.0;
    case 'F':
      mlPerKg = 28.0;
    default:
      mlPerKg = 29.0;
  }

  // Step 2: Climate multiplier
  final double climateMultiplier;
  switch (climateLevel) {
    case 1: // Freddo
    case 2: // Mite
      climateMultiplier = 1.00;
    case 3: // Caldo
      climateMultiplier = 1.10;
    case 4: // Molto caldo
      climateMultiplier = 1.20;
    case 5: // Afoso
      climateMultiplier = 1.30;
    default:
      climateMultiplier = 1.00;
  }

  // Step 3: Calculate and round to nearest 50 ml
  final raw = mlPerKg * weightKg * climateMultiplier;
  return ((raw / 50).round() * 50).clamp(1000, 5000);
}
```

### Output Bounds

| Bound | Value | Rationale |
|-------|-------|-----------|
| Minimum | **1,000 ml** | Below this is clinically insufficient for any adult. Even a 35 kg person at 28 ml/kg = 980 ml, rounded to 1,000. |
| Maximum | **5,000 ml** | A 120 kg male in afoso climate: 120 * 30 * 1.30 = 4,680 ml. Capping at 5,000 prevents unreasonable values and avoids any risk of hyponatremia advice. The slider max in settings is already 10,000 ml, so 5,000 from the calculator is well within bounds. |
| Rounding | **Nearest 50 ml** | Clean, user-friendly output. 2,437 ml -> 2,450 ml. Avoids false precision from a formula that is inherently approximate. |

### Privacy Considerations

The milestone spec says "Privacy notice: no data saved or transmitted." Implementation notes:

1. **Calculator inputs (sex, weight, climate) must NOT be persisted.** The screen is stateless -- inputs live in local widget state only, discarded when the screen is popped.
2. **Only the output target value is saved** (when the user taps "Use as target"), and it is saved as the regular `dailyTargetMl` value in settings/target_history -- indistinguishable from a manual target change.
3. **Privacy disclaimer text** should be shown on the calculator screen. Suggested wording: "I tuoi dati (sesso, peso, clima) non vengono salvati ne trasmessi. Il calcolo avviene interamente sul tuo dispositivo." / "Your data (sex, weight, climate) is not saved or transmitted. The calculation happens entirely on your device."
4. **No analytics or logging** of inputs. The function is a pure computation.

### Disclaimer Text

The calculator screen should include a short disclaimer clarifying this is a general recommendation, not medical advice. Suggested text:

"This recommendation is based on EFSA guidelines and is intended as a general guideline. Individual needs vary. Consult a healthcare professional for personalized advice."

This protects against liability and manages user expectations about the precision of the formula.

---

## Target History Data Model

### Schema

New Drift table: `TargetHistory`

```dart
@TableIndex(name: 'idx_target_history_effective_date', columns: {#effectiveDate})
class TargetHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get effectiveDate => text().unique()();  // 'YYYY-MM-DD', same as dateKey
  IntColumn get targetMl => integer()();
}
```

**Why this schema:**
- `effectiveDate` is the date from which this target applies (inclusive). Same TEXT format as `dateKey` in `water_entries`, enabling direct string comparison.
- `targetMl` stores the target active from that date forward.
- No `endDate` needed -- the next row's `effectiveDate` implicitly terminates the previous period.
- **UNIQUE constraint on `effectiveDate`** prevents duplicate rows for the same date when the user changes the target multiple times on the same day.
- An index on `effectiveDate` makes the "find target for date" query efficient.

**Relationship to `user_settings.dailyTargetMl`:** The existing `dailyTargetMl` column in `user_settings` continues to serve as the *current* target (the one the home screen progress ring shows). `target_history` is the audit log that enables per-day lookup for past dates. When a target changes, BOTH are updated: `user_settings.dailyTargetMl` is set to the new value, and a row is inserted/upserted into `target_history`. This avoids breaking any existing code that reads from `user_settings`.

### Database Migration (v1 -> v2)

The app's current `schemaVersion` is 1. Adding the `target_history` table requires version 2.

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // ... existing seed logic for user_settings and drink_presets ...
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(targetHistory);
        // Seed the first history row with the user's current target.
        // This ensures every existing user has at least one row.
        final currentSettings = await (select(userSettings)
              ..where((t) => t.id.equals(1)))
            .getSingleOrNull();
        final currentTarget = currentSettings?.dailyTargetMl ?? 2000;
        final today = DateTime.now();
        final todayKey =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
        await into(targetHistory).insert(
          TargetHistoryCompanion.insert(
            effectiveDate: todayKey,
            targetMl: currentTarget,
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

**Why seed on upgrade:** Existing users who upgrade from v1 have been using a single global target. We create one `target_history` row with today's date and their current target so that:
- All past calendar days use this target (it is the earliest row, so `MAX(effectiveDate) <= anyPastDate` finds it).
- The query logic works consistently without special-casing "no history."

**Confidence:** HIGH -- The `m.createTable()` in `onUpgrade` pattern is documented in Drift's official migration guide (verified via Context7). The seed-on-upgrade approach ensures existing users have valid data.

### Query Pattern (find target for a given date)

The core query: "For a given `dateKey`, find the `targetMl` from the most recent `target_history` row whose `effectiveDate <= dateKey`."

**SQL equivalent:**
```sql
SELECT target_ml FROM target_history
WHERE effective_date <= :dateKey
ORDER BY effective_date DESC
LIMIT 1;
```

**Drift DAO methods:**

```dart
/// Get the target that was active on [dateKey].
/// Returns null if no history exists before that date (should not happen
/// after migration seeds the first row).
Future<int?> getTargetForDate(String dateKey) async {
  final row = await (select(targetHistory)
        ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
        ..limit(1))
      .getSingleOrNull();
  return row?.targetMl;
}

/// Watch all target history rows, sorted by effectiveDate ASC.
/// The calendar/streak providers use this to look up per-day targets
/// without issuing N individual queries.
Stream<List<TargetHistoryData>> watchAllTargetHistory() {
  return (select(targetHistory)
        ..orderBy([(t) => OrderingTerm.asc(t.effectiveDate)]))
      .watch();
}

/// Insert or update a target for the given effective date.
/// Uses UNIQUE constraint on effectiveDate for conflict resolution.
Future<void> upsertTarget(String effectiveDate, int targetMl) async {
  await into(targetHistory).insertOnConflictUpdate(
    TargetHistoryCompanion.insert(
      effectiveDate: effectiveDate,
      targetMl: targetMl,
    ),
  );
}
```

### Client-Side Resolution for Calendar and Streak

For the calendar (which needs per-day targets for ~30 days) and the streak provider (which scans backwards), issue ONE query for the full history and resolve per-day targets in memory:

```dart
/// Find the active target for a given dateKey from a sorted history list.
/// [history] must be sorted by effectiveDate ASC.
int targetForDate(List<TargetHistoryData> history, String dateKey) {
  // Iterate backwards to find the most recent effective date <= dateKey.
  for (int i = history.length - 1; i >= 0; i--) {
    if (history[i].effectiveDate.compareTo(dateKey) <= 0) {
      return history[i].targetMl;
    }
  }
  // Fallback (should never happen after migration seed).
  return 2000;
}
```

**Why client-side resolution:** The `target_history` table will have very few rows (one per target change -- most users will have 1-5 rows over their lifetime). Loading the full list is trivially cheap. Running 30+ individual SQL queries per calendar month would be far more expensive.

### Edge Cases

| Edge case | Behavior | Implementation |
|-----------|----------|---------------|
| **No history rows** | Should not happen after migration seed. Fallback: return 2000 (the default target). | `?? 2000` in DAO, `return 2000` in `targetForDate` fallback |
| **All history dates are after the queried date** | Possible for very old past dates before the user started using the app. `targetForDate` returns 2000 as fallback. | The migration seed date is "today at upgrade time," so dates before that get the fallback. This is acceptable -- the user had no logs before using the app. |
| **Multiple changes on same effective date** | UNIQUE constraint on `effectiveDate` + `insertOnConflictUpdate` ensures only one row per date. The last value set wins. | `upsertTarget()` method handles this |
| **"Apply from today"** | Upsert row with `effectiveDate = today`, update `user_settings.dailyTargetMl` immediately. | Both operations in single method call |
| **"Apply from tomorrow"** | Insert row with `effectiveDate = tomorrow`, update `user_settings.dailyTargetMl` immediately (home screen shows new target). Calendar for "today" still uses the old target from history lookup. | Two writes: upsert to history, update to settings |
| **User downgrades app** | Schema version 2 database opened by schema version 1 code. The `target_history` table is ignored (Drift/SQLite do not fail on extra tables). Settings still work from `user_settings`. | No action needed -- graceful degradation |

### Critical Design Decision: "Apply from tomorrow" and user_settings.dailyTargetMl

When the user picks "apply from tomorrow":
1. A `target_history` row is created with `effectiveDate = tomorrow` and the new `targetMl`.
2. The `user_settings.dailyTargetMl` IS updated to the new value immediately. Reason: the home screen progress ring should reflect the user's new intent for today's remaining logging.
3. The calendar for "today" will still use the OLD target (from `target_history` lookup), because today's effectiveDate query will find the previous row.

This means:
- `user_settings.dailyTargetMl` = "what the progress ring shows" (always current intent)
- `target_history` = "what was the official target on day X" (what the calendar evaluates)

### Impact on Existing Code

| Component | Current behavior | Required change |
|-----------|-----------------|-----------------|
| **Home screen** | Reads `dailyTargetMl` from `userSettingsProvider` | **No change** -- `user_settings.dailyTargetMl` is always the current target |
| **History screen (calendar)** | Uses single `dailyTarget` from settings for all days | Must watch `targetHistoryProvider` and use `targetForDate()` per day instead of one global target |
| **Streak provider** | Compares daily totals against single `settings.dailyTargetMl` | Must watch `targetHistoryProvider` and use `targetForDate()` per day |
| **Settings screen** | Slider updates `user_settings.dailyTargetMl` directly via `updateSettings()` | Must show "Apply from today/tomorrow" dialog on slider change end, then call `upsertTarget()` AND `updateSettings()` |
| **Notification goal-reached check** | Compares today's total against `settings.dailyTargetMl` | **No change** -- uses current target, which is always correct |
| **Day summary card** | Shows total against single target | Must use `targetForDate()` for the selected day |

---

## First-Launch Detection Pattern

### Existing Pattern in the Codebase

The app already has a proven first-launch detection pattern for the permission screen:

1. **SharedPreferences boolean flag:** `drinky_permissionScreenShown`
2. **GoRouter async redirect:** checks the flag on every navigation; redirects to `/permission` if false
3. **One-time set:** after the user completes the screen, the flag is set to `true` and navigation proceeds to `/`

This exact pattern should be replicated for the calculator onboarding.

### Recommended Implementation

**New SharedPreferences key:** `drinky_calculatorShown`

**GoRouter redirect chain (order matters):**

```dart
redirect: (BuildContext context, GoRouterState state) async {
  // Prevent redirect loops for onboarding screens
  if (state.matchedLocation == '/permission') return null;
  if (state.matchedLocation == '/calculator') return null;

  final prefs = await SharedPreferences.getInstance();

  // 1. Permission screen takes priority (must be shown first)
  final permissionShown = prefs.getBool('drinky_permissionScreenShown') ?? false;
  if (!permissionShown) return '/permission';

  // 2. Calculator onboarding shown second
  final calculatorShown = prefs.getBool('drinky_calculatorShown') ?? false;
  if (!calculatorShown) return '/calculator';

  return null;
}
```

**Flow for new users (fresh install of v1.2):**
1. App launches -> redirect to `/permission`
2. User completes permission screen -> sets flag, navigates to `/`
3. Redirect fires again -> permission done, calculator not shown -> redirect to `/calculator`
4. User completes calculator (or skips) -> sets flag, navigates to `/`
5. All subsequent launches -> both flags true -> no redirect

**Flow for existing users (upgrading from v1.0/v1.1 to v1.2):**
1. `drinky_permissionScreenShown` is already `true`
2. `drinky_calculatorShown` does not exist -> defaults to `false`
3. First launch after update -> redirected to `/calculator`
4. User completes or skips calculator -> normal flow

### Route Registration

The calculator route is a **top-level route** (outside `StatefulShellRoute`), just like `/permission`, so it renders WITHOUT the bottom NavigationBar:

```dart
GoRoute(
  path: '/calculator',
  builder: (context, state) {
    final isOnboarding = state.extra as bool? ?? true;
    return HydrationCalculatorScreen(isOnboarding: isOnboarding);
  },
),
```

### Re-entry from Settings

The calculator is also accessible from Settings for re-use. Differentiate onboarding vs. settings entry via the `extra` parameter:

| Entry point | `isOnboarding` | "Skip" button | Sets SharedPrefs flag | Navigation on complete |
|-------------|---------------|--------------|----------------------|----------------------|
| GoRouter redirect (first launch) | `true` | Shown | Yes | `context.go('/')` (replaces stack) |
| Settings ListTile | `false` | Hidden | No | `context.pop()` (returns to settings) |

**Settings entry point:**
```dart
ListTile(
  title: const Text('Hydration Calculator'),
  subtitle: const Text('Get a personalized recommendation'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/calculator', extra: false),
)
```

**Note on `context.go` vs `context.push`:** From onboarding, use `context.go('/')` to replace the route stack (prevents back-navigating to the onboarding screen). From settings, use `context.push('/calculator')` to add to the stack (allows the back button to return to settings).

**Confidence:** HIGH -- This pattern is already proven in the codebase (`permission_screen.dart`, `app_router.dart`). SharedPreferences + GoRouter async redirect is the standard Flutter pattern for conditional first-launch screens.

---

## Calculator Screen UX

### Input Widgets

| Input | Widget | Constraints | Default |
|-------|--------|-------------|---------|
| Sex | `SegmentedButton<String>` (Material 3) with 3 segments | Required | No default (force explicit selection) |
| Weight | `TextField` with `keyboardType: TextInputType.number`, suffix "kg" | Required; valid range 30-200 kg; integer only | Empty |
| Climate | `SegmentedButton<int>` or 5 `ChoiceChip` widgets | Required | No default (force explicit selection) |

### Interaction Flow

1. User selects sex, enters weight, selects climate level
2. Result calculates reactively as inputs change (local `setState`)
3. Result is hidden until all 3 inputs are valid
4. "Use as target" button enables only when result is displayed
5. On "Use as target":
   - Calls `upsertTarget(todayKey, calculatedMl)` on target history DAO
   - Calls `updateSettings(settings.copyWith(dailyTargetMl: calculatedMl))` on settings repo
   - If onboarding: sets `drinky_calculatorShown = true`, `context.go('/')`
   - If from settings: `context.pop()`, shows SnackBar "Target updated to X ml"
6. "Skip for now" (onboarding only): sets `drinky_calculatorShown = true`, `context.go('/')` without changing target

### Layout Structure

```
SafeArea > SingleChildScrollView > Column:
  - Icon (water_drop, size 64)
  - Headline: "How much water do you need?"
  - Body text: brief explanation
  - Sex selector (SegmentedButton)
  - Weight input (TextField)
  - Climate selector (SegmentedButton or ChoiceChip row)
  - AnimatedSwitcher for result card (appears when all inputs valid)
  - "Use as target" button (FilledButton, full width)
  - "Skip for now" (TextButton, onboarding only)
  - Privacy + disclaimer text (bodySmall, muted color)
```

---

## Sources

### Hydration Formula

- EFSA Panel on Dietetic Products, Nutrition, and Allergies. "Scientific Opinion on Dietary Reference Values for water." EFSA Journal 2010;8(3):1459. -- Primary source for 2,000/2,500 ml AI values
- IOM/NASEM. Dietary Reference Intakes for Water, Potassium, Sodium, Chloride, and Sulfate. National Academies Press, 2005. -- US/Canadian 3,700/2,700 ml AI values
- Popkin BM, D'Anci KE, Rosenberg IH. "Water, hydration, and health." Nutr Rev. 2010;68(8):439-458. PMC2908954. -- Confirmed sweat loss variability (0.3-2.0 L/h), supports "1 ml per kcal" as alternative expression
- Wikipedia: Dietary Reference Intake -- Confirmed EFSA 2.0/2.5 L and IOM 3.7/2.7 L total water values
- Wikipedia: Drinking water -- Confirmed EFSA and IOM values, noted extreme variability in hot climates
- Omnicalculator.com Water Intake Calculator -- Uses IOM AI lookup (not weight-based); confirms no standard per-kg formula exists
- Medical News Today -- Confirmed "weight x 0.5 oz" rule of thumb (~33 ml/kg), age-stratified IOM values
- Healthline -- Confirmed 2.7/3.7 L IOM values, climate increases, 20% food contribution

### Target History / Drift Migrations

- Drift official documentation: https://drift.simonbinder.eu/migrations/ -- Schema migration patterns, `m.createTable()` in `onUpgrade` (verified via Context7 library /websites/drift_simonbinder_eu)
- Drift migration API (Context7) -- Confirmed `m.createTable(schema.tableName)` pattern, `stepByStep()` helper, `insertOnConflictUpdate` for upsert

### First-Launch Detection

- Existing codebase: `lib/core/router/app_router.dart` lines 20-29 -- Proven SharedPreferences + GoRouter async redirect pattern
- Existing codebase: `lib/presentation/screens/permission_screen.dart` -- One-time screen flow reference implementation
