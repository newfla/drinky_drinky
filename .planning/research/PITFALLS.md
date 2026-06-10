# Pitfalls Research: Drinky Drinky v1.2 -- Bug Fixes & Feature Depth

**Domain:** Flutter hydration tracker / water reminder app (offline-first, iOS + Android)
**Stack:** Flutter 3.44.1 + Riverpod 3.x + Drift 2.33.0 + GoRouter + SharedPreferences
**Researched:** 2026-06-10
**Scope:** Pitfalls specific to v1.2 features: Drift schema migration (target_history table), target history query, hydration calculator with first-launch onboarding, "Use as Target" flow, and 3 bug fixes (BUG-01/02/03). v1.0/v1.1 pitfalls remain valid and are not repeated.

---

## Drift Migration Pitfalls

### Pitfall 1: Forgetting to Bump schemaVersion (CRITICAL)

**Risk:** The `target_history` table class is added to the `@DriftDatabase(tables: [...])` annotation and the Dart code compiles fine, but `schemaVersion` stays at `1`. On existing installs, Drift sees `schemaVersion == 1` (matches the stored version), skips `onUpgrade` entirely, and the new table is never created. The first query against `target_history` throws a SQLite "no such table" error at runtime, crashing the app.

**Why it happens:** Drift checks the stored schema version against `schemaVersion`. If they match, it assumes no migration is needed. The Dart code generator happily generates accessors for the new table regardless of whether the physical table exists. There is no compile-time or static analysis check that `schemaVersion` matches the number of tables.

**Consequences:** App crashes on first query to `target_history`. Every existing user (v1.0 and v1.1 installs) is affected. New installs work fine because `onCreate` calls `m.createAll()`.

**Prevention:**
1. Bump `schemaVersion` to `2` in `app_database.dart`
2. Add `onUpgrade` callback with `m.createTable(targetHistory)` for `from < 2`
3. Add a code review checklist item: "Did you bump schemaVersion if you changed tables?"
4. Write a migration test that opens a v1 database and validates v2 schema (see Pitfall 3)

**Detection:** Run the app on a device/emulator that already has v1 data. If it crashes with "no such table: target_history", the version was not bumped.

