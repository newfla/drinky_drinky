<!-- GSD:project-start source:PROJECT.md -->

## Project

**Drinky Drinky**

A Flutter mobile app that helps users track their daily water intake and stay hydrated. Users set a daily water goal, log drinks via customizable quick-add buttons, and receive configurable reminder notifications. Runs on iOS and Android.

**Core Value:** The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

### Constraints

- **Tech stack**: Flutter + Riverpod + Drift — no deviation from chosen stack
- **Platform**: iOS and Android only (no web/desktop for v1)
- **Offline-first**: No backend or cloud sync in v1

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Flutter SDK | >= 3.38.1 | App framework | Required by flutter_local_notifications 21.x; Material 3 is mature and default |
| Dart SDK | >= 3.10.0 | Language | Required by current Flutter SDK; pattern matching and sealed classes available |

### State Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_riverpod | ^3.3.1 | Widget-level state management | Stable 3.x release; reactive caching fits an offline app with streams from Drift. Use `flutter_riverpod`, not `hooks_riverpod` -- hooks add complexity this app does not need |
| riverpod_annotation | ^4.0.2 | Code-gen annotations for providers | Eliminates guesswork on provider type selection; `@riverpod` annotation is now the recommended way to declare providers |
| riverpod_generator | ^4.0.3 | Provider code generation | Generates correct provider types from annotated functions/classes; required companion to riverpod_annotation |
| riverpod_lint | ^3.1.3 | Static analysis for Riverpod | Catches common mistakes (missing ProviderScope, unsafe ref in dispose); includes refactoring assists |

### Database (Local Persistence)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| drift | ^2.33.0 | Type-safe SQLite ORM | Structured queries for daily aggregates, calendar views, and historical data; compile-time SQL verification; auto-updating streams integrate naturally with Riverpod |
| drift_flutter | ^0.3.0 | Flutter-specific database setup | **Replaces the old sqlite3_flutter_libs** (which is now EOL). Provides `driftDatabase()` helper that handles platform-specific SQLite setup automatically |
| drift_dev | ^2.33.0 | Code generator for Drift | Dev dependency; generates type-safe table code from Dart class definitions |

### Notifications

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_local_notifications | ^21.0.0 | Local notification display and scheduling | De facto standard for local notifications on Flutter; supports `zonedSchedule()` with timezone awareness, periodic notifications, and Android notification channels |
| timezone | ^0.11.0 | Timezone-aware DateTime | Required by flutter_local_notifications for `zonedSchedule()`; handles DST transitions correctly |
| flutter_timezone | ^5.1.0 | Device timezone detection | Retrieves the device's local timezone name to initialize the timezone database; recently maintained (updated 6 days ago) |
| permission_handler | ^12.0.3 | Runtime permission requests | Needed for notification permission on Android 13+ and iOS; also handles exact alarm permission on Android 14+ |

### UI Components

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| table_calendar | ^3.2.0 | Calendar view for historical data | Best-maintained Flutter calendar widget; supports month/week/two-week formats, event markers, custom day builders (for green/red color-coding), and locale support |
| percent_indicator | ^4.2.5 | Circular progress indicator | Provides `CircularPercentIndicator` with animation, gradient support, customizable stroke caps, and child widgets (for showing ml/target text inside the ring). More flexible than Flutter's built-in `CircularProgressIndicator` |
| fl_chart | ^1.2.0 | Charts for trends (optional, Phase 2+) | If you later want weekly/monthly trend charts; pie and bar charts available. Not needed for MVP but worth knowing about |

### Build Tooling

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| build_runner | ^2.15.0 | Code generation orchestrator | Required by drift_dev and riverpod_generator; runs `dart run build_runner build` |
| freezed | ^3.2.5 | Immutable data classes with copyWith | Use for settings models and any complex state objects; generates `==`, `hashCode`, `toString`, `copyWith`; integrates with Riverpod code-gen |
| freezed_annotation | ^3.1.0 | Annotations for freezed | Runtime dependency paired with freezed |
| json_annotation | ^4.12.0 | JSON serialization annotations | Needed if you ever serialize settings to JSON; freezed can generate `fromJson`/`toJson` |

### Utility

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| path_provider | ^2.1.5 | App directory paths | Required by drift_flutter for database file location |
| intl | ^0.20.2 | Date/time formatting | Format dates for calendar view, notification messages; locale-aware formatting |
| shared_preferences | ^2.5.5 | Simple key-value storage | For lightweight settings (daily target, DND window times, quick-add amounts) that do not need relational queries. Simpler than putting everything in Drift |
| google_fonts | ^8.1.0 | Typography | Clean font selection without bundling font files; optional but improves visual polish |

### Dev/Quality

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_lints | ^6.0.0 | Lint rules | Official Flutter lint set; baseline code quality |
| custom_lint | ^0.8.1 | Custom lint runner | Required by riverpod_lint to function |
| flutter_launcher_icons | ^0.14.4 | App icon generation | Generate iOS and Android launcher icons from a single source image |

