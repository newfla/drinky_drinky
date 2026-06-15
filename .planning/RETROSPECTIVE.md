# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.0 — MVP

**Shipped:** 2026-06-08
**Phases:** 5 | **Plans:** 7 | **Duration:** 5 days (2026-06-03 → 2026-06-08)
**Lines of Dart:** ~5,576 | **Commits:** 94 | **Files changed:** 166

### What Was Built

- Drift SQLite layer with 3 tables, reactive DAOs, and a 4-level Riverpod provider graph
- Home screen with animated CircularPercentIndicator, 4 quick-add presets, SnackBar undo, and midnight auto-reset
- Settings screen with live-saving daily target slider, preset edit dialogs, notification interval slider, and DND toggle
- Monthly history calendar with green/red day decoration and consecutive-day streak counter
- Notification system: rolling 64-slot TZDateTime scheduling, first-launch PermissionScreen, DND-aware skipping, goal-reached auto-cancel

### What Worked

- **Building the data layer first:** Phases 1→5 in dependency order meant each phase found a clean foundation to build on. No schema migrations needed; Drift reactive streams worked as expected downstream.
- **Code-gen (Riverpod + Drift + Freezed):** Eliminated large amounts of boilerplate and caught type errors at build time. Worth the build_runner setup cost.
- **Short plans with atomic commits:** Each plan was narrow enough to execute in 5-20 minutes. Failures were isolated and easy to diagnose.
- **Notifications built last (Phase 5):** The core tracking loop was usable and testable throughout development without notification complexity.
- **UAT as the final gate:** Running interactive tests revealed the emoji rendering issue (cosmetic) and the ring-text-past-goal issue (major) — both fixed before milestone close.

### What Was Inefficient

- **riverpod_lint excluded due to analyzer conflict:** The drift_dev/riverpod_generator version pair blocked custom_lint from loading, so Riverpod-specific linting was absent. This led to a few patterns (like `valueOrNull`) that were caught manually rather than statically.
- **VERIFICATION.md human_needed status:** Three verification files required a manual resolution step at milestone close. A lighter checklist format that captures the UAT result inline would avoid this cleanup pass.
- **Timeline sort order deviation:** Code rendered oldest-first; UI-SPEC specified newest-first. This was caught in VERIFICATION.md but not fixed — the accepted deviation creates a known UI inconsistency going into v1.1.
- **deleteLastEntry missing date filter:** A cross-day undo risk (CR-01) was flagged in Phase 1 review but deferred. If users undo after midnight, a prior-day entry may be deleted silently.

### Patterns Established

- `ConsumerStatefulWidget` + `AppLifecycleListener` + `Timer.periodic` for widgets that need both Riverpod state and lifecycle events
- `capturedKey` pattern in SnackBar closures to prevent date-key race conditions on midnight boundary
- Singleton service pattern for imperative side effects: `class Foo { Foo._(); static final Foo instance = Foo._(); }`
- GoRouter async redirect with `matchedLocation == '/permission'` loop-prevention guard
- DND check via total-minutes comparison (handles overnight windows and zero-width edge case)
- Rolling-window slot scheduling capped at 64 with a 30-day safety valve

### Key Lessons

1. **API mismatches are the #1 source of auto-fixed bugs.** Four of Phase 5's deviations were package API changes (named vs positional parameters, `TimezoneInfo` vs `String`, missing `AppSettings` class). Verifying actual pub.dev API shapes in RESEARCH.md before planning saves rework.
2. **Drift reactive streams + Riverpod code-gen is a high-leverage combination.** Once the provider graph was wired in Phase 1, all subsequent phases just watched providers — no manual invalidation, no state sync bugs.
3. **Building offline-first from the start was the right call.** SharedPreferences + Drift covered every persistence need without a backend. The constraint simplified every phase.
4. **Emoji in notification bodies is a platform hazard.** U+1F4A7 (💧) failed to render on at least one device. Prefer plain text in notification payloads unless emoji support is explicitly tested per platform.

### Cost Observations

- Model: Claude Sonnet 4.6 (this session); execution used claude-opus-4 via gsd executor
- Sessions: multiple short sessions across 5 days
- Notable: The ~8-minute average plan execution time reflects the narrow scope per plan. Plans that required platform config (Phase 5) took longer but were still bounded.

---

