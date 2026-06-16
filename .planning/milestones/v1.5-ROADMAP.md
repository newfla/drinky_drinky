# Roadmap: Drinky Drinky

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-06-08)
- ✅ **v1.1 Polish & UX** — Phases 6-8 (shipped 2026-06-08)
- ✅ **v1.2 Bug Fixes & Feature Depth** — Phases 9-11 (shipped 2026-06-15)
- ✅ **v1.3 Multilingual Support** — Phases 12-14 (shipped 2026-06-15)
- ✅ **v1.4 Polish & Bug Fixes** — Phases 15-16 (shipped 2026-06-15)
- ✅ **v1.5 Charts** — Phases 17-18 (shipped 2026-06-16)

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

<details>
<summary>✅ v1.2 Bug Fixes & Feature Depth (Phases 9-11) — SHIPPED 2026-06-15</summary>

- [x] Phase 9: Data Foundation & Bug Fixes (2/2 plans) — completed 2026-06-10
- [x] Phase 10: Target History Integration (3/3 plans) — completed 2026-06-10
- [x] Phase 11: Hydration Calculator (1/1 plans) — completed 2026-06-15

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Multilingual Support (Phases 12-14) — SHIPPED 2026-06-15</summary>

- [x] Phase 12: L10n Infrastructure (2/2 plans) — completed 2026-06-15
- [x] Phase 13: String Extraction & Translation (2/2 plans) — completed 2026-06-15
- [x] Phase 14: Notification Localization & Platform Config (2/2 plans) — completed 2026-06-15

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

<details>
<summary>✅ v1.4 Polish & Bug Fixes (Phases 15-16) — SHIPPED 2026-06-15</summary>

- [x] Phase 15: Home & History Fixes (1/1 plans) — completed 2026-06-15
- [x] Phase 16: Project README (1/1 plans) — completed 2026-06-15

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

### v1.5 Charts — SHIPPED 2026-06-16

**Milestone Goal:** Add data visualization to the History screen with monthly and daily bar charts.

- [x] **Phase 17: Monthly Bar Chart** - fl_chart dependency and monthly bar chart widget embedded in HistoryScreen (completed 2026-06-16)
- [x] **Phase 18: Day Detail Screen** - Day detail screen with per-entry chart, GoRouter wiring, and L10N strings (completed 2026-06-16)

## Phase Details

### Phase 17: Monthly Bar Chart

**Goal**: Users can see their daily hydration totals for any month as a bar chart directly below the calendar
**Depends on**: Phase 16 (v1.4 complete)
**Requirements**: CHART-01, CHART-02, CHART-03, CHART-04, CHART-05, CHART-06
**Success Criteria** (what must be TRUE):

  1. User sees a bar chart below the calendar on the History screen showing one bar per day with ml totals for the displayed month
  2. When viewing the current month, bars appear only for today and past days — no bars for future days
  3. A dashed horizontal line marks the current daily target on the chart
  4. Tapping a bar shows a tooltip with the exact ml value for that day
  5. When the user switches months in the calendar, the chart updates to show data for the newly selected month; months with no data show an empty-state message instead of the chart

**Plans**: 1 plan

Plans:

- [x] 17-01-PLAN.md — Add fl_chart dependency, create MonthlyBarChart widget, embed in HistoryScreen

**UI hint**: yes

### Phase 18: Day Detail Screen

**Goal**: Users can drill into any day to see individual intake entries visualized as a bar chart on a dedicated screen
**Depends on**: Phase 17
**Requirements**: CHART-07, CHART-08, CHART-09, CHART-10, CHART-11
**Success Criteria** (what must be TRUE):

  1. Tapping a day on the calendar or a bar on the monthly chart navigates to a separate day detail screen (push navigation)
  2. The day detail screen shows a bar chart with one bar per intake entry (x-axis = time, y-axis = ml) and the total ml for the day
  3. Days with no entries show an empty-state message instead of the chart
  4. All new strings introduced by charts (empty states, tooltips, labels, titles, totals) are localized in all 4 app languages (en/it/fr/es)

**Plans**: 2 plans

Plans:

- [x] 18-01-PLAN.md — Create DayDetailScreen widget with per-entry bar chart, total display, empty state, and L10N strings
- [x] 18-02-PLAN.md — Wire GoRouter route and rewire HistoryScreen calendar navigation

**UI hint**: yes

## Progress

**Execution Order:** Phases execute in numeric order: 17 -> 18

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
| 9. Data Foundation & Bug Fixes | v1.2 | 2/2 | Complete | 2026-06-10 |
| 10. Target History Integration | v1.2 | 3/3 | Complete | 2026-06-10 |
| 11. Hydration Calculator | v1.2 | 1/1 | Complete | 2026-06-15 |
| 12. L10n Infrastructure | v1.3 | 2/2 | Complete | 2026-06-15 |
| 13. String Extraction & Translation | v1.3 | 2/2 | Complete | 2026-06-15 |
| 14. Notification Localization & Platform Config | v1.3 | 2/2 | Complete | 2026-06-15 |
| 15. Home & History Fixes | v1.4 | 1/1 | Complete | 2026-06-15 |
| 16. Project README | v1.4 | 1/1 | Complete | 2026-06-15 |
| 17. Monthly Bar Chart | v1.5 | 1/1 | Complete    | 2026-06-16 |
| 18. Day Detail Screen | v1.5 | 2/2 | Complete   | 2026-06-16 |
