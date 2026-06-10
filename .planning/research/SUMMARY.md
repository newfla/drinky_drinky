# Research Summary: Drinky Drinky v1.2

**Project:** Drinky Drinky — v1.2 Bug Fixes & Feature Depth
**Researched:** 2026-06-10
**Confidence:** HIGH

## Executive Summary

Drinky Drinky v1.2 adds target history, a hydration calculator, and 3 bug fixes — all using the existing stack with no new packages. The central change is a Drift schema v1→v2 migration adding a `target_history` table, which enables the calendar and streak to evaluate each past day against the target that was actually active then. The dominant risks are in the migration (missing `schemaVersion` bump, no sentinel row for upgrade users, no test coverage) and the onboarding redirect (wrong priority order, redirect loop if flag set too late).

## Key Findings

### Stack Additions

**No new packages required.** All v1.2 features are achievable with the existing dependency set (drift, shared_preferences, go_router, freezed, intl).

**Drift migration API (v2.33.0):**
```dart
@override
int get schemaVersion => 2; // bump from 1

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(targetHistory);
      // Seed sentinel row for existing users
      await into(targetHistory).insert(TargetHistoryCompanion.insert(
        effectiveDate: '2000-01-01',
        targetMl: currentTargetMl,
      ));
    }
  },
);
```

**First-launch detection:** add `drinky_calculatorShown` key to existing SharedPreferences + GoRouter redirect chain (identical pattern to existing `drinky_permissionScreenShown`). Set flag in calculator screen `initState`, not on button tap.

---

### Feature Constants (implementation-ready)

**Hydration formula (EFSA-anchored):**
- Male: **30 ml/kg** | Female: **28 ml/kg** | Other: **29 ml/kg**
- Climate multipliers: Freddo/Mite = **1.00** | Caldo = **1.10** | Molto caldo = **1.20** | Afoso = **1.30**
- Output: clamped 1,000–5,000 ml, rounded to nearest 50 ml
- Calculator inputs (sex, weight, climate) are **NOT persisted** — local widget state only
- Privacy disclaimer required on screen

**Target history schema:**
```dart
class TargetHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get effectiveDate => text().unique()(); // YYYY-MM-DD
  IntColumn get targetMl => integer()();
}
```
- Query pattern: `WHERE effectiveDate <= :dateKey ORDER BY effectiveDate DESC LIMIT 1`
- Seed row on v1→v2 upgrade: `effectiveDate = '2000-01-01'`, `targetMl = currentSettings.dailyTargetMl`
- Upsert via `insertOnConflictUpdate` for same-day target changes

**SharedPreferences keys:**
- `drinky_permissionScreenShown` — existing
- `drinky_calculatorShown` — new; set in `initState` of calculator screen

---

### Architecture

**New components:**
- `TargetHistoryDao` — separate from `UserSettingsDao`; append-only with range query
- `effectiveTargetForDateProvider(dateKey)` — Riverpod provider for per-day target lookup
- `HydrationCalculatorScreen` — pure stateless computation screen
- `/calculator` GoRoute — top-level route with onboarding redirect guard

**Provider graph changes (additive only, no breaking changes):**
- `settingsProvider` unchanged — `UserSettings.dailyTargetMl` stays as current-target source for home screen and notifications
- `effectiveTargetForDateProvider(dateKey)` — new; used by calendar and streak only
- `calendarMonthTargetsProvider` — new; pre-fetches target history for visible month

**Key integration rule:** All target changes (from Settings slider AND from "Use as target" button) MUST go through a single `updateTargetWithHistory()` method that writes to BOTH `UserSettings.dailyTargetMl` AND inserts into `target_history`. Never call bare `updateSettings()` for target updates.

**Build order:**
1. Data Foundation — schema v2 migration + `TargetHistoryDao` + shared dateKey validator; BUG-01, BUG-03 here
2. Provider Layer + BUG-02 — `effectiveTargetForDateProvider`, updated `streakProvider`, midnight invalidation fix
3. Hydration Calculator Screen — formula function, screen, GoRoute, onboarding redirect, Settings tile
4. UI Integration — wire new providers into HomeScreen, HistoryScreen, SettingsScreen (today/tomorrow toggle)
5. Validation — migration integration test, onboarding flow test, calendar regression test

---

### Critical Watch List

| # | Pitfall | Severity |
|---|---------|----------|
| 1 | Forgetting to bump `schemaVersion` to 2 — `onUpgrade` silently skipped, app crashes for existing users | CRITICAL |
| 2 | No sentinel row seeded in `onUpgrade` — pre-v1.2 calendar dates have no evaluable target | CRITICAL |
| 3 | Redirect loop — `drinky_calculatorShown` set on button tap instead of on screen display | CRITICAL |
| 4 | Dual-write not enforced — bare `updateSettings()` skips `target_history`; home and calendar diverge | HIGH |
| 5 | Streak broken retroactively — streak uses today's global target for all past days | HIGH |
| 6 | No UNIQUE constraint on `effectiveDate` — same-day duplicates produce non-deterministic query results | HIGH |
| 7 | Calculator "Use as Target" must use "apply from today" semantics during onboarding | MEDIUM |

---

### Research Flags

- **Export schema v1 BEFORE bumping `schemaVersion`:** `dart run drift_dev schema dump` — first step in Phase 1
- **BUG-01 may already be fixed:** architecture research found `deleteLastEntry` DAO may already filter by `dateKey`; verify before implementing
- **Climate multipliers are opinionated estimates** — no authority publishes exact per-temperature-band percentages; add disclaimer text on screen
- **Formula constants (30/28/29 ml/kg)** are EFSA-anchored but not published verbatim; conservative and defensible

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Drift migration API | HIGH | Verified via Context7 (drift.simonbinder.eu official docs) |
| Stack additions | HIGH | No new packages; all patterns already in use |
| Hydration formula | MEDIUM | EFSA-derived per-kg simplification; not published verbatim |
| Climate multipliers | LOW-MEDIUM | Conservative estimates; no authoritative source |
| Architecture / build order | HIGH | Traced through actual import graph and source files |
| Pitfalls | HIGH | Verified against official Drift docs and existing codebase |

**Overall confidence:** HIGH

## Sources

- drift.simonbinder.eu — migration API, `createTable` in `onUpgrade`
- EFSA (2010) — Scientific Opinion on Dietary Reference Values for water (AI: 2.5L men, 2.0L women)
- GoRouter docs — redirect callback with StatefulShellRoute
- Existing codebase: `app_router.dart`, `settings_repository.dart`, `user_settings_dao.dart`

---
*Research completed: 2026-06-10*
*Ready for roadmap: yes*
