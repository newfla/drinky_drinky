# Phase 13: String Extraction & Translation - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace every hardcoded string in all 6 screens with `context.l10n` calls, produce Italian/French/Spanish translations, and make the calculator screen crash-safe on non-Italian locales.

By end of this phase:
- `HydrationCalculatorScreen` uses `BiologicalSex`/`ClimateLevel` enums (not Italian string keys) for computation; display strings come from ARB via `context.l10n`
- All 6 screens (home, settings, history/calendar, calculator, permission screen, add-intake bottom sheet) + `app_router.dart` show fully translated text in the device's language
- `app_it.arb`, `app_fr.arb`, `app_es.arb` contain complete translations for all 79 keys
- `flutter analyze` passes with zero errors
- `flutter gen-l10n` produces updated generated files including it/fr/es implementations

Phase 12 already delivers: `app_en.arb` (79 keys), `context.l10n` extension, gen-l10n pipeline wired.
Phase 14 handles: NotificationService localization, iOS/Android platform declarations.

</domain>

<decisions>
## Implementation Decisions

### Translation Tone
- **D-01:** Italian translations use **tu informale** (not Lei). The app is a personal health/wellness tool — friendly, approachable tone. Example: "La tua raccomandazione" (not "La Sua").
- **D-02:** French translations use **tu** (not vous). Same rationale.
- **D-03:** Spanish translations use **tú** (not usted). Consistent informal tone across all 3 languages.

### "Streak" Translation
- **D-04:** "streak" translates as:
  - Italian: **"giorni consecutivi"** — e.g., `=0{Nessuna serie} =1{1 giorno consecutivo} other{{count} giorni consecutivi}`
  - French: **"jours consécutifs"** — e.g., `=0{Aucune série} =1{1 jour consécutif} other{{count} jours consécutifs}`
  - Spanish: **"días consecutivos"** — e.g., `=0{Sin racha} =1{1 día consecutivo} other{{count} días consecutivos}`
  - Note: for zero case in Italian/French/Spanish use the same `=0{...}` explicit pattern already established in app_en.arb.
  - French plural: French treats 0 and 1 as "one" category (CLDR) but our explicit `=0`/`=1` cases override CLDR — use the same `=0{...} =1{...} other{...}` pattern from app_en.arb for all 3 languages.

### Plan Structure
- **D-05:** 2 plans split by concern:
  - **Plan 1:** `BiologicalSex`/`ClimateLevel` enum refactor + widget string replacement with `context.l10n` across all 6 screens. No translation work — strings still display in English via EN ARB fallback.
  - **Plan 2:** Fill `app_it.arb`, `app_fr.arb`, `app_es.arb` with complete translations for all 79 keys + re-run `flutter gen-l10n` to produce updated generated files.

### Claude's Discretion
- `BiologicalSex` and `ClimateLevel` enum placement: new file `lib/domain/models/hydration_models.dart` (keeps domain logic out of screen files) OR inline in calculator screen — Claude chooses the pattern that fits existing codebase conventions.
- All other translation choices (section headers, error messages, button labels) follow standard Italian/French/Spanish usage; Claude has discretion where no specific term was discussed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — project constraints, tech stack, core value
- `.planning/REQUIREMENTS.md` — L10N-04, L10N-05, L10N-06 (requirements for this phase)

### Phase 12 Output (prerequisite artifacts)
- `.planning/phases/12-l10n-infrastructure/12-CONTEXT.md` — all Phase 12 decisions (ARB key naming, l10n.yaml config, context.l10n extension pattern)
- `lib/l10n/app_en.arb` — canonical 79-key English template; all 3 translation files must cover every key
- `lib/l10n/l10n_extensions.dart` — `context.l10n` accessor; all widget replacements use this pattern
- `lib/l10n/generated/app_localizations.dart` — generated class; widget replacements import this

### Source Files for Widget Replacement (read all before implementing Plan 1)
- `lib/core/router/app_router.dart` — 3 tab labels (tabHome, tabHistory, tabSettings)
- `lib/presentation/screens/home_screen.dart` — 13 keys
- `lib/presentation/screens/settings_screen.dart` — 20 keys
- `lib/presentation/screens/history_screen.dart` — 9 keys (includes dayStreak plural)
- `lib/presentation/screens/hydration_calculator_screen.dart` — 22 keys + enum refactor
- `lib/presentation/screens/permission_screen.dart` — 6 keys
- `lib/presentation/widgets/preset_edit_dialog.dart` — 5 keys

### Research
- `.planning/research/PITFALLS.md` — French plural anomaly, calculator map-key crash risk, widget test delegates

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/l10n/l10n_extensions.dart` — `context.l10n` extension: replace every `Text('hardcoded')` with `Text(context.l10n.keyName)`. All screens use `ConsumerWidget` or `ConsumerStatefulWidget` so `context` is always available.
- `lib/l10n/app_en.arb` — already has all 79 keys with correct camelCase names and `@metadata`; use key names from this file verbatim in widget replacements.

### Established Patterns
- All screen widgets extend `ConsumerWidget` or `ConsumerStatefulWidget` — `context` is the first parameter of `build(BuildContext context, WidgetRef ref)`.
- Import pattern for AppLocalizations: `import 'package:drinky_drinky/l10n/generated/app_localizations.dart';` (NOT `package:flutter_gen/...` — removed after Flutter 3.32).
- The `context.l10n` extension call requires the widget to be inside the `MaterialApp.router` widget tree (which all screens are).

### Integration Points
- `lib/presentation/screens/hydration_calculator_screen.dart:27-34` — `_sexFactors` map with Italian string keys and `_climateLabels` list: both must become enum-based before widget replacement to avoid crash on non-Italian locales.
- `lib/core/router/app_router.dart` — tab labels are rendered as `Text(...)` in the bottom navigation; replace with `context.l10n.tabHome` etc.

</code_context>

<specifics>
## Specific Ideas

- dayStreak ICU plural pattern for all 3 languages: use the same `=0{...} =1{...} other{...}` structure from `app_en.arb` — explicit `=0` and `=1` cases override CLDR category system and are safe for Italian, French, and Spanish.
- Italian "streak" phrasing: `=0{Nessuna serie} =1{1 giorno consecutivo} other{{count} giorni consecutivi}`
- French "streak" phrasing: `=0{Aucune série} =1{1 jour consécutif} other{{count} jours consécutifs}`
- Spanish "streak" phrasing: `=0{Sin racha} =1{1 día consecutivo} other{{count} días consecutivos}`

</specifics>

<deferred>
## Deferred Ideas

- NotificationService localization → Phase 14 (L10N-07)
- iOS `Info.plist` CFBundleLocalizations → Phase 14 (L10N-08)
- Android `resConfigs` → Phase 14 (L10N-09)
- Human review of machine translations → v1.4+ (L10N-FUTURE-01)

</deferred>

---

*Phase: 13-String Extraction & Translation*
*Context gathered: 2026-06-15*
