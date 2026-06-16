# Phase 18: Day Detail Screen - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 18-Day Detail Screen
**Areas discussed:** Trigger di navigazione, Route e NavigationBar, Layout schermata dettaglio

---

## Trigger di navigazione

**Q1: Toccare un giorno nel calendario: cosa succede?**

| Option | Description | Selected |
|--------|-------------|----------|
| Naviga direttamente al dettaglio | Tap sul giorno → push alla DayDetailScreen. La card sommario testuale viene rimossa. | ✓ |
| Card sommario + tap card → dettaglio | Tap sul giorno → mostra ancora la card sommario. La card diventa tappabile e naviga al dettaglio. | |
| Card sommario resta, barre del chart navigano | Tap sul calendario → card sommario (invariato). Solo tap su barra del chart mensile naviga al dettaglio. | |

**User's choice:** Naviga direttamente al dettaglio
**Notes:** La card sommario inline (`_buildDaySummary`) viene rimossa completamente.

---

**Q2: Il tap sulla barra del chart mensile: che comportamento ha?**

| Option | Description | Selected |
|--------|-------------|----------|
| Tap barra → push alla DayDetailScreen | Coerente con CHART-07. Sostituisce o affianca il tooltip. | |
| Tooltip solo, nessuna navigazione da barra | Le barre del chart mensile restano con solo tooltip. La navigazione arriva unicamente dal calendario. | ✓ |

**User's choice:** Tooltip solo, nessuna navigazione da barra
**Notes:** CHART-07 richiede "tap giorno nel calendario O barra" — l'utente ha scelto di soddisfarlo solo tramite calendario. Le barre del MonthlyBarChart non vengono modificate.

---

**Q3: Solo giorni con dati navigano al dettaglio, o anche giorni senza dati?**

| Option | Description | Selected |
|--------|-------------|----------|
| Solo giorni con dati | Tap su giorno con dati → push. Tap su giorno senza dati → nessuna azione. | ✓ |
| Tutti i giorni passati navigano | Tap su qualsiasi giorno non futuro → push al dettaglio (empty state per giorni senza dati). | |

**User's choice:** Solo giorni con dati

---

## Route e NavigationBar

**Q1: La DayDetailScreen mostra la NavigationBar in fondo?**

| Option | Description | Selected |
|--------|-------------|----------|
| No — route top-level, nav bar nascosta | Uguale a /calculator. Schermata push pulita senza tab bar. | ✓ |
| Sì — route figlio di /history, nav bar visibile | L'utente può cambiare tab anche mentre è nel dettaglio. | |

**User's choice:** No — route top-level, nav bar nascosta

---

**Q2: Come viene passata la data alla DayDetailScreen?**

| Option | Description | Selected |
|--------|-------------|----------|
| Path parameter: /day/2026-06-16 | Il dateKey (YYYY-MM-DD) è nel path. GoRoute path: '/day/:dateKey'. | ✓ |
| Extra object via state.extra | DateTime passato via state.extra come già usato per isOnboarding. | |

**User's choice:** Path parameter: /day/2026-06-16

---

## Layout schermata dettaglio

**Q1: Asse x del grafico giornaliero: orario o posizione?**

| Option | Description | Selected |
|--------|-------------|----------|
| Orario HH:mm | Ogni barra ha l'orario dell'aggiunta sull'asse x. Se due aggiunte nello stesso minuto, barre affiancate. | ✓ |
| Posizione sequenziale (1, 2, 3…) | Le barre sono numerate per ordine cronologico. Perde il contesto temporale. | |

**User's choice:** Orario HH:mm

---

**Q2: Dove mostrare il totale ml del giorno (CHART-09)?**

| Option | Description | Selected |
|--------|-------------|----------|
| Testo sopra il grafico nella Card | Una riga di testo sopra il BarChart, dentro la stessa Card. | ✓ |
| Sottotitolo nell'AppBar | Il totale appare come subtitle dell'AppBar accanto alla data. | |
| Card separata sopra il grafico | Card distinta per il totale, poi Card separata per il grafico. | |

**User's choice:** Testo sopra il grafico nella Card

---

**Q3: La schermata mostra anche la lista testuale delle singole aggiunte?**

| Option | Description | Selected |
|--------|-------------|----------|
| Solo grafico + totale | Il grafico è il protagonista. Nessuna lista testuale. | ✓ |
| Grafico + lista testuale sotto | Sotto la Card del grafico, una lista con ogni aggiunta (HH:mm — Xml). | |

**User's choice:** Solo grafico + totale

---

**Q4: Titolo dell'AppBar nella DayDetailScreen?**

| Option | Description | Selected |
|--------|-------------|----------|
| Data nel formato locale | DateFormat.yMMMMd(locale) — es. '16 giugno 2026' in italiano. | ✓ |
| Data breve dd/MM/yyyy | '16/06/2026' — più compatto, non localizzato. | |
| Stringa fissa localizzata | Es. 'Dettaglio giorno' — la data non appare nel titolo. | |

**User's choice:** Data nel formato locale

---

## Claude's Discretion

- Colore delle barre giornaliere (colore primario del tema, non verde/rosso)
- Altezza del SizedBox del BarChart giornaliero (minimo 180px)
- `ValueKey` sul BarChart giornaliero (obbligatorio per prevenire artefatti)
- Gestione grouped bars per entry nello stesso minuto (implementazione fl_chart)

## Deferred Ideas

- Navigazione da barre del MonthlyBarChart verso DayDetailScreen — utente ha preferito tooltip solo
- Lista testuale delle singole aggiunte nella DayDetailScreen — fuori scope
- Editing/eliminazione entry dalla DayDetailScreen — fuori scope per v1
