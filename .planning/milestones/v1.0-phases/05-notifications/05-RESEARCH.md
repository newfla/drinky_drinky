# Phase 5: Notifications - Research

**Researched:** 2026-06-05
**Domain:** flutter_local_notifications 21.x + timezone + permission_handler + GoRouter redirect
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Show the pre-permission screen on first app launch — before the user sees the Home tab. Persisted with `SharedPreferences` (`bool permissionScreenShown`). On subsequent launches, skip entirely.

**D-02:** After the system permission prompt resolves (grant or deny), show a brief confirmation message before landing on Home:
- Granted: "Reminders enabled! You can adjust them anytime in Settings."
- Denied: "No problem — you can enable reminders later in your device Settings."

**D-03:** If the user has previously denied permission, show a subtle info banner in the Notifications card in `SettingsScreen`. Tapping it opens device Settings via `AppSettings.openAppSettings()`. No modals, no repeated prompts.

**D-04:** Rolling 4-day window approach. On each trigger event: cancel all pending notifications, compute slots for next 4 days (honouring DND and interval), schedule each via `zonedSchedule()`. Cap at 64 slots total.

**D-05:** Trigger events that reschedule: (1) app foreground resume via existing `AppLifecycleListener`, (2) settings change (`onChangeEnd` callback in `SettingsScreen`), (3) permission granted from the permission screen.

**D-06:** DND enforcement is pure Dart computation before scheduling — no system-level DND API.

**D-07:** Goal-reached detection is reactive in `HomeScreen` via `ref.listen(todayTotalProvider, ...)`. When total first crosses `dailyTargetMl`, call `NotificationService.cancelAll()`.

**D-08:** Next-day resume happens automatically via rolling window reschedule on foreground open. No special midnight trigger needed.

**D-09:** Notification content — Title: "Drinky Drinky", Body: "Time to drink water! 💧". Android channel: `id: 'hydration_reminders'`, `name: 'Hydration Reminders'`, importance: high.

**D-10:** `NotificationService` singleton at `lib/core/services/notification_service.dart`. Exposes: `initialize()`, `scheduleWindow(UserSettingsEntity)`, `cancelAll()`, `requestPermission()`, `permissionStatus` getter. Not a `@riverpod` provider.

### Claude's Discretion

- Exact `NotificationDetails` payload (large icon, sound, vibration pattern) — use platform defaults
- iOS-specific `DarwinNotificationDetails` options — set `presentAlert`, `presentBadge`, `presentSound` all `true`
- Android `AndroidNotificationDetails.priority` — use `Priority.high`
- `permissionScreenShown` SharedPreferences key name
- Whether to use `permission_handler` or `flutter_local_notifications` native permission request — research resolves this below (see Q4)
- Notification ID assignment — sequential int starting at 1000

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTF-01 | App sends reminder notifications at the user-configured interval, excluding the DND window and after the daily goal is reached | `zonedSchedule()` API, rolling-window slot algorithm, DND overnight algorithm — all documented below |
| NOTF-02 | App shows a dedicated permission request screen (pre-permission) explaining why notifications are needed before triggering the system prompt | GoRouter redirect pattern, SharedPreferences gate, permission request API — all documented below |
| NOTF-03 | Notifications automatically stop for the remainder of the day once the daily goal is reached | `cancelAll()` API + `ref.listen` on `todayTotalProvider` — documented below |
</phase_requirements>

---

## Summary

Phase 5 adds scheduled hydration reminders to an otherwise complete app. The core complexity is concentrated in three areas: (1) the rolling-window scheduling algorithm that stays within iOS's 64-notification hard limit while respecting DND and the user interval, (2) the two-platform permission flow wired into the existing GoRouter shell, and (3) the goal-reached auto-stop wired into the existing `HomeScreen` reactive pattern.

The good news: the codebase already has almost every supporting structure needed. `AppLifecycleListener`, `ConsumerStatefulWidget` + `ref.listen`, `userSettingsProvider`, `todayTotalProvider`, `SharedPreferences` in pubspec.yaml, and the `onChangeEnd` pattern in `SettingsScreen` are all present. Phase 5 adds the `NotificationService` singleton, the `PermissionScreen`, a GoRouter `redirect` guard, and wires them into existing hooks.

The main platform work is Android manifest additions (receivers, permissions, desugaring) and one Swift line in `AppDelegate.swift`. Everything else is Dart.

