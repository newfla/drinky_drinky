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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Duration | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 5 days | 5 | Baseline — first milestone |

### Cumulative Quality

| Milestone | Unit Tests | flutter analyze | UAT Issues Found |
|-----------|------------|-----------------|------------------|
| v1.0 | 11 passing | 0 issues | 2 (1 major fixed, 1 cosmetic fixed) |

### Top Lessons (Verified Across Milestones)

1. Verify actual package API shapes at planning time — docs lag behind releases
2. Build the data layer first; everything downstream becomes simpler when streams just work
