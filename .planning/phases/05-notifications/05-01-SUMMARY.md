---
phase: 05-notifications
plan: 01
subsystem: notifications
tags: [flutter_local_notifications, timezone, permission_handler, flutter_timezone, shared_preferences, go_router, riverpod]

# Dependency graph
requires:
  - phase: 03-settings-and-presets
    provides: UserSettingsEntity with notificationIntervalMinutes, dndStartHour/Minute, dndEndHour/Minute, dndEnabled fields; SettingsScreen notifications card
  - phase: 02-core-tracking-ui
    provides: HomeScreen with AppLifecycleListener, ref.listen patterns, totalMlForDateProvider

provides:
  - NotificationService singleton at lib/core/services/notification_service.dart
  - PermissionScreen at lib/presentation/screens/permission_screen.dart (first-launch onboarding)
  - Rolling-window scheduled hydration reminders respecting DND and iOS 64-slot limit
  - GoRouter first-launch redirect guard with SharedPreferences gate
  - Goal-reached automatic notification cancellation via ref.listen in HomeScreen

affects: [future-phases, any-phase-touching-notifications, any-phase-touching-routing]

# Tech tracking
tech-stack:
  added:
    - flutter_local_notifications 21.0.0 (notification scheduling plugin)
    - timezone 0.11.0 (TZDateTime for DST-safe scheduling)
    - flutter_timezone 5.1.0 (device timezone detection via TimezoneInfo)
    - permission_handler 12.0.3 (permissionGranted() status check + openAppSettings())
    - shared_preferences 2.5.5 (drinky_permissionScreenShown flag)
  patterns:
    - Plain Dart singleton accessed via static instance field (not Riverpod provider) for imperative services
    - GoRouter async redirect with FutureOr<String?> and loop-prevention guard
    - Plugin-native permission request (plugin API) vs. permission_handler only for openAppSettings()
    - Rolling-window slot algorithm capped at 64 with 30-day safety valve
    - Overnight-aware DND check using total-minutes comparison

key-files:
  created:
    - lib/core/services/notification_service.dart
    - lib/presentation/screens/permission_screen.dart
  modified:
    - pubspec.yaml (4 new packages added)
    - android/app/src/main/AndroidManifest.xml (4 permissions + 3 receivers)
    - ios/Runner/AppDelegate.swift (import UserNotifications + delegate registration)
    - lib/main.dart (async + timezone init + NotificationService.initialize())
    - lib/core/router/app_router.dart (async redirect + /permission GoRoute)
    - lib/presentation/screens/home_screen.dart (onResume reschedule + ref.listen goal-reached)
    - lib/presentation/screens/settings_screen.dart (permission banner + 3 reschedule triggers)
    - test/widget_test.dart (SharedPreferences mock for redirect bypass)

key-decisions:
  - "NotificationService is a plain Dart singleton (not @riverpod) — notifications are imperative side effects, not reactive data streams; accessed via NotificationService.instance directly from widgets"
  - "Plugin-native permission request API (AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission, IOSFlutterLocalNotificationsPlugin.requestPermissions) for the prompt; permission_handler used only for permissionGranted() status check on Android and AppSettings.openAppSettings()"
  - "FlutterTimezone.getLocalTimezone() returns TimezoneInfo object with .identifier property (not String) — use tzInfo.identifier with tz.getLocation()"
  - "FlutterLocalNotificationsPlugin.initialize() takes named parameter 'settings:' (breaking change in v21.0.0) — positional form removed"
  - "AppSettings.openAppSettings() does not exist in permission_handler 12.x — use top-level openAppSettings() function instead"
  - "Rolling window capped at 64 slots (iOS hard limit) with dayOffset > 30 safety valve; slot IDs start at 1000 to avoid collision with future features"
  - "iOS 'as? UNUserNotificationCenterDelegate' optional cast avoids compile error — FlutterAppDelegate already conforms, no extra protocol declaration needed"

patterns-established:
  - "Singleton service pattern: class Foo { Foo._(); static final Foo instance = Foo._(); }"
  - "GoRouter async redirect: guard matchedLocation == '/permission' to prevent redirect loop; SharedPreferences check on every navigation event (cached after first disk read)"
  - "Permission check split: plugin-native for prompt; permission_handler for status check (Android) and openAppSettings()"
  - "DND check: total-minutes comparison handles overnight windows and zero-width edge case"

requirements-completed: [NOTF-01, NOTF-02, NOTF-03]