**Primary recommendation:** Use `flutter_local_notifications`' native per-platform permission request methods (not `permission_handler`) for the permission prompt itself; keep `permission_handler` for `AppSettings.openAppSettings()` only (the denied-state banner in Settings).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Notification scheduling | App service layer (`NotificationService`) | OS notification system | The app computes slots; the OS delivers them |
| DND enforcement | App service layer (pure Dart) | — | Decided in D-06: no system DND API; filtering happens before `zonedSchedule()` calls |
| Permission request flow | Presentation layer (`PermissionScreen`) | App service layer (`NotificationService.requestPermission()`) | UI owns the flow; service owns the platform call |
| First-launch routing guard | Router layer (`app_router.dart` redirect) | SharedPreferences | GoRouter `redirect` callback reads SP flag; all routing stays in router |
| Goal-reached detection | Presentation layer (`HomeScreen` `ref.listen`) | App service layer (`NotificationService.cancelAll()`) | `HomeScreen` already watches `todayTotalProvider`; side effect is the cancel call |
| Permission-denied banner | Presentation layer (`SettingsScreen` Notifications card) | App service layer (`permissionStatus` getter) | Banner is UI concern; status is queried from service |

---

## Standard Stack

### Core — Packages to Add

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_local_notifications` | `^21.0.0` | Schedule and display local notifications | Flutter Favorite; 7,310 likes; 1.99M downloads; de facto standard for local notifications [VERIFIED: pub.dev] |
| `timezone` | `^0.11.0` | Timezone-aware `TZDateTime` objects | Required by `flutter_local_notifications` for `zonedSchedule()`; official Dart Labs package [VERIFIED: pub.dev] |
| `flutter_timezone` | `^5.1.0` | Retrieve device's local timezone name | Required to initialize `tz.local` from device; the only maintained Flutter plugin for this [VERIFIED: pub.dev] |
| `permission_handler` | `^12.0.3` | `AppSettings.openAppSettings()` for denied banner | Already in CLAUDE.md stack; used only for opening device Settings, not for the permission prompt itself [VERIFIED: pub.dev] |

**Already in pubspec.yaml (no add needed):**
- `shared_preferences` — used for `permissionScreenShown` flag
- `go_router ^17.3.0` — used for `/permission` route and `redirect` guard

**Installation:**
```bash
flutter pub add flutter_local_notifications timezone flutter_timezone permission_handler
```

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_local_notifications` native `requestNotificationsPermission()` | `Permission.notification.request()` from `permission_handler` | Official docs recommend the native approach; `permission_handler` is still needed for `AppSettings.openAppSettings()` so the package is already a dependency — but the prompt itself should use the plugin's own API for better platform integration |
| Rolling-window scheduling | `matchDateTimeComponents: DateTimeComponents.time` (repeating) | Repeating notifications cannot be skipped for DND; rolling-window gives per-slot control |

---

## Package Legitimacy Audit

> slopcheck was unavailable at research time. All packages verified manually via pub.dev official registry.

| Package | Registry | Age | Downloads | Source Repo | Verified | Disposition |
|---------|----------|-----|-----------|-------------|----------|-------------|
| `flutter_local_notifications` | pub.dev | ~8 years | 1.99M | github.com/MaikuB/flutter_local_notifications | Flutter Favorite, dexterx.dev verified publisher, 160/160 pub points | Approved [ASSUMED: slopcheck unavailable] |
| `timezone` | pub.dev | ~6 years | 2.38M | github.com/dart-lang/timezone | labs.dart.dev verified publisher (Dart team), 160/160 pub points | Approved [ASSUMED: slopcheck unavailable] |
| `flutter_timezone` | pub.dev | ~3 years | 627K | github.com/lluismasdeu/flutter_timezone | wolverinebeach.net verified publisher, 160/160 pub points | Approved [ASSUMED: slopcheck unavailable] |
| `permission_handler` | pub.dev | ~6 years | 2.6M | github.com/Baseflow/flutter-permission-handler | baseflow.com verified publisher, 160/160 pub points | Approved [ASSUMED: slopcheck unavailable] |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none — all packages are from verified publishers with multi-year histories and millions of downloads. Manual verification provides high confidence. No `postinstall` equivalent exists in Dart/Flutter package ecosystem.

---

## Architecture Patterns

### System Architecture Diagram

