# Phase 7: Intake Redesign - Research

**Researched:** 2026-06-08
**Domain:** Flutter UI refactoring (FAB, modal bottom sheet, preset reduction)
**Confidence:** HIGH

## Summary

Phase 7 is a UI-only refactoring phase that replaces inline quick-add buttons on the HomeScreen with a FloatingActionButton that opens a modal bottom sheet. The sheet presents 3 configurable presets and a custom ml text field. No new packages are introduced -- every widget used (`FloatingActionButton`, `showModalBottomSheet`, `FilledButton`, `TextField`) is a Flutter SDK built-in. No database migration is needed; the 4th preset is hidden at the UI layer via `.take(3)`.

The codebase is well-structured for this change. The existing `_onQuickAdd(int amountMl)` method in `home_screen.dart` already encapsulates the full insert-plus-undo-SnackBar flow with proper `mounted` guard and `ScaffoldMessenger` capture. The sheet widget only needs to call back with an `amountMl` value -- it does not interact with the database or providers directly. The `DrinkPresetDao.watchAllPresets()` returns all rows sorted by `sortOrder`; callers apply `.take(3)` at the presentation layer.

**Primary recommendation:** Implement as a single plan with 3 changes: (1) replace the quick-add Row with a FAB and sheet in `home_screen.dart`, (2) apply `.take(3)` in `settings_screen.dart`, (3) update the seed data in `app_database.dart`. Extract the sheet content into a private `_IntakeBottomSheet` StatefulWidget for clean controller lifecycle management.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** After tapping a preset button in the sheet, close the sheet first (`Navigator.pop()`), then show the SnackBar. Sheet and SnackBar are sequential, not simultaneous.
- **D-02:** After submitting a custom ml value, same behavior: sheet closes first, then SnackBar appears.
- **D-03:** Both preset tap and custom submit produce the same close-then-snackbar sequence -- no exception for either path.
- **D-04:** New seed = 3 presets: 150 ml / 250 ml / 500 ml (sortOrder 0, 1, 2). Change `app_database.dart` `onCreate` seed from 4 rows to 3 rows with these values.
- **D-05:** No Drift migration for existing users. Existing installs keep their 4 DB rows. The UI (sheet + settings) applies `LIMIT 3` / takes first 3 by sortOrder -- the 4th preset is silently invisible.
- **D-06:** The `DrinkPresetDao.watchAllPresets()` returns all rows sorted by `sortOrder`. Callers (sheet widget, settings card) take `presets.take(3)` or equivalent at the presentation layer -- no DAO change needed.
- **D-07:** The undo SnackBar format is identical to the current v1.0 format: `'+$amountMl ml added'`, with `SnackBarAction(label: 'Undo')`, `persist: false`, `duration: 5s`. No variation for sheet-originated additions.
- **D-08:** The undo logic must capture `ScaffoldMessenger` and the `mounted` check before the `async` gap -- same pattern already used in `home_screen.dart`.
- **D-09:** The sheet callback passes `amountMl` back to the HomeScreen widget which owns the insert + undo logic. The sheet itself is stateless with respect to DB writes.
- **D-10:** FAB goes on the **inner HomeScreen Scaffold**, not on the outer `StatefulShellRoute` Scaffold.
- **D-11:** Valid range: 1-9999 ml. Empty or zero results in submit button disabled. Non-numeric input rejected by `TextInputType.number` keyboard. No explicit error label needed.
- **D-12:** Submit via a `FilledButton` in the sheet (not keyboard action alone).

