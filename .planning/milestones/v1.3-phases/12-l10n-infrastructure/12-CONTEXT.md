# Phase 12: L10n Infrastructure - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Get the gen-l10n pipeline running and wired into `MaterialApp.router`. By the end of this phase:
- `flutter gen-l10n` produces a working `AppLocalizations` class with `of(context)` accessor
- `MaterialApp.router` resolves device locale (it/en/fr/es) with EN fallback
- `app_en.arb` contains ALL ~67 English strings (full template, not skeleton)
- `table_calendar` month/day names follow the device locale
- `initializeDateFormatting()` called in `main()` for all 4 locales

Phase 13 handles: calculator enum refactor + widget string replacement + it/fr/es translations.
Phase 14 handles: NotificationService localization + iOS/Android platform declarations.

</domain>

<decisions>
## Implementation Decisions

### ARB Template Scope in Phase 12

- **D-01:** Phase 12 produces a **complete** `app_en.arb` with all ~67 English strings — not a skeleton. This effectively covers L10N-05 in Phase 12, not Phase 13. Phase 13 starts with the full ARB template already defined and focuses only on widget replacement + translations.
- **D-02:** ARB output directory: `lib/l10n/` for source ARBs (`app_en.arb`, `app_it.arb`, etc.), `lib/l10n/generated/` for gen-l10n output (`app_localizations.dart`, `app_localizations_en.dart`, etc.). Configured via `l10n.yaml` with `synthetic-package: false` and `output-dir: lib/l10n/generated`.

### localizationsDelegates

- **D-03:** Include **4 delegates** in `MaterialApp.router.localizationsDelegates`:
  1. `AppLocalizations.delegate` (generated)
  2. `GlobalMaterialLocalizations.delegate`
  3. `GlobalWidgetsLocalizations.delegate`
  4. `GlobalCupertinoLocalizations.delegate` — required for iOS time pickers (DND showTimePicker uses Cupertino on iOS; without this delegate, OK/Cancel labels stay in English regardless of device language)

### Locale Resolution

- **D-04:** Use Flutter's built-in `basicLocaleListResolution` (no custom `localeResolutionCallback`). English must be listed **first** in `supportedLocales` to serve as automatic fallback for unsupported locales (e.g., German → English).
- **D-05:** `supportedLocales` order: `[Locale('en'), Locale('it'), Locale('fr'), Locale('es')]`

### TableCalendar

- **D-06:** Wire `locale: Localizations.localeOf(context).toString()` in `HistoryScreen`'s `TableCalendar` widget in **Phase 12** (not Phase 13). Month/day name localization is infrastructure, not a UI string extraction task.

### l10n.yaml Config (Claude's Discretion)

Phase 12 should configure `l10n.yaml` with:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
synthetic-package: false
nullable-getter: false
```
`nullable-getter: false` avoids null-checking boilerplate — all calls are `AppLocalizations.of(context)!` or the recommended extension pattern `context.l10n`.

### Claude's Discretion

- ARB key naming convention: use camelCase semantic keys (e.g., `homeGoalLabel`, `settingsTargetTitle`, not positional/descriptive names like `string1`). Keys should be stable — they are the long-lived contract between ARBs.
- Context extension: add `extension AppLocalizationsX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this)!; }` in `lib/l10n/l10n_extensions.dart` for ergonomic access — reduces verbosity from `AppLocalizations.of(context)!.xxx` to `context.l10n.xxx` across all screens.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — project constraints, tech stack, core value
- `.planning/REQUIREMENTS.md` — L10N-01, L10N-02, L10N-03 (L10N-05 also covered in this phase per D-01)

### Codebase Integration Points
- `lib/main.dart` — `MaterialApp.router` inside `DynamicColorBuilder`; this is where `localizationsDelegates` and `supportedLocales` are added
- `lib/presentation/screens/history_screen.dart` — contains `TableCalendar`; add `locale:` parameter here
- `pubspec.yaml` — add `flutter_localizations: sdk: flutter` + `generate: true` under `flutter:`

### Research
- `.planning/research/STACK.md` — exact pubspec changes, l10n.yaml config, gen-l10n commands
- `.planning/research/ARCHITECTURE.md` — MaterialApp wiring pattern, locale resolution order, output-dir setup
- `.planning/research/PITFALLS.md` — `synthetic-package: false` is mandatory on Flutter 3.44.1; `generate: true` required since Flutter 3.28

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/main.dart:DrinkyDrinkyApp` — single widget, wraps `MaterialApp.router`; `localizationsDelegates`/`supportedLocales` added directly here
- `lib/presentation/screens/history_screen.dart` — uses `TableCalendar`; `locale:` param goes directly on the widget

### Established Patterns
- All widgets use `ConsumerWidget` or `ConsumerStatefulWidget` — the `context` is always available for `context.l10n` calls
- Singleton pattern used for `NotificationService` — Phase 14 will use `lookupAppLocalizations()` + `platformDispatcher` (not relevant here)
- No existing l10n layer — this phase creates it from scratch

### Integration Points
- `lib/main.dart:DrinkyDrinkyApp.build()` — `MaterialApp.router(...)` is the wiring point for `localizationsDelegates`, `supportedLocales`
- `lib/core/notifications/notification_service.dart` — NOT touched in Phase 12; localized strings added in Phase 14
- `lib/l10n/` (new) — source ARBs and generated output live here

</code_context>

<specifics>
## Specific Ideas

- Phase 12 produces the **full** English ARB template (all strings), not just infrastructure + placeholder — this shifts L10N-05 into Phase 12 and keeps Phase 13 focused on replacement + translations
- 4 localizationsDelegates including Cupertino — explicitly chosen for iOS time picker correctness
- TableCalendar locale wired in Phase 12 — part of infrastructure, not string extraction

</specifics>

<deferred>
## Deferred Ideas

- NotificationService localization → Phase 14 (L10N-07)
- iOS `Info.plist` CFBundleLocalizations → Phase 14 (L10N-08)
- Android `resConfigs` → Phase 14 (L10N-09)
- Calculator `BiologicalSex`/`ClimateLevel` enum refactor → Phase 13 (L10N-04)
- Widget string replacement + it/fr/es ARB files → Phase 13 (L10N-05 remains as replacement task, L10N-06)

</deferred>

---

*Phase: 12-L10n Infrastructure*
*Context gathered: 2026-06-15*