```
App Launch
    |
    v
main.dart
    |-- tz.initializeTimeZones()
    |-- tz.setLocalLocation(FlutterTimezone.getLocalTimezone().identifier)
    |-- NotificationService.initialize()
    |-- runApp()
    |
    v
GoRouter (app_router.dart)
    |
    |-- redirect callback
    |       |-- SharedPreferences.getBool('permissionScreenShown') ?? false
    |       |-- false? --> '/permission'
    |       |-- true?  --> null (no redirect, proceed to initialLocation '/')
    |
    |-- /permission  (PermissionScreen -- outside StatefulShellRoute)
    |       |-- Explain why notifications help
    |       |-- [Grant / Skip] button
    |       |-- NotificationService.requestPermission()
    |       |-- SharedPreferences.setBool('permissionScreenShown', true)
    |       |-- Show D-02 confirmation message
    |       |-- context.go('/') [enter shell]
    |
    |-- StatefulShellRoute (Home | History | Settings tabs)
            |
            |-- HomeScreen (ConsumerStatefulWidget)
            |       |-- AppLifecycleListener.onResume
            |       |       --> NotificationService.scheduleWindow(settings)
            |       |-- ref.listen(todayTotalProvider)
            |               |-- total >= target? --> NotificationService.cancelAll()
            |
            |-- SettingsScreen
                    |-- Notifications card
                    |       |-- [permission-denied banner if isDenied]
                    |       |       --> AppSettings.openAppSettings()
                    |       |-- Interval slider onChangeEnd
                    |               --> NotificationService.scheduleWindow(settings)
                    |-- DND toggle / time pickers onChanged
                            --> NotificationService.scheduleWindow(settings)

NotificationService (singleton)
    |
    |-- scheduleWindow(UserSettingsEntity settings)
    |       |-- cancelAll()
    |       |-- generateSlots(settings) --> List<TZDateTime>
    |       |       |-- iterate days 0..N until 64 slots collected
    |       |       |-- for each candidate slot: isInDnd()? skip : add
    |       |-- for each slot: flnp.zonedSchedule(id, slot, details, ...)
    |
    |-- cancelAll() --> flnp.cancelAll()
    |-- requestPermission() --> per-platform native call
    |-- permissionStatus --> per-platform native check
```

### Recommended Project Structure

```
lib/
├── core/
│   └── services/
│       └── notification_service.dart   # NEW — NotificationService singleton
├── presentation/
│   └── screens/
│       ├── home_screen.dart            # MODIFIED — add ref.listen + scheduleWindow on resume
│       ├── settings_screen.dart        # MODIFIED — add permission banner, scheduleWindow calls
│       └── permission_screen.dart      # NEW — pre-permission explanation + grant/skip flow
└── core/
    └── router/
        └── app_router.dart             # MODIFIED — add /permission route + redirect guard
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timezone-aware scheduling | Custom DateTime offset math | `tz.TZDateTime` + `timezone` package | DST transitions, leap seconds, and timezone database maintenance are non-trivial |
| Platform notification dispatch | Direct platform channel calls | `flutter_local_notifications` | Plugin handles Android channels, iOS UNUserNotificationCenter, manifest receiver wiring, and exact-alarm permission negotiation |
| Device timezone detection | Platform channel to read `TimeZone.getDefault()` | `FlutterTimezone.getLocalTimezone()` | The plugin is 3 lines; rolling your own requires per-platform Swift/Kotlin with edge cases on Android |
| Opening device Settings | Deep-linking into OS Settings manually | `AppSettings.openAppSettings()` from `permission_handler` | Different URI schemes per Android OEM and iOS version; the library handles all variants |

**Key insight:** The OS delivers scheduled notifications even when the app is terminated — but only if the correct manifest receivers are declared. Skipping `ScheduledNotificationReceiver` means notifications silently fail when the app is not in the foreground.

---

## Verified API Signatures

### Q1 — `zonedSchedule()` exact signature (v21.0.0)

[VERIFIED: pub.dev/documentation/flutter_local_notifications/latest]

```dart
// All parameters are named (positional params removed in v20.0.0 breaking change).
// uiLocalNotificationDateInterpretation was removed in v19.0.0 (no longer needed
// since iOS 10 is the minimum and UILocalNotification is gone).
Future<void> zonedSchedule({
  required int id,
  required TZDateTime scheduledDate,
  required NotificationDetails notificationDetails,
  required AndroidScheduleMode androidScheduleMode,
  String? title,
  String? body,
  String? payload,
  DateTimeComponents? matchDateTimeComponents,
})
```

**`AndroidScheduleMode` values** [VERIFIED: pub.dev/documentation/flutter_local_notifications/latest]:
- `alarmClock` — exact + wakes from idle; requires `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`
- `exact` — exact time; may skip in low-power idle
- `exactAllowWhileIdle` — exact + wakes from idle; requires exact alarm permission
- `inexact` — approximate time; may skip in idle
- `inexactAllowWhileIdle` — approximate + wakes from idle

**Recommended for this app:** `AndroidScheduleMode.exactAllowWhileIdle` — reminders must deliver reliably regardless of device state. Requires `SCHEDULE_EXACT_ALARM` in manifest.

**`matchDateTimeComponents`:** Set to `null` for single-shot scheduled notifications. Do NOT use `DateTimeComponents.time` (repeating daily) because that bypasses per-slot DND filtering.

### Q2 — iOS 64-notification limit

[VERIFIED: pub.dev — flutter_local_notifications README]

iOS keeps only the **64 soonest-expiring** pending notifications per app. If you schedule more than 64, iOS silently discards the extras. The plugin note: "keeps the 64 most-recent."

**Slot math for this app:**
- 60-min interval, 16 active hours/day (24 − 8 DND hours) → 16 slots/day × 4 days = 64 slots (exactly at limit)
- 30-min interval, 16 active hours/day → 32 slots/day × 2 days = 64 slots
- Variable interval: `windowDays = floor(64 / slotsPerDay)`, minimum 1 day

**Rolling-window cap algorithm (pseudocode):**
```dart
// In NotificationService.scheduleWindow():
const maxSlots = 64;
int slotId = 1000;
int scheduled = 0;

