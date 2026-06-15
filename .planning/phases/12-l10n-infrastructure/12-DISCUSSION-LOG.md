# Phase 12: L10n Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 12-l10n-infrastructure
**Areas discussed:** Scope ARB in Phase 12, Cupertino delegates, locale su TableCalendar

---

## Scope ARB in Phase 12

| Option | Description | Selected |
|--------|-------------|----------|
| Solo scheletro (2-3 stringhe test) | app_en.arb ha solo appTitle + 1-2 stringhe esempio per verificare che il pipeline gira. Phase 13 aggiunge tutte le ~67 stringhe reali. | |
| ARB completo EN (tutte le stringhe) | Phase 12 estrae già tutte le stringhe EN in app_en.arb. Phase 13 inizia già con il template pronto — deve solo fare il refactor calculator e le traduzioni it/fr/es. | ✓ |

**User's choice:** ARB completo EN (tutte le stringhe)
**Notes:** Questa decisione sposta L10N-05 effettivamente in Phase 12. Phase 13 diventa: refactor calculator enum + sostituzione hardcoded strings nei widget + file it/fr/es.

---

## Cupertino delegates

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, includerlo | I bottoni di showTimePicker su iOS (OK/Cancel) usano Cupertino — senza questo delegate restano in inglese anche quando la lingua è italiana. L'aggiunta è una singola riga. | ✓ |
| No, solo Material + Widgets | Mantieni solo GlobalMaterialLocalizations + GlobalWidgetsLocalizations. Minore superficie, ma i date/time picker iOS non localizzati. | |

**User's choice:** Sì, includerlo
**Notes:** 4 delegate totali in localizationsDelegates.

---

## locale su TableCalendar

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 12 — fa parte dell'infrastruttura | TableCalendar.locale viene impostato da Localizations.localeOf(context).toString() già in Phase 12. I nomi di mesi/giorni si localizzano subito insieme agli altri Material widget. | ✓ |
| Phase 13 — è una stringa UI | I nomi dei mesi sono stringhe visibili — trattale come le altre nell'estrazione Phase 13. Phase 12 lascia locale: non impostato (usa default EN). | |

**User's choice:** Phase 12 — fa parte dell'infrastruttura
**Notes:** Coerente con la logica che l'infrastruttura Phase 12 deve portare tutti i widget Material/platform alla lingua corretta.

---

## Claude's Discretion

- ARB key naming: camelCase semantico (es. `homeGoalLabel`, `settingsTargetTitle`)
- l10n.yaml: `nullable-getter: false`, `output-class: AppLocalizations`, `output-dir: lib/l10n/generated`, `synthetic-package: false`
- Context extension: `extension AppLocalizationsX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this)!; }` in `lib/l10n/l10n_extensions.dart`

## Deferred Ideas

- NotificationService localization → Phase 14
- iOS CFBundleLocalizations / Android resConfigs → Phase 14
- Calculator enum refactor + widget replacement + it/fr/es → Phase 13
