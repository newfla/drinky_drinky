# Phase 13: String Extraction & Translation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 13-string-extraction-translation
**Areas discussed:** Tono delle traduzioni, Termine 'streak', Struttura dei piani

---

## Tono delle traduzioni

| Option | Description | Selected |
|--------|-------------|----------|
| Tu (informale) | Tono amichevole e diretto. Standard per app consumer di salute/wellness. | ✓ |
| Lei (formale) | Tono professionale e distaccato. Insolito per app di idratazione personale. | |

**User's choice:** Tu informale per italiano, tu per francese, tú per spagnolo — coerente su tutte e 3 le lingue.
**Notes:** La scelta informale è stata confermata sia per italiano che per francese e spagnolo in un'unica risposta: "Sì, tu/tú ovunque".

---

## Termine "streak"

| Option | Description | Selected |
|--------|-------------|----------|
| serie | Es: '1 giorno di serie', '5 giorni di serie'. Breve, usato in app fitness. | |
| giorni consecutivi | Es: '1 giorno consecutivo', '5 giorni consecutivi'. Più esplicito. | ✓ |
| striscia | Es: '1 giorno di striscia'. Colloquiale, meno standard. | |

**User's choice (IT):** "giorni consecutivi"
**User's choice (FR/ES):** "jours consécutifs" / "días consecutivos" (coerente con la scelta italiana)
**Notes:** La scelta "jours consécutifs / días consecutivos" è stata selezionata come opzione consigliata, coerente con la scelta italiana di usare il termine esplicito.

---

## Struttura dei piani

| Option | Description | Selected |
|--------|-------------|----------|
| Piano 1: enum + widget replacement / Piano 2: traduzioni | Separazione netta: struttura nel piano 1, contenuto nel piano 2. | ✓ |
| Piano 1: solo enum / Piano 2: widget + traduzioni | Piano 1 minimo, piano 2 molto grande. Rischio: piano 2 troppo lungo. | |

**User's choice:** Piano 1 = enum refactor + widget replacement, Piano 2 = traduzioni it/fr/es.
**Notes:** La separazione netta tra struttura e contenuto è preferita.

---

## Claude's Discretion

- Placement di `BiologicalSex`/`ClimateLevel` enum: file dedicato vs inline nel calculator screen — Claude sceglie in base ai pattern esistenti.
- Tutte le altre scelte di traduzione (intestazioni sezioni, messaggi di errore, etichette bottoni) seguono lo standard italiano/francese/spagnolo; Claude ha discrezionalità dove non è stato discusso un termine specifico.

## Deferred Ideas

- NotificationService localization → Phase 14
- iOS CFBundleLocalizations → Phase 14
- Android resConfigs → Phase 14
- Revisione umana delle traduzioni machine-generated → v1.4+
