# Phase 5: Notifications - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 gives the app the ability to remind users to drink water on a schedule. Three deliverables:

1. **Pre-permission explanation screen** (NOTF-02) — A dedicated screen shown on first app launch, explaining why notifications are needed, before triggering the system permission prompt.
2. **Scheduled interval reminders** (NOTF-01) — `flutter_local_notifications` with `zonedSchedule()` schedules the next 4 days of notification slots (rolling window) respecting the DND quiet-hours window and the user-configured interval.
3. **Goal-reached auto-stop** (NOTF-03) — When today's total reaches `dailyTargetMl`, all pending notifications are cancelled. They resume naturally on next-day app open via the rolling window reschedule.

No new user-facing settings — all configuration (interval, DND) already exists in `SettingsScreen` from Phase 3. No background service. No cloud push. Local notifications only.

</domain>

<decisions>
## Implementation Decisions

### Permission Flow (D-01 – D-03)

- **D-01:** Show the pre-permission screen **on first app launch** — before the user sees the Home tab. Persisted with `SharedPreferences` (`bool permissionScreenShown`). On subsequent launches, skip the screen entirely and go straight to the Home tab.

- **D-02:** After the user grants or denies the system permission prompt (triggered from the pre-permission screen), show a brief **confirmation message** before landing on Home:
  - Granted: "Reminders enabled! You can adjust them anytime in Settings."
  - Denied: "No problem — you can enable reminders later in your device Settings."
  - Then navigate to the Home tab.

- **D-03:** If the user has previously denied permission, show a **subtle info banner** in the Notifications card in `SettingsScreen`: "Notifications are disabled. Enable in system Settings." Tapping it opens the device Settings app (`AppSettings.openAppSettings()` from `permission_handler`). This is the only persistent reminder — no modals, no repeated prompts.

### Scheduling Strategy (D-04 – D-06)

- **D-04:** Use a **rolling 4-day window** approach. On each trigger event, cancel all pending notifications, then compute notification times for the next 4 days (each day: all slots from `now` or `startOfDay` through `endOfDay` that fall outside the DND window), schedule each via `zonedSchedule()`. A 60-minute interval with a 16-hour active window yields ~16 slots/day × 4 days = ~64 slots — within iOS's hard limit.

- **D-05:** **Trigger events that reschedule** (cancel all + recompute + schedule):
  1. App foreground resume (`AppLifecycleResumed`) — wired via the existing `AppLifecycleListener` pattern from `HomeScreen`.
  2. Settings change — when the user changes `notificationIntervalMinutes` or any DND field in `SettingsScreen` (post-save callback, same as the existing `onChangeEnd` pattern).
  3. Permission granted — immediately after the user grants permission on the pre-permission screen.

- **D-06:** DND enforcement is pure Dart computation before scheduling — for each candidate slot `DateTime`, check if it falls between `dndStartHour:dndStartMinute` and `dndEndHour:dndEndMinute` (handling overnight windows where end < start). Slots inside DND are skipped entirely. No system-level DND API needed.

### Goal-Reached Auto-Stop (D-07 – D-08)

- **D-07:** Detection is **reactive in `HomeScreen`**: the screen already watches `todayTotalProvider` and `userSettingsProvider` via Riverpod. Add a `ref.listen` on `todayTotalProvider`: when the total first crosses `dailyTargetMl`, call `NotificationService.cancelAll()`. This fires while the app is open (the only time water is logged — no background logging exists in this app).

- **D-08:** **Next-day resume** happens automatically. The rolling window reschedule on next-day foreground open starts from `now` (tomorrow morning) and the goal is 0, so scheduling proceeds normally. No special midnight trigger needed — the existing `AppLifecycleListener` + `Timer.periodic` midnight reset in `HomeScreen` already handles the day transition.

### Notification Content (D-09)

- **D-09:** Static notification copy:
  - **Title:** "Drinky Drinky"
  - **Body:** "Time to drink water! 💧"
  - Android channel: `id: 'hydration_reminders'`, `name: 'Hydration Reminders'`, importance: high.

### Architecture (D-10)

- **D-10:** Create a `NotificationService` singleton class (not a Riverpod provider) at `lib/core/services/notification_service.dart`. It wraps `FlutterLocalNotificationsPlugin` and exposes:
  - `initialize()` — called once in `main.dart` after `WidgetsFlutterBinding.ensureInitialized()`
  - `scheduleWindow(UserSettingsEntity settings)` — cancel all + compute + schedule 4-day window
  - `cancelAll()` — called when goal is reached
  - `requestPermission()` — calls `permission_handler` and returns `PermissionStatus`
  - `permissionStatus` — getter for current status

  Accessed via `ref.read` from widgets (not a `@riverpod` provider — notifications are imperative, not reactive).

### Claude's Discretion

