# Domain Pitfalls

**Domain:** Flutter hydration tracker / water reminder app (offline-first, iOS + Android)
**Stack:** Flutter + Riverpod + Drift + flutter_local_notifications
**Researched:** 2026-06-03

---

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or broken core functionality.

---

### Pitfall 1: Android OEM Background Killing Breaks Reminder Notifications

**What goes wrong:** Scheduled notifications silently stop firing on Samsung, Xiaomi, Huawei, OnePlus, Oppo, and Vivo devices. These OEMs aggressively kill background processes and AlarmManager alarms. The app works perfectly on Pixel/stock Android during development, then fails for 60-70% of real-world Android users.

**Why it happens:** OEMs add proprietary battery optimization layers that override standard Android AlarmManager behavior. Samsung limits alarms to 500 via AlarmManager. Xiaomi, Huawei, and OnePlus terminate background work even when the app follows Android best practices.

**Consequences:** Users stop receiving hydration reminders, which is the core value proposition. The app appears broken. One-star reviews ensue. This is especially devastating because hydration reminders are the primary engagement mechanism.

**Prevention:**
- Test on at least Samsung and Xiaomi physical devices (not just emulators)
- Add an in-app screen that detects the OEM and guides users to disable battery optimization for the app (link to device-specific settings using `app_settings` or equivalent)
- Use `android_alarm_manager_plus` or `USE_EXACT_ALARM` permission where appropriate
- Consider fallback to inexact alarms (`setAndAllowWhileIdle`) which survive Doze mode better
- Document the OEM issue in user-facing FAQ/help

**Detection:** Users report "notifications stopped working" but the app shows them as scheduled. Test on Samsung Galaxy and Xiaomi Redmi devices early.

**Confidence:** HIGH -- well-documented across dontkillmyapp.com and flutter_local_notifications issue tracker.

**Phase relevance:** Must be addressed in the notification scheduling phase, not deferred.

---

### Pitfall 2: Android 14+ Exact Alarm Permission Revocation Cancels All Scheduled Notifications

**What goes wrong:** On Android 14+, the `SCHEDULE_EXACT_ALARM` permission is not pre-granted for new installs. When a user revokes this permission (which they can do at any time from Settings), all future exact alarms are cancelled and the app is stopped. On app restart, `canScheduleExactAlarms()` returns the cached (stale) value for the lifetime of the app process.

**Why it happens:** Android 14 tightened exact alarm restrictions. Apps must declare `SCHEDULE_EXACT_ALARM` in the manifest and the user must grant it. Unlike Android 12-13 where it was auto-granted, Android 14 fresh installs start with the permission denied.

**Consequences:** All reminder notifications vanish silently. The app has no way to know they were cancelled until it checks on next launch. Users think the app is broken.

**Prevention:**
- Check `canScheduleExactAlarms()` before every scheduling operation
- Implement a `BroadcastReceiver` for `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` to detect revocation and reschedule
- Fall back gracefully to inexact alarms when exact permission is denied -- for a hydration reminder, a 5-10 minute drift is acceptable
- Show a non-intrusive banner when exact alarm permission is missing, explaining why it matters
- Consider using `USE_EXACT_ALARM` instead (auto-granted, cannot be revoked) but only if the app qualifies as an alarm/timer app per Google Play policy

**Detection:** Test by toggling exact alarm permission in Android Settings while notifications are scheduled. Verify the app recovers on next launch.

**Confidence:** HIGH -- verified against official Android developer documentation and flutter_local_notifications changelog (v14.1.0+).

**Phase relevance:** Notification scheduling phase. Must be part of the initial notification architecture, not bolted on later.

---

### Pitfall 3: iOS 64-Notification Hard Limit Silently Drops Reminders

**What goes wrong:** iOS enforces a hard limit of 64 pending local notifications per app. If the app schedules hourly reminders across a "quiet hours" aware schedule, it can easily exceed this limit. Notifications beyond 64 are silently discarded -- no error, no warning, no callback.

**Why it happens:** This is a documented iOS platform limitation. A hydration app with reminders every 30 minutes during a 14-hour waking window = 28 notifications/day. Scheduling even 3 days ahead hits the limit (84 notifications).

**Consequences:** Users stop receiving reminders after a few days. The app has no signal that notifications were dropped. Especially problematic if the app tries to pre-schedule a week of notifications.

