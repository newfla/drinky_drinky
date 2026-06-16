# Requirements: Drinky Drinky

**Defined:** 2026-06-16
**Core Value:** The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## v1.5 Requirements

### Charts — Monthly Bar Chart

- [x] **CHART-01**: L'utente vede un grafico a barre mensile sotto il calendario con i ml totali giornalieri per il mese visualizzato
- [x] **CHART-02**: Le barre del mese corrente escludono i giorni futuri (barre solo per giorni <= oggi)
- [x] **CHART-03**: Una linea orizzontale dashed indica il target giornaliero corrente
- [x] **CHART-04**: Toccando una barra, il tooltip mostra i ml esatti del giorno
- [x] **CHART-05**: Quando il mese non ha dati, il chart mostra un empty state testuale al posto delle barre
- [x] **CHART-06**: Il chart si aggiorna automaticamente quando l'utente cambia mese nel calendario

### Charts — Day Detail Screen

- [ ] **CHART-07**: Toccando un giorno nel calendario (o una barra del chart mensile) si apre una schermata di dettaglio separata (push)
- [ ] **CHART-08**: La schermata di dettaglio mostra un grafico a barre con le singole aggiunte del giorno (asse x = posizione/orario, asse y = ml)
- [ ] **CHART-09**: La schermata di dettaglio mostra il totale ml del giorno selezionato
- [ ] **CHART-10**: La schermata di dettaglio mostra un empty state per giorni senza dati

### Localizzazione

- [ ] **CHART-11**: Tutte le nuove stringhe del chart sono localizzate nelle 4 lingue (en/it/fr/es)

## Future Requirements

### Charts — Potenziali evoluzioni

- **CHART-FUTURE-01**: Grafico settimanale o annuale nella history screen
- **CHART-FUTURE-02**: Integrazione Apple Health / Google Health per dati comparativi
- **CHART-FUTURE-03**: Accessibilità semantica (Semantics wrapper) sui chart

## Out of Scope

| Feature | Reason |
|---------|--------|
| Background bars per target per-giorno | Complessità sproporzionata; target history già in scope come linea unica |
| Pinch-to-zoom sui chart | Anti-feature per app di tracking personale; aggiunge complessità senza valore |
| Scroll orizzontale del chart mensile | 31 giorni entrano su schermo con label ridotti; scroll aggiunge attrito |
| Grafici 3D o con gradienti | Decorativi senza valore informativo aggiuntivo |
| Esportazione dati / sharing chart | Fuori scope per v1 offline-first |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CHART-01 | Phase 17 | Complete |
| CHART-02 | Phase 17 | Complete |
| CHART-03 | Phase 17 | Complete |
| CHART-04 | Phase 17 | Complete |
| CHART-05 | Phase 17 | Complete |
| CHART-06 | Phase 17 | Complete |
| CHART-07 | Phase 18 | Pending |
| CHART-08 | Phase 18 | Pending |
| CHART-09 | Phase 18 | Pending |
| CHART-10 | Phase 18 | Pending |
| CHART-11 | Phase 18 | Pending |

**Coverage:**

- v1.5 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-06-16*
*Last updated: 2026-06-16 — phase traceability added for v1.5 roadmap*
