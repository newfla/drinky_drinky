---
status: complete
phase: 13-string-extraction-translation
source: [13-01-SUMMARY.md, 13-02-SUMMARY.md]
started: 2026-06-15T16:00:00Z
updated: 2026-06-15T16:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Italian UI — home screen
expected: Set device/simulator locale to Italian. The bottom navigation tabs show "Home", "Cronologia", "Impostazioni". The home screen text (progress ring, timeline header "Cronologia odierna") is in Italian. Ring center text is centered.
result: issue
reported: "Label Casa preferita come Home; Obiettivo raggiunto non centrato nel ring; Assunzioni di oggi preferita come Cronologia odierna"
severity: minor
fixed: true
fix: tabHome already 'Home' in ARB (confirmed); ring center wrapped in SizedBox(160)+textAlign center; todaysIntake → 'Cronologia odierna' + gen-l10n re-run

### 2. Italian UI — settings and calculator
expected: With device still on Italian. Settings tab shows Italian section headers and labels. Tapping the "Calcolatore" (calculator) button opens the calculator screen with Italian labels for sex selector, weight field, climate slider, and recommendation output. No crash.
result: pass

### 3. French UI — home and tabs
expected: Set device/simulator locale to French. Bottom tabs show "Accueil", "Historique", "Paramètres". Home screen text is in French (e.g. intake counter uses French decimal separator formatting).
result: pass

### 4. Spanish UI — home and tabs
expected: Set device/simulator locale to Spanish. Bottom tabs show "Inicio", "Historial", "Ajustes". Home screen text is in Spanish.
result: issue
reported: "non vedo 'Historial de hoy' ma 'Consumo de hoy'"
severity: minor
fixed: true
fix: app_es.arb todaysIntake → 'Historial de hoy' + gen-l10n re-run

### 5. Calculator works on non-Italian locale (no crash)
expected: With device on French or Spanish locale, open the calculator (via Settings → tap calculator button or onboarding). Select a sex option, enter a weight (e.g. 70), move the climate slider. A recommendation appears in ml with the French/Spanish label. No crash, no error screen.
result: pass

### 6. Italian streak plural
expected: With device on Italian, open the History tab. If the current streak is 0, the streak area shows "Nessuna serie". If streak is 1, it shows "1 giorno consecutivo". If streak is 2+, it shows "X giorni consecutivi". (You can check any of the three cases depending on your current streak.)
result: pass

### 7. English fallback intact
expected: Set device/simulator locale to English (or a language not supported, like German). The app shows all text in English — no missing strings, no "???" placeholders. Confirms no regression from Phase 13 changes.
result: issue
reported: "con tedesco come lingua primaria ma spagnolo nella lista preferenze, l'app rimaneva in spagnolo dopo cold restart"
severity: major
fixed: true
fix: added localeListResolutionCallback in main.dart — uses only primary locale, English fallback for unsupported languages (ignores secondary preferences)

## Summary

total: 7
passed: 4
issues: 3
pending: 0
skipped: 0
blocked: 0

## Gaps