**Prevention:**
- Never pre-schedule more than 2 days of notifications at a time
- Reschedule the next batch when the app opens or when a notification is delivered (using the notification response callback)
- Track how many notifications are pending using `pendingNotificationRequests()` before scheduling new ones
- Use a rolling window: schedule next N notifications, replenish when the app opens
- Consider a daily "refill" approach: each day on app open, cancel old notifications and schedule the next 48 hours

**Detection:** Call `pendingNotificationRequests()` in debug mode and log the count. If it approaches 64, the scheduling strategy is wrong.

**Confidence:** HIGH -- Apple documentation and flutter_local_notifications README both confirm the 64 limit.

**Phase relevance:** Notification scheduling phase. The scheduling algorithm must be designed around this constraint from the start.

---

### Pitfall 4: Drift DateTime Storage Mode Decision Cannot Be Changed Later Without Migration Pain

**What goes wrong:** Drift stores `DateTime` as Unix timestamps (seconds) by default, which loses timezone information and sub-second precision. If the app launches with the default and later needs timezone-aware date storage (e.g., for correct midnight resets across timezone changes), switching to ISO-8601 text storage requires a data migration that touches every table with a datetime column.

**Why it happens:** The storage mode (`store_date_time_values_as_text`) is set globally in `build.yaml`. Drift's default (Unix timestamps) was kept for backward compatibility but the Drift team now recommends ISO-8601 for new projects. The migration involves `ALTER TABLE` operations with column transformers for every datetime column.

**Consequences:** Either commit to a painful migration or live with timezone-unaware date storage forever. With Unix timestamps, `drift always returns a non-UTC value` even when UTC dates are stored, making timezone-correct queries unreliable.

**Prevention:**
- Set `store_date_time_values_as_text: true` in `build.yaml` from day one
- This is a "decide once at project start" decision -- changing later is possible but costly
- All datetime columns then store ISO-8601 strings with timezone offset, which makes midnight-reset queries correct across timezone changes

**Detection:** Check `build.yaml` before writing any table definitions. If `store_date_time_values_as_text` is not set, you are using the lossy default.

**Confidence:** HIGH -- verified against Drift official documentation and DateTime migration guide.

**Phase relevance:** Database setup phase. Must be configured in the very first Drift setup before any data is written.

---

### Pitfall 5: Midnight Reset Logic Fails on Timezone Change (Travel, DST)

**What goes wrong:** The app uses `DateTime.now()` to determine "today" for daily aggregate calculations. When the user travels across timezones or DST transitions occur, "today" shifts but stored entries remain in the old timezone context. The daily progress resets at the wrong time, entries appear on the wrong day, or the same entries are counted in two different days.

**Why it happens:** `DateTime.now()` returns local device time, which shifts when the user changes timezone. If entries are stored with Unix timestamps (see Pitfall 4), they have no timezone context. Even with ISO-8601 storage, the definition of "midnight" changes. DST transitions create days that are 23 or 25 hours long.

**Consequences:** User drinks 2L, flies to a new timezone, and their progress shows 0 or shows yesterday's total. Calendar view shows incorrect color-coding. Daily goal tracking becomes unreliable for travelers.

**Prevention:**
- Store all timestamps in UTC in the database
- Define "day boundaries" in the user's local timezone at the time of each entry, and store the local date (YYYY-MM-DD) as a separate column alongside the UTC timestamp
- Use the `timezone` + `flutter_timezone` packages to get the correct IANA timezone identifier, not just an offset
- Query daily aggregates by the stored local-date column, not by computing date ranges from UTC timestamps
- Initialize the `timezone` database on app startup (`initializeTimeZones()`) -- forgetting this causes crashes
- The `timezone` package does NOT detect the device's timezone -- use `flutter_timezone` for `FlutterTimezone.getLocalTimezone()` and then convert via `tz.getLocation()`

**Detection:** Test by changing device timezone in simulator/emulator settings while the app has data. Verify calendar view and daily progress remain consistent.

**Confidence:** HIGH -- well-documented class of bugs across date-handling applications.

**Phase relevance:** Database schema design phase AND daily progress calculation phase. The schema must include a local-date column from day one, and the Riverpod providers must use it for aggregation.

---

## Moderate Pitfalls

Mistakes that cause significant debugging time or user-facing bugs but are recoverable.

---

### Pitfall 6: Using ref.read() Instead of ref.watch() in build Methods