### Claude's Discretion
- Exact Flutter widget: `showModalBottomSheet` with standard drag handle -- no custom `DraggableScrollableSheet` needed
- Whether to extract the sheet content into a separate `_IntakeBottomSheet` widget or build inline
- TextField `controller` disposal strategy

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTAKE-01 | Home screen quick-add buttons are removed; a FAB opens the add-intake interface | FAB placed on inner HomeScreen Scaffold (`floatingActionButton` property); existing quick-add Row (lines 150-166) removed; `showModalBottomSheet` called from `onPressed` |
| INTAKE-02 | Add-intake modal bottom sheet displays 3 configurable preset buttons (reduced from 4) | Sheet receives `presets.take(3).toList()` from HomeScreen; each preset rendered as `FilledButton` in an `Expanded` `Row`; `onPressed` calls `Navigator.pop()` then `_onQuickAdd(preset.amountMl)` |
| INTAKE-03 | Add-intake sheet includes a custom ml text field with numeric keyboard; submitting adds the entry and closes the sheet | `TextField` with `TextInputType.number`, `suffixText: 'ml'`, `hintText: 'Custom amount'`; `FilledButton` labeled `'Add'` disabled when parsed value outside 1-9999; submit calls `Navigator.pop()` then `_onQuickAdd(parsedMl)` |
| INTAKE-04 | Settings screen preset editing is reduced to 3 configurable slots; the 4th preset slot is retired | `_presetsCard` in `settings_screen.dart` applies `.take(3)` before `.map()` at line 129 |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| FAB entry point | Client (Flutter widget tree) | -- | Pure UI widget on HomeScreen Scaffold; no backend or server involvement |
| Modal bottom sheet with presets | Client (Flutter widget tree) | -- | Stateless UI receiving data from parent; closes via `Navigator.pop()` |
| Custom ml input + validation | Client (Flutter widget tree) | -- | Client-side input validation (1-9999 range); no server validation needed |
| DB insert + undo | Client (Riverpod + Drift) | Database (SQLite) | `_onQuickAdd` in HomeScreen owns the insert call; Drift writes to local SQLite |
| Preset seed reduction | Database (SQLite onCreate) | -- | Only affects fresh installs; `app_database.dart` seed block |
| Settings preset display | Client (Flutter widget tree) | -- | `.take(3)` filter at presentation layer; no DAO or DB change |

## Standard Stack

### Core

No new packages. All widgets used are Flutter SDK built-ins.

| Widget | Module | Purpose | Why Standard |
|--------|--------|---------|--------------|
| `FloatingActionButton` | `material.dart` | Entry point for adding intake | Material 3 standard FAB; default placement, sizing, and theming |
| `showModalBottomSheet` | `material.dart` | Container for preset buttons + custom input | Flutter SDK built-in; supports `showDragHandle`, `useSafeArea` |
| `FilledButton` | `material.dart` | Preset buttons + custom submit button | Already used in existing quick-add Row and preset edit dialog |
| `TextField` | `material.dart` | Custom ml text input | Already used in `preset_edit_dialog.dart`; same pattern applies |

### Supporting

No additional supporting libraries needed. Existing dependencies (`flutter_riverpod`, `drift`, `intl`, `percent_indicator`) remain unchanged.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `showModalBottomSheet` | `DraggableScrollableSheet` | Overkill for short fixed-height content; adds complexity with snap points and scroll controllers |
| `FloatingActionButton` | `FloatingActionButton.extended` | Extended FAB takes more space; a simple icon FAB is sufficient since the action is self-evident |
| `TextField` for custom input | `TextFormField` with `Form` | Form validation adds boilerplate; simple `TextEditingController` + `int.tryParse` is sufficient for a single field |

**Installation:** No installation needed. Zero new dependencies.

## Architecture Patterns

### System Architecture Diagram

```
User taps FAB
    |
    v
showModalBottomSheet() opens
    |
    +-- Preset tap --> Navigator.pop() --> _onQuickAdd(preset.amountMl)
    |                                           |
    +-- Custom submit --> Navigator.pop() --> _onQuickAdd(parsedMl)
                                                |
                                                v
                                    WaterRepository.insertEntry()
                                                |
                                                v
                                    Drift SQLite write (local)
                                                |
                                                v
                                    Stream update triggers UI rebuild
                                                |
                                                v
                                    SnackBar shown (with undo action)
```

