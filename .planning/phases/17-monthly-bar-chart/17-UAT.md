---
status: complete
phase: 17-monthly-bar-chart
source: 17-01-SUMMARY.md
started: 2026-06-16T13:35:00Z
updated: 2026-06-16T13:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Monthly bar chart visible in History
expected: On the History screen, below the calendar, a bar chart is visible showing one bar per day for the current month. Days with data show colored bars; days with no data show no bar (transparent).
result: issue
reported: "corretto ma vorrei vi fosse un po' piu' di spazio tra il calendario e la card del grafico"
severity: cosmetic

### 2. Green and red bar colors
expected: Days where you met your daily water target show a green bar. Days where you logged water but didn't meet the target show a red bar. The colors are clearly different.
result: pass

### 3. Dashed target line
expected: A dashed horizontal line crosses the chart at the daily target level (e.g., at 2 L if your goal is 2000 ml). The line is subtle (semi-transparent) and does not dominate the chart.
result: pass

### 4. Tap bar shows tooltip
expected: Tap one of the bars in the monthly chart. A small tooltip appears showing the day/month and the ml value (e.g., "16/06\n1450 ml").
result: pass

### 5. Chart updates when switching months
expected: Use the calendar arrows to navigate to a different month. The bar chart below should update to show data for the newly selected month. Months with no data show an empty-state message ("No data this month") instead of the chart.
result: pass

### 6. Y-axis labels in L
expected: The y-axis on the left side of the chart shows values in L (e.g., "0.5L", "1L", "1.5L"), not in ml.
result: pass

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Adequate spacing between the calendar and the monthly bar chart Card"
  status: failed
  reason: "User reported: corretto ma vorrei vi fosse un po' piu' di spazio tra il calendario e la card del grafico"
  severity: cosmetic
  test: 1
  artifacts: []
  missing: []
