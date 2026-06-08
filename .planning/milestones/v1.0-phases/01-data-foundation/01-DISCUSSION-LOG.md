# Phase 1: Data Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03
**Phase:** 1-Data Foundation
**Areas discussed:** Flutter scaffold, Default values, Code generation, Folder structure

---

## Flutter Scaffold

| Option | Description | Selected |
|--------|-------------|----------|
| com.flaviobizzarri.drinkydrinky | Usa il nome come org | |
| com.bizzarri.drinkydrinky | Cognome come org identifier | ✓ |
| Decidilo tu | Usa una convenzione ragionevole | |

**User's choice:** `com.bizzarri.drinkydrinky`
**Notes:** —

| Option | Description | Selected |
|--------|-------------|----------|
| iOS 16 | Copre il 95%+ dei device attivi | ✓ |
| iOS 17 | Abilita @Observable nativo, ma esclude chi non aggiorna | |
| iOS 15 | Massima compatibilità, alcune limitazioni UI | |

**User's choice:** iOS 16

| Option | Description | Selected |
|--------|-------------|----------|
| API 26 / Android 8 | Copre >99% dei device | ✓ |
| API 24 / Android 7 | Leggermente più ampio | |

**User's choice:** API 26

---

## Default Values

| Option | Description | Selected |
|--------|-------------|----------|
| 2000 ml (2 L) | Valore comune raccomandato | ✓ |
| 2500 ml (2.5 L) | Più vicino alle raccomandazioni scientifiche | |
| 1500 ml (1.5 L) | Più conservativo | |

**User's choice:** 2000 ml

| Option | Description | Selected |
|--------|-------------|----------|
| 150 / 250 / 350 / 500 ml | Bicchiere piccolo / bicchiere / grande / bottiglia | |
| 200 / 300 / 400 / 500 ml | Valori più rotondi, facili da ricordare | ✓ |
| Decidilo tu | Scegli la progressione più naturale | |

**User's choice:** 200 / 300 / 400 / 500 ml

| Option | Description | Selected |
|--------|-------------|----------|
| 60 minuti (ogni ora) | Non invadente ma costante | ✓ |
| 90 minuti | Meno frequente | |
| 120 minuti (ogni 2 ore) | Molto raro | |

**User's choice:** 60 minuti

| Option | Description | Selected |
|--------|-------------|----------|
| 23:00 – 07:00 | Notifiche silenziose di notte | ✓ |
| 22:00 – 08:00 | Finestra più ampia | |
| Nessun DND di default | DND disabilitato finché l'utente non lo configura | |

**User's choice:** 23:00 – 07:00 (DND enabled by default)

---

## Code Generation

| Option | Description | Selected |
|--------|-------------|----------|
| @riverpod codegen | Annotazioni @riverpod, type-safe, meno boilerplate | ✓ |
| Provider manuali | Niente codegen, tutto esplicito | |

**User's choice:** @riverpod codegen

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, Freezed | Per UserSettings, DrinkPreset, DailyProgress | ✓ |
| No, plain Dart classes | Implementa manualmente copyWith ed equality | |

**User's choice:** Sì, Freezed

---

## Folder Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Feature-first | lib/features/tracking/, lib/features/settings/ | |
| Layer-first | lib/data/, lib/domain/, lib/presentation/ | ✓ |

**User's choice:** Layer-first

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, GoRouter | Standard de facto Flutter, dichiarativo | ✓ |
| Navigator 2.0 / pushNamed | Navigazione imperativa tradizionale | |

**User's choice:** Sì, GoRouter

---

## Claude's Discretion

- Database schema column types and index strategy — decided by Claude based on research (PITFALLS.md)
- Drift migration versioning strategy — standard Drift migration callbacks
- Repository interface design (abstract class vs concrete) — Claude decides based on Riverpod best practices

## Deferred Ideas

None — discussion stayed within phase scope.
