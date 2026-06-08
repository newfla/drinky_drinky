# Phase 5: Notifications - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 9 (2 new, 7 modified)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/core/services/notification_service.dart` | service | event-driven | `lib/data/repositories/settings_repository.dart` | role-match (plain Dart class, async methods, no code-gen) |
| `lib/presentation/screens/permission_screen.dart` | screen | request-response | `lib/presentation/screens/settings_screen.dart` | exact (ConsumerStatefulWidget, Scaffold, Card layout) |
| `android/app/src/main/AndroidManifest.xml` | config | — | existing file (modify) | exact |
| `ios/Runner/AppDelegate.swift` | config | — | existing file (modify) | exact |
| `pubspec.yaml` | config | — | existing file (modify) | exact |
| `lib/main.dart` | config | — | existing file (modify) | exact |
| `lib/presentation/screens/home_screen.dart` | screen | event-driven | existing file (modify) | exact |
| `lib/presentation/screens/settings_screen.dart` | screen | request-response | existing file (modify) | exact |
| `lib/core/router/app_router.dart` | config | request-response | existing file (modify) | exact |

---

## Pattern Assignments

### `lib/core/services/notification_service.dart` (service, event-driven)

**Analog:** `lib/data/repositories/settings_repository.dart`

This is the only service/singleton class pattern in the codebase. Follow the same shape: plain Dart class with a private constructor or factory, injected dependencies, async public methods, and no Riverpod annotations on the class itself (the class is exposed via a keepAlive provider in `repository_providers.dart`).

**Class structure pattern** (lines 6-11 of settings_repository.dart):
```dart
class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);
  // ... async public methods
}
```

Apply the same shape to NotificationService:
```dart
class NotificationService {
  NotificationService._(); // private constructor — singleton
  static final NotificationService instance = NotificationService._();

  // Async initializer called once from main()
  Future<void> initialize() async { ... }

  // Public async methods
  Future<bool> requestPermission() async { ... }
  Future<void> scheduleRepeating({required int intervalMinutes, ...}) async { ... }
  Future<void> cancelAll() async { ... }
  Future<bool> hasPermission() async { ... }
}
```

**Provider registration pattern** — expose via `@Riverpod(keepAlive: true)` in `lib/core/providers/repository_providers.dart`, matching lines 8-16 of that file:
```dart
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService.instance;
}
```

**Error handling pattern** — match `settings_repository.dart` lines 44-59: throw typed errors for invalid arguments; let IO errors propagate to the caller for Riverpod's AsyncValue to capture.

---

### `lib/presentation/screens/permission_screen.dart` (screen, request-response)

**Analog:** `lib/presentation/screens/settings_screen.dart`

**Imports pattern** (settings_screen.dart lines 1-8):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
// add:
import '../../core/services/notification_service.dart';
```

**Widget class pattern** (settings_screen.dart lines 10-16):
```dart
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}
```

**Scaffold + single-card layout** (settings_screen.dart lines 27-59):
```dart
return Scaffold(
  appBar: AppBar(title: const Text('Notifications')),
  body: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'PERMISSION REQUIRED'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column( ... ),
          ),
        ),
      ],
    ),
  ),
);
```

**Section label helper** — copy verbatim from settings_screen.dart lines 63-71:
```dart
Widget _sectionLabel(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
```

**Async action + mounted guard** — copy the pattern from home_screen.dart lines 207-231. After any `await`, check `if (!mounted) return;` before using `context` or `ref`.

---

### `android/app/src/main/AndroidManifest.xml` (modify)

**Analog:** existing file at `android/app/src/main/AndroidManifest.xml`

Current file ends at line 45. Add the following inside `<manifest>` before `<application>`:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:minSdkVersion="31"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"
    android:minSdkVersion="33"/>
```

Add inside `<application>` after the `<activity>` block:
```xml
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    android:exported="false"/>
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    </intent-filter>
</receiver>
```

Existing indentation style is 4-space. Preserve it.

---

### `ios/Runner/AppDelegate.swift` (modify)

**Analog:** existing file at `ios/Runner/AppDelegate.swift`

Current file is 16 lines. Add `UNUserNotificationCenterDelegate` conformance inside `didFinishLaunchingWithOptions`, before calling `super.application(...)`:

```swift
import Flutter
import UIKit
import UserNotifications  // ADD

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ADD: register this delegate for notification presentation callbacks
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  // existing didInitializeImplicitFlutterEngine stays unchanged
}
```

`FlutterAppDelegate` already conforms to `UNUserNotificationCenterDelegate` — no extra extension needed. Adding `UNUserNotificationCenter.current().delegate = self` is the only required change.

---

### `pubspec.yaml` (modify)

**Analog:** existing file at `pubspec.yaml`

Current dependency block style (lines 10-32): each group has a `# Comment` header, then package entries at 2-space indent. Match that style exactly.

Add a new group under `# Utilities`:
```yaml
  # Notifications
  flutter_local_notifications: ^21.0.0
  timezone: ^0.11.0
  flutter_timezone: ^5.1.0
  permission_handler: ^12.0.3
```

No dev-dependency additions required for these packages.

---

### `lib/main.dart` (modify)

**Analog:** existing file at `lib/main.dart`

Current `main()` (lines 5-11):
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DrinkyDrinkyApp(),
    ),
  );
}
```

Expand to async and add initialization before `runApp`:
```dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'core/services/notification_service.dart';