## Milestone: v1.1 — Polish & UX

**Shipped:** 2026-06-08
**Phases:** 3 (6-8) | **Plans:** 4 | **Duration:** 1 day (2026-06-08)
**Files changed:** 134 | **Insertions:** ~7,462 | **Deletions:** ~1,634 | **Commits:** 29

### What Was Built

- Material You dynamic theming via DynamicColorBuilder with dual light/dark ThemeData and static blue seed fallback
- SnackBar auto-dismiss fix (persist: false) and locale-aware liter display (intl.NumberFormat.decimalPatternDigits)
- Brightness-adaptive semantic colors across home and history screens for correct dark mode contrast
- FAB replaces inline quick-add row; modal bottom sheet with 3 configurable presets and custom ml input (1-9999)
- Water glass launcher icon generated via pure-Dart CLI script and flutter_launcher_icons; Android adaptive + iOS opaque

### What Worked

- **Narrow, focused phases:** Three independent concerns (theming, UX, icon) executed cleanly in sequence — no cross-phase conflicts.
- **Pure-Dart build script pattern:** `tool/generate_icon.dart` runs without Flutter engine, making icon regeneration fast and CI-friendly. No need for Figma or a design tool.
- **DynamicColorBuilder null-coalesce pattern:** Wrapping MaterialApp.router once meant zero screen-level changes for platform-adaptive theming. The pattern paid off immediately.
- **Presentation-layer .take(3) for preset reduction:** Zero-migration approach for reducing 4 presets to 3 was the right call — existing users' DB untouched, new seed data applies to fresh installs.
- **Human UAT at milestone close (not per-phase):** Phase 6 opened UAT; resolving it at milestone close (rather than during phase) was acceptable because all three phases shared the same test device.

### What Was Inefficient

- **Phase 6 UAT left open until milestone close:** The `human_needed` verification status created a stray artifact that triggered the pre-close audit. If human tests are done the same day as execution, close them in-phase rather than leaving them to be resolved at milestone close.
- **Stray SUMMARY.md written to main before merge:** The executor wrote SUMMARY.md to the main branch checkout (not just the worktree) before committing it to the worktree. Required manual cleanup (rm -f + FF merge). This is the same pattern as Phase 7 — a recurring executor behavior worth noting for the next milestone.
- **worktree_dirty blocking cleanup:** An untracked `.claude/settings.local.json` file in the worktree prevented `worktree.cleanup-wave` from running. The fix (stash + manual FF merge) took more steps than ideal.
- **image ^4.9.0 → ^4.8.0 downgrade:** The version conflict with flutter_local_notifications was predictable from the shared xml dependency. RESEARCH.md caught it but the plan still specified 4.9.0, requiring an auto-fix during execution.

### Patterns Established

- `DynamicColorBuilder` wrap of `MaterialApp.router` with `lightDynamic ?? ColorScheme.fromSeed(seedColor: ...)` for zero-overhead platform adaptation
- `_formatLiters(BuildContext context, int ml)` — locale-aware helper using `NumberFormat.decimalPatternDigits(locale: Localizations.localeOf(context).toString(), decimalDigits: 2)`
- Brightness-conditional semantic color: `theme.brightness == Brightness.dark ? Colors.X.shade400 : Colors.X.shade600`
- Bottom sheet callback pattern: parent widget owns DB writes, sheet receives `List<DrinkPreset> presets` + `void Function(int ml) onAdd` — no direct provider access inside the sheet
- `Navigator.pop` before `onAdd` callback so sheet closes before SnackBar appears
- `tool/` directory for build-time Dart scripts: pure Dart, no Flutter imports, `import 'package:image/image.dart' as img`
- Source PNGs in `assets/icon/` NOT added to `flutter: assets:` section — they are input to flutter_launcher_icons, not app runtime assets

### Key Lessons

1. **Close UAT in-phase, not at milestone.** Leaving human_needed status open creates a cleanup step at milestone close. If you can test same-day, do it before marking the phase complete.
2. **Pin dev dependency versions that share transitive deps.** image 4.9.x and flutter_local_notifications 21.x share the xml package. Checking transitive compatibility at RESEARCH.md time would have avoided the auto-fix downgrade.
3. **Worktree artifacts bleed to main.** Executor agents writing planning docs to the main checkout (before merging the worktree) is a known pattern across multiple phases. Resolve by checking `git status` on main before any merge.
4. **DynamicColorBuilder is essentially free.** Three screens inherited dark mode and Material You automatically from the single main.dart change — no per-widget changes needed.