### Recommended Project Structure

No new files needed. Changes are confined to existing files:

```
lib/
├── data/database/
│   └── app_database.dart           # Seed data change (4 presets -> 3)
└── presentation/
    ├── screens/
    │   ├── home_screen.dart         # Remove Row, add FAB + sheet
    │   └── settings_screen.dart     # Apply .take(3) to presets card
    └── widgets/
        └── preset_edit_dialog.dart  # UNCHANGED (reference for patterns)
```

### Pattern 1: Sheet-as-Callback Widget

**What:** Extract the bottom sheet content into a private `_IntakeBottomSheet` StatefulWidget that owns its `TextEditingController` and calls back to the parent with an `int amountMl` value.

**When to use:** When a modal needs local mutable state (text controller) but should not own business logic (DB writes, SnackBar display).

**Example:**
```dart
// Follows the same pattern as _PresetEditDialog in preset_edit_dialog.dart
// [VERIFIED: codebase grep - lib/presentation/widgets/preset_edit_dialog.dart]

class _IntakeBottomSheet extends StatefulWidget {
  const _IntakeBottomSheet({
    required this.presets,
    required this.onAdd,
  });
  final List<DrinkPresetEntity> presets;
  final void Function(int amountMl) onAdd;

  @override
  State<_IntakeBottomSheet> createState() => _IntakeBottomSheetState();
}

class _IntakeBottomSheetState extends State<_IntakeBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final parsed = int.tryParse(text);
    final isValid = parsed != null && parsed >= 1 && parsed <= 9999;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Preset buttons row
          Row(
            children: widget.presets.map((preset) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAdd(preset.amountMl);
                    },
                    child: Text('+${preset.amountMl} ml'),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Custom input
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Custom amount',
              suffixText: 'ml',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isValid
                  ? () {
                      Navigator.pop(context);
                      widget.onAdd(parsed);
                    }
                  : null,
              child: const Text('Add'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

### Pattern 2: FAB-to-Sheet Wiring

**What:** The FAB's `onPressed` calls `showModalBottomSheet` and passes a callback that invokes the existing `_onQuickAdd` method.

**When to use:** When the FAB is the sole entry point for an action that opens a modal.

**Example:**
```dart
// [ASSUMED] - Standard Flutter pattern for FAB + showModalBottomSheet
// Applied to existing home_screen.dart Scaffold

Scaffold(
  appBar: AppBar(title: const Text('Drinky Drinky')),
  floatingActionButton: FloatingActionButton(
    tooltip: 'Add water',
    onPressed: () {
      final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => _IntakeBottomSheet(
          presets: presets.take(3).toList(),
          onAdd: _onQuickAdd,
        ),
      );
    },
    child: const Icon(Icons.add),
  ),
  body: settingsAsync.when(/* ... */),
);
```

### Pattern 3: Presentation-Layer Filtering with .take(3)

**What:** Apply `.take(3)` to the presets list at the widget level, not at the DAO level. This means existing users with 4 DB rows silently see only 3, while the 4th remains in the database.

**When to use:** When reducing visible items without a data migration.

**Example:**
```dart
// settings_screen.dart _presetsCard
// [VERIFIED: codebase grep - lib/presentation/screens/settings_screen.dart line 129]

