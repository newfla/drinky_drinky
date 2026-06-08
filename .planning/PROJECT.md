# Drinky Drinky

## What This Is

A Flutter mobile app that helps users track their daily water intake and stay hydrated. Users set a daily water goal, log drinks via a FAB-triggered bottom sheet with configurable preset buttons, review their history on a monthly calendar, and receive configurable reminder notifications. Runs on iOS and Android. Fully offline — no backend, no user accounts.

## Core Value

The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## Shipped

- ✅ **v1.0 MVP** — Phases 1-5 (2026-06-08)
- ✅ **v1.1 Polish & UX** — Phases 6-8 (2026-06-08)

## Requirements

### Validated

- ✓ Home screen shows daily progress with an animated circular progress bar — v1.0
- ✓ User can log water intake via preset quick-add buttons (customizable amounts) — v1.0
- ✓ User can undo the last water entry — v1.0
- ✓ User can see a chronological timeline of today's individual intakes — v1.0
- ✓ User can set a global daily water target in ml — v1.0
- ✓ User can configure the notification reminder interval — v1.0
- ✓ User can define a DND window to suppress notifications — v1.0
- ✓ Calendar view shows past days color-coded green (goal met) or red (goal missed) — v1.0
- ✓ User can see consecutive-day streak count — v1.0
- ✓ App sends reminder notifications at a configurable interval, respecting DND — v1.0
- ✓ App shows a first-launch permission explanation screen before the system prompt — v1.0
- ✓ Notifications stop automatically when the daily goal is reached — v1.0
- ✓ Home screen displays goal and current intake in liters with 2 decimal places, locale-aware (HOME-01) — v1.1
- ✓ SnackBar undo notification auto-dismisses after the 5-second timer (HOME-02) — v1.1
- ✓ App uses Material You dynamic color on Android 12+; static seed palette on Android <12; iOS unaffected (THEME-01/02/03) — v1.1
- ✓ Home screen FAB opens add-intake modal bottom sheet; quick-add buttons removed from home (INTAKE-01) — v1.1
- ✓ Add-intake sheet shows 3 configurable presets and a custom ml text field with 1-9999 validation (INTAKE-02/03/04) — v1.1
- ✓ App icon uses a water glass motif across all iOS/Android sizes with opaque iOS background (ICON-01) — v1.1

### Active

*(No active requirements — next milestone not yet defined. Run `/gsd-new-milestone` to start v1.2.)*

### Out of Scope

- Variable per-day targets — single global target for simplicity
- Detailed log editing (delete arbitrary past entries) — undo last is sufficient for v1
- Social / sharing features — focus on personal tracking
- Apple Health / Google Fit integration — defer to v2
- fl oz unit support — ml/L for v1; European market focus
- Backend / cloud sync — fully offline for v1
- Smart/adaptive reminder timing — requires usage pattern learning; v2
- Full locale formatting for settings values — defer to v1.2
- fl_chart trend charts — not needed for current scope

## Context

**Current state (v1.1):**
- Stack: Flutter 3.44.1, Riverpod 3.x (code-gen), Drift 2.33.0 (SQLite), flutter_local_notifications 21.0.0
- Target platforms: iOS and Android
- Fully offline — no backend, no user accounts, no sync
- ~134 files changed across v1.1 (38 icon asset files, 4 Dart source files, planning artifacts)
- 12 DAO/unit tests passing; flutter analyze clean

**Known issues / tech debt:**
- `deleteLastEntry` in WaterEntryDao has no date filter (cross-day undo risk) — fix in v1.2
- `_todayDateKey()` captured once at provider construction — wrong after midnight without app resume — fix in v1.2
- `dateKey` validation is regex-only (allows semantically invalid dates) — low risk, fix in v1.2
- Android OEM background killing (Samsung/Xiaomi) may silently suppress notifications — requires physical device testing
- Timeline sort order is oldest-first (ASC) in code; UI-SPEC specified newest-first — accepted as-is
- Material You dynamic color on Android 12+ (THEME-01) verified by code; device wallpaper color extraction skipped in UAT (iOS/Android <12 device used)

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
| DynamicColorBuilder with null-coalesce fallback (v1.1) | lightDynamic ?? seed keeps platform adaptation transparent to all screens without per-screen changes | ✓ Good — zero screen-level changes needed for theme propagation |
| intl.NumberFormat.decimalPatternDigits for L-display (v1.1) | Locale-correct decimal separator without manual regex; already in dependency graph | ✓ Good — handles Italian/German commas automatically |
| persist: false to fix SnackBar auto-dismiss (v1.1) | Minimal one-property fix for indefinite SnackBar persistence introduced by Material 3 defaults | ✓ Good — correct and non-invasive |
| image ^4.8.0 over ^4.9.0 (v1.1) | xml package conflict between image 4.9.x (xml ^7) and flutter_local_notifications 21.x (xml ^6.5) | ✓ Necessary — 4.8.0 provides all needed APIs |
| Pure-Dart tool script for icon generation (v1.1) | Build-time PNG generation avoids dart:ui dependency; can run on CI without Flutter engine | ✓ Good — dart run tool/generate_icon.dart works everywhere |
| Presentation-layer .take(3) over DAO migration for 4→3 presets (v1.1) | Zero migration risk for existing users; DB still holds 4 presets but UI shows 3 | ✓ Good — avoids a migration path for a cosmetic constraint |
| Callback pattern for bottom sheet (v1.1) | Sheet receives presets + onAdd callback; no direct provider access — keeps sheet stateless and testable | ✓ Good — clean separation; Navigator.pop before onAdd ensures sheet closes before SnackBar |

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
*Last updated: 2026-06-08 — v1.1 milestone complete (Polish & UX — theming, SnackBar fix, L-display, intake FAB, app icon).*