final now = tz.TZDateTime.now(tz.local);
int dayOffset = 0;

while (scheduled < maxSlots) {
  final dayStart = tz.TZDateTime(tz.local,
      now.year, now.month, now.day + dayOffset, 0, 0);
  final dayEnd = tz.TZDateTime(tz.local,
      now.year, now.month, now.day + dayOffset, 23, 59);

  // Walk through the day in interval steps
  var candidate = (dayOffset == 0)
      ? now.add(Duration(minutes: intervalMinutes))   // today: start from now
      : dayStart;                                       // future days: start of day

  // Align candidate to next interval boundary (optional but cleaner)
  while (candidate.isBefore(dayEnd) && scheduled < maxSlots) {
    if (!isInDnd(candidate, settings)) {
      await _plugin.zonedSchedule(
        id: slotId++,
        scheduledDate: candidate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Drinky Drinky',
        body: 'Time to drink water! 💧',
      );
      scheduled++;
    }
    candidate = candidate.add(Duration(minutes: intervalMinutes));
  }
  dayOffset++;
  if (dayOffset > 30) break; // safety valve for very long intervals
}
```

### Q3 — Timezone initialization sequence

[VERIFIED: github.com/MaikuB/flutter_local_notifications example/lib/main.dart]

```dart
// In main() after WidgetsFlutterBinding.ensureInitialized():
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

Future<void> _initializeTimezone() async {
  tz.initializeTimeZones();                            // load the tz database
  final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier)); // set tz.local
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeTimezone();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: DrinkyDrinkyApp()));
}
```

`FlutterTimezone.getLocalTimezone()` returns a `TimezoneInfo` object; the `.identifier` property is the IANA timezone string (e.g., `"America/New_York"`) accepted by `tz.getLocation()`. [VERIFIED: pub.dev/packages/flutter_timezone]

### Q4 — Permission request approach (permission_handler vs native)

[VERIFIED: pub.dev — flutter_local_notifications README; CITED: official example code]

The **official flutter_local_notifications docs recommend the plugin's native methods**, not `permission_handler`, for the notification permission prompt:

**Android (API 33+):**
```dart
final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
final bool? granted = await androidPlugin?.requestNotificationsPermission();
```

**iOS:**
```dart
final IOSFlutterLocalNotificationsPlugin? iosPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
final bool? granted = await iosPlugin?.requestPermissions(
  alert: true,
  badge: true,
  sound: true,
);
```

**`permission_handler` role is limited to** `AppSettings.openAppSettings()` in the Settings denied banner (D-03). This is the correct split: plugin owns the prompt, `permission_handler` owns the "open Settings" shortcut.

**Checking current status (for the banner):**
```dart
// iOS — check without prompting
final NotificationsEnabledOptions? opts = await iosPlugin?.checkPermissions();
final bool iosGranted = opts?.isEnabled ?? false;