Widget _presetsCard(BuildContext context, List<DrinkPresetEntity> presets) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      children: presets.take(3).map((preset) {  // <-- .take(3) added here
        return ListTile(
          title: Text('Preset ${preset.sortOrder + 1}'),
          subtitle: Text('${preset.amountMl} ml'),
          trailing: const Icon(Icons.edit),
          onTap: () => showPresetEditDialog(context, ref, preset),
        );
      }).toList(),
    ),
  );
}
```

### Anti-Patterns to Avoid

- **Putting FAB on the outer Scaffold:** The `StatefulShellRoute.indexedStack` builder in `app_router.dart` (line 40-42) creates an outer Scaffold with the `NavigationBar`. Placing the FAB there would make it visible on all tabs (History, Settings) -- not just Home. D-10 explicitly locks FAB to the inner HomeScreen Scaffold. [VERIFIED: codebase grep - lib/core/router/app_router.dart line 40-42]
- **Accessing providers inside the sheet widget:** D-09 requires the sheet to be stateless with respect to DB writes. It receives data and a callback from the parent. Do NOT use `ref.watch` or `ref.read` inside the sheet -- this would couple the modal to Riverpod and make it harder to test.
- **Showing SnackBar before sheet closes:** D-01/D-02/D-03 require sequential behavior: `Navigator.pop()` first, then `_onQuickAdd()`. If the SnackBar fires while the sheet is still visible, it will appear behind the modal overlay and be invisible to the user.
- **Modifying `DrinkPresetDao` to add LIMIT 3:** D-06 explicitly states no DAO change. The `.take(3)` filter belongs at the presentation layer. Changing the DAO would affect all callers and potentially break future features that need all presets.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Modal bottom sheet | Custom overlay/animation | `showModalBottomSheet` | Flutter SDK handles barrier color, drag dismiss, back navigation, safe area, animation, and Material 3 theming automatically |
| Drag handle | Custom `Container` with rounded corners | `showDragHandle: true` parameter | Built-in Material 3 drag handle with correct sizing, color, and hit area |
| Input validation feedback | Custom error text widget | `FilledButton.onPressed: null` (disabled state) | D-11 specifies disabled state is sufficient; Material 3 disabled appearance is already correct |
| Bottom safe area | Manual `MediaQuery.viewPaddingOf(context).bottom` padding | `useSafeArea: true` parameter | Flutter handles safe area insets automatically with this flag |

**Key insight:** This entire phase uses zero third-party packages. Every component is a Flutter SDK built-in. The complexity is in wiring, not in widget selection.

## Common Pitfalls

### Pitfall 1: SnackBar Invisible Behind Sheet

**What goes wrong:** If `_onQuickAdd()` is called before `Navigator.pop()`, the SnackBar renders behind the modal bottom sheet's barrier overlay and the user never sees it.
**Why it happens:** The sheet occupies its own route on the navigator stack. SnackBars render in the scaffold behind the sheet overlay.
**How to avoid:** Always call `Navigator.pop(context)` first, then invoke the callback. The callback (`_onQuickAdd`) handles SnackBar display after the sheet is dismissed. This is locked per D-01/D-02/D-03.
**Warning signs:** SnackBar appears but user reports not seeing it.

### Pitfall 2: TextEditingController Leak

**What goes wrong:** If the sheet content is built inline (not as a `StatefulWidget`), the `TextEditingController` has no lifecycle hook for disposal.
**Why it happens:** `showModalBottomSheet` `builder` is a function, not a widget with `dispose()`.
**How to avoid:** Extract the sheet content into a `StatefulWidget` (`_IntakeBottomSheet`) that creates the controller in `initState` and disposes it in `dispose()`. This matches the existing pattern in `preset_edit_dialog.dart`. [VERIFIED: codebase grep - lib/presentation/widgets/preset_edit_dialog.dart lines 28-44]
**Warning signs:** Memory leak warnings in DevTools; controller not disposed.

### Pitfall 3: Navigator.pop Uses Wrong Context

**What goes wrong:** Calling `Navigator.pop(context)` with the HomeScreen's context instead of the sheet's context. The sheet's `builder` provides a `sheetContext` that corresponds to the sheet's route.
**Why it happens:** Closure captures the outer `context` instead of the `builder`'s parameter.
**How to avoid:** Inside `_IntakeBottomSheet`, use `context` from the widget's `build` method (which is the sheet's context since the widget is built inside the sheet's builder). Since the sheet widget receives its own `BuildContext`, `Navigator.pop(context)` correctly pops the sheet route.
**Warning signs:** Nothing closes, or the wrong route pops.

### Pitfall 4: Keyboard Covering Submit Button

**What goes wrong:** When the user taps the custom ml `TextField`, the soft keyboard may push the sheet content up. If `isScrollControlled: false`, the sheet has a fixed height and the submit button might be clipped.
**Why it happens:** The sheet content height plus keyboard height exceeds the available screen space.
**How to avoid:** Per UI-SPEC, `isScrollControlled: false` is specified because the content is short. However, if the content gets clipped on small screens, the fix would be to set `isScrollControlled: true` and wrap the content in `SingleChildScrollView` with `padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`. Monitor during testing. [ASSUMED]
**Warning signs:** Submit button not visible when keyboard is open on small devices.

### Pitfall 5: `.take(3)` on Empty List

**What goes wrong:** If the presets stream emits an empty list (edge case during DB initialization), `.take(3)` on an empty `Iterable` returns an empty `Iterable` (no crash), but the UI shows no preset buttons.
**Why it happens:** Normal `Iterable.take(n)` is safe on shorter lists -- it returns what's available.
**How to avoid:** No code fix needed. The existing `presetsAsync.value ?? <DrinkPresetEntity>[]` fallback handles the loading state. Once the DB seeds, 3+ presets are always present. [VERIFIED: codebase grep - Dart `Iterable.take` returns up to N elements, safe on shorter lists]
**Warning signs:** None -- this is a non-issue, documented for completeness.

### Pitfall 6: ScaffoldMessenger Captured After Async Gap

**What goes wrong:** If `ScaffoldMessenger.of(context)` is called after `await repo.insertEntry(...)`, the context may be invalid (widget unmounted).
**Why it happens:** The existing `_onQuickAdd` method already handles this correctly with a `mounted` guard at line 254-255 and `ScaffoldMessenger` capture. But if someone refactors the method, they might reorder these calls.
**How to avoid:** Preserve the existing `_onQuickAdd` method structure exactly. The `mounted` check happens before `ScaffoldMessenger.of(context)` is called. [VERIFIED: codebase grep - lib/presentation/screens/home_screen.dart lines 248-274]
**Warning signs:** `setState() called after dispose` or `Looking up a deactivated widget's ancestor` errors.

