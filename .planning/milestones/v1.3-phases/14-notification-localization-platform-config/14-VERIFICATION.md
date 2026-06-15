---
phase: 14-notification-localization-platform-config
verified: 2026-06-15T18:00:00Z
status: human_needed
score: 3/3 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Switch device language to Italian on a physical or simulator device, trigger a hydration reminder notification, and confirm the body text reads 'È ora di bere acqua! 💧' rather than 'Time to drink water! 💧'"
    expected: "Notification body appears in Italian when device locale is set to Italian"
    why_human: "Cannot programmatically verify runtime PlatformDispatcher locale resolution or the actual displayed notification text without running the app on a device"
  - test: "Switch device language to French, trigger a notification, confirm body is 'C'est l'heure de boire de l'eau ! 💧'"
    expected: "Notification body appears in French when device locale is set to French"
    why_human: "Runtime behavior cannot be verified by static analysis"
  - test: "Switch device language to Spanish, trigger a notification, confirm body is '¡Es hora de beber agua! 💧'"
    expected: "Notification body appears in Spanish when device locale is set to Spanish"
    why_human: "Runtime behavior cannot be verified by static analysis"
  - test: "On iOS simulator, switch to Italian locale, cold-launch the app, then verify PlatformDispatcher.instance.locales.first.languageCode == 'it' is reachable (breakpoint or log in _resolveLocale)"
    expected: "CFBundleLocalizations declaration causes iOS to surface the correct preferred locale to Flutter engine"
    why_human: "The CFBundleLocalizations key exists in the plist but its effect (correct locale propagation to Flutter) requires runtime validation on iOS"
---

# Phase 14: Notification Localization & Platform Config — Verification Report

