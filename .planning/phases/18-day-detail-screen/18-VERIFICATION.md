---
phase: 18-day-detail-screen
verified: 2026-06-16T00:00:00Z
status: gaps_found
score: 5/6 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Tapping a bar on the monthly chart navigates to DayDetailScreen (push)"
    status: failed
    reason: "ROADMAP SC#1 and REQUIREMENTS CHART-07 require navigation on bar tap in the monthly chart. MonthlyBarChart.barTouchData uses handleBuiltInTouches: true with tooltip only — no touchCallback, no context.push, no go_router import. HistoryScreen only wires push navigation via onDaySelected on the calendar."
    artifacts:
      - path: "lib/presentation/widgets/monthly_bar_chart.dart"
        issue: "barTouchData has no touchCallback that calls context.push('/day/...'); tap only shows tooltip"
    missing:
      - "Add touchCallback to BarTouchData in MonthlyBarChart that calls context.push('/day/$dateKey') when a bar is tapped, matching the same data-guard logic used in HistoryScreen.onDaySelected"
human_verification:
  - test: "Visual verification of day detail navigation and chart"
    expected: |
      1. Tap a day with data on the calendar -> DayDetailScreen opens without bottom NavigationBar
      2. AppBar title is locale-formatted date (e.g. "June 16, 2026" in English)
      3. Bar chart visible with one bar per intake entry; x-axis HH:mm, y-axis in L
      4. Total and target text displayed above chart inside same Card
      5. Tap a bar -> tooltip shows time and ml value
      6. Back button returns to History with calendar state preserved
      7. Tap a day with NO data -> nothing happens (no navigation)
      8. Change language (it/fr/es) -> total text and empty state appear in correct language
    why_human: "Visual layout, NavigationBar presence/absence on push route, tooltip behavior, locale switching, and back-nav state preservation cannot be verified by static code analysis"
---

# Phase 18: Day Detail Screen Verification Report

**Phase Goal:** Users can drill into any day to see individual intake entries visualized as a bar chart on a dedicated screen
**Verified:** 2026-06-16T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | DayDetailScreen displays a bar chart with one bar per intake entry (x-axis = HH:mm time, y-axis = amount in L) | VERIFIED | `day_detail_screen.dart` lines 143-163: `BarChartGroupData` built from entries grouped by `loggedAt.hour * 60 + loggedAt.minute`; bottom titles use `DateFormat('HH:mm')`; left titles show `L` unit |
| 2 | DayDetailScreen shows total ml and target ml as text above the chart inside the same Card | VERIFIED | Lines 180-183: `context.l10n.dayDetailTotal(totalMl, targetMl)` rendered as `Text` above the `SizedBox(height: 220)` chart, all inside one `Card` with `Padding(EdgeInsets.all(16))` |
| 3 | DayDetailScreen shows an empty-state message when there are no entries for the selected day | VERIFIED | Lines 81-104: `if (entries.isEmpty)` branch renders `Card` with `context.l10n.dayDetailNoEntries` text |
| 4 | All new strings (dayDetailTotal, dayDetailNoEntries) are localized in en, it, fr, es | VERIFIED | `app_en.arb` lines 492-508: both keys with @-metadata. `app_it.arb` line 121-122, `app_fr.arb` 121-122, `app_es.arb` 121-122: all present. Generated `app_localizations_en.dart` exposes `dayDetailTotal(num total, num target)` and `get dayDetailNoEntries` |
| 5 | Tapping a day with data on the calendar navigates to DayDetailScreen via push | VERIFIED | `history_screen.dart` line 234: `context.push('/day/$dateKey')` inside `onDaySelected` when `monthTotals[dateKey] != null && monthTotals[dateKey]! > 0`; `app_router.dart` line 64: `GoRoute(path: '/day/:dateKey')` as top-level route |
| 6 | Tapping a bar on the monthly chart navigates to DayDetailScreen via push | FAILED | `monthly_bar_chart.dart` `barTouchData` only has `handleBuiltInTouches: true` and a tooltip definition — no `touchCallback`, no `go_router` import, no `context.push`. ROADMAP SC#1 states "a day on the calendar **or a bar on the monthly chart**"; REQUIREMENTS CHART-07 states "o una barra del chart mensile". Only calendar tap is wired. |

