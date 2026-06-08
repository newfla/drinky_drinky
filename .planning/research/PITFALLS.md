# Domain Pitfalls -- v1.1 Polish & UX Update

**Domain:** Flutter hydration tracker / water reminder app (offline-first, iOS + Android)
**Stack:** Flutter 3.44.1 + Riverpod + Drift + flutter_local_notifications
**Researched:** 2026-06-08
**Scope:** Pitfalls specific to v1.1 features. Base v1.0 pitfalls (OEM killing, iOS 64 limit, exact alarms, DateTime storage, midnight timezone) remain valid and are not repeated here.

---

## Critical Pitfalls

### Pitfall 1: SnackBar `persist` Breaking Change (Flutter 3.38+)

**What goes wrong:** SnackBars with a `SnackBarAction` (like the UNDO button) no longer auto-dismiss after the `duration` timer. They stay on screen indefinitely until the user interacts with them or code explicitly removes them.

**Why it happens:** Flutter 3.38 introduced a Material 3 accessibility change. SnackBars with an `action` now default to `persist: true`, meaning they do NOT auto-dismiss. The `duration` property is silently ignored. This is documented at: https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update

**Consequences:** The "+200 ml added" SnackBar with UNDO stays on screen forever, overlapping content and confusing users. Multiple rapid taps create a visual stack of undismissed SnackBars (the existing `clearSnackBars()` call prevents queue buildup, but each new SnackBar still persists).

**Prevention:** Add `persist: false` to any SnackBar that has an action but should still auto-dismiss after its duration:

```dart
SnackBar(
  content: Text('+$amountMl ml added'),
  duration: const Duration(seconds: 5),
  persist: false,  // <-- restores auto-dismiss
  action: SnackBarAction(label: 'UNDO', onPressed: () { ... }),
)
```

**Detection:** Tap a quick-add button. If the SnackBar stays on screen longer than 5 seconds without user interaction, `persist` is defaulting to true.

**Confidence:** HIGH -- official Flutter breaking change documentation. Confirmed this app uses Flutter 3.44.1 (via FVM), which includes this change.

**Phase relevance:** Phase 1 (bug fix). One-line fix, zero risk.

---

### Pitfall 2: ThemeData `colorScheme` vs `colorSchemeSeed` Assertion Conflict

**What goes wrong:** When integrating DynamicColorBuilder, the developer passes both `colorScheme:` (from the builder) and `colorSchemeSeed:` (the existing `Colors.blue`). ThemeData throws an assertion error at runtime: "You cannot provide both colorScheme and colorSchemeSeed."

**Why it happens:** The current code uses `colorSchemeSeed: Colors.blue`. DynamicColorBuilder provides a `ColorScheme` object. When migrating, developers often add `colorScheme:` without removing `colorSchemeSeed:`.

**Consequences:** App crashes on launch with an assertion error.

**Prevention:** When switching to DynamicColorBuilder, replace `colorSchemeSeed` entirely with `colorScheme`:

```dart
// WRONG:
ThemeData(
  colorScheme: lightDynamic,
  colorSchemeSeed: Colors.blue,  // CRASHES
  useMaterial3: true,
)

// RIGHT:
ThemeData(
  colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
)
```

**Detection:** Immediate crash on launch. Caught by assertion in debug mode.

**Confidence:** HIGH -- ThemeData source code contains explicit assertion.

**Phase relevance:** Phase 1 (theme). Easy to catch if you run the app, but worth documenting.

---

## Moderate Pitfalls

### Pitfall 3: Bottom Sheet Keyboard Overlap

**What goes wrong:** The custom amount TextField in the bottom sheet opens the soft keyboard, which pushes up behind the bottom sheet instead of the sheet content moving above it. The TextField becomes partially or fully hidden.

**Why it happens:** `showModalBottomSheet` without `isScrollControlled: true` constrains the sheet to half the screen height and does not respond to keyboard insets. The sheet stays fixed while the keyboard covers it.

**Consequences:** Users cannot see or interact with the custom amount TextField. They must close the keyboard, scroll, or give up.

