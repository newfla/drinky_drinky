import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/user_settings_entity.dart';

/// Singleton service wrapping [FlutterLocalNotificationsPlugin].
///
/// Exposes imperative methods for scheduling and cancelling hydration reminders.
/// Accessed via [NotificationService.instance] — not a Riverpod provider because
/// notifications are imperative side effects, not reactive data streams.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'hydration_reminders';
  static const String _channelName = 'Hydration Reminders';
  static const String _notifTitle = 'Drinky Drinky';
  static const String _notifBody = 'Time to drink water! \u{1F4A7}';

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the plugin and (on Android) create the notification channel.
  ///
  /// Must be called once from [main()] after [WidgetsFlutterBinding.ensureInitialized()]
  /// and after the timezone database has been set up.
  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Defer permission to PermissionScreen (D-10): request*Permission: false
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // Create Android notification channel (required for Android 8+).
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Notification details
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  /// Request notification permission using the plugin's native per-platform API.
  ///
  /// Returns true if the user granted permission.
  /// Does NOT use [permission_handler] for the prompt (per official docs, D-10).
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  /// Check current notification permission status WITHOUT prompting.
  ///
  /// Android: uses [permission_handler] for status check.
  /// iOS: uses plugin's [checkPermissions()] to avoid prompting.
  Future<bool> permissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final opts = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Cancel all
  // ---------------------------------------------------------------------------

  /// Cancel all pending scheduled notifications and any displayed ones.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Schedule rolling window (D-04)
  // ---------------------------------------------------------------------------

  /// Cancel all pending notifications and schedule a rolling window of up to 64
  /// new notification slots honouring [settings.notificationIntervalMinutes] and
  /// the DND window.
  ///
  /// Guards:
  /// - Does nothing if not initialized.
  /// - Does nothing if permission is not granted.
  Future<void> scheduleWindow(UserSettingsEntity settings) async {
    await cancelAll();

    if (!_initialized) return;
    if (!(await permissionGranted())) return;

    const int maxSlots = 64;
    int slotId = 1000;
    int scheduled = 0;
    int dayOffset = 0;

    final now = tz.TZDateTime.now(tz.local);

    while (scheduled < maxSlots) {
      // Safety valve: avoid an infinite loop for very long intervals (> 1 day).
      if (dayOffset > 30) break;

      // For today (dayOffset == 0): start from now + interval.
      // For future days: start at the beginning of that day (00:00).
      var candidate = dayOffset == 0
          ? now.add(Duration(minutes: settings.notificationIntervalMinutes))
          : tz.TZDateTime(
              tz.local,
              now.year,
              now.month,
              now.day + dayOffset,
              0,
              0,
            );

      // End-of-day boundary: 23:59 local time on dayOffset day.
      final dayEnd = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + dayOffset,
        23,
        59,
      );

      // Walk through the day in interval steps, scheduling non-DND slots.
      while (candidate.isBefore(dayEnd) && scheduled < maxSlots) {
        if (!_isInDnd(candidate, settings)) {
          await _plugin.zonedSchedule(
            id: slotId++,
            scheduledDate: candidate,
            notificationDetails: _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            title: _notifTitle,
            body: _notifBody,
            matchDateTimeComponents: null,
          );
          scheduled++;
        }
        candidate = candidate.add(
          Duration(minutes: settings.notificationIntervalMinutes),
        );
      }

      dayOffset++;
    }
  }

  // ---------------------------------------------------------------------------
  // DND check (D-06)
  // ---------------------------------------------------------------------------

  /// Returns true if [slot] falls within the DND window defined by [settings].
  ///
  /// Handles overnight windows (e.g. 23:00–07:00) and same-day windows.
  /// All comparisons use total minutes to include minute-precision.
  bool _isInDnd(tz.TZDateTime slot, UserSettingsEntity settings) {
    if (!settings.dndEnabled) return false;

    final startMinutes =
        settings.dndStartHour * 60 + settings.dndStartMinute;
    final endMinutes = settings.dndEndHour * 60 + settings.dndEndMinute;
    final slotMinutes = slot.hour * 60 + slot.minute;

    // Edge case: zero-width window — treat as disabled.
    if (startMinutes == endMinutes) return false;

    if (endMinutes < startMinutes) {
      // Overnight window (e.g. start=23:00, end=07:00):
      // slot is in DND if it is >= start OR < end.
      return slotMinutes >= startMinutes || slotMinutes < endMinutes;
    } else {
      // Same-day window (e.g. start=13:00, end=14:00):
      // slot is in DND if it is >= start AND < end.
      return slotMinutes >= startMinutes && slotMinutes < endMinutes;
    }
  }
}