**What goes wrong:** Developer uses `ref.read(dailyProgressProvider)` in a widget's `build` method to "optimize" by avoiding rebuilds. The daily progress value changes (user logs water) but the UI does not update. The progress bar appears stuck.

**Why it happens:** Riverpod's `ref.read()` returns the current value without subscribing to changes. The Riverpod documentation explicitly flags this as an anti-pattern: "Do not use ref.read for optimizations when a value is guaranteed not to change. Relying on read for such optimizations is brittle."

**Prevention:**
- Use `ref.watch()` in all `build` methods, always
- Use `ref.read()` only in event handlers (`onPressed`, `onTap`, etc.)
- Lint rule: consider enabling `riverpod_lint` package which catches this at analysis time

**Detection:** UI does not update when state changes. Search codebase for `ref.read` inside `build` methods.

**Confidence:** HIGH -- official Riverpod documentation anti-pattern.

**Phase relevance:** Every UI phase. Establish the pattern in the first widget that reads state.

---

### Pitfall 7: Riverpod autoDispose Kills State During Navigation

**What goes wrong:** A provider is marked `.autoDispose` and holds the daily water intake state. When the user navigates to Settings and back, the provider disposes and the state is lost. The progress bar resets to 0 until the provider refetches from the database.

**Why it happens:** `.autoDispose` destroys state when all listeners are removed. Navigating away from a screen removes widget listeners. If the provider doesn't persist state (e.g., it only holds an in-memory aggregate), the state is lost.

**Consequences:** Flickering UI -- progress momentarily shows 0 or loading state when returning to the home screen. Bad UX for a frequently-navigated utility app.

**Prevention:**
- For the core daily progress provider: do NOT use autoDispose. This state should persist for the app's lifetime
- Use `ref.keepAlive()` if autoDispose is needed for other reasons (e.g., the provider has parameters via `.family`)
- Separate ephemeral UI state (autoDispose OK) from persistent domain state (no autoDispose)
- If the provider fetches from Drift, the data is recoverable, but the loading flash is still a UX problem -- consider `ref.keepAlive()` with a cache duration

**Detection:** Navigate away from the home screen and back. If the progress bar flickers or briefly shows 0/loading, the provider is being disposed.

**Confidence:** HIGH -- well-known Riverpod lifecycle behavior, documented in official docs.

**Phase relevance:** State management architecture phase. Decide which providers are long-lived vs. ephemeral before building UI.

---

### Pitfall 8: Drift Schema Migration Not Tested, Data Lost on App Update

**What goes wrong:** Developer adds a new column (e.g., `drink_type`) to the water entries table, bumps `schemaVersion`, but writes the migration incorrectly or forgets to handle the `onUpgrade` callback. Existing user data is lost or the app crashes on update because the migration fails silently.

**Why it happens:** Drift's manual migrations are error-prone. Developers often test by deleting the app and reinstalling (which creates a fresh database) rather than upgrading from the old schema. The Drift docs explicitly warn: "Writing migrations manually is error-prone and can lead to data loss."

**Consequences:** Users who update the app lose their hydration history. For a tracking app, this is catastrophic -- historical data is the user's primary reason to keep using the app.

**Prevention:**
- Use `dart run drift_dev make-migrations` (guided migrations) from the very first schema version, not just when you need a migration
- Generate and run Drift's auto-generated migration tests: `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`
- Call `validateDatabaseSchema()` in the `beforeOpen` callback to catch schema mismatches at runtime
- Never test migrations by deleting the app -- always test by upgrading from version N to N+1
- During development, delete-and-reinstall is fine, but write the migration before releasing

**Detection:** Run `validateDatabaseSchema()` on every app open. If it throws, the migration is broken. Run generated migration tests in CI.

**Confidence:** HIGH -- Drift official documentation recommends this workflow explicitly.

**Phase relevance:** Database setup phase. Set up the migration infrastructure from the first schema version, not retroactively.

---

### Pitfall 9: Notification Permission Request on App Launch Causes Denial

**What goes wrong:** The app requests notification permission immediately on first launch (during initialization). The user has no context for why notifications matter and taps "Don't Allow." iOS remembers this choice and does not show the prompt again -- the user must now go to Settings manually to enable notifications.

**Why it happens:** Developers call `requestPermissions()` during `flutter_local_notifications` initialization. iOS gives you exactly one chance to show the system permission dialog. Android 13+ is slightly more forgiving but still creates friction.

