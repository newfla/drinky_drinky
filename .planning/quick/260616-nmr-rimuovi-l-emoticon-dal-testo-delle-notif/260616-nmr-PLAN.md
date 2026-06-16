---
quick_id: 260616-nmr
description: "rimuovi l'emoticon dal testo delle notifiche"
date: 2026-06-16
---

# Quick Task 260616-nmr: rimuovi l'emoticon dal testo delle notifiche

## Task

Remove the 💧 emoji from `notificationBody` in all 4 ARB files. The emoji fails to render correctly on some platforms (noted in v1.0 retrospective as a known platform hazard).

## Files

- `lib/l10n/app_en.arb` — remove ` 💧` from notificationBody value
- `lib/l10n/app_it.arb` — remove ` 💧` from notificationBody value
- `lib/l10n/app_fr.arb` — remove ` 💧` from notificationBody value
- `lib/l10n/app_es.arb` — remove ` 💧` from notificationBody value

No `flutter gen-l10n` required — string content only, no structural ARB change.
