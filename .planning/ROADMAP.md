# Roadmap: Drinky Drinky

## Milestones

- v1.0 MVP -- Phases 1-5 (shipped 2026-06-08)
- v1.1 Polish & UX -- Phases 6-8 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-5) -- SHIPPED 2026-06-08</summary>

- [x] Phase 1: Data Foundation (2/2 plans) -- completed 2026-06-03
- [x] Phase 2: Core Tracking UI (2/2 plans) -- completed 2026-06-04
- [x] Phase 3: Settings (1/1 plans) -- completed 2026-06-05
- [x] Phase 4: Calendar & Streaks (1/1 plans) -- completed 2026-06-05
- [x] Phase 5: Notifications (1/1 plans) -- completed 2026-06-05

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### v1.1 Polish & UX (In Progress)

**Milestone Goal:** Refine the interaction model, fix known bugs, adopt Material You theming with dark mode, and give the app a proper icon.

- [x] **Phase 6: Bug Fix + Theme + L-Display** -- Fix SnackBar persistence bug, show liters with locale formatting, and adopt Material You dynamic color with dark mode support (completed 2026-06-08)
- [ ] **Phase 7: Intake Redesign** -- Replace home-screen quick-add buttons with a FAB-triggered modal bottom sheet featuring 3 presets and custom ml input
- [ ] **Phase 8: App Icon** -- Generate a water glass motif launcher icon for all iOS and Android sizes

## Phase Details

### Phase 6: Bug Fix + Theme + L-Display

**Goal**: The app displays progress in liters, auto-dismisses SnackBars correctly, uses the device's Material You palette on supported Android devices, falls back to a static blue seed on older Android and iOS, and adapts to system dark mode
**Depends on**: Phase 5 (v1.0 complete)
**Requirements**: HOME-01, HOME-02, THEME-01, THEME-02, THEME-03
**Success Criteria** (what must be TRUE):

  1. Home screen shows current intake and goal in liters with 2 decimal places using locale-appropriate decimal separator (e.g. "1,75 L / 2,00 L" on Italian locale)
  2. SnackBar with undo action auto-dismisses after 5 seconds without user intervention
  3. On Android 12+ device, app colors derive from the device wallpaper; on Android <12 and iOS, app uses a static blue seed palette
  4. When the device is set to dark mode, all screens render with a dark color scheme and semantic colors (goal-met green, goal-missed red, partial orange) remain legible on dark surfaces

**Plans**: 2 plans
Plans:

- [x] 06-01-PLAN.md -- Add dynamic_color and intl dependencies; integrate DynamicColorBuilder with dual theme in main.dart
- [x] 06-02-PLAN.md -- SnackBar persist fix, locale-aware L-display, brightness-adaptive semantic colors across home and history screens

**UI hint**: yes

### Phase 7: Intake Redesign

**Goal**: Users add water intake through a single FAB that opens a modal bottom sheet with 3 configurable presets and a custom ml input, replacing the previous inline quick-add buttons
**Depends on**: Phase 6
**Requirements**: INTAKE-01, INTAKE-02, INTAKE-03, INTAKE-04
**Success Criteria** (what must be TRUE):

  1. Home screen no longer shows inline quick-add buttons; a FAB is the sole entry point for adding intake
  2. Tapping the FAB opens a modal bottom sheet displaying 3 configurable preset buttons that log intake and close the sheet
  3. The bottom sheet includes a text field with numeric keyboard where the user can type a custom ml amount, submit it, and have the entry logged and the sheet closed
  4. Settings screen shows exactly 3 preset slots for editing (the former 4th slot is retired)

**Plans**: TBD
**UI hint**: yes

### Phase 8: App Icon

**Goal**: The app has a recognizable water glass launcher icon on all iOS and Android device sizes
**Depends on**: Nothing (independent of Phases 6-7; sequenced last because it requires a design asset)
**Requirements**: ICON-01
**Success Criteria** (what must be TRUE):

  1. App appears on the home screen / app drawer with a water glass motif icon at the correct resolution for the device
  2. iOS icon has an opaque background with no alpha transparency (App Store requirement)

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 6 -> 7 -> 8

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Data Foundation | v1.0 | 2/2 | Complete | 2026-06-03 |
| 2. Core Tracking UI | v1.0 | 2/2 | Complete | 2026-06-04 |
| 3. Settings | v1.0 | 1/1 | Complete | 2026-06-05 |
| 4. Calendar & Streaks | v1.0 | 1/1 | Complete | 2026-06-05 |
| 5. Notifications | v1.0 | 1/1 | Complete | 2026-06-05 |
| 6. Bug Fix + Theme + L-Display | v1.1 | 2/2 | Complete    | 2026-06-08 |
| 7. Intake Redesign | v1.1 | 0/0 | Not started | - |
| 8. App Icon | v1.1 | 0/0 | Not started | - |