**Phase Goal:** Notification reminders arrive in the user's language and both iOS and Android correctly detect the app's supported locales
**Verified:** 2026-06-15T18:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `notificationBody` key exists in all 4 ARBs, `_resolveLocale()` is implemented in NotificationService, and `lookupAppLocalizations` is called in `scheduleWindow()` | VERIFIED | Key present in all 4 ARBs (lines 487, 119, 119, 119 of en/it/fr/es). `_resolveLocale()` at line 145 of notification_service.dart. `lookupAppLocalizations(_resolveLocale())` at line 175. `l10n.notificationBody` passed to `zonedSchedule` at line 223. |
| 2 | `CFBundleLocalizations` array with en/it/fr/es exists in `ios/Runner/Info.plist` | VERIFIED | Lines 9-15 of Info.plist: `<key>CFBundleLocalizations</key>` followed by `<array>` with `<string>en</string>`, `<string>it</string>`, `<string>fr</string>`, `<string>es</string>`. plist is well-formed (`plutil -lint`: OK). |
| 3 | `resourceConfigurations += setOf("en", "it", "fr", "es")` exists in `android/app/build.gradle.kts` defaultConfig block | VERIFIED | Line 31 of build.gradle.kts, inside the `defaultConfig {}` block (lines 22-32). Exact Kotlin DSL syntax matches requirement. |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/l10n/app_en.arb` | `notificationBody` key with EN value and `@notificationBody` metadata | VERIFIED | "notificationBody": "Time to drink water! 💧" at line 487; @notificationBody metadata at lines 488-490 |
| `lib/l10n/app_it.arb` | `notificationBody` key with IT value | VERIFIED | "notificationBody": "È ora di bere acqua! 💧" at line 119 |
| `lib/l10n/app_fr.arb` | `notificationBody` key with FR value | VERIFIED | "notificationBody": "C'est l'heure de boire de l'eau ! 💧" at line 119 |
| `lib/l10n/app_es.arb` | `notificationBody` key with ES value | VERIFIED | "notificationBody": "¡Es hora de beber agua! 💧" at line 119 |
| `lib/l10n/generated/app_localizations.dart` | `String get notificationBody;` in abstract class | VERIFIED | Line 583: `String get notificationBody;` with documentation comment. `lookupAppLocalizations` function present at line 603. |
| `lib/l10n/generated/app_localizations_en.dart` | `notificationBody` getter returning EN text | VERIFIED | Line 292: `String get notificationBody => 'Time to drink water! 💧';` |
| `lib/l10n/generated/app_localizations_it.dart` | `notificationBody` getter returning IT text | VERIFIED | Line 297: `String get notificationBody => 'È ora di bere acqua! 💧';` |
| `lib/l10n/generated/app_localizations_fr.dart` | `notificationBody` getter returning FR text | VERIFIED | Line 297: `String get notificationBody => 'C\'est l\'heure de boire de l\'eau ! 💧';` |
| `lib/l10n/generated/app_localizations_es.dart` | `notificationBody` getter returning ES text | VERIFIED | Line 296: `String get notificationBody => '¡Es hora de beber agua! 💧';` |
| `lib/core/services/notification_service.dart` | `_resolveLocale()` method, `lookupAppLocalizations` call, `l10n.notificationBody` in `zonedSchedule` | VERIFIED | `_resolveLocale()` at lines 145-153; `lookupAppLocalizations(_resolveLocale())` at line 175 (with try/catch English fallback at line 177); `body: l10n.notificationBody` at line 223 |
| `ios/Runner/Info.plist` | `CFBundleLocalizations` array with en/it/fr/es | VERIFIED | Lines 9-15; plist is well-formed |
| `android/app/build.gradle.kts` | `resourceConfigurations += setOf("en", "it", "fr", "es")` in defaultConfig | VERIFIED | Line 31 inside `defaultConfig {}` block |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `notification_service.dart` | `app_localizations.dart` | `import '../../l10n/generated/app_localizations.dart'` | WIRED | Import at line 9; `lookupAppLocalizations` called at line 175 |
| `notification_service.dart` | `dart:ui` | `import 'dart:ui' show Locale, PlatformDispatcher` | WIRED | Import at line 2; `PlatformDispatcher.instance.locales` used in `_resolveLocale()` at line 146; `Locale` used as return type and in literals |
| `_resolveLocale()` | `AppLocalizations.supportedLocales` | `for (final supported in AppLocalizations.supportedLocales)` | WIRED | Line 149 iterates `supportedLocales` to find a `languageCode` match |
| `lookupAppLocalizations` | `zonedSchedule` | `body: l10n.notificationBody` | WIRED | `l10n` assigned at line 175, consumed at line 223 in `_plugin.zonedSchedule(...)` |
| `CFBundleLocalizations` | iOS locale detection | plist entry in `ios/Runner/Info.plist` | WIRED (runtime unverifiable) | Key exists at lines 9-15; runtime effect requires device testing |
| `resourceConfigurations` | Android APK locale stripping | `defaultConfig` in `build.gradle.kts` | WIRED (build-time) | Line 31 inside correct block; effect verified at build time only |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `notification_service.dart` `scheduleWindow()` | `l10n` (AppLocalizations) | `lookupAppLocalizations(_resolveLocale())` which reads `PlatformDispatcher.instance.locales` at runtime | Yes — locale resolved from actual device locale list; localizations backed by generated ARB strings, not hardcoded | FLOWING |
| `notification_service.dart` `scheduleWindow()` | `l10n.notificationBody` | Generated locale file (e.g., `app_localizations_it.dart` returning `'È ora di bere acqua! 💧'`) | Yes — real translated strings from ARB pipeline | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED — cannot run the Flutter app or trigger notification scheduling without a device/emulator. The notification scheduling path requires an initialized `FlutterLocalNotificationsPlugin` and a live device.

### Probe Execution

Step 7c: SKIPPED — no probe scripts found in `scripts/*/tests/probe-*.sh` for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| L10N-07 | 14-01-PLAN.md | NotificationService uses `lookupAppLocalizations` to get localized title/body without BuildContext | SATISFIED (with intentional deviation) | `lookupAppLocalizations(_resolveLocale())` at line 175. Deviation: REQUIREMENTS.md specifies `basicLocaleListResolution` but D-01 (LOCKED in 14-CONTEXT.md) mandates primary-only resolution — same behavior as `main.dart` since Phase 13 UAT commit d38615a. The intent (locale-aware notifications without BuildContext) is fully met. |
| L10N-08 | 14-02-PLAN.md | iOS Info.plist adds CFBundleLocalizations for it/fr/es (and en) | SATISFIED | `<key>CFBundleLocalizations</key>` with en/it/fr/es array at lines 9-15 of Info.plist. plutil validation: OK. |
| L10N-09 | 14-02-PLAN.md | Android build.gradle.kts adds resourceConfigurations for en/it/fr/es | SATISFIED | `resourceConfigurations += setOf("en", "it", "fr", "es")` at line 31 inside `defaultConfig {}` |

**Note on L10N-07 deviation:** REQUIREMENTS.md line 24 says `basicLocaleListResolution(platformDispatcher.locales, supportedLocales)`. The implementation uses a custom primary-only loop per D-01 (locked). This deviation was deliberate and pre-established in Phase 13 (commit d38615a: "Replace basicLocaleListResolution with a localeListResolutionCallback that considers only locales.first"). The phase CONTEXT.md documents D-01 as LOCKED. The observable outcome — notification body in the device's primary language with English fallback — is identical. This is not a gap.

**Note on L10N-08:** REQUIREMENTS.md says `it`, `fr`, `es` (without `en`). The implementation includes `en` as well. This is explicitly addressed in 14-02-PLAN.md Notes section: "including en explicitly is harmless and makes the supported set unambiguous." The plist is a superset of the requirement.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `android/app/build.gradle.kts` | 23 | `// TODO: Specify your own unique Application ID` | Warning | Pre-existing Flutter template boilerplate; applicationId is already set on the next line (`com.bizzarri.drinky_drinky`). TODO is stale, not a genuine gap. |
| `android/app/build.gradle.kts` | 36 | `// TODO: Add your own signing config for the release build.` | Warning | Pre-existing Flutter template boilerplate about release signing. Unrelated to phase goal (locale configuration). Does not block notification localization or locale detection. |

Both TODOs are in the `Warning` category (not the BLOCKER-tier `TBD`/`FIXME`/`XXX` markers). Both pre-exist Phase 14 and are generated by Flutter's project template. Neither prevents the phase goal.

### Human Verification Required

#### 1. Italian notification body at runtime

**Test:** Set the device/simulator language to Italian. Open the app, grant notification permission, wait for a scheduled notification to fire (or reduce the interval to the minimum for testing). Check the notification body text.
**Expected:** Notification body reads "È ora di bere acqua! 💧"
**Why human:** `_resolveLocale()` reads `PlatformDispatcher.instance.locales` which is only populated correctly at runtime with a real device locale. Static analysis confirms the code path is wired but cannot execute the PlatformDispatcher call or observe the rendered notification.

#### 2. French notification body at runtime

**Test:** Set device/simulator language to French, trigger a notification.
**Expected:** Notification body reads "C'est l'heure de boire de l'eau ! 💧"
**Why human:** Same reason as above — runtime-only behavior.

#### 3. Spanish notification body at runtime

**Test:** Set device/simulator language to Spanish, trigger a notification.
**Expected:** Notification body reads "¡Es hora de beber agua! 💧"
**Why human:** Same reason as above — runtime-only behavior.

#### 4. iOS CFBundleLocalizations locale propagation

**Test:** On iOS simulator, set language to Italian. Cold-launch the app. Verify that the Flutter engine receives `it` as the primary locale (e.g., via breakpoint in `_resolveLocale()` or a temporary debug log showing `PlatformDispatcher.instance.locales.first.languageCode`).
**Expected:** `locales.first.languageCode == 'it'` when device is set to Italian
**Why human:** `CFBundleLocalizations` is the iOS handshake that tells the OS which languages the app supports. The key exists in the plist (verified), but whether it correctly causes the OS to propagate the selected locale to the Flutter engine requires iOS runtime testing. Without this key, `PlatformDispatcher.instance.locales` may still reflect the correct locale on some iOS versions — the test confirms the key has the intended effect.

### Gaps Summary

No gaps found. All three success criteria are fully implemented:
- `notificationBody` key exists in all 4 ARBs with correct translations, `String get notificationBody;` is declared in the abstract class and implemented in all 4 generated locale files, `_resolveLocale()` is implemented using primary-only locale matching (D-01), and `lookupAppLocalizations` is called in `scheduleWindow()` with `l10n.notificationBody` flowing to `_plugin.zonedSchedule()`.
- `CFBundleLocalizations` with all 4 locales is present in `ios/Runner/Info.plist` and the file is well-formed XML.
- `resourceConfigurations += setOf("en", "it", "fr", "es")` is present in `defaultConfig {}` of `android/app/build.gradle.kts`.

The `status: human_needed` reflects that runtime verification of notification locale delivery and iOS locale propagation requires device testing — not code gaps.

---

_Verified: 2026-06-15T18:00:00Z_
_Verifier: Claude (gsd-verifier)_
