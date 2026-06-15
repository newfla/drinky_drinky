---
status: partial
phase: 14-notification-localization-platform-config
source: [14-VERIFICATION.md]
started: 2026-06-15T17:30:00Z
updated: 2026-06-15T17:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Italian notification body at runtime
expected: Set device to Italian. Trigger a notification (set a short interval, lock the screen or use simulator, wait for the reminder to fire). Confirm the notification body text reads "È ora di bere acqua! 💧".
result: [pending]

### 2. French notification body at runtime
expected: Set device to French. Trigger a notification. Confirm the notification body text reads "C'est l'heure de boire de l'eau ! 💧".
result: [pending]

### 3. Spanish notification body at runtime
expected: Set device to Spanish. Trigger a notification. Confirm the notification body text reads "¡Es hora de beber agua! 💧".
result: [pending]

### 4. iOS CFBundleLocalizations propagation
expected: On iOS simulator set to Italian locale, confirm the app UI and notification locale is Italian (CFBundleLocalizations causes the OS to correctly signal the locale to Flutter's PlatformDispatcher).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
