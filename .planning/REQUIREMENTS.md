# Requirements: Drinky Drinky

**Defined:** 2026-06-10
**Core Value:** The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## v1.2 Requirements

Requirements for milestone v1.2 (Bug Fixes & Feature Depth).

### Bug Fixes

- [ ] **BUG-01**: `deleteLastEntry` aggiunge filtro `WHERE dateKey = :today` per evitare cancellazione cross-day (undo dell'ultima entry di ieri invece di oggi)
- [ ] **BUG-02**: La data corrente si aggiorna a mezzanotte senza richiedere restart dell'app (il provider con `_todayDateKey()` viene invalidato alla mezzanotte)
- [ ] **BUG-03**: `dateKey` valida sia formato (regex YYYY-MM-DD) sia semantica (DateTime.tryParse), rifiutando date come 2024-02-30

### Target History

- [ ] **TARGET-01**: Nuova tabella Drift `target_history (id, effectiveDate TEXT UNIQUE, targetMl INTEGER)` con migration schema v1→v2 e sentinel row per utenti esistenti (`effectiveDate = '2000-01-01'`)
- [ ] **TARGET-02**: Nuovo setting "Applica target da: oggi / da domani" — la scelta viene applicata ad ogni modifica del target nei Settings
- [ ] **TARGET-03**: Home screen usa il target effettivo della giornata corrente (query su `target_history`) per il progress ring e il testo goal
- [ ] **TARGET-04**: Calendario usa il target effettivo della giornata appropriata (query su `target_history`) per determinare verde/rosso per ogni giorno

### Hydration Calculator

- [ ] **CALC-01**: Schermata calcolatore con input sesso (M/F/Altro), peso (kg, campo numerico), clima (5 opzioni: Freddo/Mite/Caldo/Molto caldo/Afoso), formula locale (nessun dato trasmesso), output raccomandazione in ml arrotondato ai 50ml, disclaimer privacy esplicito
- [ ] **CALC-02**: Calcolatore mostrato automaticamente al primo avvio dell'app (dopo il permission screen esistente, prima della home)
- [ ] **CALC-03**: Calcolatore richiamabile dai Settings tramite tile dedicata ("Ricalcola raccomandazione idratazione")
- [ ] **CALC-04**: Bottone "Usa come target" applica la raccomandazione come target della giornata corrente (writing to `target_history`); sesso/peso/clima NON vengono salvati

## Future Requirements

Requirements deferred to a future milestone.

### Localizzazione

- **LOCALE-01**: Formattazione locale dei valori nei Settings (separatore decimale per lingua)

### Testing dispositivi fisici

- **DEVICE-01**: Verificare notifiche su dispositivo fisico Samsung/Xiaomi con OEM background killing

### Analytics / Export

- **EXPORT-01**: Export storico intake in CSV
- **CHART-01**: Grafici trend settimanali/mensili (fl_chart)

### Salute integrations

- **HEALTH-01**: Apple Health / Google Fit integration

## Out of Scope

| Feature | Reason |
|---------|--------|
| Target diverso per ogni singolo giorno | v1.2 implementa storico target (when it changed); target per-day configuration rimane fuori scope |
| Salvataggio parametri calcolatore (sesso/peso/clima) | Privacy by design — i dati non vengono mai persistiti o trasmessi |
| fl oz unit support | ml/L per v1; mercato europeo |
| Backend / cloud sync | Fully offline per tutta la serie v1 |
| Smart/adaptive reminder timing | Richiede usage pattern learning; v2+ |
| Social / sharing features | Focus su tracking personale |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUG-01 | Phase 9 | Pending |
| BUG-02 | Phase 10 | Pending |
| BUG-03 | Phase 9 | Pending |
| TARGET-01 | Phase 9 | Pending |
| TARGET-02 | Phase 10 | Pending |
| TARGET-03 | Phase 10 | Pending |
| TARGET-04 | Phase 10 | Pending |
| CALC-01 | Phase 11 | Pending |
| CALC-02 | Phase 11 | Pending |
| CALC-03 | Phase 11 | Pending |
| CALC-04 | Phase 11 | Pending |

**Coverage:**
- v1.2 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-06-10*
*Last updated: 2026-06-10 — traceability updated with phase assignments*