**Confidence:** HIGH -- confirmed via Drift official docs (https://drift.simonbinder.eu/faq/): "If you add a new table after your app is installed, you must write a migration to create it."

**Phase:** Must be addressed in the same phase that introduces the `target_history` table (TARGET-01).

---

### Pitfall 2: Using addColumn Instead of createTable for a New Table

**Risk:** The developer writes `m.addColumn(targetHistory, targetHistory.someColumn)` inside `onUpgrade`, confusing "add a column to an existing table" with "create a new table." The migration throws because the `target_history` table does not exist yet -- you cannot add a column to a non-existent table.

**Why it happens:** The Drift migration API has `addColumn` (for adding a column to an existing table) and `createTable` (for creating a brand new table). The names are clear, but developers who have only seen `addColumn` examples in tutorials may reach for it by default.

**Consequences:** Migration fails. The database is left in an inconsistent state. Depending on whether the migration runs inside a transaction (Drift does wrap migrations in a transaction by default), the failure may roll back cleanly, but the app still cannot open the database successfully.

**Prevention:**
```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 2) {
    await m.createTable(targetHistory);  // NOT addColumn
  }
},
```

**Detection:** Run the migration on a v1 database. If it throws, check whether `createTable` was used instead of `addColumn`.

**Confidence:** HIGH -- Drift official docs show `createTable` for new tables and `addColumn` for new columns on existing tables.

**Phase:** TARGET-01.

---

### Pitfall 3: No Migration Test Coverage

**Risk:** The migration from v1 to v2 is written but never tested. A subtle error (wrong table reference, missing column, typo in column name) is only discovered when the first user upgrades from v1.0/v1.1 to v1.2. By then, the app is published and users are crashing.

**Why it happens:** Migration tests require exporting schema snapshots with `dart run drift_dev schema dump` and generating test helpers with `dart run drift_dev schema generate`. This is extra setup that is easy to skip, especially since the existing project has zero migration tests (only DAO tests using `NativeDatabase.memory()`, which always runs `onCreate`).

**Consequences:** A broken migration reaches production. Users with existing data cannot open the app. The only recovery is an emergency update.

**Prevention:**
1. Export schema v1 before making changes: `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
2. Make the schema changes (add table, bump version)
3. Export schema v2
4. Generate test helpers: `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`
5. Write a test:
```dart
test('upgrade from v1 to v2', () async {
  final connection = await verifier.startAt(1);
  final db = AppDatabase(connection);
  await verifier.migrateAndValidate(db, 2);
  await db.close();
});
```

**Detection:** If the `drift_schemas/` directory does not exist, migration tests have not been set up.

**Confidence:** HIGH -- Drift official docs strongly recommend migration testing: https://drift.simonbinder.eu/migrations/tests/

**Phase:** TARGET-01 (must be done as part of the migration implementation).

---

### Pitfall 4: onCreate Does Not Seed target_history for New Installs

**Risk:** The migration `onUpgrade` creates the `target_history` table, but `onCreate` still only calls `m.createAll()` and seeds `userSettings` and `drinkPresets`. For new installs, the `target_history` table is created (because `createAll` handles it), but it has zero rows. The app then queries for the target applicable to today and gets null. If the fallback is not implemented correctly, the progress ring shows 0/0 or crashes.

**Why it happens:** `onCreate` runs for fresh installs (no existing database). `onUpgrade` runs for upgrades. Developers often focus on `onUpgrade` and forget that new installs also need correct initial state.

**Consequences:** New users on v1.2 see broken target display until they manually set a target in Settings. The default 2000ml from `UserSettings` is not reflected in `target_history`.

**Prevention:** Two options:
- **Option A (recommended):** Seed an initial `target_history` row in `onCreate` with `effectiveDate = '2000-01-01'` (epoch sentinel) and `targetMl = 2000` (matching the default).
- **Option B:** Ensure the target lookup query falls back to `UserSettings.dailyTargetMl` when `target_history` has no rows. This is needed anyway for upgrade users (see Pitfall 8).

Both options should be implemented. Option A ensures consistency; Option B provides a safety net.

**Detection:** Install the app fresh (delete all app data). Check if the home screen shows the correct default target.

**Confidence:** HIGH -- direct inspection of current `onCreate` in `app_database.dart` (line 37-49).

**Phase:** TARGET-01.

---

### Pitfall 5: Downgrade After Target History Is Added

**Risk:** A user installs v1.2 (schemaVersion=2), then somehow gets v1.1 (schemaVersion=1) reinstalled (e.g., enterprise MDM rollback, sideloading). The stored schema version (2) is higher than the app's `schemaVersion` (1). Drift does NOT call `onUpgrade` (because from > to). It silently opens the database with the v2 schema but the v1 code. The `target_history` table is present but unused. The user's data is preserved, but if the downgraded code queries tables that were altered (not our case here), it could fail.

**Why it happens:** Drift has no `onDowngrade` callback. It simply opens the database if the stored version is >= the app version. SQLite itself is forward-compatible (extra tables do not cause errors).

**Consequences:** For this specific migration (adding a new table only, no column changes to existing tables), downgrade is actually safe. The v1 code will never query `target_history`, so the extra table is harmless. However, this is worth documenting so the team does not assume downgrades are always safe for future migrations.

**Prevention:** No action needed for v1.2 specifically. For future migrations that alter existing tables (e.g., adding a column to `water_entries`), consider adding a `beforeOpen` check that validates critical tables/columns exist.

**Confidence:** MEDIUM -- Drift docs do not document downgrade behavior explicitly. Verified by reasoning about SQLite behavior (extra tables are ignored) and Drift source code (no `onDowngrade` callback exists).

**Phase:** TARGET-01 (document in code comments, no code change needed).

---

## Target History Query Pitfalls

### Pitfall 6: Off-by-One on Same-Day Target Change

**Risk:** User changes their target on June 10th. The `target_history` row is inserted with `effectiveDate = '2026-06-10'`. A query for "what is my target on June 10th?" uses `MAX(effectiveDate) WHERE effectiveDate <= '2026-06-10'`, which correctly returns the new target. This is NOT an off-by-one -- the query works correctly for same-day changes.

However, the "apply from tomorrow" option (TARGET-02) introduces a real off-by-one risk: if the user changes the target at 11:59 PM and selects "apply from tomorrow," the effective date is `'2026-06-11'`. Between 11:59 PM and midnight, today's target still shows the old value. At midnight, `_todayDateKey()` flips to `'2026-06-11'`, and the new target kicks in. This is correct behavior, but developers might incorrectly try to make it "apply immediately" when the user selected "tomorrow."

**Prevention:**
- The query `SELECT targetMl FROM target_history WHERE effectiveDate <= :dateKey ORDER BY effectiveDate DESC LIMIT 1` is correct for both "today" and "tomorrow" semantics.
- "Apply from today" sets `effectiveDate = todayDateKey()`.
- "Apply from tomorrow" sets `effectiveDate = tomorrowDateKey()`.
- Do NOT add any "apply at time of day" logic. The dateKey is a date, not a timestamp.

**Detection:** Write tests:
1. Set target to 2000 on June 9th, change to 3000 on June 10th with "apply today." Query for June 10th should return 3000.
2. Same scenario with "apply tomorrow." Query for June 10th should return 2000. Query for June 11th should return 3000.

**Confidence:** HIGH -- reasoning from the SQL query pattern and dateKey semantics.

**Phase:** TARGET-01/02.

---

### Pitfall 7: Multiple Same-Day Target Changes Create Duplicate Rows

**Risk:** The user changes their target twice on the same day (e.g., 2000->3000 at 9 AM, then 3000->2500 at 2 PM). Two rows in `target_history` have `effectiveDate = '2026-06-10'`. The query `MAX(effectiveDate) WHERE effectiveDate <= dateKey` returns BOTH rows (same date), and `LIMIT 1` returns whichever the database picks. If you do `ORDER BY effectiveDate DESC LIMIT 1` without a tiebreaker, the result is non-deterministic.

**Why it happens:** The table allows multiple rows with the same `effectiveDate`.

**Consequences:** The wrong target is displayed. The progress ring shows inconsistent values.

**Prevention:** Two options:
- **Option A (recommended):** Use `INSERT OR REPLACE` with a UNIQUE constraint on `effectiveDate`. The second change overwrites the first. This means the day always has one canonical target.
- **Option B:** Add an `id` autoincrement and use `ORDER BY effectiveDate DESC, id DESC LIMIT 1` to break ties by insertion order (most recent wins).

Option A is simpler and matches the domain semantics: "the target for a given effective date" is a single value, not a history of changes within the same day.

**Detection:** Write a test: insert two target_history rows with the same effectiveDate. Query for that date. Verify the result is deterministic and correct.

**Confidence:** HIGH -- standard SQL uniqueness concern.

**Phase:** TARGET-01 (table design phase).

---

### Pitfall 8: No History Row for Pre-v1.2 Dates (Upgrade Users)

**Risk:** A user who has been using v1.0/v1.1 since June 3rd upgrades to v1.2 on June 10th. The `target_history` table is created empty by the migration. When the calendar view queries the target for June 5th, the query `MAX(effectiveDate) WHERE effectiveDate <= '2026-06-05'` returns null (no rows match). The calendar view has no target to compare against, so it cannot determine green/red coloring.

**Why it happens:** Historical data (water entries from June 3-9) exists, but target history does not. The migration creates the table but does not backfill it.

**Consequences:** Calendar view for all pre-v1.2 dates shows no color coding (no target to compare against) or crashes if the null is not handled.

**Prevention:**
1. **Migration seeds a sentinel row:** In `onUpgrade from < 2`, after creating the table, insert a row with `effectiveDate = '2000-01-01'` and `targetMl = currentSettingsTarget`. This ensures every date query returns at least this sentinel.
   ```dart
   onUpgrade: (Migrator m, int from, int to) async {
     if (from < 2) {
       await m.createTable(targetHistory);
       // Seed with current target so historical dates are colored correctly
       final settings = await (select(userSettings)
         ..where((t) => t.id.equals(1))).getSingle();
       await into(targetHistory).insert(
         TargetHistoryCompanion.insert(
           effectiveDate: '2000-01-01',
           targetMl: settings.dailyTargetMl,
         ),
       );
     }
   };
   ```
2. **Query-level fallback:** If the target_history query returns null, fall back to `UserSettings.dailyTargetMl`. This is a safety net, not the primary strategy.

**Detection:** Upgrade from v1 with existing water entries. Open the calendar for a past date. If no green/red coloring appears, the migration did not seed historical target data.

**Confidence:** HIGH -- direct consequence of the migration design; confirmed by examining current `app_database.dart` migration (no onUpgrade exists currently).

**Phase:** TARGET-01 (migration phase).

---

### Pitfall 9: Timezone Edge Case with dateKey Storage

**Risk:** The `dateKey` is formatted as `YYYY-MM-DD` using `DateTime.now()` local time. If the user travels across timezones (e.g., lands in a new timezone at 11 PM), `DateTime.now()` might return a different date than expected. A target change made "today" might get stored with tomorrow's date in the old timezone.

**Why it happens:** `DateTime.now()` returns local time. Timezone changes shift what "today" means. The `target_history.effectiveDate` and `water_entries.dateKey` both use local time, so they are at least consistent with each other. The real risk is the user's perception: "I changed my target today" but the app stored it as tomorrow.

**Consequences:** Minor. The target and water entries use the same `todayDateKey()` function, so they are always consistent. The "wrong" timezone date affects both equally. The user might see their target change reflected one day earlier or later than expected in the calendar, but the progress calculation is internally consistent.

**Prevention:** Accept this as a known limitation. Document it. Do NOT try to store UTC or a specific timezone -- this would create far worse inconsistencies with water entries that are already stored in local time. The existing approach (local-time dateKey everywhere) is correct for an offline app.

**Detection:** Not practically testable without timezone simulation.

**Confidence:** MEDIUM -- edge case that affects perception, not correctness.

**Phase:** No action needed. Document as known limitation.

---

## First-Launch Onboarding Pitfalls

### Pitfall 10: Race Between SharedPreferences Async Read and GoRouter Redirect (CRITICAL)

**Risk:** The existing GoRouter redirect checks `SharedPreferences.getInstance()` asynchronously on EVERY navigation event. The new onboarding (CALC-02: show calculator on first launch) introduces a SECOND SharedPreferences check (`drinky_calculatorShown` or similar). Now there are two async SharedPreferences reads racing against GoRouter initialization: one for the permission screen and one for the calculator.

**Why it happens:** GoRouter's `redirect` is called on every navigation event (not just initial launch). The existing implementation awaits `SharedPreferences.getInstance()` inside the redirect function. SharedPreferences caches after the first read, so subsequent calls are fast. However, the FIRST call (before the cache is warm) introduces a delay. If two redirects check two flags, the order of checks matters.

**Consequences:** On first launch:
- If both `drinky_permissionScreenShown` and `drinky_calculatorShown` are false, the redirect must decide which screen to show first.
- If the redirect is not deterministic, the user might see the calculator before the permission screen (wrong order) or get caught in a redirect loop between the two screens.

**Prevention:**
1. **Single redirect function with explicit ordering:**
   ```dart
   redirect: (context, state) async {
     // Check location guards in priority order
     if (state.matchedLocation == '/permission') return null;
     if (state.matchedLocation == '/calculator') return null;

     final prefs = await SharedPreferences.getInstance();

     // Permission screen first (highest priority)
     final permShown = prefs.getBool('drinky_permissionScreenShown') ?? false;
     if (!permShown) return '/permission';

     // Calculator second
     final calcShown = prefs.getBool('drinky_calculatorShown') ?? false;
     if (!calcShown) return '/calculator';

     return null;
   },
   ```
2. **Guard against BOTH screens** in the location check, not just `/permission`.
3. The permission screen's `_onEnableReminders` and `_onSkip` set `drinky_permissionScreenShown = true` and then call `context.go('/')`. The redirect then re-evaluates and routes to `/calculator`.

**Detection:** Fresh install. If the calculator appears before the permission screen, or if the app flickers between screens, the redirect ordering is wrong.

**Confidence:** HIGH -- direct analysis of existing `app_router.dart` (lines 23-30).

**Phase:** CALC-02 (first-launch onboarding).

---

### Pitfall 11: Redirect Loop if Calculator Flag Is Never Set

**Risk:** The calculator screen is shown on first launch. The user navigates away (e.g., presses the back button, or the app restarts before the flag is set). The redirect fires again, sees `drinky_calculatorShown = false`, and redirects back to the calculator. The user is stuck in a loop.

**Why it happens:** The flag `drinky_calculatorShown` must be set BEFORE navigating away from the calculator screen, not after. If the user can dismiss the calculator without triggering the flag write, the redirect will keep sending them back.

**Consequences:** User is trapped on the calculator screen. The only escape is to clear app data.

**Prevention:**
1. Set the flag at the moment the calculator screen is displayed (in `initState`), not when the user presses "Use as Target" or navigates away. This guarantees the flag is set even if the app crashes mid-screen.
   ```dart
   @override
   void initState() {
     super.initState();
     SharedPreferences.getInstance().then((prefs) {
       prefs.setBool('drinky_calculatorShown', true);
     });
   }
   ```
2. Alternatively, set the flag in the redirect itself before returning the redirect path:
   ```dart
   if (!calcShown) {
     prefs.setBool('drinky_calculatorShown', true);  // fire-and-forget
     return '/calculator';
   }
   ```
   This is slightly less clean but guarantees no loop.
3. Add a "Skip" button on the calculator screen that sets the flag and navigates to `/`.

**Detection:** Force-kill the app while on the calculator screen. Relaunch. If the calculator reappears, the flag was not set early enough.

**Confidence:** HIGH -- direct analysis of existing permission screen pattern (it sets the flag before navigation).

**Phase:** CALC-02.

---

### Pitfall 12: Deep Links Intercepted by Onboarding Redirect

**Risk:** A deep link (e.g., from a push notification) targets `/history` or `/settings`. The redirect function intercepts it and sends the user to `/calculator` instead (because `drinky_calculatorShown` is false). The intended destination is lost.

**Why it happens:** GoRouter's top-level `redirect` runs on ALL navigation events, including deep links. The existing permission redirect already has this issue, but it was acceptable because the permission screen is shown exactly once on first launch. The calculator redirect extends this window.

**Consequences:** Minor for this app. Push notification deep links (if any) would be intercepted during the brief first-launch window. After the flag is set, deep links work normally.

**Prevention:**
1. For v1.2, this is acceptable. The app has no external deep links currently (notifications use the default launch behavior, not deep links to specific routes).
2. If deep links are added later, store the intended destination and restore it after onboarding:
   ```dart
   if (!calcShown) {
     // Save intended destination for post-onboarding redirect
     prefs.setString('drinky_pendingDeepLink', state.uri.toString());
     return '/calculator';
   }
   ```

**Detection:** Not testable in v1.2 (no deep links exist). Flag for v2 if deep link support is added.

**Confidence:** MEDIUM -- theoretical risk, not applicable to current feature set.

**Phase:** CALC-02 (document only, no code change).

---

## "Use as Target" Flow Pitfalls

### Pitfall 13: First History Entry Created Before Table Exists

**Risk:** The user presses "Use as Target" on the calculator screen during first-launch onboarding. At this point, the Drift database may not have finished its migration yet (if the database is opened lazily). The `target_history` table might not exist when the insert is attempted.

**Why it happens:** The Drift database is initialized via Riverpod's `databaseProvider`. If the calculator screen is shown BEFORE any provider reads the database (because the home screen has not loaded yet), the database might not be opened and migrated yet.

**Consequences:** Insert into `target_history` throws "no such table" error.

**Prevention:**
1. Ensure the database is opened and migrated before the calculator screen is shown. The current `databaseProvider` is a `keepAlive` provider that opens the database on first read. The permission screen already reads `userSettingsProvider`, which triggers database initialization. So if the permission screen comes before the calculator, the database is already open.
2. If the calculator screen can be the FIRST screen (e.g., if `drinky_permissionScreenShown` is already true from a previous version), ensure the calculator's "Use as Target" handler reads a database provider first.
3. Safest approach: have the "Use as Target" handler go through `SettingsRepository.updateSettings()` (which already works) AND create the target_history entry. The settings repository already depends on the database being open.

**Detection:** Fresh install, skip permission quickly, immediately press "Use as Target" on calculator. If it crashes, the database was not ready.

**Confidence:** MEDIUM -- depends on provider initialization order, which the current code handles correctly for the permission screen but may not for the calculator.

**Phase:** CALC-04.

---

### Pitfall 14: "Use as Target" Does Not Create target_history Entry

**Risk:** The "Use as Target" button updates `UserSettings.dailyTargetMl` (the existing setting) but forgets to also insert a `target_history` row. The home screen works (it still reads from `UserSettings`), but the calendar view uses `target_history` for per-day coloring and finds no rows.

**Why it happens:** The existing `SettingsRepository.updateSettings()` only writes to the `UserSettings` table. The developer calls this existing method and forgets that v1.2 also requires a `target_history` insert.

**Consequences:** Home screen shows the correct target. Calendar shows no green/red coloring for today and future dates (unless the migration seeded a sentinel row, and the sentinel has the old default value, not the calculator's recommendation).

**Prevention:**
1. Create a new method (e.g., `SettingsRepository.updateTargetWithHistory()`) that:
   a. Updates `UserSettings.dailyTargetMl`
   b. Inserts/replaces a `target_history` row with `effectiveDate = todayDateKey()` and the new target
2. Use this method everywhere the target is changed: Settings slider, "Use as Target" button, and any future target-change flow.
3. Do NOT leave the old `updateSettings` path as an unguarded way to change the target without creating history.

**Detection:** Press "Use as Target." Open calendar for today. If the day is not colored according to the new target, the history entry was not created.

**Confidence:** HIGH -- identified by tracing the code path from `settings_screen.dart` slider handler (line 114) which currently calls `updateSettings()` without any history logic.

**Phase:** TARGET-01 + CALC-04 (the method must be created in TARGET-01 and used by CALC-04).

---

### Pitfall 15: "Use as Target" Should Always Use "Apply From Today" Semantics

**Risk:** The calculator's "Use as Target" button uses "apply from tomorrow" semantics because the developer copied the logic from the Settings target change (which offers "today/tomorrow"). During onboarding, this makes the recommended target take effect TOMORROW, not today. The user sets up their target on first launch and sees 0/2000 instead of 0/3000 (the recommendation).

**Why it happens:** The "today/tomorrow" toggle exists in Settings for users who want to change mid-day without retroactively affecting today's progress. During onboarding (first launch), the user has zero entries, so "today" is always correct.

**Consequences:** Confusing first impression. The user expects the recommended target to apply immediately.

**Prevention:**
1. The calculator's "Use as Target" handler always uses `effectiveDate = todayDateKey()` (no toggle, no dialog).
2. The Settings target change shows the "today/tomorrow" toggle as designed.
3. Document this distinction in code comments.

**Detection:** First launch. Use calculator. Press "Use as Target" with 3000ml recommendation. Home screen should show 0/3000, not 0/2000.

**Confidence:** HIGH -- UX logic.

**Phase:** CALC-04.

---

## Bug Fix Pitfalls

### Pitfall 16: deleteLastEntry Filter on createdAt vs dateKey (BUG-01)

**Risk:** The bug fix for `deleteLastEntry` adds a date filter to prevent cross-day deletion. The developer filters on `loggedAt` (the timestamp) instead of `dateKey` (the date string). If the user logs an entry at 11:58 PM and presses "undo" at 12:02 AM (after midnight), the `loggedAt` timestamp is on the old day, but `todayDateKey()` has flipped to the new day. Filtering on `loggedAt` with today's date would fail to find the entry.

**Why it happens:** The confusion between `loggedAt` (DateTime, includes time) and `dateKey` (String, date only). The current `deleteLastEntry` already filters by `dateKey` (see `water_entry_dao.dart` line 36: `..where((t) => t.dateKey.equals(dateKey))`), so this bug is actually already fixed in the DAO. The real BUG-01 issue is at the caller level in `home_screen.dart`.

**Actual bug analysis:** Looking at the current code, `_onQuickAdd` captures `_dateKey` before the async gap (line 246: `final capturedKey = _dateKey;`), and the undo handler calls `repo.deleteLastEntry(capturedKey)` (line 265). The `capturedKey` was captured at the time of logging, so if `_dateKey` flips at midnight, the undo still uses the old date key. This is CORRECT behavior for entries logged before midnight.

The ACTUAL BUG-01 scenario is: the user logs an entry on June 10th, does NOT undo it, goes to sleep, wakes up on June 11th, and taps UNDO. The SnackBar is gone (5-second timer), so this should not happen. BUT if the SnackBar is still showing (e.g., the user locked their phone within 5 seconds), the captured key is still June 10th, and the delete correctly targets June 10th's entry.

**Re-evaluation:** The current `deleteLastEntry` DAO already filters by `dateKey`. The caller already captures the dateKey at log time. The bug may be more nuanced -- perhaps it is about the case where `_dateKey` has NOT been updated at midnight and the user logs a new entry at 12:01 AM with the stale `_dateKey` of the previous day. This is actually BUG-02, not BUG-01.

**Prevention:**
1. Re-read the exact BUG-01 description before implementing: "deleteLastEntry aggiunge filtro sulla data odierna per evitare cancellazione cross-day."
2. The current DAO implementation already filters by dateKey. The fix may need to be at the repository or home_screen level, ensuring the undo callback always uses the dateKey that was current when the entry was logged (which it already does via `capturedKey`).
3. If the bug is about a different scenario (e.g., the `_dateKey` field being stale), it overlaps with BUG-02.

**Detection:** Write a test: insert entry with dateKey='2026-06-10', then call deleteLastEntry('2026-06-11'). It should return 0 (no deletion). Then call deleteLastEntry('2026-06-10'). It should return 1.

**Confidence:** MEDIUM -- the existing code appears to handle this correctly already. Need to verify the exact BUG-01 scenario before implementing.

**Phase:** BUG-01.

---

### Pitfall 17: _todayDateKey() Midnight Refresh via Timer.periodic vs AppLifecycleListener (BUG-02)

**Risk:** The current code uses BOTH `Timer.periodic(Duration(seconds: 60))` AND `AppLifecycleListener.onResume` to check for date changes (see `home_screen.dart` lines 39-43 and 32-36). The Timer.periodic approach has two problems:
1. It fires every 60 seconds even when the app is backgrounded, wasting battery
2. On some Android OEMs, the timer may be killed in the background, and when the app returns to the foreground, the timer might not fire immediately (it waits for the next 60-second tick)

**Why it happens:** `Timer.periodic` continues to fire in the background on iOS (until the app is suspended by the OS) and on Android (until the process is killed). The `AppLifecycleListener.onResume` fires reliably when the app returns to the foreground.

**Consequences:** If the user opens the app at 11:59 PM, locks the phone, and reopens at 12:01 AM, the `onResume` callback fires and updates `_dateKey`. However, if the user keeps the app in the foreground across midnight, only the timer will catch the change -- and it might take up to 60 seconds.

**Prevention:**
1. Keep `AppLifecycleListener.onResume` as the primary mechanism (already works correctly)
2. Keep the `Timer.periodic` as a fallback for the "app stays in foreground across midnight" case, but change it to a smarter approach:
   - **Option A:** Calculate the exact duration until midnight and schedule a single `Timer(durationUntilMidnight, _checkDateChange)`, then reschedule after each trigger. This eliminates unnecessary 60-second polling.
   - **Option B:** Keep the 60-second timer but accept the 0-60 second delay. This is simpler and the delay is acceptable for a hydration app.
3. Do NOT remove the timer entirely -- the `onResume` approach only works when the app transitions from background to foreground, not when it stays in the foreground.

**Detection:** Keep the app open in the foreground across midnight. If the dateKey does not update within 60 seconds, the timer is not working.

**Confidence:** HIGH -- direct code analysis of `home_screen.dart`.

**Phase:** BUG-02.

---

### Pitfall 18: dateKey Semantic Validation Incomplete (BUG-03)

**Risk:** The current `insertEntry` validation (see `water_repository.dart` lines 34-47) uses `DateTime.tryParse(dateKey)` followed by a round-trip format check. The `DateTime.parse` function in Dart is lenient -- it accepts `2024-02-30` and silently normalizes it to `2024-03-01`. The round-trip check (`roundTrip != dateKey`) catches this because `2024-03-01` != `2024-02-30`. This validation is already correct.

**Re-analysis:** The BUG-03 description says "dateKey valida sia il formato sia la semantica della data (niente 2024-02-30)." The current round-trip check in `water_repository.dart` already rejects `2024-02-30`. So this bug may already be fixed, or the fix is needed in other locations that accept dateKey (e.g., the new target_history DAO).

**Prevention:**
1. Verify that the round-trip validation catches all edge cases: `2024-02-30`, `2024-13-01`, `2024-00-15`, `2024-06-00`, `2024-06-31` (June has 30 days).
2. Extract the validation into a shared utility function (e.g., `bool isValidDateKey(String dateKey)`) so it is not duplicated between `WaterRepository.insertEntry` and the new `TargetHistoryDao.insertEntry` (or equivalent).
3. Write explicit tests for each edge case.

**Detection:** Call `insertEntry` with dateKey='2024-02-30'. If it does not throw ArgumentError, the validation is broken. (Current code DOES throw -- verified by reading `water_repository.dart` lines 38-47.)

**Confidence:** HIGH -- direct code analysis confirms current validation is correct for water_repository but needs to be applied to target_history insertion as well.

**Phase:** BUG-03 + TARGET-01.

---

## Integration Pitfalls (New Feature Breaks Existing Feature)

### Pitfall 19: Home Screen Target Source Changes Break Notifications

**Risk:** The home screen currently reads the target from `UserSettings.dailyTargetMl` (via `userSettingsProvider`). With target history, the home screen should read from `target_history` instead. If this change is made, the notification goal-reached check (line 83: `ref.read(userSettingsProvider).value?.dailyTargetMl`) still reads from the old `UserSettings` table. If the user changes their target via the calculator (which updates `target_history` but might not update `UserSettings`), the notification system uses the old target.

**Why it happens:** Two sources of truth: `UserSettings.dailyTargetMl` and `target_history`. If they disagree, different parts of the app use different targets.

**Consequences:** Notifications stop at the wrong target. The ring shows 0/3000 (from target_history) but notifications stop at 2000 (from UserSettings).

**Prevention:**
1. **Single source of truth rule:** When the target changes (via Settings slider OR "Use as Target"), ALWAYS update BOTH `UserSettings.dailyTargetMl` AND `target_history`. The `UserSettings.dailyTargetMl` becomes the "current" target (used by notifications, home screen real-time display), while `target_history` is the "per-date" target (used by calendar for historical accuracy).
2. Create a provider like `targetForDateProvider(dateKey)` that reads from `target_history` for historical dates and from `UserSettings` for today. Or always read from `target_history` everywhere.
3. Audit all usages of `settings.dailyTargetMl` in the codebase:
   - `home_screen.dart` line 83 (notification goal check)
   - `home_screen.dart` line 129 (progress ring)
   - `history_screen.dart` line 131 (calendar green/red)
   - `settings_screen.dart` line 91 (slider current value)
   - `notification_service.dart` (if it reads the target)

**Detection:** Change target via Settings. Check if both the progress ring and the notification cutoff use the same value.

**Confidence:** HIGH -- identified by tracing provider usage across all screens.

**Phase:** TARGET-03/04 (must be addressed when integrating target_history with the UI).

---

### Pitfall 20: Streak Calculation Uses Global Target, Not Per-Day Target

**Risk:** The streak provider (see `stream_providers.dart` lines 84-119) uses `settings.dailyTargetMl` to check if each past day met the goal. With target history, each past day should be compared against that day's applicable target, not today's global target. If the user had a 2000ml target on June 5th and changed it to 3000ml on June 8th, the streak calculation should compare June 5th's intake against 2000ml, not 3000ml.

**Why it happens:** The streak provider currently reads `settings.dailyTargetMl` once and uses it for all past dates. It does not query `target_history`.

**Consequences:** Streak count is wrong. Days that were previously "goal met" at 2000ml now appear as "goal missed" if the current target is 3000ml. This is particularly frustrating because users lose their streak retroactively when they increase their target.

**Prevention:**
1. The streak provider must query `target_history` for each date it checks, or (more efficiently) load all target history entries and apply the correct target for each date range.
2. Algorithm:
   ```
   Load all target_history entries ordered by effectiveDate DESC.
   For each day from yesterday backwards:
     Find the target_history entry with MAX(effectiveDate <= day).
     Compare that day's total against that target.
   ```
3. This is a query-heavy change. Consider pre-computing a map of `dateKey -> applicableTarget` once and reusing it.

**Detection:** Change the daily target from 2000 to 3000. Check if the streak count changes (it should NOT, because past days should still be measured against their historical target).

**Confidence:** HIGH -- direct analysis of `stream_providers.dart` streak logic.

**Phase:** TARGET-03/04.

---

### Pitfall 21: Calendar Month Provider Does Not Include Target History

**Risk:** The `calendarMonthProvider` (see `stream_providers.dart` lines 69-76) returns `Map<dateKey, totalMl>`. The `HistoryScreen` compares each day's total against `settings.dailyTargetMl` (line 131). With target history, the calendar needs to know each day's applicable target, not just the current global target.

**Why it happens:** The calendar view was designed with a single global target in mind.

**Consequences:** Past days are colored green/red based on the current target, not the target that was active on that day. Same issue as Pitfall 20 but for visual display, not streak counting.

**Prevention:**
1. Create a provider that returns `Map<dateKey, {totalMl, targetMl}>` for a given month, where `targetMl` is the applicable target from `target_history`.
2. Or keep the existing `calendarMonthProvider` and add a separate `targetForMonthProvider` that returns `Map<dateKey, targetMl>`.
3. The calendar builder then compares `total >= targetForDay` instead of `total >= dailyTarget`.

**Detection:** Change the target mid-month. Navigate to the calendar. Days before the change should be colored based on the old target.

**Confidence:** HIGH -- direct analysis of `history_screen.dart`.

**Phase:** TARGET-04.

---

## Phase-Specific Warnings Summary

| Phase Topic | Pitfall | Severity | Mitigation |
|-------------|---------|----------|------------|
| TARGET-01 (Drift migration) | #1 (schema version), #2 (createTable), #3 (test), #4 (onCreate seed) | CRITICAL | Bump version, use createTable, write migration test, seed sentinel row |
| TARGET-01 (table design) | #7 (duplicate effectiveDate rows) | HIGH | UNIQUE constraint on effectiveDate |
| TARGET-01 (upgrade users) | #8 (no history for old dates) | HIGH | Migration seeds sentinel row with current target |
| TARGET-02 (today/tomorrow) | #6 (off-by-one) | MEDIUM | Correct query pattern, clear semantics |
| TARGET-03/04 (UI integration) | #19 (dual source of truth), #20 (streak), #21 (calendar) | HIGH | Always update both tables; per-day target lookup |
| CALC-02 (first-launch) | #10 (redirect ordering), #11 (loop prevention) | CRITICAL | Priority-ordered redirect; set flag early |
| CALC-04 (Use as Target) | #13 (DB not ready), #14 (missing history entry), #15 (today semantics) | HIGH | Ensure DB init; update both tables; always "today" for onboarding |
| BUG-01 (deleteLastEntry) | #16 (dateKey vs loggedAt) | MEDIUM | Verify existing filter; may already be correct |
| BUG-02 (midnight refresh) | #17 (Timer vs lifecycle) | MEDIUM | Keep both; consider targeted midnight timer |
| BUG-03 (dateKey validation) | #18 (extract shared utility) | LOW | Extract validator; apply to target_history DAO |
| Integration | #5 (downgrade safety) | LOW | Document only; safe for this migration |
| Integration | #9 (timezone) | LOW | Known limitation; no action needed |
| Integration | #12 (deep links) | LOW | No deep links in v1.2; defer |

---

## Sources

- Drift official migration docs: https://drift.simonbinder.eu/migrations/ (HIGH confidence)
- Drift migration testing docs: https://drift.simonbinder.eu/migrations/tests/ (HIGH confidence)
- Drift migration API docs: https://drift.simonbinder.eu/migrations/api/ (HIGH confidence)
- Drift FAQ (no such table): https://drift.simonbinder.eu/faq/ (HIGH confidence)
- Drift step-by-step migration docs: https://drift.simonbinder.eu/migrations/step_by_step/ (HIGH confidence)
- GoRouter changelog: https://pub.dev/packages/go_router/changelog (HIGH confidence)
- Direct codebase analysis: `app_database.dart`, `water_entry_dao.dart`, `home_screen.dart`, `history_screen.dart`, `app_router.dart`, `stream_providers.dart`, `settings_repository.dart`, `water_repository.dart` (HIGH confidence)
