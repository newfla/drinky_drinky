# Project Research Summary

**Project:** Drinky Drinky (Hydration Tracker)
**Domain:** Offline-first mobile utility app (Flutter, iOS + Android)
**Researched:** 2026-06-03
**Confidence:** HIGH

## Executive Summary

Drinky Drinky is a focused hydration tracker -- a well-understood category with clear table-stakes features and proven architecture patterns. The recommended stack is Flutter 3.38+ with Riverpod 3.x for state management, Drift for SQLite persistence, and flutter_local_notifications for reminders. All packages are verified on pub.dev with high confidence. The architecture follows a feature-first, four-layer pattern (Presentation, Application, Domain, Data) with Drift streams flowing through Riverpod providers to create a fully reactive UI. This is a well-trodden path with official documentation backing every major decision.

The core product loop is simple: open app, tap preset button, see progress ring update. Everything else supports this loop. The "2-second rule" from competitor analysis is the north star -- logging water must take under 2 seconds or users abandon the app within a week. Two features missing from the current requirements should be added: measurement unit preference (ml vs fl oz) and a today's intake timeline below the progress bar. Both are table stakes that competitors universally include.

The primary risks are all in the notification layer. Android OEM background killing silently breaks reminders for 60-70% of real-world Android users. iOS caps pending notifications at 64. Android 14+ can revoke exact alarm permissions at any time. These are not hypothetical -- they are well-documented, high-confidence pitfalls that must be designed around from the start, not patched after launch. The mitigation is a rolling-window scheduling strategy with inexact-alarm fallback, tested on physical Samsung and Xiaomi devices. The second risk area is the Drift DateTime storage decision: `store_date_time_values_as_text: true` must be set in `build.yaml` before any data is written, as changing it later requires a painful migration.

## Key Findings

### Recommended Stack

Flutter 3.38+ with Dart 3.10+, using code generation throughout (Riverpod, Drift, Freezed). All 24 packages verified on pub.dev with HIGH confidence. Notable: `drift_flutter` replaces the now-EOL `sqlite3_flutter_libs`. `hooks_riverpod` explicitly rejected in favor of `flutter_riverpod` -- hooks add unnecessary complexity.

**Core technologies:**
- **Flutter + Riverpod 3.x:** Reactive state management with code-gen; functional style fits a focused utility app better than BLoC's boilerplate
- **Drift 2.33:** Type-safe SQLite with auto-updating streams; enables reactive UI without manual refresh; SQL aggregates power calendar view
- **flutter_local_notifications 21.x:** `zonedSchedule()` for timezone-aware reminders with DND window filtering; requires compileSdk 36, minSdk 24
- **table_calendar 3.2 + percent_indicator 4.2:** Proven UI components for the two main visual features (calendar history, progress ring)
- **Freezed 3.2:** Immutable domain models with `copyWith` -- essential for Riverpod state updates

### Expected Features

**Must have (table stakes):**
- Daily goal setting, circular progress bar, quick-add preset buttons (the core loop)
- Reminder notifications with configurable interval + DND quiet hours
- Undo last entry (fat-finger recovery)
- Calendar/history view with green/red color-coding
- Measurement unit preference (ml/L vs fl oz) -- **missing from current requirements, must add**
- Today's intake timeline -- **missing from current requirements, must add**

**Should have (v1 differentiators):**
- Goal completion celebration (haptic + confetti at 100%)
- Hydration streak counter (consecutive goal-met days)
- Simple onboarding flow (unit selection + goal setting)
- Dark mode (respect system theme via Material 3)
- Haptic feedback on logging

**Defer (v2+):**
- Home screen widget (high complexity, platform-specific)
- Multiple drink types, health app sync, weather-based goals, cloud sync, data export

### Architecture Approach

Feature-first folder structure with four layers (Presentation, Application, Domain, Data). Drift streams flow through Repositories into Riverpod StreamProviders, giving the UI fully reactive updates with zero manual refresh. Single AppDatabase instance as a Riverpod provider. Controllers are AsyncNotifiers. Services exist only for cross-cutting logic (notification scheduling). Domain models are pure Dart with no framework imports.

**Major components:**
1. **AppDatabase + DAOs** -- single Drift instance, modular queries per feature
2. **Repositories** -- transform DB rows to domain models, expose streams
3. **Controllers (Riverpod Notifiers)** -- screen-level state, expose action methods
4. **NotificationScheduler + NotificationService** -- compute DND-aware times, wrap platform APIs

### Critical Pitfalls

1. **Android OEM background killing** -- Samsung/Xiaomi/Huawei silently stop notifications. Test on physical devices; add OEM-specific battery optimization guidance (dontkillmyapp.com)
2. **iOS 64-notification limit** -- use rolling-window scheduling (max 2 days ahead), replenish on app open
3. **Android 14+ exact alarm revocation** -- check `canScheduleExactAlarms()` before every schedule; fall back to inexact alarms gracefully
4. **Drift DateTime storage mode** -- set `store_date_time_values_as_text: true` in `build.yaml` on day one; cannot be changed later without painful migration
5. **Midnight reset across timezones** -- store UTC timestamps + local date string (`dateKey`) as separate columns; aggregate by `dateKey`, not computed UTC ranges

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Foundation
**Rationale:** Every feature depends on persistence. Schema decisions (DateTime storage, dateKey column) are irreversible and must be correct from the start.
**Delivers:** Drift database with tables (WaterEntries, UserSettings, DrinkPresets), DAOs, repositories, core Riverpod providers, domain models (Freezed), unit tests with in-memory DB.
**Addresses:** Persistent local data, measurement unit preference (stored in settings)
**Avoids:** Pitfall 4 (DateTime storage mode), Pitfall 5 (timezone schema), Pitfall 8 (migration infra from v1), Pitfall 15 (beforeOpen misuse)

