---
status: complete
phase: 02-core-tracking-ui
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md]
started: 2026-06-04T15:30:00Z
updated: 2026-06-05T00:01:00Z
---

## Current Test

[testing complete]

## Tests

### 1. App launches with bottom NavigationBar
expected: Open the app on simulator/device. A bottom NavigationBar with 3 tabs is visible at the bottom: Home (water drop icon, selected by default), History (calendar icon), Settings (gear icon). The Home tab is active and the "Drinky Drinky" AppBar is visible at the top.
result: pass

### 2. Progress ring visible at start
expected: On the Home tab, a circular progress ring is centered on screen. At a fresh launch (no drinks logged today), the ring is empty/unfilled and the center shows "0 / 2000 ml". Four FilledButton presets are below the ring: +200 ml, +300 ml, +400 ml, +500 ml.
result: pass
note: "Initial overflow bug fixed (commit 8890bf0) — confirmed pass after fix"

### 3. Tap a quick-add preset — ring updates
expected: Tap the "+200 ml" button. Within 1 second: the ring animates to fill a small arc (10% of target), the center text updates to "200 / 2000 ml", and a SnackBar appears at the bottom saying "+200 ml added" with an UNDO button.
result: pass

### 4. SnackBar UNDO reverts entry
expected: While the SnackBar from the previous test is still showing, tap UNDO. Within 1 second: the ring animates back to empty, the center text returns to "0 / 2000 ml", the SnackBar disappears, and the entry disappears from the timeline (or timeline shows empty state again).
result: pass

### 5. Timeline shows today's intakes newest-first
expected: Tap "+200 ml", then "+500 ml", then "+300 ml" (three taps, waiting ~1 second between each). Scroll down to see the "Today's Intake" section below the buttons. The timeline lists 3 entries: the most recent entry (+300 ml) appears at the top, then +500 ml, then +200 ml at the bottom. Each row shows a HH:mm timestamp on the left and "+N ml" on the right.
result: pass

### 6. Empty state shown when no drinks logged
expected: Start fresh or undo all entries until none remain. The area below the section header "Today's Intake" shows the text "No drinks logged yet" and "Tap a button above to log your first drink today." (No empty list, no error, just the two-line placeholder.)
result: pass

### 7. Progress ring turns green at 100%
expected: Tap quick-add presets until the total reaches 2000 ml (e.g., four taps of +500 ml). When the total hits or exceeds 2000 ml: the ring fills completely and turns green, and the center text changes to "Goal reached!" (not the ml amounts).
result: pass

### 8. Logging continues past 100% goal
expected: With the ring already at 100% (green, "Goal reached!"), tap "+200 ml" again. The preset buttons remain active (not greyed out). After the tap: the ring stays full and green, and the center text changes to show the actual total, e.g., "2200 / 2000 ml" — the ring does NOT overflow beyond a full circle.
result: issue
reported: "il testo nel ring rimane 'Goal reached!'"
severity: major

### 9. History tab shows "Coming soon"
expected: Tap the History tab in the NavigationBar. The screen shows an AppBar with the title "History" and centered body text "Coming soon". No crash, no blank screen.
result: pass

### 10. Settings tab shows "Coming soon"
expected: Tap the Settings tab in the NavigationBar. The screen shows an AppBar with the title "Settings" and centered body text "Coming soon". No crash, no blank screen.
result: pass

### 11. Tab state preserved when switching
expected: Log "+300 ml" on the Home tab (so the ring shows 300/2000 ml and timeline has one entry). Tap History tab, then tap Home tab again. The ring still shows 300/2000 ml and the timeline entry is still visible — state was not reset by tab switching.
result: pass

## Summary

total: 11
passed: 10
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "After logging past 100%, ring center text shows actual total (e.g. '2200 / 2000 ml'), not 'Goal reached!'"
  status: fixed
  reason: "User reported: il testo nel ring rimane 'Goal reached!'"
  severity: major
  test: 8
  root_cause: "home_screen.dart:111 — condition `isGoalMet` (totalMl >= target) kept showing 'Goal reached!' for any amount at or above target; should only show it when totalMl == target exactly"
  artifacts:
    - path: "lib/presentation/screens/home_screen.dart"
      issue: "Line 111: `isGoalMet ? 'Goal reached!' : ...` never reverts to ml display once goal is met"
  missing:
    - "Change condition to `isGoalMet && totalMl == target` so over-goal amounts show actual total"
  debug_session: ""
