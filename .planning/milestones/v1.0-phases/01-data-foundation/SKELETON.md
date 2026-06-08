# Walking Skeleton -- Drinky Drinky

**Phase:** 1
**Generated:** 2026-06-03

## Capability Proven End-to-End

User can tap a quick-add button on the home screen and see their water intake total update, backed by a real Drift SQLite database with reactive streams flowing through Riverpod providers.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.38+ with Dart 3.10+ | Required by go_router 17.x and current SDK ecosystem; Material 3 default |
| Data layer | Drift 2.33 + drift_flutter 0.3 (SQLite) | Type-safe SQL, reactive .watch() streams, compile-time query verification; fully offline |
| State management | flutter_riverpod 3.3.1 + @riverpod code-gen | Reactive caching fits offline app with Drift streams; code-gen eliminates provider type guesswork |
| Data classes | Freezed 3.2.5 (abstract class syntax) | Automatic copyWith, equality, toString for domain entities; integrates with Riverpod code-gen |
| Navigation | GoRouter 17.3.0 | Declarative routing with 3 routes; Flutter team maintained |
| Directory layout | Layer-first: lib/data/, lib/domain/, lib/presentation/, lib/core/ | User decision D-12; separates concerns by architectural layer |
| DateTime storage | store_date_time_values_as_text: true (IRREVERSIBLE) | ISO-8601 text storage prevents timezone/DST bugs; set before first code generation |
| Daily aggregation | date_key TEXT column (YYYY-MM-DD local) | Correct midnight-reset behavior across timezones; query by local date, not UTC |
| Platform targets | iOS 16.0+ / Android API 26+ | Covers 95%+ iOS devices, 99%+ Android devices; compatible with all dependencies |

## Stack Touched in Phase 1

- [x] Project scaffold (flutter create, pubspec.yaml, build.yaml, platform config)
- [x] Routing -- GoRouter with 3 routes (/, /history, /settings)
- [x] Database -- Drift schema with 3 tables, DAOs with CRUD + reactive streams, migration seeding
- [x] UI -- Placeholder screens wired to Riverpod providers (home screen shows data from DB)
- [x] Deployment -- `flutter run` exercises full stack locally

## Out of Scope (Deferred to Later Slices)

- Animated circular progress bar (Phase 2)
- Quick-add preset buttons with real UI (Phase 2)
- Undo last entry UI (Phase 2)
- Today's intake timeline display (Phase 2)
- Settings screen with editable fields (Phase 3)
- Calendar view with green/red day coloring (Phase 4)
- Streak counter display (Phase 4)
- Notification scheduling and permission flow (Phase 5)
- DND window enforcement in notifications (Phase 5)
- Custom app icons and typography (deferred polish)

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- Phase 2: Core Tracking UI -- Users can log water with a single tap, see progress ring update, undo mistakes, and review today's intake timeline
- Phase 3: Settings -- Users can customize daily target, preset amounts, notification interval, and DND quiet hours
- Phase 4: Calendar and Streaks -- Users can review hydration history on a monthly calendar and see consecutive day streak
- Phase 5: Notifications -- Users receive scheduled reminders respecting DND window and auto-stopping on goal completion
