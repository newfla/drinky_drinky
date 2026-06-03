# Architecture Patterns

**Domain:** Offline hydration tracker (Flutter mobile)
**Researched:** 2026-06-03

## Recommended Architecture

Feature-first folder layout with a four-layer architecture adapted from the official Flutter architecture guide and the Riverpod application architecture pattern. The four layers are **Presentation**, **Application**, **Domain**, and **Data**. Dependencies flow strictly downward: Presentation -> Application -> Domain <- Data. Riverpod providers wire the layers together.

### High-Level Diagram

```
+------------------------------------------------------------------+
|                      PRESENTATION LAYER                          |
|  Widgets (ConsumerWidget / ConsumerStatefulWidget)               |
|  Controllers (Notifier / AsyncNotifier via Riverpod)             |
+------------------------------------------------------------------+
          |  ref.watch / ref.read            ^  AsyncValue<T>
          v                                  |
+------------------------------------------------------------------+
|                      APPLICATION LAYER                           |
|  Services (business logic spanning multiple repos)               |
|  NotificationScheduler, HydrationService                         |
+------------------------------------------------------------------+
          |                                  ^
          v                                  |
+------------------------------------------------------------------+
|                         DOMAIN LAYER                             |
|  Models: WaterEntry, DailyProgress, UserSettings, DrinkPreset    |
|  Pure Dart classes, no framework imports                         |
+------------------------------------------------------------------+
          ^                                  ^
          |                                  |
+------------------------------------------------------------------+
|                          DATA LAYER                              |
|  Drift Database (AppDatabase, DAOs)                              |
|  Repositories (WaterRepository, SettingsRepository)              |
|  Platform Services (NotificationPlugin wrapper)                  |
+------------------------------------------------------------------+
```

### Folder Structure

```
lib/
  src/
    common_widgets/           # Shared UI components (progress ring, etc.)
    constants/                # App-wide constants, theme, sizing
    routing/                  # GoRouter config
    utils/                    # Date helpers, formatters

    features/
      hydration/
        presentation/
          home_screen.dart            # Main screen with progress ring
          home_controller.dart        # Notifier managing today's state
          widgets/
            progress_ring.dart
            quick_add_buttons.dart
        application/
          hydration_service.dart      # Orchestrates add/undo logic
        domain/
          water_entry.dart            # Immutable model
          daily_progress.dart         # Aggregate model
        data/
          water_repository.dart       # Wraps Drift DAO, exposes streams
          water_dao.dart              # Drift DAO with @DriftAccessor

      calendar/
        presentation/
          calendar_screen.dart
          calendar_controller.dart
        domain/
          day_summary.dart
        data/
          calendar_repository.dart    # Reads from same DB, aggregate queries

      settings/
        presentation/
          settings_screen.dart
          settings_controller.dart
        domain/
          user_settings.dart
          drink_preset.dart
        data/
          settings_repository.dart
          settings_dao.dart

      notifications/
        application/
          notification_scheduler.dart   # Computes times, reschedules on change
        data/
          notification_service.dart     # Wraps flutter_local_notifications

    database/
      app_database.dart               # Single Drift @DriftDatabase class
      tables/
        water_entries.dart
        user_settings.dart
        drink_presets.dart
```

**Rationale for feature-first over layer-first:** All files for a feature (hydration tracking, calendar view, settings) are colocated. Adding or removing a feature does not scatter files across the project. The `database/` folder is shared because Drift requires a single database class that references all tables, so table definitions live centrally while DAOs live within their feature's data layer.

