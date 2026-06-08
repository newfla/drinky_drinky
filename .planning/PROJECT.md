# Drinky Drinky

## What This Is

A Flutter mobile app that helps users track their daily water intake and stay hydrated. Users set a daily water goal, log drinks via customizable quick-add buttons, review their history on a monthly calendar, and receive configurable reminder notifications. Runs on iOS and Android. Fully offline — no backend, no user accounts.

## Core Value

The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

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

### Active

- [ ] Daily target displayed in liters as well as ml (SETT-01 L-display, deferred from Phase 3 per D-15)

### Out of Scope

- Variable per-day targets — single global target for simplicity
- Manual custom input field per drink — presets cover this
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

---
*Last updated: 2026-06-08 after v1.0 MVP milestone — all 13 v1 requirements delivered across 5 phases in 5 days.*
