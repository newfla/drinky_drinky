# Drinky Drinky

## What This Is

A Flutter mobile app that helps users track their daily water intake and stay hydrated. Users set a daily water goal, log drinks via customizable quick-add buttons, and receive configurable reminder notifications. Runs on iOS and Android.

## Core Value

The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can set a global daily water target in liters
- [ ] Home screen shows daily progress with a circular progress bar
- [ ] User can log water intake via preset quick-add buttons (customizable amounts)
- [ ] User can undo the last water entry
- [ ] Calendar view shows past days color-coded green (goal met) or red (goal missed)
- [ ] App sends reminder notifications at a configurable interval
- [ ] User can define a DND window (start/end time) to suppress notifications
- [ ] Quick-add button amounts are user-configurable

### Out of Scope

- Variable per-day targets — single global target for simplicity
- Manual custom input field per drink — presets cover this
- Detailed log editing (delete arbitrary past entries) — undo last is sufficient for v1
- Social / sharing features — focus on personal tracking
- Apple Health / Google Fit integration — defer to v2

## Context

- Stack: Flutter, Riverpod (state management), Drift (local SQLite), flutter_local_notifications
- Target platforms: iOS and Android
- Fully offline app — no backend, no user accounts
- Data stored locally via Drift; no sync needed for v1

## Constraints

- **Tech stack**: Flutter + Riverpod + Drift — no deviation from chosen stack
- **Platform**: iOS and Android only (no web/desktop for v1)
- **Offline-first**: No backend or cloud sync in v1

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Drift over Hive/SharedPreferences | Structured queries needed for daily aggregates and calendar view | — Pending |
| Riverpod over BLoC | Lighter boilerplate, good fit for a focused utility app | — Pending |
| Single global daily target | Simplifies the data model and UX; per-day targets deferred | — Pending |
| Undo last (not full log) | Keeps home screen simple; covers the most common error case | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-03 — Phase 1 (Data Foundation) complete. Drift schema, DAOs, repositories, Riverpod providers, GoRouter wired. 11 DAO unit tests passing. App launches on device. Moving to Phase 2: Core Tracking UI.*