- Exact `NotificationDetails` payload (large icon, sound, vibration pattern) — use platform defaults
- iOS-specific `DarwinNotificationDetails` options (badge, alert, sound) — set all to `true` for standard behavior
- Android `AndroidNotificationDetails.priority` — use `Priority.high`
- `permissionScreenShown` SharedPreferences key name
- Whether to use `permission_handler` or `flutter_local_notifications` native permission request (`requestPermissionsFromUser()`) — either is fine, planner should pick based on research
- Notification ID assignment for individual slots (sequential int, modulo safe)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — NOTF-01, NOTF-02, NOTF-03 (3 requirements this phase must satisfy)
- `.planning/ROADMAP.md` — Phase 5 section: goal, success criteria (4 SC), mode

### Existing Code — Settings & Data Layer
- `lib/data/database/tables/user_settings_table.dart` — `UserSettings` Drift table with all notification fields: `notificationIntervalMinutes`, `dndStartHour`, `dndStartMinute`, `dndEndHour`, `dndEndMinute`, `dndEnabled`
- `lib/data/database/entities/user_settings_entity.dart` — `UserSettingsEntity` Freezed model (same fields)
- `lib/core/providers/stream_providers.dart` — `userSettingsProvider` (keepAlive) for watching settings reactively
- `lib/presentation/screens/settings_screen.dart` — Notifications card with interval slider and DND fields (reference for where to add the permission-denied banner, D-03)

### Existing Code — Home Screen Pattern
- `lib/presentation/screens/home_screen.dart` — `AppLifecycleListener` and `Timer.periodic` midnight reset patterns (D-05, D-07, D-08). Reference for `ref.listen` on providers and `ConsumerStatefulWidget` lifecycle.

### Stack Reference
- `CLAUDE.md` — Tech Stack table. Notification packages NOT yet in `pubspec.yaml` and must be added:
  - `flutter_local_notifications: ^21.0.0`
  - `timezone: ^0.11.0`
  - `flutter_timezone: ^5.1.0`
  - `permission_handler: ^12.0.3`
  - Also: `compileSdk: 36` required on Android (check `android/app/build.gradle`)
  - iOS: Register `UNUserNotificationCenterDelegate` in `AppDelegate.swift`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppLifecycleListener` in `HomeScreen` — already wired for foreground resume detection; Phase 5 adds a `scheduleWindow()` call inside the same `_handleLifecycleChange` method.
- `userSettingsProvider` (`keepAlive: true` stream) — provides `UserSettingsEntity` reactively; `NotificationService.scheduleWindow(settings)` uses this directly.
- `SharedPreferences` — already in `pubspec.yaml` (used for nothing yet in code, but available); used by Phase 5 for `permissionScreenShown` flag.
- `Timer.periodic` midnight reset in `HomeScreen` — triggers day transition; Phase 5 does NOT need a new timer since foreground reschedule handles next-day recovery.

### Established Patterns
- `ConsumerStatefulWidget` + `ref.listen` for reactive side effects — `HomeScreen` uses this for state management; Phase 5 adds a `ref.listen` on `todayTotalProvider` for goal-reached detection (D-07).
- Layer-first folders: new service at `lib/core/services/notification_service.dart`; new screen at `lib/presentation/screens/permission_screen.dart`.
- `withValues(alpha:)` not `withOpacity()` (deprecated in Flutter 3.44.1).

### Integration Points
- `main.dart` — add `NotificationService.initialize()` call after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp()`. Also initialize `timezone` database here (`tz.initializeTimeZones()` + `flutter_timezone` for device timezone).
- `GoRouter` — add `/permission` route to the shell (or as a top-level route). On first launch, router guard redirects to `/permission` before `/home`; after permission screen is dismissed, navigate to `/home`.
- `SettingsScreen` Notifications card — add permission-denied banner (D-03) as the first child of the card, shown conditionally when `permissionStatus.isDenied`.
- `HomeScreen` — add `ref.listen(todayTotalProvider, ...)` for goal-reached detection (D-07); add `NotificationService.scheduleWindow(settings)` in `_handleLifecycleChange` for foreground reschedule (D-05).

</code_context>

<specifics>
## Specific Ideas

- Pre-permission screen navigation: use `SharedPreferences.getBool('permissionScreenShown') ?? false` as the gate; write `true` after the screen is dismissed (regardless of grant/deny).
- DND overnight window example: if `dndStartHour = 23` and `dndEndHour = 7`, a slot at 01:00 is inside DND. Guard: `isInDnd(slot)` returns true if `endHour < startHour` (overnight) and `slot.hour >= startHour || slot.hour < endHour`, OR if `endHour >= startHour` (same-day window) and `slot.hour >= startHour && slot.hour < endHour`.
- iOS 64-slot math: 60-min interval, 16 active hours/day (24 − 8 DND) = 16 slots/day × 4 days = 64 slots exactly at the limit. If interval is shorter (e.g., 30 min), 32 slots/day × 2 days = 64. The window calculation should cap at 64 slots total, not 4 fixed days.
- Notification ID strategy: use sequential IDs starting at 1000 (avoids collision with any future IDs from other features). Each scheduled slot gets a unique ID.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 5-notifications*
*Context gathered: 2026-06-05*
