---
status: complete
phase: 05-notifications
source: [05-01-SUMMARY.md]
started: 2026-06-08T00:00:00Z
updated: 2026-06-08T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running app instance. Relaunch from scratch (flutter run or tap app icon). App boots without errors, no Drift or NotificationService crash in the console, and the PermissionScreen (or Home screen if already granted) appears cleanly.
result: pass

### 2. First-launch PermissionScreen appears
expected: On a fresh install (or after clearing app data / removing the drinky_permissionScreenShown SharedPreferences key), open the app. Instead of going directly to the Home tab, the app shows a PermissionScreen — an explanation of why notifications are needed, with a "Grant Access" button and a "Skip" or "Not now" option. The bottom NavigationBar is NOT visible on this screen.
result: pass

### 3. Grant permissions → confirmation → Home
expected: On the PermissionScreen, tap "Grant Access". The OS permission prompt appears ("Drinky Drinky would like to send you notifications"). Tap "Allow". A SnackBar briefly appears confirming access was granted. The app then navigates to the Home tab with the bottom NavigationBar visible. The PermissionScreen does not reappear on subsequent launches.
result: pass

### 4. Skip permissions → Home (no prompt)
expected: Clear app data so PermissionScreen shows again. On the PermissionScreen, tap "Skip" (or "Not now"). The OS system prompt does NOT appear. The app navigates directly to the Home tab. The PermissionScreen does not reappear on subsequent launches.
result: pass

### 5. Permission denied banner in Settings
expected: Deny notifications for the app in system settings (iOS: Settings → Drinky Drinky → Notifications off; Android: App Info → Notifications off). Open the app and navigate to the Settings tab. A banner is visible at the top of the Settings screen saying notifications are disabled, with a button labeled something like "Open Settings" or "Enable". Tapping it opens the system settings for the app.
result: pass

### 6. Goal-reached cancels reminders
expected: Set your notification interval to a short value (e.g. 5 min) in Settings. Log enough water to meet your daily goal (ring turns green, "Goal reached!" appears). After the next scheduled interval passes (or check the scheduled notifications list via developer tools), no new notification fires — the reminder series has been cancelled. Logging more water past the goal does not restart notifications.
result: pass

### 7. DND window blocks notifications during quiet hours
expected: In Settings, enable the DND quiet window and set it to cover the current time (e.g. start 00:00, end 23:59 to block all day, or a 2-hour window that includes the current time). Wait for the notification interval to pass. No notification fires during the DND window. After the DND window ends (or if you update the DND end time to be before now), the next interval fires normally.
result: pass

### 8. Interval change reschedules on settings save
expected: Change the notification interval slider in Settings (e.g. from 60 min to 30 min) and release. The app does not crash. Notifications are rescheduled with the new interval — the next reminder should arrive closer to the new interval, not the old one. Reopening the app after a kill-and-reopen should still use the new interval.
result: issue
reported: "si funziona ma l'ultimo carattere della notific appare come simblo non riconosciuto"
severity: cosmetic

## Summary

total: 8
passed: 7
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Notification text renders cleanly with no garbled or unrecognized characters at the end"
  status: fixed
  reason: "User reported: si funziona ma l'ultimo carattere della notific appare come simblo non riconosciuto"
  severity: cosmetic
  test: 8
  root_cause: "notification_service.dart:25 — _notifBody ends with \\u{1F4A7} (💧, U+1F4A7, a supplementary plane emoji). Some Android versions and notification renderers do not support 4-byte emoji in notification body text, rendering it as an unrecognized symbol."
  artifacts:
    - path: "lib/core/services/notification_service.dart"
      issue: "Line 25: _notifBody uses \\u{1F4A7} emoji which fails to render on some devices"
  missing:
    - "Replace \\u{1F4A7} with a BMP-safe alternative or remove the emoji from _notifBody"
  debug_session: ""
