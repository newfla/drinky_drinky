# Requirements: Drinky Drinky

**Defined:** 2026-06-15
**Core Value:** The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## v1.3 Requirements

Requirements for milestone v1.3 (Multilingual Support).

### Infrastruttura l10n

- [ ] **L10N-01**: App carica le traduzioni via Flutter gen-l10n (`flutter_localizations` SDK dep, `l10n.yaml` con `synthetic-package: false`, `generate: true` in `pubspec.yaml`)
- [ ] **L10N-02**: `MaterialApp.router` dichiara `localizationsDelegates` e `supportedLocales` per it/en/fr/es; lingua di sistema seguita automaticamente con EN fallback via `basicLocaleListResolution`
- [ ] **L10N-03**: `initializeDateFormatting()` chiamata in `main()` per le 4 lingue (table_calendar usa intl per i nomi dei mesi)

### Estrazione stringhe UI

- [ ] **L10N-04**: `HydrationCalculatorScreen` refactora `_sexFactors` e `_climateLabels` da Italian display-string keys a enum (`BiologicalSex` / `ClimateLevel`) — prerequisito anti-crash per tutte le lingue non-italiane
- [ ] **L10N-05**: Tutte le stringhe visibili nelle 6 schermate (home, settings, history/calendar, calculator, permission screen, add-intake bottom sheet) estratte in `app_en.arb` come template canonico con chiavi semantiche e metadata `@key`
- [ ] **L10N-06**: File `app_it.arb`, `app_fr.arb`, `app_es.arb` prodotti con traduzioni machine-generated; plurali ICU corretti (French: `one` category copre 0 e 1)

### Notifiche

- [ ] **L10N-07**: `NotificationService` usa `lookupAppLocalizations(basicLocaleListResolution(platformDispatcher.locales, supportedLocales))` per ottenere titolo/corpo del reminder nella lingua corrente senza `BuildContext`

### Platform Config

- [ ] **L10N-08**: iOS `Info.plist` aggiunge `CFBundleLocalizations` con `it`, `fr`, `es` (senza questa voce iOS non segnala il locale a Flutter anche se il device è impostato in italiano)
- [ ] **L10N-09**: Android `build.gradle.kts` aggiunge `resConfigs("en", "it", "fr", "es")` per bundle splits corretti

## Future Requirements

Requirements deferred to a future milestone.

### Qualità traduzioni

- **L10N-FUTURE-01**: Revisione umana nativa per it/fr/es — machine-translation prodotta in v1.3, review quality-gate per v1.4+

### Lingue aggiuntive

- **L10N-FUTURE-02**: Tedesco (de), Portoghese (pt) — lingue con base utenti rilevante ma fuori scope v1.3

## Out of Scope

| Feature | Reason |
|---------|--------|
| Override lingua in-app | Sistema deve seguire il device; override manuale aggiunge complessità UX non giustificata per v1.3 |
| Layout RTL | en/it/fr/es sono tutte LTR; nessun rischio |
| App Store metadata localization | Testi store (description, screenshots) gestiti fuori dal codebase |
| Notification channel name localization | Canal name raramente visibile all'utente; polish item per v1.4+ |
| Salvataggio lingua scelta | Privacy by design — nessun dato personale aggiuntivo; locale viene da sistema |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| L10N-01 | — | Pending |
| L10N-02 | — | Pending |
| L10N-03 | — | Pending |
| L10N-04 | — | Pending |
| L10N-05 | — | Pending |
| L10N-06 | — | Pending |
| L10N-07 | — | Pending |
| L10N-08 | — | Pending |
| L10N-09 | — | Pending |

**Coverage:**

- v1.3 requirements: 9 total
- Mapped to phases: 0
- Unmapped: 9 (roadmap pending)

---
*Requirements defined: 2026-06-15*
*Last updated: 2026-06-15 — initial definition for v1.3 Multilingual Support*
