# Requirements: Drinky Drinky

**Defined:** 2026-06-03
**Core Value:** The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## v1 Requirements

Requirements for initial release. Each maps to a roadmap phase.

### Home Screen

- [x] **HOME-01**: User can see their daily water intake progress via an animated circular progress bar showing current intake vs daily target
- [x] **HOME-02**: User can log water intake with a single tap via quick-add preset buttons showing the amount in ml
- [x] **HOME-03**: User can undo the last water entry from the home screen
- [x] **HOME-04**: User can see a chronological timeline of today's individual intakes with timestamp and amount below the progress bar

### Settings

- [x] **SETT-01**: User can set a global daily water target in ml (displayed also as L)
- [x] **SETT-02**: User can customize the amount for each quick-add preset button
- [x] **SETT-03**: User can configure the notification reminder interval (in minutes or hours)
- [x] **SETT-04**: User can define a DND window with start time and end time during which no notifications are sent

### History

- [x] **HIST-01**: User can view a monthly calendar where each past day is colored green (daily goal met) or red (daily goal not met)
- [x] **HIST-02**: User can see their current streak of consecutive days with the daily goal reached

### Notifications

- [x] **NOTF-01**: App sends reminder notifications at the user-configured interval, excluding the DND window and after the daily goal is reached
- [x] **NOTF-02**: App shows a dedicated permission request screen (pre-permission) explaining why notifications are needed before triggering the system prompt
- [x] **NOTF-03**: Notifications automatically stop for the remainder of the day once the daily goal is reached

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Integrations

- **INTG-01**: Sync with Apple Health / Google Fit
- **INTG-02**: Home screen widget (iOS WidgetKit / Android AppWidgetProvider)

### Personalization

- **PERS-01**: Unit preference toggle (ml/L vs fl oz) for international users
- **PERS-02**: Weather-based dynamic goal adjustment
- **PERS-03**: Multiple drink types (water, tea, coffee with hydration coefficient)

### Gamification

- **GAME-01**: Goal completion celebration animation (haptic + visual)
- **GAME-02**: Achievement badges for streaks and milestones

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Variable per-day targets | Adds data model complexity; single global target is sufficient for v1 |
| Manual custom input field per drink | Presets cover the common case; keeps home screen fast |
| Full log editing (delete arbitrary entries) | Undo-last covers the most common error; full CRUD deferred |
| Social / sharing features | Focus on personal tracking; social adds backend complexity |
| Multiple user profiles | Single-user offline app for v1 |
| fl oz unit support | Only ml/L for v1; European market focus |
| Backend / cloud sync | Fully offline for v1; no server costs or auth complexity |
| Smart/adaptive reminder timing | Requires usage pattern learning; deferred to v2 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| HOME-01 | Phase 2 | Complete |
| HOME-02 | Phase 2 | Complete |
| HOME-03 | Phase 2 | Complete |
| HOME-04 | Phase 2 | Complete |
| SETT-01 | Phase 3 | Complete |
| SETT-02 | Phase 3 | Complete |
| SETT-03 | Phase 3 | Complete |
| SETT-04 | Phase 3 | Complete |
| HIST-01 | Phase 4 | Complete |
| HIST-02 | Phase 4 | Complete |
| NOTF-01 | Phase 5 | Complete |
| NOTF-02 | Phase 5 | Complete |
| NOTF-03 | Phase 5 | Complete |

**Coverage:**

- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-03*
*Last updated: 2026-06-03 after initial definition*