## Code Examples

### Complete FAB Integration in HomeScreen

```dart
// [VERIFIED: codebase grep - home_screen.dart current Scaffold structure at line 90]
// The Scaffold currently has appBar and body. Add floatingActionButton property.

@override
Widget build(BuildContext context) {
  final settingsAsync = ref.watch(userSettingsProvider);
  final totalAsync = ref.watch(totalMlForDateProvider(_dateKey));
  final entriesAsync = ref.watch(waterEntriesForDateProvider(_dateKey));
  final presetsAsync = ref.watch(drinkPresetsProvider);

  // ... ref.listen for goal-reached notification cancel (unchanged) ...

  return Scaffold(
    appBar: AppBar(title: const Text('Drinky Drinky')),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Add water',
      onPressed: () {
        final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _IntakeBottomSheet(
            presets: presets.take(3).toList(),
            onAdd: _onQuickAdd,
          ),
        );
      },
      child: const Icon(Icons.add),
    ),
    body: settingsAsync.when(/* ... existing code ... */),
  );
}
```

### Updated _buildContent Without Quick-Add Row

```dart
// [VERIFIED: codebase grep - home_screen.dart lines 108-214]
// Remove the Padding+Row block at lines 150-166.
// Change SizedBox(height: 24) at line 149 to SizedBox(height: 32) per UI-SPEC.

Widget _buildContent(
  BuildContext context,
  UserSettingsEntity settings,
  int totalMl,
  List<WaterEntryEntity> entries,
  List<DrinkPresetEntity> presets,  // parameter still used for FAB in build()
) {
  // ... ring code unchanged ...

  return Column(
    children: [
      const SizedBox(height: 48),
      CircularPercentIndicator(/* ... unchanged ... */),
      const SizedBox(height: 32),  // was 24 + Row + 32, now single 32px gap
      // Timeline Section Header (unchanged)
      Padding(/* ... */),
      const SizedBox(height: 8),
      Expanded(/* ... timeline list unchanged ... */),
    ],
  );
}
```

