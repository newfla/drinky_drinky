# Requirements: Drinky Drinky

**Defined:** 2026-06-15
**Core Value:** The user always knows how close they are to their daily hydration goal and gets reminded before they forget.

## v1.4 Requirements

Requirements for milestone v1.4 (Polish & Bug Fixes).

### UI Polish

- [ ] **POLISH-01**: Il testo placeholder nella home ("tocca il pulsante...") ha padding laterale/verticale consistente con il resto dell'UI e il testo è centrato orizzontalmente

### Bug Fix

- [ ] **BUG-04**: La schermata Cronologia mostra correttamente gli intake del giorno corrente dopo il primo inserimento su fresh install — non mostra "Nessuna cronologia" in presenza di dati

### Documentation

- [ ] **DOC-01**: `README.md` nella root del repository descrive il progetto con due screenshot della home screen (iOS e Android) e le istruzioni di build essenziali

## Future Requirements

- **L10N-FUTURE-01**: Revisione umana nativa per it/fr/es — machine-translation prodotta in v1.3, review quality-gate per v1.4+
- **L10N-FUTURE-02**: Tedesco (de), Portoghese (pt) — lingue con base utenti rilevante ma fuori scope v1.3

## Out of Scope

| Feature | Reason |
|---------|--------|
| Re-show system notification popup after denial | Restrizione di piattaforma: iOS e Android non permettono di ri-mostrare il dialog nativo dopo una negazione — l'unica via è openAppSettings() |
| Variable per-day targets | Storico target implementato in v1.2; target diverso per ogni singolo giorno rimane fuori scope |
| Detailed log editing | Undo last è sufficiente per v1 |
| Social / sharing features | Focus on personal tracking |
| Apple Health / Google Fit integration | Defer to v2 |
| fl oz unit support | ml/L for v1; European market focus |
| Backend / cloud sync | Fully offline for v1 |
| Smart/adaptive reminder timing | Requires usage pattern learning; v2 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| POLISH-01 | Phase 15 | Pending |
| BUG-04 | Phase 15 | Pending |
| DOC-01 | Phase 16 | Pending |

**Coverage:**

- v1.4 requirements: 3 total
- Mapped to phases: 3
- Unmapped: 0

---
*Requirements defined: 2026-06-15*
