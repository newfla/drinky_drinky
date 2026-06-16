---
quick_id: 260616-nmr
status: complete
date: 2026-06-16
commit: 99b51e5
---

# Quick Task 260616-nmr: rimuovi l'emoticon dal testo delle notifiche

## What Was Done

Removed the 💧 emoji from `notificationBody` in all 4 ARB locales (en/it/fr/es).

| File | Before | After |
|------|--------|-------|
| app_en.arb | `"Time to drink water! 💧"` | `"Time to drink water!"` |
| app_it.arb | `"È ora di bere acqua! 💧"` | `"È ora di bere acqua!"` |
| app_fr.arb | `"C'est l'heure de boire de l'eau ! 💧"` | `"C'est l'heure de boire de l'eau !"` |
| app_es.arb | `"¡Es hora de beber agua! 💧"` | `"¡Es hora de beber agua!"` |

No `flutter gen-l10n` required — string content change only, no structural ARB changes.

## Commit

`99b51e5` — fix(l10n): remove 💧 emoji from notification body text