### Cost Observations

- Model: Claude Sonnet 4.6 (orchestrator); gsd-executor subagents via worktrees
- Sessions: single day, 3 phases
- Notable: Phase 7 (3 min execution) and Phase 8 (6 min execution) were the fastest in the project. Narrow, well-researched plans with clear patterns dramatically reduce execution time.

---

## Milestone: v1.2 — Bug Fixes & Feature Depth

**Shipped:** 2026-06-15
**Phases:** 3 (9-11) | **Plans:** 6 | **Duration:** 5 days (2026-06-10 → 2026-06-15)
**Files changed:** 62 | **Insertions:** ~10,145 | **Deletions:** ~1,279 | **Commits:** 54

### What Was Built

- 3 targeted bug fixes: cross-day deleteLastEntry filter, midnight date-key reset via keepAlive Notifier, semantic dateKey validation (YYYY-MM-DD regex + DateTime.tryParse)
- Drift `target_history` table with dual-write via `updateTargetWithHistory()` and Drift schema migration v2
- `applyFromTomorrow` toggle in Settings — per-change effective date (today vs tomorrow)
- Home screen and calendar consuming per-day effective targets from `target_history`
- `todayDateKeyProvider` with Timer-based midnight invalidation and `keepAlive(ref)` lifecycle
- `HydrationCalculatorScreen` — sex (SegmentedButton), weight (validated TextField), climate (Slider/5 steps), live recommendation formula, privacy disclaimer
- First-launch calculator onboarding via GoRouter redirect chain (`drinky_calculatorShown` SharedPreferences key)
- Settings entry ("Ricalcola raccomandazione idratazione") that pushes the same screen in non-onboarding mode
- "Usa come target" writes recommendation to `target_history` via existing dual-write path; inputs never persisted

### What Worked

- **Single dual-write method (`updateTargetWithHistory`):** Centralizing all target changes through one repository method made it trivial to wire the calculator's "Usa come target" button — it just called the existing API. No special-casing or alternative write paths.
- **`isOnboarding` constructor parameter over `canPop()`:** GoRouter's `canPop()` is unreliable after redirect-initiated navigation (redirect replaces the stack). Passing `isOnboarding` via `state.extra` was deterministic and required zero runtime conditions.
- **Privacy-by-design without extra work:** Holding calculator inputs in ephemeral widget state (`_selectedSex`, `_weightController`, `_climateValue`) meant no deletion logic — widget disposal is sufficient. CALC-04 was satisfied without any persistence footprint.
- **Schema migration path established:** Drift migration v2 (adding `target_history` + seeding defaults) worked cleanly. The pattern is now validated for future schema evolution.
- **Phase-in-phase UAT (11 tests, all pass):** The calculator had a rich test matrix (onboarding vs settings, Usa/Salta, weight validation, live calculation) and all 11 scenarios passed on first human test run.

### What Was Inefficient

- **REQUIREMENTS.md checkboxes left stale from Phase 10:** BUG-02, TARGET-02, TARGET-03, TARGET-04 were still unchecked at milestone close despite being shipped. Required a manual fix before archiving. The per-phase transition step should include a requirements checkbox audit.
- **Schema migration v2 needed two iterations:** The first migration attempt missed year-padding for dates seeded from `DateTime.now()`. A second fix commit (`e2e76af`) resolved it. The pattern of testing migrations against real SQLite earlier in the verify cycle would catch this faster.
- **gsd-tools commit helper brittle when files are unstaged:** The CLI commit helper failed mid-session because files hadn't been staged. Fell back to manual `git add` + `git commit`. The helper should either auto-stage or give a clearer error.

### Patterns Established

- `isOnboarding: state.extra as bool? ?? true` — pass context through GoRoute `state.extra`; null → redirect default (true), explicit false → Settings push
- `keepAlive(ref)` + `Timer`-based invalidation — self-scheduling midnight reset without AppLifecycleListener
- Redirect loop prevention: `if (state.matchedLocation == '/calculator') return null;` guards before the redirect check
- `SegmentedButton<String>` with `emptySelectionAllowed: true` — unselected-by-default multi-option input
- `FilteringTextInputFormatter.digitsOnly` + range validation in `_computeRecommendation()` — no separate form key needed for a single numeric field
- Privacy-by-design: ephemeral widget state only; no SharedPreferences or Drift keys; widget disposal = data erasure

