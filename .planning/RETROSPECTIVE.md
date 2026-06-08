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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Duration | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 5 days | 5 | Baseline — first milestone |
| v1.1 | 1 day | 3 | Narrow polish phases; worktree executor; icon via pure-Dart CLI |

### Cumulative Quality

| Milestone | Unit Tests | flutter analyze | UAT Issues Found |
|-----------|------------|-----------------|------------------|
| v1.0 | 11 passing | 0 issues | 2 (1 major fixed, 1 cosmetic fixed) |
| v1.1 | 12 passing | 0 issues | 0 (UAT passed; Material You skipped/N/A on test device) |

### Top Lessons (Verified Across Milestones)

1. Verify actual package API shapes at planning time — docs lag behind releases
2. Build the data layer first; everything downstream becomes simpler when streams just work
3. Close human UAT in-phase; open human_needed status creates mandatory cleanup at milestone close
4. Worktree artifacts may bleed to main — check `git status` on main before any merge