void main() async {                              // make async
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone init (required by flutter_local_notifications zonedSchedule)
  tz.initializeTimeZones();
  final timezoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneName));

  // Notification service init (registers Android channels, iOS delegate hook)
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: DrinkyDrinkyApp(),
    ),
  );
}
```

`DrinkyDrinkyApp` (lines 14-29) stays unchanged. Keep `ConsumerWidget` + `ref.watch(appRouterProvider)` pattern.

---

### `lib/presentation/screens/home_screen.dart` (modify)

**Analog:** existing file — modify in place.

**AppLifecycleListener pattern** already exists (lines 30-37). Extend `onResume` to also call `NotificationService.instance.reschedule(...)`:
```dart
_lifecycleListener = AppLifecycleListener(
  onResume: () {
    _checkDateChange();
    _rescheduleNotifications(); // ADD
  },
);
```

**ref.listen pattern** — add inside `build()` after existing `ref.watch` calls. No existing `ref.listen` in the file yet; the pattern from Riverpod docs for listening to stream providers is:
```dart
ref.listen<AsyncValue<int>>(
  totalMlForDateProvider(_dateKey),
  (previous, next) {
    final prev = previous?.value ?? 0;
    final curr = next.value ?? 0;
    final target = ref.read(userSettingsProvider).value?.dailyTargetMl ?? 0;
    if (target > 0 && prev < target && curr >= target) {
      NotificationService.instance.cancelAll(); // goal reached — silence reminders
    }
  },
);
```

Place `ref.listen` calls at the top of `build()` before returning the widget tree. `ref.listen` must be called unconditionally (not inside `when` callbacks).

**Async action + mounted guard** — already established in `_onQuickAdd` (lines 207-231). Apply same `if (!mounted) return;` guard to any new async methods added.

---

### `lib/presentation/screens/settings_screen.dart` (modify)

**Analog:** existing file — modify in place.

**Permission-denied banner pattern** — insert at the top of `_notificationsCard` (currently line 125), above the interval slider. Use a `MaterialBanner`-style `Container` inside the `Card.Column`, matching the existing color/theme access pattern:

```dart
// At top of _notificationsCard Column children list:
if (_permissionDenied)
  Container(
    color: Theme.of(context).colorScheme.errorContainer,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.onErrorContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Notification permission denied. Tap to open Settings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
        TextButton(
          onPressed: _openAppSettings,
          child: const Text('Open'),
        ),
      ],
    ),
  ),
```

**State field pattern** — match existing `double? _dailyTargetDrag` pattern (line 19); add:
```dart
bool _permissionDenied = false;
```

**initState permission check** — `SettingsScreen` currently has no `initState`. Add one following the `ConsumerState.initState` super-call pattern from home_screen.dart lines 27-38:
```dart
@override
void initState() {
  super.initState();
  _checkPermission();
}