# Metrics
duration: 8min
completed: 2026-06-05
---

# Phase 5 Plan 01: Notifications Summary

**Scheduled hydration reminders with rolling 64-slot window, DND-aware TZDateTime scheduling, first-launch PermissionScreen, and goal-reached auto-stop via ref.listen in HomeScreen**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-05T15:09:32Z
- **Completed:** 2026-06-05T15:17:59Z
- **Tasks:** 4 (+ 1 auto-fix commit)
- **Files modified:** 9

## Accomplishments

- NotificationService singleton with rolling-window algorithm scheduling up to 64 TZDateTime slots respecting interval, DND (overnight-aware), and the iOS hard limit
- First-launch PermissionScreen with grant/skip flow, D-02 SnackBar confirmation, and SharedPreferences gate controlling GoRouter async redirect
- Goal-reached auto-stop: ref.listen on totalMlForDateProvider fires cancelAll() when total crosses dailyTargetMl (crossing check prevents repeated calls)
- Three reschedule triggers wired: foreground resume (AppLifecycleListener.onResume), interval slider onChangeEnd, DND toggle/time picker changes
- D-03 permission-denied banner in SettingsScreen with openAppSettings() button

## Task Commits

Each task was committed atomically:

1. **Task 1: Add packages and platform configuration** - `6c6a037` (feat)
2. **Task 2: NotificationService singleton + main.dart timezone init** - `ef1d19d` (feat)
3. **Task 3: PermissionScreen + GoRouter first-launch redirect** - `fa6c6cd` (feat)
4. **Task 4: HomeScreen + SettingsScreen integration** - `1de9258` (feat)
5. **Auto-fix: widget_test.dart for GoRouter async redirect** - `322e327` (fix)

## Files Created/Modified

- `lib/core/services/notification_service.dart` — NotificationService singleton (initialize, requestPermission, permissionGranted, cancelAll, scheduleWindow, _isInDnd)
- `lib/presentation/screens/permission_screen.dart` — First-launch permission explanation screen
- `pubspec.yaml` — Added flutter_local_notifications, timezone, flutter_timezone, permission_handler, shared_preferences
- `android/app/src/main/AndroidManifest.xml` — RECEIVE_BOOT_COMPLETED, VIBRATE, POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM; ScheduledNotificationReceiver, ScheduledNotificationBootReceiver, ActionBroadcastReceiver
- `ios/Runner/AppDelegate.swift` — `import UserNotifications` + `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate`
- `lib/main.dart` — Made async; tz.initializeTimeZones(), FlutterTimezone.getLocalTimezone().identifier, tz.setLocalLocation(), NotificationService.instance.initialize()
- `lib/core/router/app_router.dart` — async redirect callback with loop guard; /permission GoRoute as top-level route before StatefulShellRoute
- `lib/presentation/screens/home_screen.dart` — _rescheduleNotifications() on onResume; ref.listen goal-reached cancelAll()
- `lib/presentation/screens/settings_screen.dart` — _permissionDenied + initState/_checkPermission; permission banner; scheduleWindow calls after 3 trigger events
- `test/widget_test.dart` — SharedPreferences.setMockInitialValues for redirect bypass

## Decisions Made

- **NotificationService as singleton not Riverpod provider:** Notifications are imperative side effects (schedule/cancel), not reactive streams. Singleton avoids Riverpod lifecycle complexity for a service that must be accessed from both widget callbacks and initState.
- **Plugin-native permission request:** Official flutter_local_notifications docs recommend `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()` over `permission_handler` for the prompt. `permission_handler` is kept for `openAppSettings()` and Android status check.
- **Rolling window capped at 64:** iOS hard limit. Algorithm walks days (offset 0..30 safety valve) collecting slots until 64 are scheduled. Interval slider range (5–240 min) means worst case at 5 min is 192 slots/day — the cap stops at 64 regardless.
- **GoRouter /permission outside StatefulShellRoute:** Placing it as a sibling before the shell ensures the onboarding screen has no NavigationBar. The loop-prevention guard on `matchedLocation == '/permission'` is required because GoRouter evaluates redirect on every navigation event.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FlutterLocalNotificationsPlugin.initialize() requires named 'settings:' parameter**
- **Found during:** Task 2 (NotificationService creation)
- **Issue:** Called `_plugin.initialize(const InitializationSettings(...))` with positional argument; v21.0.0 requires `settings:` named parameter
- **Fix:** Changed to `_plugin.initialize(settings: const InitializationSettings(...))`
- **Files modified:** lib/core/services/notification_service.dart
- **Verification:** `fvm flutter analyze` exited 0
- **Committed in:** ef1d19d (Task 2 commit)