## DND Window Handling -- Architecture Note

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| State management | flutter_riverpod 3.x | BLoC / flutter_bloc | BLoC has more boilerplate (events, states, blocs) for a focused utility app; Riverpod's functional style with code-gen is simpler for this scope |
| State management | flutter_riverpod | hooks_riverpod | Hooks add a paradigm unfamiliar to most Flutter devs; no material benefit for this app's complexity level |
| Database | Drift | Hive | Hive is key-value, not relational; daily aggregates and calendar queries would require manual indexing and iteration instead of SQL |
| Database | Drift | SharedPreferences (for everything) | SharedPreferences cannot do queries like "sum of intake grouped by date" efficiently; Drift was specifically chosen for structured data |
| Database setup | drift_flutter | sqlite3_flutter_libs | sqlite3_flutter_libs is now EOL (marked obsolete on pub.dev). drift_flutter is the official replacement |
| Notifications | flutter_local_notifications | awesome_notifications | awesome_notifications is explicitly incompatible with flutter_local_notifications; flutter_local_notifications is more established and lighter; awesome_notifications adds complexity we do not need |
| Calendar | table_calendar | syncfusion_flutter_calendar | Syncfusion requires a license for commercial use; table_calendar is MIT-licensed and covers the needed functionality |
| Calendar | table_calendar | flutter_calendar_carousel | flutter_calendar_carousel has not been updated in over 2 years; table_calendar is actively maintained |
| Circular progress | percent_indicator | sleek_circular_slider | sleek_circular_slider is from an unverified publisher with no updates in 12+ months; percent_indicator is well-maintained with 4.2.5 released ~14 months ago but stable API |
| Circular progress | percent_indicator | liquid_progress_indicator | liquid_progress_indicator is unmaintained (last updated 4 years ago); would be a fun visual but too risky to depend on |
| Circular progress | percent_indicator | Custom paint (built-in) | CustomPainter works but requires significant boilerplate for animation, gradient, and child layout that percent_indicator provides out of the box |
| Data classes | freezed | manual implementation | Freezed eliminates ~50 lines of boilerplate per model class; `copyWith` is essential for immutable state updates in Riverpod |
| Settings storage | shared_preferences | Drift table | Simple key-value settings (target, DND times) do not justify a database table; shared_preferences is simpler and faster for this use case |

## Packages to NOT Use

| Package | Why Not |
|---------|---------|
| sqlite3_flutter_libs | EOL/obsolete. Use drift_flutter instead |
| awesome_notifications | Incompatible with flutter_local_notifications (cannot coexist) |
| get / GetX | Anti-pattern for testable architecture; Riverpod is the chosen approach |
| provider (standalone) | Riverpod supersedes provider; mixing both causes confusion |
| hive / isar | Drift already chosen; adding a second persistence layer creates maintenance burden |
| flutter_native_timezone | Unmaintained predecessor of flutter_timezone |

## Installation

# pubspec.yaml

# After adding dependencies:

# Run code generation (drift tables, riverpod providers, freezed models):

# Or watch for changes during development:

## Platform Configuration Notes

### Android

- `compileSdk: 36` required by flutter_local_notifications 21.x
- `minSdk: 24` (Android 7.0) required by flutter_local_notifications 21.x
- Add exact alarm permission in AndroidManifest for Android 14+:

### iOS

- Minimum iOS 13 required by flutter_local_notifications 21.x
- Notification permission must be requested at runtime via permission_handler
- Register `UNUserNotificationCenterDelegate` in AppDelegate per flutter_local_notifications docs

## Version Confidence Assessment

| Package | Version | Confidence | Verified Via |
|---------|---------|------------|--------------|
| flutter_riverpod | 3.3.1 | HIGH | pub.dev direct fetch |
| riverpod_annotation | 4.0.2 | HIGH | pub.dev direct fetch |
| riverpod_generator | 4.0.3 | HIGH | pub.dev direct fetch |
| riverpod_lint | 3.1.3 | HIGH | pub.dev direct fetch |
| drift | 2.33.0 | HIGH | pub.dev direct fetch |
| drift_flutter | 0.3.0 | HIGH | pub.dev direct fetch + official drift docs |
| drift_dev | 2.33.0 | HIGH | pub.dev direct fetch |
| flutter_local_notifications | 21.0.0 | HIGH | pub.dev direct fetch + changelog |
| timezone | 0.11.0 | HIGH | pub.dev direct fetch |
| flutter_timezone | 5.1.0 | HIGH | pub.dev direct fetch |
| permission_handler | 12.0.3 | HIGH | pub.dev direct fetch |
| table_calendar | 3.2.0 | HIGH | pub.dev direct fetch |
| percent_indicator | 4.2.5 | HIGH | pub.dev direct fetch |
| fl_chart | 1.2.0 | HIGH | pub.dev direct fetch |
| build_runner | 2.15.0 | HIGH | pub.dev direct fetch |
| freezed | 3.2.5 | HIGH | pub.dev direct fetch |
| freezed_annotation | 3.1.0 | HIGH | pub.dev direct fetch |
| json_annotation | 4.12.0 | HIGH | pub.dev direct fetch |
| path_provider | 2.1.5 | HIGH | pub.dev direct fetch |
| shared_preferences | 2.5.5 | HIGH | pub.dev direct fetch |
| intl | 0.20.2 | HIGH | pub.dev direct fetch |
| google_fonts | 8.1.0 | HIGH | pub.dev direct fetch |
| flutter_lints | 6.0.0 | HIGH | pub.dev direct fetch |
| custom_lint | 0.8.1 | HIGH | pub.dev direct fetch |
| flutter_launcher_icons | 0.14.4 | HIGH | pub.dev direct fetch |

## Sources

- pub.dev package pages (direct fetch, June 2026)
- Drift official documentation: https://drift.simonbinder.eu/setup/
- flutter_local_notifications API documentation: https://pub.dev/documentation/flutter_local_notifications/latest/
- Riverpod changelog: https://pub.dev/packages/riverpod/changelog
- flutter_local_notifications changelog: https://pub.dev/packages/flutter_local_notifications/changelog

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