---

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **AppDatabase** (Drift) | Single SQLite database instance; schema definition; migration strategy | DAOs (provides table access) |
| **DAOs** (Drift) | Type-safe queries for a single feature domain | AppDatabase (reads/writes), Repositories (called by) |
| **Repositories** | Abstract data access; transform DB rows to domain models; expose Streams for reactivity | DAOs (reads/writes), Services and Controllers (called by) |
| **Services** | Cross-cutting business logic spanning multiple repositories | Repositories (reads), NotificationService (calls) |
| **Controllers** (Riverpod Notifiers) | Hold UI state for a single screen; expose command methods for user actions | Services/Repositories (reads), Widgets (watched by) |
| **Widgets** | Render UI from controller state; dispatch user actions to controllers | Controllers (watches via ref.watch) |
| **NotificationService** | Wraps flutter_local_notifications; handles platform setup, permission requests, scheduling calls | Called by NotificationScheduler; interacts with OS notification APIs |
| **NotificationScheduler** | Computes next notification times from settings; calls NotificationService to schedule/cancel | SettingsRepository (reads DND/interval), NotificationService (calls) |

### Boundary Rules

1. **Widgets never import DAOs or AppDatabase** -- they only see Controllers.
2. **Controllers never import Drift classes** -- they receive domain models from Repositories.
3. **Repositories own the Stream contract** -- Drift's `.watch()` streams bubble up through repositories, wrapped in Riverpod StreamProviders.
4. **Services exist only when logic spans multiple repositories** -- Controllers call repositories directly for simple single-repository reads/writes. Do not create services for trivial pass-through.
5. **NotificationService is the only component touching flutter_local_notifications** -- isolating all platform-specific notification code.
6. **Domain models are plain Dart** -- no Drift, no Flutter, no Riverpod imports. Pure data classes.

---

## Data Flow

### Primary Flow: User Adds Water

```
1. User taps Quick-Add button (250ml)
   |
2. Widget calls controller.addWater(250)
   |
3. Controller (HomeController / Notifier) calls waterRepository.insertEntry(250)
   |
4. WaterRepository -> WaterDAO.insertEntry() -> SQLite INSERT
   |
5. Drift's stream infrastructure detects table change
   -> active .watch() queries on water_entries re-execute automatically
   |
6. StreamProvider<DailyProgress> emits new DailyProgress
   |
7. Controller's ref.watch picks up new value -> state updates
   |
8. Widget rebuilds -> progress ring animates to new percentage
```

### Reactive Data Pipeline: Drift -> Riverpod

```dart
// Database singleton provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository provider
final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(ref.watch(appDatabaseProvider));
});

// Stream provider wrapping Drift's reactive query
final dailyProgressProvider = StreamProvider<DailyProgress>((ref) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchTodayProgress();
});
```

```dart
// In WaterRepository
class WaterRepository {
  final AppDatabase _db;
  WaterRepository(this._db);

  Stream<DailyProgress> watchTodayProgress() {
    final today = DateTime.now().dateOnly;
    return _db.waterDao.watchEntriesForDate(today).map((entries) {
      final totalMl = entries.fold(0, (sum, e) => sum + e.amountMl);
      return DailyProgress(totalMl: totalMl, entries: entries);
    });
  }

  Future<void> insertEntry(int amountMl) async {
    await _db.waterDao.insertEntry(
      WaterEntriesCompanion.insert(
        amountMl: amountMl,
        timestamp: DateTime.now(),
        dateKey: DateTime.now().toDateKey(), // 'YYYY-MM-DD'
      ),
    );
  }
}
```

This pattern is the core data flow mechanism. Drift's `.watch()` returns a `Stream<List<Row>>` that auto-emits whenever the underlying table changes. Wrapping it in a Riverpod `StreamProvider` gives the UI reactive access with zero manual refresh calls. Drift emits an initial value on listen, so the UI always has data immediately.

### Calendar View Flow

```
1. User navigates to Calendar screen
   |
2. CalendarController.build() watches calendarRepository.watchMonthSummaries(month)
   |
3. CalendarRepository queries Drift:
   SELECT date_key, SUM(amount_ml) as total
   FROM water_entries
   WHERE date_key BETWEEN ? AND ?
   GROUP BY date_key
   |
4. Repository maps results + user's daily target -> List<DaySummary>
   each DaySummary has: date, totalMl, targetMl, goalMet (bool)
   |
5. Calendar widget renders green/red color coding per day
```

