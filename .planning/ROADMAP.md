# Roadmap: Drinky Drinky

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-06-08)
- ✅ **v1.1 Polish & UX** — Phases 6-8 (shipped 2026-06-08)
- ✅ **v1.2 Bug Fixes & Feature Depth** — Phases 9-11 (shipped 2026-06-15)
- ✅ **v1.3 Multilingual Support** — Phases 12-14 (shipped 2026-06-15)
- 🚧 **v1.4 Polish & Bug Fixes** — Phases 15-16 (in progress)

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

### v1.4 Polish & Bug Fixes (In Progress)

**Milestone Goal:** Fix two visible UI issues from v1.3 and add a public-facing README with screenshots.

- [x] **Phase 15: Home & History Fixes** - Fix placeholder centering on home and stale empty-state on history screen (completed 2026-06-15)
- [ ] **Phase 16: Project README** - Add README.md with screenshots and build instructions

## Phase Details

### Phase 15: Home & History Fixes

**Goal**: Users see correct UI states on home and history screens from the very first interaction
**Depends on**: Phase 14 (v1.3 complete)
**Requirements**: POLISH-01, BUG-04
**Success Criteria** (what must be TRUE):

  1. When no intakes exist for today, the home screen placeholder text is horizontally centered with consistent lateral and vertical padding matching the rest of the UI
  2. On a fresh install, after logging the first water intake, navigating to the history screen shows today's intake data (not "Nessuna cronologia")
  3. After adding multiple intakes on a fresh install, the history screen timeline updates to reflect all entries without requiring app restart

**Plans**: 1 plan

Plans:

- [x] 15-01-PLAN.md — Fix home empty-state centering + history screen reactivity

**UI hint**: yes

### Phase 16: Project README

**Goal**: A developer or reviewer landing on the repository can understand the project and build it
**Depends on**: Phase 15 (screenshots require fixed UI)
**Requirements**: DOC-01
**Success Criteria** (what must be TRUE):

  1. README.md exists in the repository root and contains a project description, two home screen screenshots (one iOS, one Android), and build instructions
  2. The build instructions are sufficient for a developer with Flutter installed to clone and run the app

**Plans**: 1 plan

Plans:

- [ ] 16-01-PLAN.md — Write project README with description, screenshots, features, and build instructions

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
| 9. Data Foundation & Bug Fixes | v1.2 | 2/2 | Complete | 2026-06-10 |
| 10. Target History Integration | v1.2 | 3/3 | Complete | 2026-06-10 |
| 11. Hydration Calculator | v1.2 | 1/1 | Complete | 2026-06-15 |
| 12. L10n Infrastructure | v1.3 | 2/2 | Complete | 2026-06-15 |
| 13. String Extraction & Translation | v1.3 | 2/2 | Complete | 2026-06-15 |
| 14. Notification Localization & Platform Config | v1.3 | 2/2 | Complete | 2026-06-15 |
| 15. Home & History Fixes | v1.4 | 1/1 | Complete    | 2026-06-15 |
| 16. Project README | v1.4 | 0/1 | Not started | - |
