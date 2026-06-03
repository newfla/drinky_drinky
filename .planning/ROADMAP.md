# Roadmap: Drinky Drinky

## Overview

Drinky Drinky delivers a focused hydration tracker in five phases. We start with the data foundation (schema decisions that are irreversible), then build the core tracking loop (the thing that makes the app useful), followed by settings customization, calendar/streak history, and finally notifications (the most platform-complex feature, built last so the core app works without it).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Data Foundation** - Drift schema, DAOs, repositories, and Riverpod providers that all features depend on
- [ ] **Phase 2: Core Tracking UI** - Home screen with progress ring, quick-add presets, undo, and today's timeline
- [ ] **Phase 3: Settings** - Daily target, preset customization, notification interval, and DND window configuration
- [ ] **Phase 4: Calendar & Streaks** - Monthly history calendar with green/red days and consecutive streak counter
- [ ] **Phase 5: Notifications** - Scheduled reminders with DND awareness, permission flow, and auto-stop on goal

## Phase Details

### Phase 1: Data Foundation
**Goal**: The persistence layer is complete, tested, and exposes reactive streams so all subsequent phases can read and write data without touching SQLite directly
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: None (technical prerequisite -- all 13 v1 requirements depend on this infrastructure but none map directly to it)
**Success Criteria** (what must be TRUE):
  1. Drift database initializes successfully on both iOS and Android with correct DateTime-as-text storage mode
  2. DAOs can create, read, and query water entries, user settings, and drink presets with type-safe APIs
  3. Repositories expose reactive streams that emit updates when underlying data changes
  4. Riverpod providers are wired to repositories so widgets can watch data without direct DB access
  5. Unit tests pass against an in-memory database covering all DAO operations
**Plans**: TBD

### Phase 2: Core Tracking UI
**Goal**: Users can open the app, log water with a single tap, see their progress update instantly, undo mistakes, and review today's intake history
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: HOME-01, HOME-02, HOME-03, HOME-04
**Success Criteria** (what must be TRUE):
  1. User sees an animated circular progress bar on the home screen showing current intake vs daily target
  2. User can tap a quick-add preset button and see the progress bar update within one second
  3. User can undo the last water entry and see the progress bar revert accordingly
  4. User can see a chronological timeline of today's individual intakes with timestamp and amount below the progress bar
**Plans**: TBD
**UI hint**: yes

### Phase 3: Settings
**Goal**: Users can customize their daily target, quick-add preset amounts, notification interval, and DND quiet hours
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: SETT-01, SETT-02, SETT-03, SETT-04
**Success Criteria** (what must be TRUE):
  1. User can set a daily water target in ml (displayed also as L) and see it reflected on the home screen progress bar
  2. User can customize the amount for each quick-add preset button and see updated labels on the home screen
  3. User can configure the notification reminder interval in minutes or hours
  4. User can define a DND window with start and end times during which no notifications will be sent
**Plans**: TBD
**UI hint**: yes

### Phase 4: Calendar & Streaks
**Goal**: Users can review their hydration history on a monthly calendar and see how many consecutive days they have met their goal
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: HIST-01, HIST-02
**Success Criteria** (what must be TRUE):
  1. User can view a monthly calendar where each past day is colored green (goal met) or red (goal missed)
  2. User can navigate between months to review historical hydration data
  3. User can see their current streak of consecutive days with the daily goal reached
**Plans**: TBD
**UI hint**: yes

### Phase 5: Notifications
**Goal**: Users receive timely hydration reminders that respect their quiet hours and stop automatically when the daily goal is reached
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: NOTF-01, NOTF-02, NOTF-03
**Success Criteria** (what must be TRUE):
  1. App sends reminder notifications at the user-configured interval during allowed hours
  2. No notifications are sent during the user-defined DND window
  3. App presents a dedicated permission request screen explaining why notifications are needed before triggering the system prompt
  4. Notifications automatically stop for the remainder of the day once the daily goal is reached
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Foundation | 0/0 | Not started | - |
| 2. Core Tracking UI | 0/0 | Not started | - |
| 3. Settings | 0/0 | Not started | - |
| 4. Calendar & Streaks | 0/0 | Not started | - |
| 5. Notifications | 0/0 | Not started | - |