### Notification Scheduling Flow

```
1. App starts OR user changes reminder settings (interval, DND window)
   |
2. NotificationScheduler.reschedule() is called
   |
3. Scheduler reads current settings from SettingsRepository:
   - reminderIntervalMin (e.g., 60)
   - dndStartTime (e.g., "22:00")
   - dndEndTime (e.g., "07:00")
   - remindersEnabled (bool)
   |
4. Scheduler calls notificationService.cancelAll()
   |
5. Scheduler computes next N notification times:
   - Start from current time (or dndEndTime if currently in DND)
   - Add interval repeatedly
   - Skip any time falling in DND window
   - Cap at ~50 notifications (iOS keeps max 64)
   |
6. For each computed time:
   notificationService.scheduleNotification(id, time, title, body)
   -> flutterLocalNotificationsPlugin.zonedSchedule(...)
   |
7. OS handles delivery even when app is killed/terminated
```

**Why zonedSchedule over periodicallyShow:** `periodicallyShow` only supports fixed enum intervals (every minute, hourly, daily) and cannot respect a DND window. `zonedSchedule` allows scheduling specific times, enabling skip-logic for DND. The tradeoff is manually computing and scheduling a batch of ~50 notifications, then rescheduling when settings change or on app launch. This is the correct approach for this use case.

---

## Patterns to Follow

### Pattern 1: AsyncNotifier for Screen Controllers

**What:** Each screen gets a Riverpod `AsyncNotifier` (or `Notifier` for sync state) that initializes from repository data and exposes mutation methods.

**When:** Any screen that loads data and supports user actions.

```dart
@riverpod
class HomeController extends _$HomeController {
  @override
  Stream<DailyProgress> build() {
    return ref.watch(dailyProgressProvider.stream);
  }

  Future<void> addWater(int amountMl) async {
    final repo = ref.read(waterRepositoryProvider);
    await repo.insertEntry(amountMl);
    // No manual refresh needed -- Drift stream triggers rebuild
  }

  Future<void> undoLast() async {
    final repo = ref.read(waterRepositoryProvider);
    await repo.deleteLastEntry();
  }
}
```

**Key insight:** Using `ref.watch` on a StreamProvider inside `build()` makes the controller automatically reactive to Drift changes. No invalidation or manual state mutation is needed.

### Pattern 2: Single Database Instance via Provider

**What:** One `AppDatabase` instance provided at app root; all DAOs and repositories access it.

**When:** Always. Drift databases must be singletons.

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
```

**Why critical:** SQLite file locking prevents multiple database instances. Drift's stream notification system only works within a single instance -- if you create two, changes from one will not trigger streams in the other.

### Pattern 3: Repository as Stream Gateway

**What:** Repositories wrap Drift DAO streams and transform raw rows into domain models. The UI layer never sees Drift-generated row types.

**When:** Every data access path.

```dart
class WaterRepository {
  final AppDatabase _db;
  WaterRepository(this._db);

  Stream<DailyProgress> watchTodayProgress() {
    return _db.waterDao
      .watchEntriesForDate(DateTime.now().dateOnly)
      .map(_toDailyProgress);
  }

