# Phase 9: Data Foundation & Bug Fixes - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 9 adds the `target_history` Drift table to the initial schema and delivers the complete `TargetHistoryDao` (read + write). It also adds confirmation tests for BUG-01 and BUG-03, which are already implemented in the codebase. The repository-level dual-write method (`updateTargetWithHistory()`) is explicitly deferred to Phase 10 where the "apply today/tomorrow" logic lives.

This phase does NOT wire up any UI, providers, or settings — that is Phase 10 and 11.

</domain>

<decisions>
## Implementation Decisions

### Bug Disposition (BUG-01, BUG-03)

- **D-01:** BUG-01 (`deleteLastEntry` date filter) is **already implemented** in `lib/data/database/daos/water_entry_dao.dart:35–44`. The DAO fetches the most recent entry filtered by `dateKey` before deleting by ID. No code changes needed.
- **D-02:** BUG-03 (`dateKey` semantic validation) is **already implemented** in `lib/data/repositories/water_repository.dart:34–47`. Validation includes regex + `DateTime.tryParse` + round-trip check. No code changes needed.
- **D-03:** Add **confirmation tests** for both bugs in the existing `test/` directory using in-memory Drift (same pattern as the 11 existing DAO tests). Tests verify: (a) `deleteLastEntry` with a `dateKey` does not delete entries from other dates; (b) `insertEntry` rejects semantically invalid dateKeys such as `"2024-02-30"`.

### target_history Table & Seed

- **D-04:** Add `TargetHistory` table to the **initial schema** (`lib/data/database/app_database.dart`). No migration needed — this is the first real installation of the app. `schemaVersion` stays at `1`.
- **D-05:** Seed the initial `target_history` row in `onCreate` alongside existing seeds. Use:
  - `effectiveDate`: `DateTime.now()` formatted as `YYYY-MM-DD` (today's date at install time)
  - `targetMl`: `2000` (hardcoded, matching `UserSettings.dailyTargetMl` default of `Constant(2000)`)
  - Rationale: fresh install has no water entries before today, so no past-date queries will miss this row.
- **D-06:** The `TargetHistory` table must have a UNIQUE constraint on `effectiveDate`. Use Drift's `uniqueKeys` override or `@TableIndex` with unique flag to enforce this. Upsert via `insertOnConflictUpdate` for same-day changes.

### TargetHistoryDao Scope

- **D-07:** Phase 9 delivers a **complete DAO** with both read and write methods:
  - `Future<int?> getTargetForDate(String dateKey)` — returns `targetMl` for the most recent row where `effectiveDate <= dateKey`. Returns `null` if no rows exist (should not happen after D-05, but defensive).
  - `Stream<List<TargetHistoryEntry>> watchAll()` — reactive stream of all history rows, ordered by `effectiveDate ASC`. Used by Phase 10 for calendar/streak queries.
  - `Future<void> insertOrReplace(String effectiveDate, int targetMl)` — upserts a row. Phase 10 calls this from `updateTargetWithHistory()`.
- **D-08:** The repository-level `updateTargetWithHistory()` method (dual-write to `UserSettings` + `target_history`) belongs in **Phase 10**, not Phase 9. Phase 9 only exposes the DAO primitives.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Drift schema and pattern
- `lib/data/database/app_database.dart` — Current schema: 3 tables, `schemaVersion => 1`, `onCreate` seed pattern. Add `TargetHistory` table and DAO here.
- `lib/data/database/tables/water_entries_table.dart` — Table definition pattern to follow for `TargetHistoryTable`.
- `lib/data/database/tables/user_settings_table.dart` — Column default value pattern (`Constant(2000)` for `dailyTargetMl`).
- `lib/data/database/daos/water_entry_dao.dart` — DAO pattern: `@DriftAccessor`, typed queries, stream and future return types.
- `lib/data/database/daos/user_settings_dao.dart` — Single-row DAO pattern (for contrast with multi-row `target_history`).

### Bug implementations (already done — read to understand before writing tests)
- `lib/data/database/daos/water_entry_dao.dart:35–44` — BUG-01 fix: `deleteLastEntry` filters by `dateKey`.
- `lib/data/repositories/water_repository.dart:34–47` — BUG-03 fix: dateKey semantic validation (regex + DateTime.tryParse + round-trip).

### Requirements
- `.planning/REQUIREMENTS.md` — BUG-01, BUG-03, TARGET-01 in scope for Phase 9.
- `.planning/research/SUMMARY.md` — Target history schema details, UNIQUE constraint, query pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `todayDateKey()` in `lib/core/providers/stream_providers.dart:57–60` — helper that formats `DateTime.now()` as `YYYY-MM-DD`. Use this exact pattern in `onCreate` to compute the seed `effectiveDate`.
- Existing `@TableIndex` usage in `water_entries_table.dart:3` — same decorator pattern for the index on `target_history.effectiveDate`.
- `batch((batch) { ... })` pattern in `app_database.dart:44–50` — use for seeding multiple rows if needed; for the single seed row, plain `into(targetHistory).insert(...)` is sufficient.

### Established Patterns
- **Table file:** `lib/data/database/tables/{name}_table.dart` — one file per table, class extends `Table`.
- **DAO file:** `lib/data/database/daos/{name}_dao.dart` — `@DriftAccessor(tables: [...])`, `part '{name}_dao.g.dart'`.
- **Registration:** Both table and DAO listed in `@DriftDatabase(tables: [...], daos: [...])` in `app_database.dart`.
- **Code-gen:** After adding new table/DAO, run `dart run build_runner build --delete-conflicting-outputs`.
- **Tests:** Existing tests use `AppDatabase(NativeDatabase.memory())` — same pattern for Phase 9 confirmation tests.

### Integration Points
- `app_database.dart` — Register `TargetHistory` table and `TargetHistoryDao` here.
- `lib/core/providers/repository_providers.dart` — May need a new `targetHistoryRepositoryProvider` (or expose DAO directly); Phase 10 decides how to consume it.

</code_context>

<specifics>
## Specific Ideas

- The `getTargetForDate(String dateKey)` query is: `WHERE effectiveDate <= :dateKey ORDER BY effectiveDate DESC LIMIT 1`. In Drift: use `select()` with `where`, `orderBy(DESC)`, `limit(1)`, `getSingleOrNull()`.
- For the UNIQUE constraint on `effectiveDate`: in Drift, use `@override List<Set<Column>> get uniqueKeys => [{effectiveDate}];` in the table class.
- `insertOrReplace` upsert: use `into(targetHistory).insertOnConflictUpdate(companion)`.

</specifics>

<deferred>
## Deferred Ideas

- `updateTargetWithHistory()` repository method (dual-write to UserSettings + target_history) → **Phase 10**
- Provider wiring (`effectiveTargetForDateProvider`) → **Phase 10**
- UI integration (home screen, calendar, settings toggle) → **Phase 10**
- `TargetHistoryRepository` wrapper class → Phase 10 decides if needed or if DAO direct access suffices

</deferred>

---

*Phase: 9-data-foundation-bug-fixes*
*Context gathered: 2026-06-10*