**Score:** 5/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/presentation/screens/day_detail_screen.dart` | DayDetailScreen ConsumerWidget, min 80 lines | VERIFIED | 309 lines; `class DayDetailScreen extends ConsumerWidget` |
| `lib/l10n/app_en.arb` | Contains `dayDetailTotal` key with @-metadata | VERIFIED | Lines 492-508: key present with placeholders `total` (num), `target` (num) |
| `lib/l10n/app_it.arb` | Contains `dayDetailTotal` key | VERIFIED | Line 121: `"{total} ml / {target} ml obiettivo"` |
| `lib/l10n/app_fr.arb` | Contains `dayDetailTotal` key | VERIFIED | Line 121: `"{total} ml / {target} ml objectif"` |
| `lib/l10n/app_es.arb` | Contains `dayDetailTotal` key | VERIFIED | Line 121: `"{total} ml / {target} ml objetivo"` |
| `lib/core/router/app_router.dart` | GoRoute for `/day/:dateKey` top-level | VERIFIED | Lines 63-69: `GoRoute(path: '/day/:dateKey', ...)` between `/calculator` route and `StatefulShellRoute` |
| `lib/presentation/screens/history_screen.dart` | ConsumerWidget, push navigation, no dead code | VERIFIED | `class HistoryScreen extends ConsumerWidget`; grep count 0 for `_selectedDay`, `_buildDaySummary`, `AnimatedSwitcher`, `selectedDayPredicate`, `ConsumerStatefulWidget` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `day_detail_screen.dart` | `waterEntriesForDateProvider` | `ref.watch(waterEntriesForDateProvider(dateKey))` | WIRED | Line 45: exact pattern match |
| `day_detail_screen.dart` | `allTargetHistoryProvider` | `ref.watch(allTargetHistoryProvider)` | WIRED | Line 46: exact pattern match |
| `history_screen.dart` | `app_router.dart` | `context.push('/day/$dateKey')` | WIRED | Line 234: conditional push when `monthTotals[dateKey] > 0` |
| `app_router.dart` | `day_detail_screen.dart` | `DayDetailScreen(dateKey: dateKey)` builder | WIRED | Lines 65-68: `final dateKey = state.pathParameters['dateKey']!; return DayDetailScreen(dateKey: dateKey)` |
| `monthly_bar_chart.dart` | `app_router.dart` / day detail | `context.push('/day/...')` on bar tap | NOT_WIRED | `barTouchData` has no `touchCallback`; tooltip only. ROADMAP SC#1 and CHART-07 require this link |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `day_detail_screen.dart` | `entries` (List\<WaterEntryEntity\>) | `waterEntriesForDateProvider(dateKey)` — Drift stream query | Yes — stream from SQLite via Drift | FLOWING |
| `day_detail_screen.dart` | `targets` (List\<TargetHistoryEntry\>) | `allTargetHistoryProvider` — Drift stream query | Yes — stream from SQLite via Drift | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED — Flutter app requires device/simulator; no runnable CLI entry points. Route and widget checks covered by static analysis above.

### Probe Execution

Step 7c: No `probe-*.sh` files declared or conventionally present for this phase. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CHART-07 | 18-02 | Tapping a day (or bar on monthly chart) opens day detail screen via push | PARTIAL | Calendar tap: WIRED (`history_screen.dart:234`). Monthly chart bar tap: NOT WIRED (`monthly_bar_chart.dart` has tooltip-only barTouchData) |
| CHART-08 | 18-01 | Day detail shows per-entry bar chart (x=time, y=ml) | SATISFIED | `day_detail_screen.dart` lines 113-162: entries grouped by minute, `BarChartGroupData` built with HH:mm x-axis |
| CHART-09 | 18-01 | Day detail shows total ml for the selected day | SATISFIED | `day_detail_screen.dart` line 108: `totalMl = entries.fold(0, ...)`, line 181: rendered via `dayDetailTotal(totalMl, targetMl)` |
| CHART-10 | 18-01 | Day detail shows empty state for days without data | SATISFIED | `day_detail_screen.dart` lines 81-104: `if (entries.isEmpty)` branch with `dayDetailNoEntries` |
| CHART-11 | 18-01 | All new chart strings localized in en/it/fr/es | SATISFIED | Both keys present in all 4 ARB files; generated Dart L10N exposes both getters |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| No debt markers (TBD/FIXME/XXX) found in any phase-modified file | — | — | — | — |

### Human Verification Required

#### 1. DayDetailScreen Visual Layout and Interaction

**Test:** Run `flutter run`, go to History tab, tap a day with water intake data.
**Expected:** New screen opens without the bottom NavigationBar. AppBar title shows locale-formatted date (e.g., "June 16, 2026" in English). A bar chart is visible with one bar per intake entry; x-axis shows HH:mm times; y-axis shows values in L. Total and target text appear above the chart inside the same Card. Tapping a bar shows a tooltip with time and ml value.
**Why human:** NavigationBar presence/absence on pushed route, chart rendering, tooltip interaction, and visual layout cannot be verified by static analysis.

#### 2. Back Navigation State Preservation

**Test:** From DayDetailScreen, press the back button.
**Expected:** Returns to HistoryScreen with calendar displaying the same month and focused day as before navigation.
**Why human:** GoRouter push-pop state preservation is a runtime behavior not verifiable statically.

#### 3. Navigation Guard (No-Data Days)

**Test:** On the calendar, tap a day with no color circle (no recorded data).
**Expected:** Nothing happens — no navigation, no error.
**Why human:** Runtime guard behavior (`monthTotals` check) requires interaction.

#### 4. L10N Display on Device Language Change

**Test:** Change device language to Italian (or French, Spanish). Open History tab, tap a day with data.
**Expected:** On DayDetailScreen, the total text reads "X ml / Y ml obiettivo" (Italian) and the empty state reads "Nessun dato per questo giorno".
**Why human:** Locale switching requires a running device and language setting change.

### Gaps Summary

**1 gap blocking full goal achievement.**

**CHART-07 partial implementation:** The ROADMAP Success Criterion 1 states "Tapping a day on the calendar **or a bar on the monthly chart** navigates to a separate day detail screen (push navigation)". REQUIREMENTS.md CHART-07 states "Toccando un giorno nel calendario (**o una barra del chart mensile**) si apre una schermata di dettaglio separata (push)".

The calendar tap path is fully wired (`history_screen.dart` → `context.push('/day/$dateKey')`). However, `lib/presentation/widgets/monthly_bar_chart.dart` has no navigation on bar tap — `barTouchData` only configures `handleBuiltInTouches: true` with a tooltip. The monthly chart widget does not import `go_router` and has no `touchCallback`.

Plan 18-02 narrowed the CHART-07 objective to "navigation from calendar to day detail via push" and did not mention the monthly chart bar tap. This planning narrowing does not reduce the ROADMAP contract.

**Fix required:** Add a `touchCallback` to `BarTouchData` in `MonthlyBarChart` (or pass a callback from the parent `HistoryScreen`) that calls `context.push('/day/$dateKey')` when a bar is tapped, applying the same data-presence guard used in `onDaySelected`.

---

_Verified: 2026-06-16T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