**2. [Rule 1 - Bug] FlutterTimezone.getLocalTimezone() returns TimezoneInfo, not String**
- **Found during:** Task 2 (main.dart modification)
- **Issue:** PATTERNS.md showed String-based usage; actual API in v5.1.0 returns `TimezoneInfo` object; `tz.getLocation(timezoneName)` fails with type mismatch
- **Fix:** Changed to `final tzInfo = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(tzInfo.identifier));`
- **Files modified:** lib/main.dart
- **Verification:** `fvm flutter analyze` exited 0
- **Committed in:** ef1d19d (Task 2 commit)

**3. [Rule 1 - Bug] AppSettings.openAppSettings() does not exist — use top-level openAppSettings()**
- **Found during:** Task 4 (SettingsScreen modification)
- **Issue:** Plan specified `AppSettings.openAppSettings()` but permission_handler 12.x exports a top-level `openAppSettings()` function — no `AppSettings` class
- **Fix:** Changed `AppSettings.openAppSettings()` to `openAppSettings()`
- **Files modified:** lib/presentation/screens/settings_screen.dart
- **Verification:** `fvm flutter analyze` exited 0
- **Committed in:** 1de9258 (Task 4 commit)

**4. [Rule 1 - Bug] widget_test.dart broke: GoRouter redirect sends first launch to /permission**
- **Found during:** Post-task verification (fvm flutter test)
- **Issue:** Existing test expected 'Drinky Drinky' text on launch; with redirect now active and no SharedPreferences set, app renders PermissionScreen instead
- **Fix:** Added `SharedPreferences.setMockInitialValues({'drinky_permissionScreenShown': true})` before pumping; added extra `pump()` calls to let async redirect resolve
- **Files modified:** test/widget_test.dart
- **Verification:** `fvm flutter test` — all 12 tests pass
- **Committed in:** 322e327

---

**Total deviations:** 4 auto-fixed (all Rule 1 — API signature mismatches between docs/plan and actual package versions)
**Impact on plan:** All fixes were necessary for correct function. No scope creep. Plan intent preserved exactly.

## Issues Encountered

- `FlutterLocalNotificationsPlugin.initialize()` uses named parameter form in v21.0.0 (positional removed in v20.0.0 breaking change) — caught by analyzer, fixed immediately
- `FlutterTimezone.getLocalTimezone()` returns `TimezoneInfo` (not `String`) in v5.1.0 — PATTERNS.md showed the String form which was incorrect; RESEARCH.md Q3 correctly documented `TimezoneInfo.identifier`
- `AppSettings` class absent from permission_handler 12.x — `openAppSettings()` is a top-level function; fixed by dropping the class prefix

## Actual Package Versions Resolved by pub get

| Package | Requested | Resolved |
|---------|-----------|---------|
| flutter_local_notifications | ^21.0.0 | 21.0.0 |
| timezone | ^0.11.0 | 0.11.0 |
| flutter_timezone | ^5.1.0 | 5.1.0 |
| permission_handler | ^12.0.3 | 12.0.3 |
| shared_preferences | ^2.5.5 | 2.5.5 |

All versions matched CLAUDE.md expectations exactly.

## API Notes for Future Reference

- `zonedSchedule()` in v21.0.0: all named parameters — `id:`, `scheduledDate:`, `notificationDetails:`, `androidScheduleMode:`, `title:`, `body:`, `matchDateTimeComponents:`
- `initialize()` in v21.0.0: `settings:` is a named required parameter of type `InitializationSettings`
- `FlutterTimezone.getLocalTimezone()` returns `TimezoneInfo` with `.identifier` (IANA string, e.g. "America/New_York")
- `openAppSettings()` is a top-level function from `package:permission_handler/permission_handler.dart`; no `AppSettings` class

## User Setup Required

None - local notifications require no external service configuration. Android and iOS platform configs are handled by manifest/AppDelegate changes in this plan.

## Next Phase Readiness

Phase 5 is the final phase. All NOTF requirements are satisfied. The app now:
- Sends hydration reminders at the user-configured interval
- Skips reminders during the DND window (including overnight windows)
- Cancels reminders automatically when the daily goal is reached
- Shows a first-launch permission explanation before any system prompt
- Re-schedules on foreground resume and settings changes

---
*Phase: 05-notifications*
*Completed: 2026-06-05*