### Updated Empty State Copy

```dart
// [VERIFIED: codebase grep - home_screen.dart lines 217-236]
// Update body text to reference FAB instead of "a button above"

Widget _buildEmptyState(ThemeData theme) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No drinks logged yet',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the + button to log your first drink today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
```

### Updated Error State Copy

```dart
// [VERIFIED: codebase grep - home_screen.dart lines 94-96]
// Per UI-SPEC copywriting contract: add recovery instruction

error: (e, _) => const Center(
  child: Text('Something went wrong loading your data. Please restart the app.'),
),
```

### Updated Seed Data in app_database.dart

```dart
// [VERIFIED: codebase grep - lib/data/database/app_database.dart lines 44-50]
// Change from 4 presets (200/300/400/500) to 3 presets (150/250/500)

await batch((batch) {
  batch.insertAll(drinkPresets, [
    DrinkPresetsCompanion.insert(amountMl: 150, sortOrder: 0),
    DrinkPresetsCompanion.insert(amountMl: 250, sortOrder: 1),
    DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 2),
  ]);
});
```

### Settings Screen .take(3)

```dart
// [VERIFIED: codebase grep - lib/presentation/screens/settings_screen.dart line 129]

Widget _presetsCard(BuildContext context, List<DrinkPresetEntity> presets) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      children: presets.take(3).map((preset) {
        return ListTile(
          title: Text('Preset ${preset.sortOrder + 1}'),
          subtitle: Text('${preset.amountMl} ml'),
          trailing: const Icon(Icons.edit),
          onTap: () => showPresetEditDialog(context, ref, preset),
        );
      }).toList(),
    ),
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline quick-add buttons in body | FAB + modal bottom sheet | Phase 7 (this phase) | Cleaner home screen; FAB is standard Material 3 pattern for primary actions |
| 4 drink presets (200/300/400/500 ml) | 3 drink presets (150/250/500 ml) | Phase 7 (this phase) | Simpler UI; 3 presets fit better in a Row without crowding |
| `showDragHandle` unavailable | Available since Flutter 3.7 | Flutter 3.7 (2023) | No need to build custom drag handle widgets |
| `useSafeArea` unavailable | Available since Flutter 3.7 | Flutter 3.7 (2023) | No need for manual safe area padding in bottom sheets |

**Deprecated/outdated:**
- The `persistentFooterButtons` approach for bottom sheet actions is outdated; `showModalBottomSheet` with inline content is the standard approach. [ASSUMED]
- `BottomSheet` widget used directly is rarely needed; `showModalBottomSheet` wraps it with the modal barrier and animation. [ASSUMED]

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation (this phase adds zero new packages)
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- `flutter_riverpod` 3.x (not `hooks_riverpod`)
- `showModalBottomSheet` is the standard approach (no third-party sheet packages)
- `FilledButton` is used for preset buttons (consistent with existing codebase)
- `TextInputType.number` for numeric keyboard (consistent with preset_edit_dialog.dart)
- `persist: false` on SnackBar (Flutter 3.38+ breaking change, fixed in Phase 6)

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `isScrollControlled: false` may clip submit button on small screens when keyboard is open | Pitfall 4 | LOW -- can be fixed during testing by switching to `true` + scroll wrapper |
| A2 | `persistentFooterButtons` approach is outdated for bottom sheets | State of the Art | NONE -- informational only |
| A3 | `BottomSheet` widget used directly is rarely needed | State of the Art | NONE -- informational only |
| A4 | Standard Flutter pattern for FAB + showModalBottomSheet | Pattern 2: FAB-to-Sheet Wiring | LOW -- this is basic Flutter API usage, well-established |

**If this table is empty:** N/A -- 4 minor assumed claims listed above, all LOW risk.

## Open Questions

1. **Keyboard behavior with `isScrollControlled: false`**
   - What we know: The UI-SPEC specifies `isScrollControlled: false` because content is short.
   - What's unclear: Whether the soft keyboard will clip the submit button on smaller devices (e.g., iPhone SE, small Android phones).
   - Recommendation: Implement with `isScrollControlled: false` as specified. If clipping occurs during testing, switch to `isScrollControlled: true` with a `SingleChildScrollView` wrapper and bottom padding for keyboard insets. This is a minor adjustment that does not affect architecture.

2. **`_buildContent` presets parameter after Row removal**
   - What we know: The `presets` parameter is currently passed to `_buildContent` to build the quick-add Row.
   - What's unclear: After removing the Row, `_buildContent` no longer uses `presets` directly.
   - Recommendation: Remove the `presets` parameter from `_buildContent` since the FAB accesses `presetsAsync` from the `build()` method's scope. This simplifies the method signature.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A -- offline local app, no auth |
| V3 Session Management | no | N/A -- no sessions |
| V4 Access Control | no | N/A -- single-user local app |
| V5 Input Validation | yes | `int.tryParse` + range check (1-9999) on custom ml input |
| V6 Cryptography | no | N/A -- no encryption in this phase |

### Known Threat Patterns for Flutter Mobile (Phase 7 scope)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Integer overflow on custom ml input | Tampering | `int.tryParse` returns null for non-parseable input; range clamped to 1-9999; `FilledButton` disabled when invalid |
| Negative value injection | Tampering | `TextInputType.number` keyboard does not provide minus sign on most platforms; `parsed >= 1` check prevents zero/negative |

Note: This phase's security surface is minimal. Input validation is limited to a single numeric text field with a bounded range. No network calls, no file I/O, no IPC.

## Sources

### Primary (HIGH confidence)
- Codebase grep: `lib/presentation/screens/home_screen.dart` -- current quick-add Row structure, `_onQuickAdd` method, Scaffold layout
- Codebase grep: `lib/presentation/screens/settings_screen.dart` -- `_presetsCard` method, preset rendering
- Codebase grep: `lib/data/database/app_database.dart` -- `onCreate` seed block, current 4-preset values
- Codebase grep: `lib/core/router/app_router.dart` -- `StatefulShellRoute.indexedStack` outer Scaffold confirms FAB must go on inner Scaffold
- Codebase grep: `lib/presentation/widgets/preset_edit_dialog.dart` -- `TextEditingController` lifecycle pattern, validation pattern
- Codebase grep: `lib/data/database/daos/drink_preset_dao.dart` -- `watchAllPresets()` sorts by sortOrder ASC
- Codebase grep: `lib/core/providers/stream_providers.dart` -- `drinkPresetsProvider` is a keepAlive stream provider
- Phase 7 UI-SPEC: `.planning/phases/07-intake-redesign/07-UI-SPEC.md` -- layout contract, interaction contract, copywriting contract
- Phase 7 CONTEXT.md: `.planning/phases/07-intake-redesign/07-CONTEXT.md` -- all locked decisions D-01 through D-12

### Secondary (MEDIUM confidence)
- Flutter SDK documentation for `showModalBottomSheet` parameters (`showDragHandle`, `useSafeArea`, `isScrollControlled`) -- available since Flutter 3.7 [ASSUMED based on training data, not verified against current SDK docs]

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all widgets are Flutter SDK built-ins; no new packages
- Architecture: HIGH -- changes confined to 3 existing files with clear codebase patterns to follow
- Pitfalls: HIGH -- identified from codebase analysis and locked decisions; async/mounted patterns already established in codebase

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable -- no moving parts, all Flutter SDK built-ins)