  DailyProgress _toDailyProgress(List<WaterEntryRow> rows) {
    final entries = rows.map((r) => WaterEntry(
      id: r.id,
      amountMl: r.amountMl,
      timestamp: r.timestamp,
    )).toList();
    final total = entries.fold(0, (sum, e) => sum + e.amountMl);
    return DailyProgress(totalMl: total, entries: entries);
  }
}
```

### Pattern 4: Notification Permission Request at First Use

**What:** Request notification permissions lazily when the user first enables reminders in settings, not at app launch.

**When:** First time user toggles "Enable reminders" on.

**Why:** Both iOS and Android present a one-shot permission dialog. Requesting at launch before the user understands why leads to denials that cannot be reversed without going to system Settings.

### Pattern 5: Cancel-Then-Reschedule for Notifications

**What:** Every time notification settings change, cancel ALL pending notifications and reschedule from scratch.

**When:** On settings change, app startup, and midnight rollover.

**Why:** The OS owns notification state, not the app. Trying to track "which notifications are currently pending" in the database is fragile and leads to duplicate or missed notifications. Stateless rescheduling is simpler and more reliable.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Watching Drift Streams Directly in Widgets via StreamBuilder

**What:** Using Flutter's `StreamBuilder` with a Drift `.watch()` stream inside a widget build method.

**Why bad:** Bypasses Riverpod's caching and lifecycle management. Multiple widgets watching the same query create duplicate database listeners. No automatic disposal or sharing.

**Instead:** Wrap Drift streams in Riverpod `StreamProvider`, watch those from widgets via `ref.watch`. Riverpod handles caching, sharing, and disposal.

### Anti-Pattern 2: God Database Class

**What:** Putting all queries in the `AppDatabase` class itself instead of using DAOs.

**Why bad:** The class grows to hundreds of methods. Drift's DAO system exists specifically to modularize queries by domain.

**Instead:** Use `@DriftAccessor` DAOs grouped by feature. `AppDatabase` references tables and DAOs but contains zero query methods.

### Anti-Pattern 3: Storing Notification State in the Database

**What:** Tracking pending notification IDs or scheduled times in SQLite.

**Why bad:** The OS owns notification state. It will desync from the database when users swipe away notifications, clear app data, reboot, or force-stop the app.

**Instead:** Treat notifications as fire-and-forget. On every relevant trigger (app launch, settings change), cancel all and reschedule from scratch using current settings. The database stores configuration (interval, DND window), not notification IDs.

### Anti-Pattern 4: Business Logic in Widgets

**What:** Calculating progress percentages, determining DND overlap, formatting dates, or computing daily totals inside widget build methods.

**Why bad:** Untestable, duplicated across screens, mixes presentation with logic.

**Instead:** Controllers compute derived state. Domain models carry computed properties (e.g., `DailyProgress.percentComplete`). Widgets only render.

### Anti-Pattern 5: Multiple Database Instances

**What:** Creating `AppDatabase()` in multiple places (e.g., in each DAO or repository constructor).

**Why bad:** SQLite file locking causes crashes. Drift's stream notification only works within a single instance.

**Instead:** Single instance via `appDatabaseProvider` at the root ProviderScope.

---

## Drift Database Schema Design

### Tables

```dart
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get timestamp => dateTime()();
  // Denormalized date key for efficient daily GROUP BY queries
  TextColumn get dateKey => text()(); // 'YYYY-MM-DD'
}

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyTargetMl =>
      integer().withDefault(const Constant(2000))();
  IntColumn get reminderIntervalMin =>
      integer().withDefault(const Constant(60))();
  TextColumn get dndStartTime =>
      text().withDefault(const Constant('22:00'))();
  TextColumn get dndEndTime =>
      text().withDefault(const Constant('07:00'))();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(false))();
}

class DrinkPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  TextColumn get label => text()();
  IntColumn get sortOrder => integer()();
}
```

### Key Schema Decisions

- **`dateKey` as denormalized text column:** Enables indexed GROUP BY queries for the calendar view without runtime date extraction from timestamps. Index on `dateKey` makes "all daily totals for a month" queries fast.
- **`UserSettings` is a single-row table (singleton):** The app reads/updates row id=1. Seed it in `MigrationStrategy.onCreate`. This keeps all persistent state in Drift (no SharedPreferences dependency), which is simpler for a Drift-centric app.
- **`DrinkPresets` with `sortOrder`:** Supports user-customizable button ordering on the home screen.
- **Store DateTimes as ISO-8601 text:** Enable `store_date_time_values_as_text: true` in `build.yaml` for better debugging, human readability, and timezone awareness.
- **`amountMl` as integer (not double):** Milliliters are always whole numbers for water tracking. Avoids floating-point comparison issues in aggregates.

### Index

```dart
@TableIndex(name: 'idx_water_entries_date_key', columns: {#dateKey})
class WaterEntries extends Table { ... }
```

The `dateKey` index is critical for calendar view performance. Without it, monthly aggregate queries require a full table scan.

---

## Platform-Specific Architecture: Notifications

### iOS Specifics

| Concern | Detail |
|---------|--------|
| **Notification limit** | iOS keeps only the 64 most recently scheduled local notifications. For a 60-min interval across 16 waking hours, that is ~16/day. Schedule 2-3 days ahead max. |
| **Permission timing** | Request via `IOSFlutterLocalNotificationsPlugin.requestPermissions()`. No second chance if denied -- user must go to system Settings manually. |
| **AppDelegate setup** | Must set `UNUserNotificationCenter.current().delegate = self` in `didFinishLaunchingWithOptions`. |
| **Background delivery** | iOS delivers scheduled local notifications even when the app is terminated. No background execution mode needed. |

### Android Specifics

| Concern | Detail |
|---------|--------|
| **Notification channels** | Required on Android 8.0+. Create a "Hydration Reminders" channel at initialization. Sound and vibration settings are locked at channel creation time. |
| **Exact alarms (Android 12+)** | Requires `SCHEDULE_EXACT_ALARM` permission. Android 14+ requires explicit user grant. Handle the revocation case gracefully. |
| **Boot receiver** | Register `ScheduledNotificationBootReceiver` in AndroidManifest.xml. Requires `RECEIVE_BOOT_COMPLETED` permission. Ensures notifications survive device reboot. |
| **Battery optimization** | Some OEMs (Xiaomi, Huawei, Samsung, Oppo) aggressively kill background apps and prevent alarm delivery. This is a known, unsolvable problem at the app level. Show a guidance screen linking to dontkillmyapp.com for affected devices. |
| **compileSdk** | Must be 35+ (or 36 for flutter_local_notifications 21.x). |
| **Java desugaring** | Required in build.gradle for scheduled notification features. |

### NotificationService Skeleton

```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // Request later, at first use
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      return await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    if (Platform.isAndroid) {
      return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  Future<void> scheduleNotification({
    required int id,
    required TZDateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  static void _onNotificationTapped(NotificationResponse response) {
    // Navigate to home screen or handle action
  }
}
```

---

## App Lifecycle Integration

### Startup Sequence

```
1. main() {
     WidgetsFlutterBinding.ensureInitialized();
     tz.initializeTimeZones();    // timezone package for zonedSchedule
   }
   |
2. ProviderScope wraps MaterialApp
   |
3. appDatabaseProvider lazily creates AppDatabase (Drift)
   |
4. NotificationService.initialize() called early via a startup provider
   |
5. On first frame: Home screen watches dailyProgressProvider
   -> triggers Drift query -> stream emits initial state
   |
6. NotificationScheduler checks if reminders are enabled
   -> if yes, reschedules from current settings (handles reboot / app update)
```

### App Resume (from background)

```
1. WidgetsBindingObserver.didChangeAppLifecycleState(resumed)
   |
2. Invalidate dailyProgressProvider to refresh "today" boundary
   (if app was backgrounded past midnight, "today" changed)
   |
3. Optionally re-check notification permissions
   (user may have revoked in system Settings while app was backgrounded)
```

### Settings Change -> Notification Reschedule

```
1. User changes reminder interval or DND window in Settings
   |
2. SettingsController saves new values to SettingsRepository -> Drift
   |
3. SettingsRepository stream emits new UserSettings
   |
4. NotificationScheduler watches settings stream
   -> on new emission: cancelAll() then reschedule with new parameters
```

---

## Suggested Build Order (Dependency-Driven)

Build in this order because each phase depends on the one before it.

### Phase 1: Data Foundation

Build first because every other component depends on data access.

1. **Domain models** (pure Dart classes -- WaterEntry, DailyProgress, UserSettings, DrinkPreset)
2. **Drift tables + AppDatabase** (schema, code generation)
3. **DAOs** (WaterDao, SettingsDao)
4. **Repositories** (WaterRepository, SettingsRepository wrapping DAOs)
5. **Core Riverpod providers** (appDatabaseProvider, repository providers, stream providers)
6. **Unit tests** with in-memory Drift database

### Phase 2: Core Tracking UI

The central value proposition -- add water, see progress. Depends on Phase 1 data layer.

1. **Home screen scaffold** (app bar, layout)
2. **Progress ring widget** (watches dailyProgressProvider)
3. **Quick-add buttons** (reads DrinkPresets provider, calls controller.addWater)
4. **Undo functionality** (controller.undoLast)
5. **Navigation / routing** (GoRouter with 3 routes: home, calendar, settings)

### Phase 3: Settings

Depends on Phase 1 data layer. Enables customization of target, presets, and notification config.

1. **Settings screen UI** (daily target input, preset editor, reminder toggle)
2. **Settings controller** (reads/writes via SettingsRepository)
3. **Seed default settings** in database migration onCreate

### Phase 4: Calendar

Read-only view over existing water_entries data. Depends on Phase 1 (data) and Phase 3 (daily target from settings).

1. **Calendar screen** (month view with green/red day markers)
2. **CalendarRepository** (aggregate query: GROUP BY dateKey)
3. **Calendar controller** (watches month summaries + daily target)

### Phase 5: Notifications

Most platform-specific feature with the most edge cases. Build last so the core app works without it and notification bugs do not block tracking.

1. **NotificationService** (platform initialization, permission flow)
2. **NotificationScheduler** (compute DND-aware times, schedule batch)
3. **Wire to settings** (watch remindersEnabled / interval / DND changes -> reschedule)
4. **Android manifest + iOS plist setup** (permissions, boot receiver, channels)
5. **Battery optimization guidance** (detect OEM, show dontkillmyapp.com link)

### Phase Ordering Rationale

- Phase 1 before everything: all features read/write data
- Phase 2 before Phase 3: the core loop must work with default values before customization exists
- Phase 3 before Phase 5: notification scheduling reads settings -- settings must exist first
- Phase 4 is independent of Phase 3/5 but needs daily target from settings, so after Phase 3
- Phase 5 last: most complex, most platform-specific, least critical to core value proposition

---

## Scalability Considerations

| Concern | v1 (current) | v2 (future) |
|---------|-------------|-------------|
| Data volume | ~10-20 entries/day, single device | Add data export/import (JSON/CSV) for backup |
| Schema changes | Drift step-by-step migrations | Use `drift_dev schema` tooling for verified migrations |
| State management | ~10-15 Riverpod providers | Code-gen with `@riverpod` annotation keeps it manageable |
| Notifications | zonedSchedule batch of ~50 | Push notifications if cloud sync is added |
| Platform code | flutter_local_notifications | Health kit / Google Fit would need method channels or plugins |
| Testing | Unit test repos with in-memory Drift DB | Widget tests with ProviderScope overrides |

A user logging 10 drinks/day for 10 years produces ~36,500 rows. SQLite handles this trivially with indexed queries.

---

## Sources

- Flutter official architecture guide: https://docs.flutter.dev/app-architecture/guide (HIGH confidence)
- Riverpod 3.3.0 documentation via Context7: pub.dev/documentation/flutter_riverpod/3.3.0 (HIGH confidence)
- Drift documentation via Context7: drift.simonbinder.eu (HIGH confidence)
- flutter_local_notifications pub.dev: https://pub.dev/packages/flutter_local_notifications (HIGH confidence)
- flutter_local_notifications v21.0.0 changelog: https://pub.dev/packages/flutter_local_notifications/changelog (HIGH confidence)
- Andrea Bizzotto, Flutter project structure: https://codewithandrea.com/articles/flutter-project-structure/ (MEDIUM confidence -- well-regarded community source)
- Andrea Bizzotto, Riverpod app architecture: https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/ (MEDIUM confidence -- community source)
