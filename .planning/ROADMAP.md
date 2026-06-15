# Roadmap: Drinky Drinky

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-06-08)
- ✅ **v1.1 Polish & UX** — Phases 6-8 (shipped 2026-06-08)
- ✅ **v1.2 Bug Fixes & Feature Depth** — Phases 9-11 (shipped 2026-06-15)
- **v1.3 Multilingual Support** — Phases 12-14

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

### v1.3 Multilingual Support

**Milestone Goal:** App follows system language — Italian, English, French, and Spanish; English as fallback for unsupported locales.

- [ ] **Phase 12: L10n Infrastructure** - Gen-l10n pipeline, MaterialApp locale wiring, date formatting initialization
- [x] **Phase 13: String Extraction & Translation** - Calculator enum refactor, all UI strings to ARB, 4-language translation files (completed 2026-06-15)
- [x] **Phase 14: Notification Localization & Platform Config** - NotificationService locale-aware strings, iOS/Android platform declarations (completed 2026-06-15)

## Phase Details

### Phase 12: L10n Infrastructure

**Goal**: App has a working localization pipeline that resolves the device locale and provides translated Material widgets
**Depends on**: Phase 11 (v1.2 complete)
**Requirements**: L10N-01, L10N-02, L10N-03
**Success Criteria** (what must be TRUE):

  1. `flutter gen-l10n` runs without errors and generates `AppLocalizations` class with `of(context)` accessor
  2. App launched on a device set to Italian/French/Spanish shows localized Material widget text (date picker buttons, dialog actions)
  3. App launched on an unsupported locale (e.g., German) falls back to English strings
  4. `table_calendar` displays month and day names in the device's language

**Plans**: 2 plans
Plans:

- [x] 12-01-PLAN.md — L10n pipeline setup (pubspec, l10n.yaml, MaterialApp wiring, initializeDateFormatting, TableCalendar locale, context extension)
- [x] 12-02-PLAN.md — Complete app_en.arb (79 English strings) + flutter gen-l10n generation

### Phase 13: String Extraction & Translation

**Goal**: Every user-visible string in the app displays in the device's language (it/en/fr/es)
**Depends on**: Phase 12
**Requirements**: L10N-04, L10N-05, L10N-06
**Success Criteria** (what must be TRUE):

  1. Calculator screen displays sex/climate labels in the device's language without crashing (enum-based computation, not string-keyed)
  2. All 6 screens (home, settings, history/calendar, calculator, permission screen, add-intake sheet) show fully translated text with no hardcoded Italian or English remnants
  3. Plural forms render correctly in all 4 languages (e.g., French "0 jour" singular, streak counters)
  4. `app_en.arb` serves as the canonical template with semantic keys and `@key` metadata for all extractable strings

**Plans**: 2 plans
Plans:

- [x] 13-01-PLAN.md — BiologicalSex/ClimateLevel enum refactor + widget string replacement with context.l10n across all screens
- [x] 13-02-PLAN.md — Complete app_it.arb, app_fr.arb, app_es.arb (79 keys each) + flutter gen-l10n regeneration

### Phase 14: Notification Localization & Platform Config

**Goal**: Notification reminders arrive in the user's language and both iOS and Android correctly detect the app's supported locales
**Depends on**: Phase 12
**Requirements**: L10N-07, L10N-08, L10N-09
**Success Criteria** (what must be TRUE):

  1. Hydration reminder notification title and body text appear in the device's language (it/en/fr/es)
  2. On iOS, switching device language to Italian/French/Spanish causes the app to follow the new locale (CFBundleLocalizations declared)
  3. Android APK bundles only en/it/fr/es locale resources (resConfigs filtering active)

**Plans**: 2 plans
Plans:

- [x] 14-01-PLAN.md — L10n pipeline setup (pubspec, l10n.yaml, MaterialApp wiring, initializeDateFormatting, TableCalendar locale, context extension)
- [x] 14-02-PLAN.md — Complete app_en.arb (~73 English strings) + flutter gen-l10n generation

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
| 10. Target History Integration | v1.2 | 3/3 | Complete   | 2026-06-10 |
| 11. Hydration Calculator | v1.2 | 1/1 | Complete    | 2026-06-15 |
| 12. L10n Infrastructure | v1.3 | 2/2 | Complete   | 2026-06-15 |
| 13. String Extraction & Translation | v1.3 | 2/2 | Complete    | 2026-06-15 |
| 14. Notification Localization & Platform Config | v1.3 | 2/2 | Complete   | 2026-06-15 |