**Prevention:**
1. Set `isScrollControlled: true` on `showModalBottomSheet`
2. Wrap sheet content in padding that respects `MediaQuery.of(context).viewInsets.bottom`:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
    ),
    child: _IntakeSheet(/* ... */),
  ),
);
```

3. Use `mainAxisSize: MainAxisSize.min` on the sheet's Column so it wraps content rather than expanding to full height.

**Detection:** Open the bottom sheet, tap the custom amount TextField. If the keyboard covers the field, `isScrollControlled` or `viewInsets` padding is missing.

**Confidence:** HIGH -- well-documented Flutter pattern for keyboard-aware bottom sheets.

**Phase relevance:** Phase 2 (FAB + sheet). Must be correct from the start.

---

### Pitfall 4: Wrong Navigator Context Closes Screen Instead of Sheet

**What goes wrong:** Calling `Navigator.of(context).pop()` inside the bottom sheet's preset button handler uses the parent screen's `context` instead of the sheet's `context`. This pops the HomeScreen from the navigation stack instead of dismissing the bottom sheet.

**Why it happens:** The `builder:` callback in `showModalBottomSheet` provides a new `BuildContext` (the sheet's context). If the sheet widget captures the parent screen's context via closure, `Navigator.of(parentContext).pop()` traverses up to the nearest Navigator above the parent -- which is the app's router, not the modal barrier.

**Consequences:** The entire Home tab disappears. The user sees a blank screen or is pushed to a different route.

**Prevention:** Use the `context` from the sheet builder, or pass a callback from the parent that calls `Navigator.of(sheetContext).pop()`:

```dart
// Option A: use builder context
showModalBottomSheet(
  context: context,
  builder: (sheetContext) => FilledButton(
    onPressed: () {
      Navigator.of(sheetContext).pop();  // correct: pops sheet
      _onQuickAdd(amount);
    },
    child: Text('+$amount ml'),
  ),
);