// Android — use permission_handler for status check (simpler than plugin API)
final PermissionStatus status = await Permission.notification.status;
final bool androidGranted = status.isGranted;
```

### Q5 — Android manifest requirements (complete)

[VERIFIED: pub.dev — flutter_local_notifications README]

Add to `android/app/src/main/AndroidManifest.xml`:

**Inside `<manifest>` (before `<application>`):**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

**Inside `<application>`:**
```xml
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
```

**`SCHEDULE_EXACT_ALARM` vs `USE_EXACT_ALARM`:**
- `SCHEDULE_EXACT_ALARM` — user-grantable; on Android 14+ the system may revoke it and the app must call `requestExactAlarmsPermission()`. Revocation is recoverable (user can re-grant).
- `USE_EXACT_ALARM` — no user prompt; requires app store approval/audit. Not appropriate for a consumer app.
- **Recommendation: use `SCHEDULE_EXACT_ALARM`.**

**`ScheduledNotificationBootReceiver` role:** The plugin re-schedules pending notifications automatically after device reboot. No app-side code needed for this — declaring the receiver and `RECEIVE_BOOT_COMPLETED` is sufficient. [VERIFIED: pub.dev]

**Desugaring (required for `zonedSchedule()` on older Android):**

`android/app/build.gradle.kts` already has Java 17 and `compileSdk = 36`. Add desugaring:

```kotlin
android {
    defaultConfig {
        multiDexEnabled = true
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // sourceCompatibility/targetCompatibility already present
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**`compileSdk` check:** Current `build.gradle.kts` has `compileSdk = 36`. CLAUDE.md requires 36. No change needed. [VERIFIED: codebase]

**`minSdk` check:** Current is `minSdk = 26`. CLAUDE.md states `minSdk: 24` is required by flutter_local_notifications 21.x — the app already exceeds this floor. No change needed. [VERIFIED: codebase]

### Q6 — iOS AppDelegate: `UNUserNotificationCenterDelegate`

[VERIFIED: pub.dev — flutter_local_notifications README]

The existing `AppDelegate.swift` does not register the delegate. Required addition:

```swift
import Flutter
import UIKit
import flutter_local_notifications   // ADD THIS IMPORT

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ADD THIS LINE before super.application(...)
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

The `FlutterAppDelegate` class already conforms to `UNUserNotificationCenterDelegate` — no additional protocol declarations are needed. The single line in `didFinishLaunchingWithOptions` is sufficient. [CITED: pub.dev/packages/flutter_local_notifications README]

### Q7 — GoRouter first-launch redirect pattern

[VERIFIED: pub.dev/documentation/go_router/latest — GoRouterRedirect typedef]

GoRouter 17.x supports `FutureOr<String?>` in the `redirect` callback, enabling async SharedPreferences reads. The router currently uses a `@Riverpod(keepAlive: true)` provider — the redirect must be `async` and reads SP at navigation time.

**Pattern:**

```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      // Only redirect when navigating to the root route
      if (state.matchedLocation != '/') return null;

      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('permissionScreenShown') ?? false;
      if (!shown) return '/permission';
      return null; // no redirect needed
    },
    routes: [
      // /permission is a TOP-LEVEL route (outside StatefulShellRoute)
      // so it has no bottom navigation bar
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),

      StatefulShellRoute.indexedStack(
        // ... existing shell with /, /history, /settings
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```

**Key points:**
- `/permission` must be a **top-level route outside `StatefulShellRoute`** — if it's inside the shell, it inherits the `NavigationBar` which is incorrect for a one-time onboarding screen.
- The `redirect` fires for every navigation event; the `state.matchedLocation != '/'` guard ensures it only checks on root navigation, not on every tab switch.
- After `PermissionScreen` is dismissed, it calls `context.go('/')` — the router re-evaluates `redirect`, but now SP returns `true`, so no further redirect occurs.
- The `SharedPreferences.getInstance()` call inside `redirect` is lightweight (cached after first call).

### Q8 — DND overnight window algorithm

[CITED: Phase 5 CONTEXT.md `<specifics>` section — algorithm confirmed by standard clock logic]

```dart
/// Returns true if [slot] falls within the DND window defined by [settings].
/// Handles overnight windows (e.g., 23:00–07:00) and same-day windows (e.g., 13:00–14:00).
/// Minutes are considered for precision.
bool isInDnd(TZDateTime slot, UserSettingsEntity settings) {
  if (!settings.dndEnabled) return false;

  final startMinutes = settings.dndStartHour * 60 + settings.dndStartMinute;
  final endMinutes   = settings.dndEndHour   * 60 + settings.dndEndMinute;
  final slotMinutes  = slot.hour * 60 + slot.minute;

  if (endMinutes <= startMinutes) {
    // Overnight window: e.g., start=23:00 (1380), end=07:00 (420)
    // DND if slot is >= start OR < end
    return slotMinutes >= startMinutes || slotMinutes < endMinutes;
  } else {
    // Same-day window: e.g., start=13:00, end=14:00
    return slotMinutes >= startMinutes && slotMinutes < endMinutes;
  }
}
```

**Example verification (dndStart=23:00, dndEnd=07:00):**
- slot at 01:00 (60 min): `endMinutes(420) <= startMinutes(1380)` → overnight branch; `60 >= 1380` is false, `60 < 420` is true → **in DND** (correct)
- slot at 10:00 (600 min): `600 >= 1380` is false, `600 < 420` is false → **not in DND** (correct)
- slot at 23:30 (1410 min): `1410 >= 1380` is true → **in DND** (correct)

**Edge case — start equals end:** If `dndStartHour == dndEndHour && dndStartMinute == dndEndMinute`, the window is zero-width. `endMinutes <= startMinutes` is true (equal), so the overnight branch fires and marks ALL slots as DND. The planner should add a guard: if `dndEnabled` but `startMinutes == endMinutes`, treat DND as disabled for scheduling purposes.

### Q9 — `cancelAll()` behavior

[VERIFIED: pub.dev/documentation/flutter_local_notifications/latest]

```dart
await flutterLocalNotificationsPlugin.cancelAll();
```

- Cancels **all** pending scheduled notifications and all currently displayed notifications on **both platforms**.
- No caveats for iOS or Android.
- After `cancelAll()`, the notification tray is empty and the schedule is empty — the next `scheduleWindow()` call starts fresh.
- Appropriate for goal-reached auto-stop (D-07) and for the cancel-all-then-reschedule rolling-window pattern (D-04).

### Q10 — `NotificationService` architecture

[CITED: CONTEXT.md D-10; pattern is idiomatic Flutter service layer]

A plain Dart singleton (not a Riverpod provider) is correct here. Notifications are imperative side effects, not reactive data streams. Widgets call `ref.read(notificationServiceProvider)` — but since this is a singleton, the simplest approach is a static instance:

```dart
// lib/core/services/notification_service.dart

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'hydration_reminders';
  static const _channelName = 'Hydration Reminders';

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // defer to PermissionScreen
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<bool?> requestPermission() async {
    // Platform-specific native approach (per official docs)
    if (Platform.isAndroid) {
      final ap = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return ap?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ip = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return ip?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  Future<bool> get permissionStatus async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final ip = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final opts = await ip?.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    return false;
  }

  Future<void> scheduleWindow(UserSettingsEntity settings) async {
    await cancelAll();
    // [slot generation algorithm — see Q2 above]
  }
}
```

Widgets access it via `NotificationService.instance` directly (no Riverpod provider needed).

---

## Common Pitfalls

### Pitfall 1: Scheduling outside `tz.local` causes wrong delivery times

**What goes wrong:** Using `DateTime.now()` or a plain `DateTime` in `zonedSchedule()` instead of `tz.TZDateTime.now(tz.local)`. The notification fires at the wrong wall-clock time, especially after DST transitions.
**Why it happens:** Dart's `DateTime` is unaware of timezone; it stores UTC offset at construction time.
**How to avoid:** Always construct slot times as `tz.TZDateTime(tz.local, year, month, day, hour, minute)`. Call `_initializeTimezone()` before `NotificationService.initialize()` in `main()`.
**Warning signs:** Notifications arrive 1 hour early/late after DST change; notifications at wrong time when device is in a different timezone than compile time.

### Pitfall 2: `initializeTimeZones()` not called before `getLocation()`

**What goes wrong:** `tz.getLocation('America/New_York')` throws `LocationNotFoundException` at startup.
**Why it happens:** The timezone database must be loaded before any location lookup.
**How to avoid:** Always call `tz.initializeTimeZones()` before `tz.setLocalLocation(tz.getLocation(...))`. Both must happen before `runApp()`.
**Warning signs:** App crashes on launch with `LocationNotFoundException`.

### Pitfall 3: Scheduling more than 64 slots breaks iOS

**What goes wrong:** iOS silently drops the oldest-scheduled notifications when you exceed 64 pending.
**Why it happens:** iOS hard limit of 64 pending local notifications per app.
**How to avoid:** The rolling-window algorithm above caps at `maxSlots = 64`. Always verify: `slotsPerDay * windowDays <= 64`.
**Warning signs:** Notifications stop arriving on iOS after a few days even though scheduling appears to succeed.

### Pitfall 4: Missing `ScheduledNotificationReceiver` in AndroidManifest causes silent failures

**What goes wrong:** `zonedSchedule()` appears to succeed but notifications never appear on Android when the app is not in the foreground.
**Why it happens:** The plugin delivers scheduled notifications via a `BroadcastReceiver`. Without the receiver declaration, Android silently drops the broadcast.
**How to avoid:** Add all three receivers to `<application>` block as shown in Q5.
**Warning signs:** Notifications work in debug with app open; fail in background/release build.

### Pitfall 5: Exact alarm permission revoked on Android 14+

**What goes wrong:** `exactAllowWhileIdle` silently falls back or throws if `SCHEDULE_EXACT_ALARM` is revoked.
**Why it happens:** Android 14 introduced user-revocable exact alarm permissions.
**How to avoid:** On Android, before calling `scheduleWindow()`, check if exact alarms are allowed. If not allowed, either call `requestExactAlarmsPermission()` or fall back to `AndroidScheduleMode.inexactAllowWhileIdle`.
**Warning signs:** Plugin logs error message about exact alarm permission; notifications arrive at wrong times.

### Pitfall 6: GoRouter redirect causes infinite loop

**What goes wrong:** The redirect to `/permission` fires again when navigating away from `/permission`, creating an infinite loop.
**Why it happens:** GoRouter evaluates the `redirect` callback on every navigation event.
**How to avoid:** Guard with `if (state.matchedLocation != '/') return null;` — only redirect when at the root, not when already at `/permission` or any other route.
**Warning signs:** App hangs or crashes immediately after `context.go('/')` from `PermissionScreen`.

### Pitfall 7: DND check uses integer hours only (ignores minutes)

**What goes wrong:** Slots scheduled at e.g. 23:30 when DND starts at 23:00 incorrectly pass the DND check because hour comparison misses minute precision.
**Why it happens:** Using `slot.hour >= dndStartHour` without accounting for minutes.
**How to avoid:** Always convert to total minutes before comparing, as shown in the `isInDnd()` implementation in Q8.

### Pitfall 8: `cancelAll()` called before `initialize()` crashes

**What goes wrong:** Calling `NotificationService.cancelAll()` or `scheduleWindow()` before `initialize()` has completed throws a null pointer exception.
**Why it happens:** `FlutterLocalNotificationsPlugin` must be initialized before any method calls.
**How to avoid:** Await `NotificationService.initialize()` in `main()` before `runApp()`. Methods on `NotificationService` that call the plugin should guard with `if (!_initialized) return;`.

### Anti-Patterns to Avoid

- **Using `matchDateTimeComponents: DateTimeComponents.time`** for hydration reminders — it creates one repeating daily notification, ignoring DND. Use single-shot `zonedSchedule()` per slot instead.
- **Calling `scheduleWindow()` on every `userSettingsProvider` stream event** — stream events fire frequently (every DB write). Only reschedule on explicit trigger events (D-05). Use `ref.listen` with equality check or `onChangeEnd`, not stream watch.
- **Using `permission_handler` `Permission.notification.request()`** for the initial prompt — the official docs recommend the plugin's native method. `permission_handler` is correct only for `AppSettings.openAppSettings()`.

---

## Runtime State Inventory

> Phase 5 is a greenfield addition of notification scheduling — no rename or migration is involved.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | No notification-related records in Drift DB; `SharedPreferences` empty (nothing written yet) | None — Phase 5 writes `permissionScreenShown` as new key |
| Live service config | No external notification services configured | None |
| OS-registered state | No pending notifications registered (package not yet installed) | None |
| Secrets/env vars | No notification service credentials (local-only) | None |
| Build artifacts | No notification-related build artifacts | None |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | App build | Must verify | >=3.38.1 required by flutter_local_notifications 21.x | None — must meet minimum |
| Android compileSdk 36 | flutter_local_notifications 21.x | ✓ | 36 (confirmed in build.gradle.kts) | None needed |
| Android minSdk | flutter_local_notifications 21.x | ✓ | 26 (exceeds required minimum of 24) | None needed |
| iOS 13+ | flutter_local_notifications 21.x | [ASSUMED] | Set in Xcode project | None — required minimum |
| Dart async/await in GoRouter redirect | GoRouter 17.x | ✓ | `FutureOr<String?>` supported | None needed |

**Missing dependencies with no fallback:** None known — all platform requirements appear to be met.
**Missing dependencies with fallback:** None.

---

## Security Domain

> `security_enforcement: true` in config.json. ASVS Level 1 applies.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Not applicable — no user accounts |
| V3 Session Management | No | Not applicable — no session tokens |
| V4 Access Control | No | Not applicable — single-user local app |
| V5 Input Validation | Partial | Notification ID integers: use modulo-safe sequential IDs (capped at e.g. `Int.MAX`) to prevent overflow if slot count grows |
| V6 Cryptography | No | No secrets in notification payloads |

### Known Threat Patterns for Local Notifications

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Notification payload injection (if payload contains user data) | Tampering | Keep payload null or limited to static strings — no PII in notification body |
| Excessive notification scheduling (DoS against iOS slot limit) | Denial of Service | Cap at 64 slots via `maxSlots` constant; never schedule unbounded loops |
| SharedPreferences key collision | Tampering | Use a namespaced key: `'drinky_permissionScreenShown'` — prevents accidental collision if another package writes to SP |
| Permission state race (checking status vs actual OS state) | Information Disclosure | Always re-query permission status on foreground resume; cache for UI display only |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All four packages approved by slopcheck (unavailable) | Package Legitimacy Audit | Very low — all are from verified publishers with multi-year track records and millions of downloads |
| A2 | iOS deployment target is 13+ in the Xcode project | Environment Availability | If <13, flutter_local_notifications 21.x will reject at build time — easy to fix by updating iOS deployment target |
| A3 | `FlutterTimezone.getLocalTimezone()` returns `.identifier` as the IANA string compatible with `tz.getLocation()` | Q3 Timezone sequence | The example code from the official flutter_local_notifications repo uses this exact pattern; very low risk |
| A4 | `FlutterAppDelegate` already conforms to `UNUserNotificationCenterDelegate` (meaning no extra protocol declaration needed in AppDelegate.swift) | Q6 iOS AppDelegate | If wrong, the Swift file would need `UNUserNotificationCenterDelegate` added to class declaration — a one-line fix |
| A5 | GoRouter 17.x `redirect` fires on the root `/` navigation and not on subsequent tab switches within `StatefulShellRoute` | Q7 GoRouter pattern | If wrong, the redirect guard must be adjusted to check `state.fullPath` more carefully; testable at runtime |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. (Table is not empty — A1 through A5 require awareness.)

---

## Open Questions (RESOLVED)

All 10 research questions from the brief are answered:

1. **`zonedSchedule()` API** — Resolved. Full named-parameter signature in Q1. `uiLocalNotificationDateInterpretation` was removed in v19.0.0. `AndroidScheduleMode.exactAllowWhileIdle` is the correct choice.

2. **iOS 64-notification limit** — Resolved. Hard limit of 64. Rolling-window algorithm with `maxSlots = 64` cap documented in Q2.

3. **Timezone initialization** — Resolved. Exact sequence: `tz.initializeTimeZones()` → `FlutterTimezone.getLocalTimezone()` → `tz.setLocalLocation(tz.getLocation(tzInfo.identifier))` in Q3.

4. **Permission approach (permission_handler vs native)** — Resolved. Official docs recommend the plugin's native per-platform methods for the prompt. `permission_handler` is kept only for `AppSettings.openAppSettings()` in the denied banner. Full per-platform code in Q4.

5. **Android manifest requirements** — Resolved. Three receivers + four permissions + desugaring in Q5. Kotlin DSL format documented.

6. **iOS AppDelegate** — Resolved. One line: `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` in `didFinishLaunchingWithOptions`, before `super.application(...)`. Import `flutter_local_notifications` in Swift.

7. **GoRouter first-launch redirect** — Resolved. Top-level `/permission` route outside `StatefulShellRoute`; `redirect` callback with `FutureOr<String?>` + SharedPreferences check in Q7.

8. **DND overnight window edge cases** — Resolved. Total-minutes comparison algorithm with overnight branch in Q8. Edge case (start == end) identified and guard recommended.

9. **`cancelAll()` behavior** — Resolved. Cancels all pending + displayed notifications on both platforms. No caveats. Q9.

10. **`NotificationService` architecture** — Resolved. Plain Dart singleton (`NotificationService.instance`) is correct for imperative side effects. Full class scaffold in Q10.

---

## Sources

### Primary (HIGH confidence)
- `pub.dev/packages/flutter_local_notifications` — README, changelog, API docs (v21.0.0 verified June 2026)
- `pub.dev/documentation/flutter_local_notifications/latest` — `zonedSchedule()`, `initialize()`, `cancelAll()`, `AndroidScheduleMode`, `DarwinNotificationDetails`, `AndroidNotificationDetails`, `IOSFlutterLocalNotificationsPlugin`, `AndroidFlutterLocalNotificationsPlugin`
- `github.com/MaikuB/flutter_local_notifications` example/lib/main.dart — timezone initialization sequence (confirmed `TimezoneInfo.identifier` → `tz.setLocalLocation`)
- `pub.dev/packages/timezone` — `initializeTimeZones()`, `TZDateTime`, `setLocalLocation()` (v0.11.0)
- `pub.dev/packages/flutter_timezone` — `FlutterTimezone.getLocalTimezone()`, `TimezoneInfo` return type (v5.1.0)
- `pub.dev/packages/permission_handler` — `Permission.notification.status`, `AppSettings.openAppSettings()` (v12.0.3)
- `pub.dev/documentation/go_router/latest` — `GoRouterRedirect` typedef `FutureOr<String?> Function(BuildContext, GoRouterState)`

### Secondary (MEDIUM confidence)
- Codebase — `build.gradle.kts` (compileSdk=36, minSdk=26 confirmed), `AndroidManifest.xml` (current state — no receivers yet), `AppDelegate.swift` (current state — no delegate), `app_router.dart` (current GoRouter structure), `main.dart` (current init sequence)
- CLAUDE.md tech stack table — package versions, minSdk, iOS 13+ requirement

### Tertiary (LOW confidence — from training knowledge)
- `FlutterAppDelegate` conformance to `UNUserNotificationCenterDelegate` — not explicitly verified in iOS SDK docs in this session [A4 in Assumptions]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified on pub.dev with current versions
- API signatures: HIGH — fetched from official pub.dev API documentation
- Architecture patterns: HIGH — based on official example code + codebase analysis
- Android manifest: HIGH — fetched from official README
- iOS AppDelegate: MEDIUM — single official source; `FlutterAppDelegate` conformance is assumed (A4)
- GoRouter redirect: HIGH — `GoRouterRedirect` typedef confirmed from official API docs
- DND algorithm: HIGH — pure logic verified with manual examples

**Research date:** 2026-06-05
**Valid until:** 2026-07-05 (stable packages; flutter_local_notifications API unlikely to change in 30 days)
