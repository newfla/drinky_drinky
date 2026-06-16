# Drinky Drinky

## What This Is

A Flutter mobile app that helps users track their daily water intake and stay hydrated. Users set a daily water goal, log drinks via a FAB-triggered bottom sheet with configurable preset buttons, review their history on a monthly calendar, and receive configurable reminder notifications. Runs on iOS and Android. Fully offline — no backend, no user accounts.

## Core Value

The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## Current Milestone: v1.5 Charts

**Goal:** Aggiungere visualizzazione dati nella History screen con grafici a barre mensili e giornalieri.

**Target features:**
- Grafico a barre mensile sotto il calendario (asse x = giorni del mese, asse y = ml totali giornalieri)
- Schermata di dettaglio giornaliero (push separato) con grafico delle singole aggiunte (asse x = orario, asse y = ml)

## Shipped

- ✅ **v1.0 MVP** — Phases 1-5 (2026-06-08)
- ✅ **v1.1 Polish & UX** — Phases 6-8 (2026-06-08)
- ✅ **v1.2 Bug Fixes & Feature Depth** — Phases 9-11 (2026-06-15)
- ✅ **v1.3 Multilingual Support** — Phases 12-14 (2026-06-15)
- ✅ **v1.4 Polish & Bug Fixes** — Phases 15-16 (2026-06-15)

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
- ✓ **BUG-01**: `deleteLastEntry` adds today's date filter — Phase 9 (v1.2)
- ✓ **BUG-02**: `_todayDateKey()` updates at midnight via keepAlive Notifier — Phase 10 (v1.2)
- ✓ **BUG-03**: `dateKey` validated for format AND semantic correctness — Phase 9 (v1.2)
- ✓ **TARGET-01/02/03/04**: Target history in Drift, per-day targets on home/calendar, "Applica da oggi/domani" setting — Phase 9–10 (v1.2)
- ✓ **CALC-01/02/03/04**: Hydration calculator (sex/weight/climate), first-launch onboarding, Settings entry, "Usa come target" — Phase 11 (v1.2)
- ✓ **L10N-01/02/03**: Gen-l10n pipeline (flutter_localizations, l10n.yaml, synthetic-package: false), MaterialApp locale wiring, initializeDateFormatting — Phase 12 (v1.3)
- ✓ **L10N-04/05/06**: BiologicalSex/ClimateLevel enum refactor, 79-key ARB extraction, Italian/French/Spanish translations with ICU plurals — Phase 13 (v1.3)
- ✓ **L10N-07/08/09**: Localized notifications via PlatformDispatcher + lookupAppLocalizations, iOS CFBundleLocalizations, Android resourceConfigurations — Phase 14 (v1.3)
- ✓ **POLISH-01**: Home empty-state placeholder text centered with 32px horizontal padding — Phase 15 (v1.4)
- ✓ **BUG-04**: History screen reactively updates when first water entry is logged on fresh install — Phase 15 (v1.4)
- ✓ **DOC-01**: README.md with project description, screenshot references (iOS + Android), 12-item feature list, and build instructions — Phase 16 (v1.4)

### Out of Scope

- Variable per-day targets — storico target implementato in v1.2; target diverso per ogni singolo giorno rimane fuori scope
- Detailed log editing (delete arbitrary past entries) — undo last is sufficient for v1
- Social / sharing features — focus on personal tracking
- Apple Health / Google Fit integration — defer to v2
- fl oz unit support — ml/L for v1; European market focus
- Backend / cloud sync — fully offline for v1
- Smart/adaptive reminder timing — requires usage pattern learning; v2
- Full locale formatting for settings values — defer to v1.3
- fl_chart trend charts — not needed for current scope

## Context

**Current state (v1.4 complete — 16 phases shipped):**
- Stack: Flutter 3.44.1, Riverpod 3.x (code-gen), Drift 2.33.0 (SQLite), flutter_local_notifications 21.0.0, flutter_localizations (SDK), intl 0.20.2
- Target platforms: iOS 16.0+ and Android (minSdk 26 / compileSdk 36)
- Fully offline — no backend, no user accounts, no sync
- All v1.4 requirements shipped: home placeholder polish, history screen reactivity fix, project README
- UAT passed for all phases; DOC-01 verified; iOS screenshot present, Android screenshot pending developer addition

**Known issues / tech debt:**
- Android OEM background killing (Samsung/Xiaomi) may silently suppress notifications — requires physical device testing; **deferred**
- Timeline sort order is oldest-first (ASC) in code; UI-SPEC specified newest-first — accepted as-is
- Material You dynamic color on Android 12+ (THEME-01) verified by code; device wallpaper color extraction skipped in UAT
- ARB translations (it/fr/es) are machine-generated — native speaker review recommended before wide distribution (L10N-FUTURE-01)
- `minSdk = 26` in build.gradle.kts vs CLAUDE.md documented minimum of 24 — pre-existing from Phase 1 scaffold, no functional impact

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
| `isOnboarding` constructor parameter over `GoRouter.canPop()` (v1.2 Phase 11) | `canPop()` returns false after GoRouter redirect-initiated navigation, making onboarding vs Settings context detection unreliable | ✓ Good — deterministic; passed via `state.extra` (null defaults to `true` for redirects, Settings push explicit `extra: false`) |
| Privacy-by-design for calculator inputs (v1.2 Phase 11) | Sex/weight/climate held only in ephemeral widget state; never written to SharedPreferences or Drift | ✓ Good — CALC-04 satisfied without any special deletion logic; widget disposal is sufficient |
| Callback pattern for bottom sheet (v1.1) | Sheet receives presets + onAdd callback; no direct provider access — keeps sheet stateless and testable | ✓ Good — clean separation; Navigator.pop before onAdd ensures sheet closes before SnackBar |
| `synthetic-package: false` for gen-l10n (v1.3) | Flutter 3.44.1 analyzer conflict between drift_dev and riverpod_generator namespace; true would inject into app package and break the code-gen chain | ✓ Good — resolved analyzer conflicts; output-dir: lib/l10n/generated/ cleanly separates generated code |
| BiologicalSex/ClimateLevel enums over Italian string keys (v1.3) | Calculator used Italian display strings as map keys; switching locale crashed with null deref. Enums are locale-agnostic by definition | ✓ Good — prerequisite for crash-free locale switching; pattern: computation on enums, display on translated strings |
| Primary-only locale resolution (v1.3) | `locales.first` with English fallback — consistent across UI (localeListResolutionCallback in main.dart) and NotificationService (_resolveLocale). Simpler than basicLocaleListResolution and avoids sub-locale edge cases | ✓ Good — consistent behavior confirmed in Phase 13 UAT; notification locale matches UI locale |
| PlatformDispatcher + lookupAppLocalizations for NotificationService (v1.3) | Service runs without BuildContext (it's a singleton). PlatformDispatcher.instance.locales is the only locale source available outside widget tree | ✓ Good — dart:ui import, no widget dependency; try/catch English fallback covers edge cases |
| Stream provider over initState Future for HistoryScreen (v1.4) | StatefulShellRoute.indexedStack keeps screens alive; initState runs only once per session, so a one-time Future never re-evaluates after the first entry is logged. Stream provider (Drift watchSingle + @riverpod) eliminates the stale-state class of bug | ✓ Good — history screen now reactive; removed 3 local state vars and the entire initState override |

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
*Last updated: 2026-06-16 — Milestone v1.5 Charts started. Monthly and daily bar charts scoped.*
