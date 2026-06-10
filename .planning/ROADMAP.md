# Roadmap: Drinky Drinky

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-06-08)
- ✅ **v1.1 Polish & UX** — Phases 6-8 (shipped 2026-06-08)
- **v1.2 Bug Fixes & Feature Depth** — Phases 9-11 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) — SHIPPED 2026-06-08</summary>

- [x] Phase 1: Data Foundation (2/2 plans) — completed 2026-06-03
- [x] Phase 2: Core Tracking UI (2/2 plans) — completed 2026-06-04
- [x] Phase 3: Settings (1/1 plans) — completed 2026-06-05
- [x] Phase 4: Calendar & Streaks (1/1 plans) — completed 2026-06-05
- [x] Phase 5: Notifications (1/1 plans) — completed 2026-06-05

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Polish & UX (Phases 6-8) — SHIPPED 2026-06-08</summary>

- [x] Phase 6: Bug Fix + Theme + L-Display (2/2 plans) — completed 2026-06-08
- [x] Phase 7: Intake Redesign (1/1 plans) — completed 2026-06-08
- [x] Phase 8: App Icon (1/1 plans) — completed 2026-06-08

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### v1.2 Bug Fixes & Feature Depth (In Progress)

**Milestone Goal:** Fix 3 known bugs and add target history tracking and a hydration calculator with onboarding tutorial.

- [x] **Phase 9: Data Foundation & Bug Fixes** - Drift schema v2 migration, target_history table, dateKey validation, delete-entry date filter (completed 2026-06-10)
- [ ] **Phase 10: Target History Integration** - Per-day target in home/calendar, today/tomorrow setting, midnight reset fix
- [ ] **Phase 11: Hydration Calculator** - Calculator screen with onboarding redirect, Settings tile, "Use as target" button

## Phase Details

### Phase 9: Data Foundation & Bug Fixes

**Goal**: Data layer correctly validates dates, safely deletes entries, and includes target_history from the initial schema
**Depends on**: Phase 8 (v1.1 complete)
**Requirements**: BUG-01, BUG-03, TARGET-01
**Success Criteria** (what must be TRUE):

  1. Undo on a new day does not delete yesterday's last entry — only today's entries are candidates for deletion
  2. Invalid dateKeys such as "2024-02-30" or "abcd-ef-gh" are rejected by the shared validator
  3. target_history table is part of the initial Drift schema (no migration needed — first real install)
  4. On first launch, target_history is seeded with the default target so downstream queries always find a row

**Plans:** 2/2 plans complete
Plans:

- [x] 09-01-PLAN.md — Tabella TargetHistory + DAO completo + seed row + code-gen
- [x] 09-02-PLAN.md — Test di conferma BUG-01/BUG-03 + test completi TargetHistoryDao

### Phase 10: Target History Integration

**Goal**: Users see the correct historical target for each day across home and calendar, and can control when target changes take effect
**Depends on**: Phase 9
**Requirements**: BUG-02, TARGET-02, TARGET-03, TARGET-04
**Success Criteria** (what must be TRUE):

  1. Home screen progress ring and goal text reflect the target that was active on today's date from target_history
  2. Calendar green/red decorations evaluate each past day against the target that was active on that specific day
  3. User can choose "Apply from today" or "Apply from tomorrow" when changing the target in Settings
  4. App automatically transitions to the new day at midnight without requiring restart — progress resets and dateKey updates

**Plans:** 1/3 plans executed
Plans:

- [x] 10-01-PLAN.md — Data layer: applyFromTomorrow column, watchTargetForDate DAO method, updateTargetWithHistory repository method
- [ ] 10-02-PLAN.md — Provider layer: todayDateKeyProvider, effectiveTargetForDate, allTargetHistory, streak update
- [ ] 10-03-PLAN.md — UI wiring: HomeScreen midnight reset + per-day target, HistoryScreen per-day calendar, SettingsScreen toggle

**UI hint**: yes

### Phase 11: Hydration Calculator

**Goal**: Users can calculate a personalized hydration recommendation and optionally apply it as their daily target
**Depends on**: Phase 9
**Requirements**: CALC-01, CALC-02, CALC-03, CALC-04
**Success Criteria** (what must be TRUE):

  1. Calculator screen accepts sex (M/F/Other), weight (kg), and climate (5 levels) and displays a recommendation in ml rounded to nearest 50
  2. Calculator is shown automatically on first app launch after the permission screen, before the home screen
  3. Calculator is accessible from Settings via a dedicated "Recalculate hydration recommendation" tile
  4. "Use as target" button applies the recommendation as the daily target by writing to target_history
  5. Calculator inputs (sex, weight, climate) are never persisted to disk or transmitted — privacy disclaimer is visible on screen

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Data Foundation | v1.0 | 2/2 | Complete | 2026-06-03 |
| 2. Core Tracking UI | v1.0 | 2/2 | Complete | 2026-06-04 |
| 3. Settings | v1.0 | 1/1 | Complete | 2026-06-05 |
| 4. Calendar & Streaks | v1.0 | 1/1 | Complete | 2026-06-05 |
| 5. Notifications | v1.0 | 1/1 | Complete | 2026-06-05 |
| 6. Bug Fix + Theme + L-Display | v1.1 | 2/2 | Complete | 2026-06-08 |
| 7. Intake Redesign | v1.1 | 1/1 | Complete | 2026-06-08 |
| 8. App Icon | v1.1 | 1/1 | Complete | 2026-06-08 |
| 9. Data Foundation & Bug Fixes | v1.2 | 2/2 | Complete    | 2026-06-10 |
| 10. Target History Integration | v1.2 | 1/3 | In Progress|  |
| 11. Hydration Calculator | v1.2 | 0/? | Not started | - |