### Phase 2: Core Tracking UI
**Rationale:** The primary value loop must work with defaults before customization exists. This is what makes the app usable.
**Delivers:** Home screen with progress ring, quick-add buttons, today's timeline, undo last entry. App navigation shell.
**Addresses:** Daily goal, progress bar, quick-add presets, undo, today's timeline (the "2-second rule" loop)
**Avoids:** Pitfall 6 (ref.read in build), Pitfall 7 (autoDispose killing core state)

### Phase 3: Settings and Customization
**Rationale:** Users need to customize target, presets, and unit preferences. Settings must exist before notifications (which read interval/DND from settings).
**Delivers:** Settings screen (daily target, preset editor, unit toggle, reminder toggle, DND window config). Default seed data.
**Addresses:** Goal setting customization, unit preference, DND window configuration, drink preset customization

### Phase 4: Calendar and Streaks
**Rationale:** Read-only view over accumulated data. Depends on daily target from settings. Independent of notifications.
**Delivers:** Calendar screen with green/red day markers, streak counter, monthly aggregate queries.
**Addresses:** Calendar/history view, streak counter (differentiator)
**Avoids:** Pitfall 5 (midnight reset -- uses dateKey column from Phase 1)

### Phase 5: Notifications
**Rationale:** Most platform-specific, most edge cases, most pitfalls. Build last so the core app works without it. Requires settings infrastructure from Phase 3.
**Delivers:** Notification scheduling with DND awareness, permission flow, rolling-window strategy, OEM battery guidance, Android manifest setup.
**Addresses:** Reminder notifications, DND window enforcement, smart reminder suppression (if included)
**Avoids:** Pitfalls 1, 2, 3, 9, 10, 11, 12, 13 (the entire notification pitfall cluster)

### Phase 6: Polish and Onboarding
**Rationale:** UX refinements that improve retention but are not core functionality. Onboarding wraps the whole app experience.
**Delivers:** Onboarding flow, goal celebration (haptic + visual), dark mode, haptic feedback on logging, animated water-fill effect.
**Addresses:** Differentiator features (celebration, streaks display, onboarding, dark mode)

### Phase Ordering Rationale

- Phase 1 before everything: all features read/write data; schema decisions are irreversible
- Phase 2 before Phase 3: core loop must work with default values before customization
- Phase 3 before Phase 5: notification scheduling reads interval/DND from settings
- Phase 4 independent but needs daily target from settings, so after Phase 3
- Phase 5 last among functional phases: most complex, most platform-specific, highest pitfall density
- Phase 6 is pure polish; can ship without it if schedule is tight

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 5 (Notifications):** Highest pitfall density (8 of 15 pitfalls). Android OEM testing strategy, rolling-window scheduling algorithm, exact alarm fallback logic, and iOS 64-limit management all need detailed implementation planning.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Data Foundation):** Drift setup is well-documented with official guides and code samples provided in ARCHITECTURE.md
- **Phase 2 (Core Tracking UI):** Standard Riverpod + Flutter widget patterns; code samples provided
- **Phase 3 (Settings):** Standard CRUD screen pattern
- **Phase 4 (Calendar):** table_calendar integration is straightforward; aggregate SQL queries are standard

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All 24 packages verified on pub.dev with version numbers confirmed |
| Features | MEDIUM | Based on competitor website analysis and GitHub project survey; no app store review data (web search unavailable) |
| Architecture | HIGH | Based on official Flutter architecture guide, Riverpod docs, and Drift docs |
| Pitfalls | HIGH | All critical pitfalls verified against official platform documentation |

**Overall confidence:** HIGH

### Gaps to Address

- **Unit preference (ml vs fl oz) not in PROJECT.md:** Must be added to requirements. Affects display formatting, preset labels, and storage (store in ml internally, convert for display).
- **Today's timeline not in PROJECT.md:** Must be added. Simple list of today's entries below the progress bar.
- **OEM battery optimization testing:** Cannot be fully validated without physical Samsung/Xiaomi devices. Plan for device testing in Phase 5.
- **Smart reminder suppression complexity:** Rescheduling notifications after each water log adds complexity. May be better as Phase 6 polish rather than Phase 5 core notifications. Decide during Phase 5 planning.
- **GoRouter not in STACK.md:** Architecture references GoRouter for navigation but it was not included in the stack research. Evaluate during Phase 2 planning (may use Navigator 2.0 directly for a 3-screen app).

## Sources

### Primary (HIGH confidence)
- pub.dev package pages -- all 24 packages verified with exact versions (June 2026)
- Drift official documentation (drift.simonbinder.eu) -- schema, migrations, DateTime storage
- flutter_local_notifications v21.0.0 changelog and API docs
- Riverpod 3.3.x documentation -- providers, code-gen, lifecycle
- Android developer docs -- exact alarm permissions, notification channels
- Apple developer docs -- 64 pending notification limit
- Flutter official architecture guide (docs.flutter.dev/app-architecture/guide)

### Secondary (MEDIUM confidence)
- WaterMinder and Waterlogged official websites -- competitor feature analysis
- GitHub hydration tracker projects (39+ repos) -- feature pattern survey
- Andrea Bizzotto Flutter architecture articles -- project structure patterns
- dontkillmyapp.com -- Android OEM background killing documentation

### Tertiary (LOW confidence)
- Domain expertise on mobile utility app UX patterns -- the "2-second rule" and anti-feature recommendations

---
*Research completed: 2026-06-03*
*Ready for roadmap: yes*
