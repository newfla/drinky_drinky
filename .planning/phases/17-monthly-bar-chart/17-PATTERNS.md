# Phase 17: Monthly Bar Chart - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `pubspec.yaml` | config | N/A | `pubspec.yaml` (self) | exact |
| `lib/presentation/widgets/monthly_bar_chart.dart` | component | transform | `lib/presentation/screens/history_screen.dart` (StreakCard + _buildDayCell) | role-match |
| `lib/presentation/screens/history_screen.dart` | screen | request-response | self (modify existing) | exact |

## Pattern Assignments

### `lib/presentation/widgets/monthly_bar_chart.dart` (component, transform)

**Analog:** `lib/presentation/screens/history_screen.dart`

This is a new StatelessWidget (not ConsumerWidget) that receives data via constructor. All provider watching stays in HistoryScreen.

**Imports pattern** (lines 1-8 of history_screen.dart):
```dart
import 'package:flutter/material.dart';
// New file will also need:
// import 'package:fl_chart/fl_chart.dart';
// import '../../domain/entities/target_history_entry.dart';
```

**Card wrapping pattern** (lines 127-149 of history_screen.dart -- StreakCard):
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: /* content */,
  ),
),
```

**Color logic pattern** (lines 296-308 of history_screen.dart -- _buildDayCell):
```dart
if (metGoal == true) {
  final green = brightness == Brightness.dark
      ? Colors.green.shade400
      : Colors.green.shade600;
  fillColor = green.withValues(alpha: 0.15);
  textColor = green;
} else if (metGoal == false) {
  final red = brightness == Brightness.dark
      ? Colors.red.shade400
      : Colors.red.shade600;
  fillColor = red.withValues(alpha: 0.15);
  textColor = red;
}
```

**Target lookup pattern** (lines 21-31 of history_screen.dart -- _findActiveTarget):
```dart
int _findActiveTarget(List<TargetHistoryEntry> targets, String dateKey) {
  int result = 2000;
  for (final t in targets) {
    if (t.effectiveDate.compareTo(dateKey) <= 0) {
      result = t.targetMl;
    } else {
      break;
    }
  }
  return result;
}
```

**DateKey helper** (lines 12-14 of history_screen.dart):
```dart
String _toDateKey(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

---

### `lib/presentation/screens/history_screen.dart` (screen, modify existing)

**Analog:** Self -- this file is being modified, not created.

**Integration point** (lines 251-253): Insert MonthlyBarChart widget between TableCalendar and AnimatedSwitcher in the Column children list.

Current order at lines 119-270:
```
Column children:
  SizedBox(height: 24)          // line 124
  Card (StreakCard)              // line 127
  SizedBox(height: 24)          // line 152
  TableCalendar(...)            // line 155
  SizedBox(height: 16)          // line 253
  AnimatedSwitcher(...)         // line 256
  SizedBox(height: 24)          // line 269
```

New order should be:
```
  ...TableCalendar...
  SizedBox(height: 16)          // spacing
  MonthlyBarChart(...)          // NEW
  SizedBox(height: 16)          // spacing (reuse existing or add)
  AnimatedSwitcher(...)
```

**Data already available in scope** (lines 85-101):
- `focused` -- from `ref.watch(focusedMonthProvider)` (line 85)
- `targets` -- from `ref.watch(allTargetHistoryProvider)` (line 87, inside `.data`)
- `monthTotals` -- from `ref.watch(calendarMonthProvider(focused.year, focused.month))` (lines 96-98)

All three can be passed directly to MonthlyBarChart constructor.

---

### `pubspec.yaml` (config)

Add `fl_chart: ^1.2.0` under `dependencies:` section. No pattern excerpt needed -- straightforward dependency addition.

---

## Shared Patterns

### Dark Mode Color Selection
**Source:** `lib/presentation/screens/history_screen.dart` lines 291-308
**Apply to:** `monthly_bar_chart.dart` bar colors
```dart
final brightness = Theme.of(context).brightness;
final green = brightness == Brightness.dark
    ? Colors.green.shade400
    : Colors.green.shade600;
final red = brightness == Brightness.dark
    ? Colors.red.shade400
    : Colors.red.shade600;
```

### Card Styling
**Source:** `lib/presentation/screens/history_screen.dart` lines 127-149
**Apply to:** `monthly_bar_chart.dart` outer wrapper
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: /* chart widget */,
  ),
),
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | -- | -- | All files have analogs |

## Metadata

**Analog search scope:** `lib/presentation/`
**Files scanned:** 3 (history_screen.dart, preset_edit_dialog.dart, home_screen.dart)
**Pattern extraction date:** 2026-06-16
