---
status: complete
phase: 11-hydration-calculator
source: 11-01-SUMMARY.md
started: 2026-06-15T00:00:00Z
updated: 2026-06-15T00:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. First-launch routing — calculator appears after permission screen
expected: On a fresh install (or with app data cleared), launch the app. After completing the permission screen (either "Enable Reminders" or "Skip for now"), the Hydration Calculator screen should appear automatically — before the home screen. The calculator screen should have NO bottom NavigationBar visible.
result: pass

### 2. Calculator form initial state
expected: On the calculator screen (first launch), the sex SegmentedButton has no segment preselected (all three — Maschio, Femmina, Altro — appear unselected). The weight field is empty. The climate Slider is at the second position ("Mite"). The recommendation displays "Compila tutti i campi" (not a number). The "Usa come target" button is disabled/greyed out.
result: pass

### 3. Live calculation updates
expected: Select a sex (e.g. "Maschio"), enter a weight (e.g. "70"), and observe the recommendation update instantly to a number in ml formatted with thousands separator (e.g. "2 550 ml" for Male 70kg Mite climate). Moving the climate Slider to a different position immediately updates the recommendation. Clearing the weight field returns the display to "Compila tutti i campi" and disables the button.
result: pass

### 4. Weight validation
expected: With a sex selected and the weight field containing "0" or "301" (out of range), the "Usa come target" button remains disabled and the field shows the error "Inserisci un peso tra 1 e 300 kg". With a valid weight (1–300), the button becomes enabled and no error text shows.
result: pass

### 5. Privacy disclaimer visible
expected: The calculator screen shows the text "I tuoi dati (sesso, peso, clima) non vengono salvati ne' trasmessi. Il calcolo avviene interamente sul tuo dispositivo." somewhere on the screen (scroll down if needed).
result: pass

### 6. First-launch: "Usa come target" applies target and navigates home
expected: With valid inputs (sex + weight + climate), tap "Usa come target". A SnackBar appears with a message like "Target aggiornato a 2 550 ml". The home screen then appears, and the progress ring / daily target reflects the new value. Relaunching the app goes directly to the home screen (no calculator loop).
result: pass

### 7. First-launch: "Salta" skips and navigates home without changing target
expected: On the calculator screen (first launch), tap "Salta" (visible below the "Usa come target" button). The home screen appears without any SnackBar. The daily target on the home screen is unchanged from before. Relaunching the app goes directly to the home screen (no calculator loop).
result: pass

### 8. Settings HYDRATION section visible
expected: Navigate to the Settings tab. Scroll down past the Notifications card. A "HYDRATION" section header is visible, followed by a card containing a ListTile with a calculator icon on the left, the text "Ricalcola raccomandazione idratazione" in the centre, and a chevron arrow on the right.
result: pass

### 9. Settings: calculator opens with back button, no Salta
expected: Tap "Ricalcola raccomandazione idratazione" in Settings. The calculator screen opens. The AppBar shows a back arrow (← or ‹). The "Salta" button is NOT visible on screen. Fill in valid inputs and note the recommendation.
result: pass

### 10. Settings: "Usa come target" pops back to Settings
expected: With the calculator open from Settings and valid inputs entered, tap "Usa come target". A SnackBar appears with the updated target. The Settings screen is displayed (not home). The back button correctly returned the navigation stack to Settings.
result: pass

### 11. Settings: back button returns to Settings
expected: Open the calculator from Settings. Tap the AppBar back button WITHOUT tapping "Usa come target". The Settings screen appears. The daily target is unchanged.
result: pass

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