### Key Lessons

1. **Audit requirements checkboxes at phase transition, not milestone close.** Stale checkboxes in REQUIREMENTS.md were only discovered during milestone archival. A one-line check at `/gsd-transition` time would catch this per phase.
2. **Test schema migrations against a real SQLite file before verify.** The year-padding bug in migration v2 was only caught by the verify agent reading the migrated DB. Running `dart run tool/migrate_check.dart` (or equivalent) as part of plan execution would catch this earlier.
3. **GoRouter `canPop()` is unreliable after redirect navigation.** Redirect-initiated navigation replaces the back stack, so `canPop()` returns false in both onboarding and deep-link contexts. Always pass explicit context via `state.extra` when routing behavior depends on the navigation origin.
4. **Dual-write centralisation pays forward.** Writing `updateTargetWithHistory()` once in Phase 9/10 meant the Phase 11 calculator required zero data-layer changes — it just called an existing method. Centralise early.

### Cost Observations

- Model: Claude Sonnet 4.6 (orchestrator); executor subagents via worktrees
- Sessions: multiple sessions across 5 days (2026-06-10 → 2026-06-15)
- Notable: Phase 11 (1 plan, 240-line screen) executed cleanly in one wave. The combination of UI-SPEC + research + CONTEXT.md meant the executor had enough signal to produce correct `isOnboarding` handling without iteration.

---

## Milestone: v1.3 — Multilingual Support

**Shipped:** 2026-06-15
**Phases:** 3 (12-14) | **Plans:** 6 | **Duration:** 1 day (2026-06-15)
**Files changed:** 105 | **Insertions:** ~8,501 | **Deletions:** ~11,984 | **Commits:** ~35

### What Was Built

- Gen-l10n pipeline: `l10n.yaml` (synthetic-package: false), flutter_localizations SDK dep, `context.l10n` extension, `initializeDateFormatting()` before runApp()
- 79-key `app_en.arb` canonical template with full `@key` metadata; Italian, French, Spanish ARBs with ICU plurals
- `BiologicalSex` and `ClimateLevel` enums replacing locale-sensitive Italian string map keys in the calculator
- Full string extraction across 6 screens via `context.l10n` — zero hardcoded user-visible strings
- Localized notifications: `_resolveLocale()` via `PlatformDispatcher.instance.locales`, `lookupAppLocalizations()` without BuildContext
- iOS `CFBundleLocalizations` + Android `resourceConfigurations` for correct platform locale detection

### What Worked

- **Discuss-phase locking locale resolution strategy first:** Locking "primary locale only" as D-01 in CONTEXT.md before planning meant the NotificationService implementation and `localeListResolutionCallback` in main.dart were automatically consistent. No divergence discovered during UAT.
- **Enum refactor as a prerequisite phase:** Identifying that the Italian string-key pattern in the calculator would crash on non-Italian locales in Phase 13 research, and executing the enum refactor first in 13-01, meant 13-02 (translations) had no crash surface. Zero calculator crashes in UAT.
- **Code review catching guard ordering:** The code review on Phase 14 caught two blocking bugs (cancelAll before permission check, zero-interval infinite loop) that static verification missed. Code review as a gate before verification was the right sequencing.
- **`lookupAppLocalizations` pattern for service-layer l10n:** Avoiding BuildContext in NotificationService was a clean design constraint. The generated `lookupAppLocalizations()` function with a try/catch English fallback was the correct escape hatch.
- **Parallel worktree execution for 14-01 and 14-02:** The two Phase 14 plans were independent (ARB/service vs platform config) — parallel worktree execution saved time with zero merge conflicts.

### What Was Inefficient

- **Machine-generated translations without native review:** ARBs ship with machine translations for it/fr/es. A quality gate (L10N-FUTURE-01) was deferred. If the app reaches native speakers before v1.4, this becomes visible tech debt.
- **14-VERIFICATION.md and 12-VERIFICATION.md remained human_needed at milestone close:** Both phases had completed UAT but the VERIFICATION.md status was never updated from `human_needed` to `complete`. The audit tool flagged them as open artifacts. Either update VERIFICATION.md inline when UAT completes, or change the UAT workflow to also patch the verification file.
- **Phase 14 plan descriptions in ROADMAP.md were inaccurate:** 14-01 and 14-02 plan descriptions incorrectly said "L10n pipeline setup" / "Complete app_en.arb" (copied from Phase 12 plans). Caught during milestone archival, not at planning time. Plan descriptions should be reviewed against actual PLAN.md content before committing.

