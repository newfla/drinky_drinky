# Drinky Drinky

## What This Is

A Flutter mobile app that helps users track their daily water intake and stay hydrated. Users set a daily water goal, log drinks via customizable quick-add buttons, review their history on a monthly calendar, and receive configurable reminder notifications. Runs on iOS and Android. Fully offline — no backend, no user accounts.

## Core Value

The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## Current Milestone: v1.1 Polish & UX

**Goal:** Refine the interaction model, fix known bugs, adopt Material You theming on Android, and give the app a proper icon.

**Target features:**
- L-display: home screen progress ring shows liters with 2 decimal places
- SnackBar bug: undo notification does not dismiss — fix auto-clear after 5 s
- Material You: Android 12+ uses dynamic color; iOS retains static palette; Android <12 falls back to static seed
- Add-intake bottom sheet: FAB replaces home-screen quick-add buttons; sheet has 3 configurable presets + custom ml input
- App icon: water glass motif generated via flutter_launcher_icons for all iOS/Android sizes

## Requirements

### Validated

- ✓ Home screen shows daily progress with an animated circular progress bar — v1.0
- ✓ User can log water intake via preset quick-add buttons (customizable amounts) — v1.0
- ✓ User can undo the last water entry — v1.0
- ✓ User can see a chronological timeline of today's individual intakes — v1.0
- ✓ User can set a global daily water target in ml — v1.0 (L display deferred to v1.1)
- ✓ User can customize the amount for each quick-add preset button — v1.0
- ✓ User can configure the notification reminder interval — v1.0
- ✓ User can define a DND window to suppress notifications — v1.0
- ✓ Calendar view shows past days color-coded green (goal met) or red (goal missed) — v1.0
- ✓ User can see consecutive-day streak count — v1.0
- ✓ App sends reminder notifications at a configurable interval, respecting DND — v1.0
- ✓ App shows a first-launch permission explanation screen before the system prompt — v1.0
- ✓ Notifications stop automatically when the daily goal is reached — v1.0

### Validated

- ✓ Home screen displays goal and current intake in liters with 2 decimal places (L-DISP-01) — Validated in Phase 6
- ✓ SnackBar undo notification auto-dismisses after the 5-second timer (BUG-01) — Validated in Phase 6
- ✓ App uses Material You dynamic color on Android 12+; static seed palette on Android <12; iOS unaffected (THEME-01) — Validated in Phase 6

### Active

- ✓ Home screen FAB opens add-intake modal bottom sheet; quick-add buttons removed from home (INTAKE-01) — Validated in Phase 7
- ✓ Add-intake sheet shows 3 configurable presets and a custom ml text field (INTAKE-02) — Validated in Phase 7
- [ ] App icon uses a water glass motif across all iOS/Android sizes (ICON-01) — v1.1

### Out of Scope

- Variable per-day targets — single global target for simplicity
- Manual custom input field per drink — moved to v1.1 scope as part of add-intake sheet (INTAKE-02)
- Detailed log editing (delete arbitrary past entries) — undo last is sufficient for v1
- Social / sharing features — focus on personal tracking
- Apple Health / Google Fit integration — defer to v2
- fl oz unit support — ml/L for v1; European market focus
- Backend / cloud sync — fully offline for v1
- Smart/adaptive reminder timing — requires usage pattern learning; v2

## Context

**Current state (v1.0):**
- Stack: Flutter 3.44.1, Riverpod 3.x (code-gen), Drift 2.33.0 (SQLite), flutter_local_notifications 21.0.0
- Target platforms: iOS and Android
- Fully offline — no backend, no user accounts, no sync
- ~5,576 lines of Dart across 166 files changed
- 11 DAO unit tests passing; flutter analyze clean

**Known issues / tech debt:**
- `deleteLastEntry` in WaterEntryDao has no date filter (cross-day undo risk) — fix in v1.1
- `_todayDateKey()` captured once at provider construction — wrong after midnight without app resume — fix in v1.1
- `dateKey` validation is regex-only (allows semantically invalid dates) — low risk, fix in v1.1
- Android OEM background killing (Samsung/Xiaomi) may silently suppress notifications — requires physical device testing
- Timeline sort order is oldest-first (ASC) in code; UI-SPEC specified newest-first — accepted as-is

## Constraints

- **Tech stack**: Flutter + Riverpod + Drift — no deviation from chosen stack
- **Platform**: iOS and Android only (no web/desktop for v1)
- **Offline-first**: No backend or cloud sync in v1

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Drift over Hive/SharedPreferences | Structured queries needed for daily aggregates and calendar view | ✓ Good — reactive streams integrated cleanly with Riverpod |
| Riverpod over BLoC | Lighter boilerplate, good fit for a focused utility app | ✓ Good — code-gen providers reduced guesswork significantly |
| Single global daily target | Simplifies the data model and UX; per-day targets deferred | ✓ Good — no complexity needed for v1 |
| Undo last (not full log) | Keeps home screen simple; covers the most common error case | ✓ Good — users confirmed via UAT |
| NotificationService as singleton (not Riverpod) | Notifications are imperative side effects, not reactive streams | ✓ Good — avoids Riverpod lifecycle complexity for a fire-and-forget service |
| Plugin-native permission request (not permission_handler) | Official flutter_local_notifications docs recommend resolvePlatformSpecificImplementation | ✓ Good — cleaner API, permission_handler kept for status check and openAppSettings() only |
| Rolling 64-slot scheduling window | iOS hard limit on pending notifications | ✓ Good — 30-day safety valve prevents infinite loop |
| Notifications built last (Phase 5) | Highest pitfall density and platform complexity | ✓ Good — core app worked without notifications during development |
| Flutter 3.44.1 (upgraded from 3.38.1) | analyzer version conflict between drift_dev and riverpod_generator required upgrade | ✓ Necessary — resolved the conflict cleanly |

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
*Last updated: 2026-06-08 — Phase 7 complete (Intake Redesign — FAB + modal bottom sheet).*