**Consequences:** The user never receives hydration reminders (the app's core value proposition) and doesn't know how to fix it. The app becomes a manual-only tracker with no engagement loop.

**Prevention:**
- Initialize flutter_local_notifications with all permissions set to false: `DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false)`
- Show a pre-permission screen explaining why notifications matter ("We'll remind you to drink water throughout the day") with a "Enable Reminders" button
- Only call `requestPermissions()` when the user taps that button or explicitly sets up a reminder schedule
- If permission was denied, detect it and show a "Notifications are disabled" banner with a link to app Settings via `openAppSettings()`

**Detection:** Check notification permission status on app open. If denied, show a non-intrusive recovery UI.

**Confidence:** HIGH -- well-documented iOS permission pattern, standard mobile UX best practice.

**Phase relevance:** Onboarding/settings phase. Permission request flow must be designed before building the notification feature.

---

### Pitfall 10: DND Window Logic Conflicts with Platform DND

**What goes wrong:** The app implements its own "Do Not Disturb" window (user-configurable quiet hours, e.g., 10pm-7am) to suppress reminders. But the developer also sets `bypassDnd: true` on the notification channel to ensure reminders always fire. Result: notifications blast through the user's system-level DND/Sleep Focus mode at 3am because the app's custom DND window and the platform's DND are orthogonal.

**Why it happens:** Confusion between two separate DND concepts: (1) the app's quiet hours feature, which suppresses scheduling, and (2) the platform's system-wide DND mode, which suppresses delivery. Setting `bypassDnd: true` makes notifications pierce system DND, which is almost never what a hydration app should do.

**Consequences:** User is woken up at 3am by a "Drink water!" notification. Immediate uninstall.

**Prevention:**
- Never set `bypassDnd: true` or `channelBypassDnd: true` for a hydration reminder. This is for critical alerts (medical devices, security alarms), not water reminders
- Implement the app's quiet hours by simply not scheduling notifications during the DND window -- this is a scheduling-time decision, not a delivery-time decision
- Let the platform's DND work as the user configured it -- do not fight it
- When rescheduling notifications (rolling window from Pitfall 3), skip time slots that fall within the user's configured quiet hours

**Detection:** Set system DND on, enable app reminders with no quiet hours. If notifications arrive during system DND, `bypassDnd` is incorrectly set.

**Confidence:** HIGH -- flutter_local_notifications API documentation describes bypassDnd explicitly.

**Phase relevance:** Notification scheduling phase. The quiet hours feature must be implemented as a scheduling filter, not a delivery-time override.

---

## Minor Pitfalls

Cause friction during development but are straightforward to fix.

---

### Pitfall 11: Missing Android Manifest Declarations for Scheduled Notifications

**What goes wrong:** Notifications work in debug mode but fail silently in release builds. Scheduled notifications never fire. No error is thrown.

**Why it happens:** flutter_local_notifications v16+ only declares bare minimum permissions in its own manifest. Apps must explicitly add `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`, and receiver declarations in their own `AndroidManifest.xml`. Debug builds may work due to different build configurations.

**Prevention:**
- Follow the flutter_local_notifications setup guide completely, including all manifest entries
- Add `RECEIVE_BOOT_COMPLETED` for rescheduling after device reboot
- Test in release mode on a physical device before considering notifications "done"

**Confidence:** HIGH -- documented in flutter_local_notifications README.

---

### Pitfall 12: ProGuard/R8 Strips Notification Icons in Release Builds

**What goes wrong:** Notification icons show as a blank square or default Android icon in release builds, even though they display correctly in debug builds.

**Why it happens:** R8 code shrinking discards drawable resources it thinks are unused. Notification icon resources are referenced by string name at runtime, not by direct code reference, so R8 cannot detect the usage.

**Prevention:**
- Add a `res/raw/keep.xml` file that declares notification icon drawables as kept
- Test notifications in release builds before shipping

**Confidence:** HIGH -- documented in flutter_local_notifications known issues.

---

### Pitfall 13: timezone Package Not Initialized Before Notification Scheduling

**What goes wrong:** App crashes with an uninitialized error when trying to schedule a notification using `zonedSchedule()`. Or worse, notifications are scheduled in UTC instead of local time without any error.

**Why it happens:** `flutter_local_notifications`'s `zonedSchedule` requires `TZDateTime` objects from the `timezone` package. The `timezone` database must be initialized with `tz.initializeTimeZones()` before any scheduling. Additionally, `flutter_timezone` must be used to get the device's current IANA timezone since the `timezone` package defaults to UTC.

**Prevention:**
- Call `tz.initializeTimeZones()` in `main()` before `runApp()`
- Call `FlutterTimezone.getLocalTimezone()` and set `tz.setLocalLocation(tz.getLocation(localTimezone))` before scheduling
- Wrap this in a startup service that runs before any notification code

**Confidence:** HIGH -- documented in both flutter_local_notifications and timezone package docs.

**Phase relevance:** App initialization phase.

---

### Pitfall 14: Family Provider Parameter Identity Causes Provider Leaks

**What goes wrong:** Using a `Provider.family` with a `DateTime` parameter for "today's data" creates a new provider instance for every unique DateTime value. Over days of app usage, old provider instances accumulate in memory because Riverpod does not automatically garbage-collect family instances (unless autoDispose is used).

**Why it happens:** Riverpod family providers cache instances by parameter equality. `DateTime` objects with different millisecond values create different cache keys. Even `DateTime(2024, 1, 15)` and another `DateTime(2024, 1, 15)` are equal, but if constructed with `DateTime.now()`, each call produces a unique key.

**Prevention:**
- For date-based family providers, normalize parameters to `DateTime(year, month, day)` with no time component
- Or use a `String` parameter like "2024-01-15" which has trivial equality
- Use `.autoDispose` on family providers that are date-parameterized, so old days are cleaned up
- Prefer a single "current day" provider that invalidates on day change, rather than a family

**Detection:** Monitor memory usage over multiple days of app usage. Check Riverpod DevTools for provider count growth.

**Confidence:** MEDIUM -- based on Riverpod documentation on family providers and equality semantics.

---

### Pitfall 15: Drift beforeOpen Callback Runs on Every App Launch

**What goes wrong:** Developer puts data seeding or migration logic in `beforeOpen` without checking `details.wasCreated` or `details.hadUpgrade`. Default drink presets are re-inserted on every app launch, duplicating data or overwriting user customizations.

**Why it happens:** `beforeOpen` fires every time the database opens, not just during creation or migration. It is commonly confused with `onCreate`.

**Prevention:**
- Always check `details.wasCreated` before inserting seed data
- Always check `details.hadUpgrade` before running post-migration fixups
- Use `beforeOpen` only for connection-level setup (e.g., `PRAGMA foreign_keys = ON`)

**Confidence:** HIGH -- documented in Drift migration docs.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| Database schema design | Pitfall 4 (DateTime storage mode), Pitfall 5 (timezone in schema) | Set `store_date_time_values_as_text: true` from day one. Add `local_date` TEXT column alongside UTC timestamps. |
| Database migration infra | Pitfall 8 (untested migrations) | Run `make-migrations` from schema v1. Add `validateDatabaseSchema()` to `beforeOpen`. |
| Notification scheduling | Pitfalls 1, 2, 3, 10 (OEM killing, exact alarm revocation, iOS 64 limit, DND conflict) | Implement rolling-window scheduling. Fall back to inexact alarms. Never bypass system DND. Test on Samsung/Xiaomi hardware. |
| Notification permissions | Pitfall 9 (premature permission request) | Defer permission request to user-initiated action. Show contextual pre-permission screen. |
| State management setup | Pitfalls 6, 7, 14 (ref.read in build, autoDispose, family leaks) | Establish ref.watch-in-build pattern early. Keep core providers alive. Normalize family parameters. |
| Daily progress / aggregates | Pitfall 5 (midnight reset timezone) | Query by stored local-date column, not computed UTC ranges. |
| App initialization | Pitfall 13 (timezone init), Pitfall 15 (beforeOpen misuse) | Initialize timezone in main(). Guard beforeOpen with wasCreated/hadUpgrade checks. |
| Release / production build | Pitfalls 11, 12 (manifest, R8 stripping) | Test in release mode on physical device. Add ProGuard keep rules. |

---

## Sources

- flutter_local_notifications pub.dev package documentation and changelog (v21.0.0)
- Drift official documentation: migrations, DateTime storage, beforeOpen callbacks
- Riverpod official documentation: ref.read vs ref.watch, autoDispose, family providers, keepAlive
- Android developer documentation: exact alarm scheduling, SCHEDULE_EXACT_ALARM vs USE_EXACT_ALARM
- Apple developer documentation: 64 pending notification limit
- dontkillmyapp.com: Android OEM background process killing
- timezone and flutter_timezone package documentation