### Patterns Established

- `synthetic-package: false` + `output-dir: lib/l10n/generated/` for gen-l10n on Flutter 3.44+ with riverpod_generator/drift_dev in the dependency graph
- `context.l10n` via `extension AppLocalizationsX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this)!; }` — single extension, single import
- Enum-keyed computation pattern: enums carry all locale-agnostic values; display labels resolved via `context.l10n` at render time — no string-key map lookup, no locale coupling
- `PlatformDispatcher.instance.locales` + `lookupAppLocalizations(locale)` — service-layer locale resolution without BuildContext
- Primary-only locale matching: `locales.first`, iterate `supportedLocales` by `languageCode`, English fallback — consistent across UI and service layer
- ICU plural with explicit `=0` + `=1` + `other` — French `one` category covers 0 and 1, so explicit `=0`/`=1` avoids French-specific divergence

### Key Lessons

1. **Lock locale resolution strategy in discuss-phase.** A single decision (primary-only vs list resolution) determines how UI locale and notification locale align. Locking it early prevented silent divergence.
2. **Enum refactor before translation.** Any string-keyed computation that uses display strings as map keys will crash when locale changes. Identify these in research, refactor to enums first, then add translations.
3. **Update VERIFICATION.md when UAT completes.** Leaving `status: human_needed` after UAT passes creates stale artifacts that the pre-close audit flags as open. Patch the status field inline or merge the UAT result into VERIFICATION.md.
4. **Review plan descriptions in ROADMAP.md before committing.** Copy-paste errors in plan descriptions (14-01/14-02 reused Phase 12 descriptions) are invisible at planning time but create misleading history. A quick sanity check at plan completion prevents this.

### Cost Observations

- Model: Claude Sonnet 4.6 (orchestrator); executor subagents via worktrees
- Sessions: single day (2026-06-15), ~3.5 hours wall-clock
- Notable: 105 files changed, but most of the delta was generated code (ARB locale implementations, `app_localizations_*.dart`). The actual hand-written diff was much smaller. Generated code churn can be misleading as a complexity proxy.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Duration | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 5 days | 5 | Baseline — first milestone |
| v1.1 | 1 day | 3 | Narrow polish phases; worktree executor; icon via pure-Dart CLI |
| v1.2 | 5 days | 3 | Bug fixes + feature depth; schema migration; onboarding screen chain |
| v1.3 | 1 day | 3 | l10n pipeline; ARB + codegen; enum refactor; platform locale config |

### Cumulative Quality

| Milestone | Unit Tests | flutter analyze | UAT Issues Found |
|-----------|------------|-----------------|------------------|
| v1.0 | 11 passing | 0 issues | 2 (1 major fixed, 1 cosmetic fixed) |
| v1.1 | 12 passing | 0 issues | 0 (UAT passed; Material You skipped/N/A on test device) |
| v1.2 | 12 passing | 0 issues | 0 (UAT 11/11 passed; schema migration verified) |
| v1.3 | 12 passing | 0 issues | 3 inline fixes during Phase 13 UAT + 2 code review blockers in Phase 14 (all resolved) |

### Top Lessons (Verified Across Milestones)

1. Verify actual package API shapes at planning time — docs lag behind releases
2. Build the data layer first; everything downstream becomes simpler when streams just work
3. Close human UAT in-phase; open human_needed status creates mandatory cleanup at milestone close
4. Worktree artifacts may bleed to main — check `git status` on main before any merge
5. Audit requirements checkboxes at phase transition, not milestone close
6. Centralise write paths early — a single dual-write method made a later onboarding feature require zero data-layer changes
7. Lock cross-cutting design decisions in discuss-phase; enum-vs-string and locale-resolution-strategy must be consistent across all phases that touch the same subsystem
8. Generated code churn (ARB implementations, Drift DAOs) inflates file/LOC stats — measure hand-written delta separately when assessing complexity
