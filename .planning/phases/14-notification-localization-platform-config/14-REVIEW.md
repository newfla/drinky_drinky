---
phase: 14-notification-localization-platform-config
reviewed: 2026-06-15T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - android/app/build.gradle.kts
  - ios/Runner/Info.plist
  - lib/core/services/notification_service.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_es.arb
  - lib/l10n/app_fr.arb
  - lib/l10n/app_it.arb
  - lib/l10n/generated/app_localizations.dart
  - lib/l10n/generated/app_localizations_en.dart
  - lib/l10n/generated/app_localizations_es.dart
  - lib/l10n/generated/app_localizations_fr.dart
  - lib/l10n/generated/app_localizations_it.dart
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-06-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 14 adds notification localization (4 locales), a `_resolveLocale()` helper in
`NotificationService`, and platform configuration for Android and iOS. The ARB files and
generated Dart localizations are complete and consistent across all four locales. The
plist XML is well-formed and the Kotlin DSL syntax is correct.

Two correctness bugs were found in `notification_service.dart`. One is a potential
infinite loop when `notificationIntervalMinutes` is zero. The other is a logic-ordering
defect: `lookupAppLocalizations` and `cancelAll` are both executed before the
`!_initialized` guard, meaning locale lookup and notification cancellation happen on
every call regardless of whether the service is ready to schedule. While the
`!_initialized` early-return inside `cancelAll` prevents a crash, the ordering is
semantically wrong and creates a subtle state hazard. Additionally, `minSdk` in
`build.gradle.kts` diverges from the value documented in CLAUDE.md without explanation.

## Critical Issues

### CR-01: Zero-interval causes infinite loop in `scheduleWindow`

**File:** `lib/core/services/notification_service.dart:209-225`

**Issue:** The inner `while` loop advances `candidate` by
`Duration(minutes: settings.notificationIntervalMinutes)` on every iteration. If
`notificationIntervalMinutes` is `0`, `candidate` never advances, `scheduled` never
reaches `maxSlots`, and `candidate.isBefore(dayEnd)` remains permanently true — an
infinite loop that freezes the isolate. The outer `dayOffset > 30` safety valve only
increments in the outer loop and is therefore unreachable when the inner loop is
spinning. There is no validation of the interval value before it is used.

```dart
// Fix: guard before entering the scheduling loop
Future<void> scheduleWindow(UserSettingsEntity settings) async {
  // Validate interval to prevent infinite loop
  if (settings.notificationIntervalMinutes <= 0) return;

  await cancelAll();
  // ... rest of method unchanged
```

Alternatively, validate `notificationIntervalMinutes` at the settings layer (the
data class or the repository that persists it) and ensure it can never be zero or
negative.

---

### CR-02: `cancelAll()` and locale lookup execute before the `!_initialized` guard

**File:** `lib/core/services/notification_service.dart:167-172`

**Issue:** `scheduleWindow` calls `cancelAll()` (line 167) and
`lookupAppLocalizations(_resolveLocale())` (line 169) before the `if (!_initialized) return`
guard at line 171. The consequences:

1. **Silent notification wipe on uninitialized service.** `cancelAll()` itself guards
   with `if (!_initialized) return`, so when the service is uninitialized the call is a
   no-op — this is currently safe. However, if the inner guard is ever removed or the
   initialization order changes, all scheduled notifications are erased before the early
   return fires.

2. **Notifications wiped when permission check fails.** If `_initialized` is true but
   `permissionGranted()` returns `false` (line 172), `cancelAll()` has already erased
   all pending notifications and nothing is rescheduled. The user silently loses all
   reminders because permission was revoked between two calls.  Whether this is
   intentional is ambiguous — the comment on the method does not document this
   destructive behavior.

3. **Locale lookup wastefully runs even on early-return paths.** Minor but indicates
   the method body was not structured with the guards in mind.

The correct structure puts the initialized + permission guards first, then cancels,
then looks up the locale:

```dart
Future<void> scheduleWindow(UserSettingsEntity settings) async {
  if (!_initialized) return;
  if (!(await permissionGranted())) return;
  if (settings.notificationIntervalMinutes <= 0) return;  // from CR-01

  await cancelAll();

  final l10n = lookupAppLocalizations(_resolveLocale());

  // ... scheduling loop unchanged
}
```

This ordering ensures:
- The destructive `cancelAll()` only fires when the service is ready and permission
  is confirmed.
- The locale lookup is skipped on all no-op paths.

## Warnings

### WR-01: `minSdk` set to 26, contradicting the documented minimum of 24

**File:** `android/app/build.gradle.kts:27`

**Issue:** CLAUDE.md states "minSdk: 24 (Android 7.0) required by
flutter_local_notifications 21.x". The file sets `minSdk = 26` (Android 8.0). This
raises the device floor by two API levels without a documented rationale. Android 7.0
and 7.1 devices (API 24–25) represent a non-trivial share of the installed base in
some markets. If this deviation is intentional (e.g., a Drift or other dependency
actually requires API 26), the reason should be captured in a comment; if it is
accidental, it should be reverted to 24.

```kotlin
// Fix (if 24 is truly sufficient for all runtime dependencies):
minSdk = 24

// Or, if 26 is required, document why:
minSdk = 26  // Drift requires API 26; flutter_local_notifications permits 24
```

---

### WR-02: `lookupAppLocalizations` will throw `FlutterError` for any locale that slips past `_resolveLocale`

**File:** `lib/core/services/notification_service.dart:169` /
`lib/l10n/generated/app_localizations.dart:603-621`

**Issue:** `lookupAppLocalizations` ends with an unconditional `throw FlutterError(...)` for
unrecognised language codes. `_resolveLocale()` currently guarantees to return only
locales from `AppLocalizations.supportedLocales`, so in practice the throw cannot be
reached from `scheduleWindow`. However, there is no compile-time enforcement of this
coupling: `lookupAppLocalizations` is a public function and can be called from anywhere
with an arbitrary locale.

The specific risk here is that `_resolveLocale()` iterates `AppLocalizations.supportedLocales`
and returns the first match on `languageCode`. If a future locale is added to `supportedLocales`
but the `switch` in `lookupAppLocalizations` is not updated (easy to miss since this is
generated code that can be regenerated out of sync), the function throws an unhandled
`FlutterError` at runtime, crashing the scheduling path with no user-visible error
message.

The safest fix is to wrap the call at the call site:

```dart
AppLocalizations _lookupL10nSafe() {
  try {
    return lookupAppLocalizations(_resolveLocale());
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}
```

And replace line 169 with `final l10n = _lookupL10nSafe();`. This ensures the
notification path never crashes due to a localization misconfiguration.

## Info

### IN-01: ARB metadata annotations absent from non-English locale files

**File:** `lib/l10n/app_es.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_it.arb`

**Issue:** The English ARB includes `@`-prefixed metadata entries (e.g.
`@notificationBody`, `@tabHome`, etc.) with `description` fields. The other three
locale files omit all metadata. This is technically valid — Flutter's gen-l10n only
requires metadata in the template locale (English) — but it makes the non-English files
harder for future translators to understand without cross-referencing the English file.
No code impact; raised as a consistency note.

**Fix:** No code change required. If readability for translators is a concern, metadata
entries can be duplicated into each locale file, or left as-is since gen-l10n does not
require them outside the template locale.

---

_Reviewed: 2026-06-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