Future<void> _checkPermission() async {
  final denied = !(await NotificationService.instance.hasPermission());
  if (mounted) setState(() => _permissionDenied = denied);
}
```

---

### `lib/core/router/app_router.dart` (modify)

**Analog:** existing file — modify in place.

**GoRoute addition pattern** — the existing `GoRoute` entries (lines 48-69) use:
```dart
GoRoute(
  path: '/some-path',
  builder: (context, state) => const SomeScreen(),
),
```

Add `/permission` as a top-level route outside the `StatefulShellRoute` so it does not render the bottom navigation bar:
```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    // First-launch guard: if notification permission never asked, redirect once
    final neverAsked = await NotificationService.instance.wasNeverAsked();
    if (neverAsked && state.matchedLocation != '/permission') {
      return '/permission';
    }
    return null;
  },
  routes: [
    GoRoute(                             // ADD before StatefulShellRoute
      path: '/permission',
      builder: (context, state) => const PermissionScreen(),
    ),
    StatefulShellRoute.indexedStack(     // existing — unchanged
      ...
    ),
  ],
);
```

**ref.onDispose** (line 74) stays unchanged — it disposes the router on provider teardown.

**Provider annotation** (line 13) stays unchanged:
```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
```

Note: GoRouter `redirect` can be async as of go_router 13+. The project uses `^17.3.0` so async redirect is supported.

---

## Shared Patterns

### ConsumerStatefulWidget + initState
**Source:** `lib/presentation/screens/home_screen.dart` lines 13-51
**Apply to:** `permission_screen.dart`, and `settings_screen.dart` (adding initState)

The canonical pattern:
```dart
class XScreen extends ConsumerStatefulWidget {
  const XScreen({super.key});
  @override
  ConsumerState<XScreen> createState() => _XScreenState();
}

class _XScreenState extends ConsumerState<XScreen> {
  @override
  void initState() {
    super.initState();
    // setup
  }

  @override
  void dispose() {
    // teardown
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { ... }
}
```

### Async action + mounted guard
**Source:** `lib/presentation/screens/home_screen.dart` lines 207-231
**Apply to:** all new async methods in home_screen.dart, settings_screen.dart, permission_screen.dart

```dart
void _someAction() async {
  await someAsyncCall();
  if (!mounted) return;         // always check before context/setState
  setState(() { ... });
}
```

### ref.read for writes, ref.watch for reads
**Source:** `lib/presentation/screens/settings_screen.dart` lines 98-99, 173-175
**Apply to:** all screens calling NotificationService

```dart
// Reads (reactive): ref.watch(someProvider)
// Writes / one-shot calls: ref.read(someProvider)
ref.read(settingsRepositoryProvider).updateSettings(...);
```

NotificationService is a singleton (not a provider), so call it directly: `NotificationService.instance.scheduleRepeating(...)`.

### AsyncValue.when for provider data
**Source:** `lib/presentation/screens/home_screen.dart` lines 63-77
**Apply to:** permission_screen.dart if it reads any stream provider

```dart
settingsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => const Center(child: Text('Something went wrong loading your data.')),
  data: (settings) => _buildContent(context, settings),
);
```

### keepAlive provider for long-lived services
**Source:** `lib/core/providers/repository_providers.dart` lines 8-16
**Apply to:** NotificationService provider in repository_providers.dart

```dart
@Riverpod(keepAlive: true)
SomeService someService(Ref ref) {
  return SomeService.instance;
}
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/core/services/notification_service.dart` (class internals) | service | event-driven | No event-driven / notification scheduling code exists yet. Use flutter_local_notifications API per CLAUDE.md RESEARCH stack. The class shell follows settings_repository.dart, but `FlutterLocalNotificationsPlugin`, `AndroidNotificationDetails`, `DarwinNotificationDetails`, `zonedSchedule()`, `permission_handler` calls have no codebase analog — derive from package docs. |

---

## Metadata

**Analog search scope:** `lib/` (all subdirectories), `android/app/src/main/`, `ios/Runner/`, project root
**Files scanned:** 15
**Pattern extraction date:** 2026-06-05