// Option B: pass callback that handles closing
AddDrinkSheet(
  onAdd: (amount) {
    Navigator.of(sheetContext).pop();  // parent handles close
    _onQuickAdd(amount);
  },
)
```

**Detection:** Tap a preset in the bottom sheet. If the home screen disappears instead of the sheet closing, the wrong context was used.

**Confidence:** HIGH -- common Flutter navigation mistake.

**Phase relevance:** Phase 2 (FAB + sheet).

---

### Pitfall 5: FAB Overlaps Timeline List Content

**What goes wrong:** The FloatingActionButton sits in the bottom-right corner of the Scaffold, overlapping the last few items of the intake timeline ListView. Users cannot tap or read the bottom entries.

**Why it happens:** The ListView extends to the bottom of the screen. The FAB floats above it but does not reserve space. Without bottom padding, the last ListTile is hidden behind the FAB.

**Consequences:** Users think entries are missing or cannot interact with the last few timeline items.

**Prevention:** Add bottom padding to the ListView equal to the FAB height + spacing:

```dart
ListView.separated(
  padding: const EdgeInsets.only(bottom: 80), // FAB height (56) + margin (24)
  itemCount: entries.length,
  // ...
)
```

Or use `FloatingActionButton.isExtended` which is taller (48px + padding). Adjust accordingly.

**Detection:** Log enough entries to fill the screen. Check if the last entry is readable with the FAB present.

**Confidence:** HIGH -- standard Flutter layout consideration.

**Phase relevance:** Phase 2 (FAB + sheet).

---

### Pitfall 6: Dark Theme Readability of Hardcoded Colors

**What goes wrong:** Adding `darkTheme` via DynamicColorBuilder activates dark mode when the device is in dark mode. The hardcoded `Colors.green.shade600`, `Colors.red.shade600`, and `Colors.orange.shade700` used for semantic indicators (goal met, goal missed, streak) become hard to read against dark backgrounds.

**Why it happens:** These colors were chosen for light backgrounds. On dark surfaces, they lack sufficient contrast. `Colors.green.shade600` on a dark surface might pass WCAG AA but looks washed out.

**Consequences:** Calendar day markers, goal-met ring color, and streak icon are hard to see in dark mode.

**Prevention:**
- Option A: Use `Theme.of(context).brightness` to select light vs dark variants:
  ```dart
  final goalColor = theme.brightness == Brightness.dark
      ? Colors.green.shade400
      : Colors.green.shade600;
  ```
- Option B: Use the `dynamic_color` package's `harmonizeWith()` to adapt semantic colors to the current color scheme:
  ```dart
  final harmonized = Colors.green.harmonizeWith(colorScheme.primary);
  ```
- Option C: Accept the v1.0 colors for now and defer dark mode color tuning to v1.2.

**Detection:** Enable dark mode on the device. Check if the green/red/orange indicators are clearly visible.

**Confidence:** MEDIUM -- depends on whether darkTheme is included in v1.1 scope.

**Phase relevance:** Phase 1 (theme), if dark theme is included.

---

## Minor Pitfalls

### Pitfall 7: Liter Formatting Edge Case at Zero

**What goes wrong:** When `totalMl` is 0, the display shows "0.0 L / 2.0 L". This is technically correct but reads awkwardly. Some users may prefer "0 ml" or simply "0" when no water has been logged.

**Why it happens:** The formatting function applies uniformly to all values including zero.

**Prevention:** Consider a special case for zero:
```dart
String _formatMl(int ml) {
  if (ml == 0) return '0';
  return '${(ml / 1000).toStringAsFixed(1)} L';
}
```

Or accept "0.0 L" as fine. This is a UX judgment call, not a bug.

**Confidence:** LOW -- subjective. Not a real pitfall, just a design consideration.

**Phase relevance:** Phase 1 (L-display).

---

### Pitfall 8: flutter_launcher_icons iOS Transparency Rejection

**What goes wrong:** The source icon PNG has an alpha channel (transparency). The generator produces iOS icons with transparency. Apple's App Store Connect rejects the build during upload, citing "Invalid Icon - the icon must not contain transparency."

**Why it happens:** iOS app icons must have opaque backgrounds per Apple's Human Interface Guidelines. Many icon designs start as transparent PNGs.

**Prevention:**
- Ensure the source PNG at `assets/icon/app_icon.png` has a solid background (no alpha channel)
- Use separate source images for iOS and Android if the Android adaptive icon needs a transparent foreground:
  ```yaml
  flutter_launcher_icons:
    image_path: "assets/icon/app_icon.png"  # opaque, for iOS
    adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"  # transparent OK
    adaptive_icon_background: "#2196F3"
  ```

**Detection:** Attempt to upload to App Store Connect. The rejection is immediate and clear.

**Confidence:** HIGH -- Apple's guideline is unambiguous.

**Phase relevance:** Phase 3 (app icon).

---

## Phase-Specific Warnings (v1.1)

| Phase | Likely Pitfall | Mitigation |
|-------|---------------|------------|
| Phase 1: Bug Fix + Theme | Pitfall 1 (SnackBar persist), Pitfall 2 (colorScheme assertion), Pitfall 6 (dark mode colors) | Add `persist: false`. Replace `colorSchemeSeed` with `colorScheme`. Test dark mode if included. |
| Phase 2: FAB + Sheet | Pitfalls 3, 4, 5 (keyboard overlap, wrong Navigator, FAB overlap) | Use `isScrollControlled: true` + viewInsets padding. Use sheet context for pop. Add bottom padding to ListView. |
| Phase 3: App Icon | Pitfall 8 (iOS transparency) | Use opaque PNG for iOS. Separate foreground for Android adaptive. |

---

## Sources

- https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update -- SnackBar persist breaking change (HIGH confidence)
- Flutter ThemeData source code -- colorScheme/colorSchemeSeed assertion (HIGH confidence)
- Flutter showModalBottomSheet API documentation -- isScrollControlled behavior (HIGH confidence)
- Apple Human Interface Guidelines -- icon transparency prohibition (HIGH confidence)
- dynamic_color package documentation -- harmonizeWith API (HIGH confidence)
