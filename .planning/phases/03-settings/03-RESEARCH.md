# Phase 3: Settings - Research

**Researched:** 2026-06-05
**Domain:** Flutter UI -- settings form with Slider, AlertDialog, SwitchListTile, showTimePicker; Riverpod state consumption; live-save via existing repository
**Confidence:** HIGH

## Summary

Phase 3 replaces the "Coming soon" stub in `SettingsScreen` with a fully functional settings form. The entire data layer (repository, entities, providers, streams) already exists from Phase 1 and is already consumed by the HomeScreen in Phase 2. Phase 3 is purely a presentation-layer task: build UI widgets that read from existing stream providers and write back through existing repository methods.

No new packages are needed. No database schema changes. No new providers. The work is entirely within `lib/presentation/screens/settings_screen.dart` (and potentially extracted sub-widgets in `lib/presentation/widgets/`). The main technical concerns are: (1) correctly wiring `ConsumerStatefulWidget` to handle local slider/dialog state alongside Riverpod stream state, (2) the `Slider` widget requiring `double` values while the domain model uses `int`, and (3) ensuring the preset-edit dialog validates input before allowing save.

**Primary recommendation:** Build a single `ConsumerStatefulWidget` for SettingsScreen that watches `userSettingsProvider` and `drinkPresetsProvider`, delegates saves to `settingsRepositoryProvider`, and extracts the preset-edit dialog as a separate stateful widget (or a `showDialog` function) to manage local `TextEditingController` state.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Settings screen uses 3 elevated Cards in a scrollable Column: Daily Goal, Quick-Add Presets, Notifications
- **D-02:** Each card has a visible section title above it in uppercase (e.g., `DAILY GOAL`), styled as small caps label
- **D-03:** AppBar title: "Settings"
- **D-04:** Rows inside cards use `ListTile` style: `title` = setting name, `subtitle` = current value, `trailing` = control or edit icon
- **D-05:** Daily target edited via a `Slider` widget. Label above shows current value in ml, updating live. On `onChangeEnd`, calls `SettingsRepository.updateSettings()`
- **D-06:** Step size: 250 ml per division. Divisions: `(10000 - 1000) / 250 = 36`
- **D-07:** Valid range: 1000 ml -- 10000 ml
- **D-08:** Each preset row is a ListTile labeled "Preset 1"/"Preset 2" etc. with current amount as subtitle. Tapping opens AlertDialog
- **D-09:** AlertDialog contains TextField pre-filled with current amount (numeric keyboard). Confirm calls `SettingsRepository.updatePreset(id, amountMl)`. Cancel discards
- **D-10:** Valid range for presets: 50 ml -- 2000 ml. Values outside show inline error; Confirm button disabled until valid
- **D-11:** Notification interval via Slider, 5-minute steps. Range: 5 min -- 240 min. Label above in minutes format. `onChangeEnd` saves
- **D-12:** SwitchListTile controls `dndEnabled`. Toggling live-saves. When disabled, Start/End rows greyed (opacity ~0.38) and non-tappable
- **D-13:** Start/End time rows show current value. Tapping opens `showTimePicker()` (24h format). On confirm, live-saves
- **D-14:** Live-save on every change -- no Save button. Every control interaction writes immediately via `SettingsRepository`
- **D-15:** Daily target shows ml only on settings. "Displayed also as L" is intentionally deferred from Phase 3

### Claude's Discretion
- Exact card elevation and padding (use M3 defaults -- Card with elevation 1 or 2, margin EdgeInsets.symmetric horizontal 16 vertical 8)
- Error state color for preset dialog text field (use M3 colorScheme.error)
- Whether DND time rows show 12h or 24h -- match device system format via `MediaQuery.alwaysUse24HourFormat`

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SETT-01 | User can set a global daily water target in ml (displayed also as L) | Daily target Slider (D-05 through D-07) covers ml. L display intentionally deferred per D-15; planner should note this as a known UAT gap |
| SETT-02 | User can customize the amount for each quick-add preset button | Preset edit dialog (D-08 through D-10); uses existing `updatePreset(id, amountMl)` |
| SETT-03 | User can configure the notification reminder interval (in minutes or hours) | Notification interval Slider (D-11); stored as integer minutes; label shows minutes only per decision |
| SETT-04 | User can define a DND window with start time and end time during which no notifications are sent | DND toggle + time pickers (D-12, D-13); no scheduling logic in Phase 3 -- that is Phase 5 |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack locked:** Flutter + Riverpod + Drift. No deviation.
- **Platform:** iOS and Android only.
- **Offline-first:** No backend or cloud sync.
- **Riverpod style:** Use `flutter_riverpod`, not `hooks_riverpod`. Use code-gen annotations (`@riverpod`).
- **Database setup:** Use `drift_flutter` (not `sqlite3_flutter_libs` which is EOL).
- **Notifications lib:** `flutter_local_notifications` only (not `awesome_notifications`).
- **Data classes:** Use Freezed for domain model classes.
- **Settings storage:** Settings live in Drift (the `user_settings` single-row table), not `shared_preferences`.
- **Folder structure:** Layer-first (`lib/data/`, `lib/domain/`, `lib/presentation/`, `lib/core/`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Daily target editing | Frontend (Flutter UI) | -- | Pure UI: Slider reads/writes to local DB via existing provider |
| Preset amount editing | Frontend (Flutter UI) | -- | Dialog with TextField, saves via repository |
| Notification interval editing | Frontend (Flutter UI) | -- | Slider UI only; actual scheduling is Phase 5 |
| DND window configuration | Frontend (Flutter UI) | -- | Toggle + time pickers; enforcement is Phase 5 |
| Settings persistence | Database (Drift) | -- | Already implemented in Phase 1; Phase 3 only calls existing write methods |
| Reactive UI updates | State Management (Riverpod) | -- | Already implemented; `userSettingsProvider` and `drinkPresetsProvider` are `keepAlive: true` streams that auto-propagate changes to HomeScreen |

All Phase 3 work lives in the **presentation layer**. No data layer, domain layer, provider, or router changes are needed.

## Standard Stack

### Core (already installed -- no new packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management | Already in pubspec; provides `ConsumerStatefulWidget`, `ref.watch()`, `ref.read()` |
| drift | ^2.33.0 | Local persistence | Already in pubspec; `SettingsRepository` already provides `updateSettings()` and `updatePreset()` |
| freezed_annotation | ^3.1.0 | Domain entities | Already in pubspec; `UserSettingsEntity.copyWith()` used for incremental updates |

### Supporting (already installed -- no new packages)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| go_router | ^17.3.0 | Navigation | Already wired; `/settings` route already exists |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Slider for daily target | TextField with stepper buttons | Slider provides better UX for large bounded ranges; locked by D-05 |
| AlertDialog for presets | Bottom sheet | AlertDialog is simpler and standard for single-field edits; locked by D-08 |
| Live-save on change | Save button at bottom | Live-save eliminates "forgot to save" errors; locked by D-14 |

**Installation:** No new packages required. Phase 3 uses only existing dependencies.

## Architecture Patterns

### System Architecture Diagram

```
User Interaction
       |
       v
+-------------------+
| SettingsScreen     |  <-- ConsumerStatefulWidget
| (presentation)    |
|                   |
| +-- Daily Goal Card ---- Slider --onChangeEnd--> |
| +-- Presets Card ------- ListTile tap --> AlertDialog --> |
| +-- Notifications Card                                   |
|     +-- Interval Slider --onChangeEnd--> |                |
|     +-- DND Switch --onChanged--------> |                 |
|     +-- Time rows --showTimePicker----> |                 |
+-------------------+
       |
       | ref.read(settingsRepositoryProvider)
       | .updateSettings(entity.copyWith(...))
       | .updatePreset(id, amountMl)
       v
+-------------------+
| SettingsRepository |  <-- Already exists (Phase 1)
| (data layer)       |
+-------------------+
       |
       v
+-------------------+
| Drift DB           |  <-- user_settings table, drink_presets table
+-------------------+
       |
       | Stream<UserSettingsEntity>, Stream<List<DrinkPresetEntity>>
       v
+-------------------+
| userSettingsProvider     |  <-- keepAlive stream providers (Phase 1)
| drinkPresetsProvider     |
+-------------------+
       |
       | ref.watch(...)
       v
+-------------------+      +-------------------+
| SettingsScreen     |      | HomeScreen         |
| (reads + writes)   |      | (reads only)       |
+-------------------+      +-------------------+
```

Changes flow: UI control -> repository write -> DB update -> stream emission -> all watching widgets rebuild.

### Recommended Project Structure

```
lib/
  presentation/
    screens/
      settings_screen.dart    # Full rewrite: ConsumerStatefulWidget with all settings UI
    widgets/
      preset_edit_dialog.dart  # Optional: extracted AlertDialog for preset editing
```

Only `settings_screen.dart` must change. Extracting the preset dialog into its own file is at Claude's discretion for readability.

### Pattern 1: Slider with Live-Save via onChangeEnd

**What:** A Slider that shows the current value live (via local state) but only persists on release.
**When to use:** Daily target slider, notification interval slider.
**Example:**
```dart
// Source: Flutter API docs (api.flutter.dev/flutter/material/Slider-class.html)
// + Riverpod pattern from existing HomeScreen

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local state for slider dragging (avoids writing to DB on every frame)
  double? _dailyTargetSliderValue;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Use local state during drag, fall back to DB value when idle
        final currentTarget = _dailyTargetSliderValue ?? settings.dailyTargetMl.toDouble();

        return Slider(
          value: currentTarget,
          min: 1000,
          max: 10000,
          divisions: 36, // (10000 - 1000) / 250
          onChanged: (val) => setState(() => _dailyTargetSliderValue = val),
          onChangeEnd: (val) {
            setState(() => _dailyTargetSliderValue = null); // Clear local override
            final repo = ref.read(settingsRepositoryProvider);
            repo.updateSettings(settings.copyWith(dailyTargetMl: val.toInt()));
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

**Critical detail:** The Slider widget requires `double` values but `UserSettingsEntity.dailyTargetMl` and `notificationIntervalMinutes` are `int`. Convert with `.toDouble()` for the Slider and `.toInt()` (or `.round()`) on save. With discrete divisions, the Slider always snaps to exact step values, so `.toInt()` is safe.

### Pattern 2: Preset Edit Dialog with Validation

**What:** An AlertDialog with a TextField for editing a single numeric value, with range validation.
**When to use:** Preset amount editing (D-08 through D-10).
**Example:**
```dart
// Source: Flutter API docs (api.flutter.dev/flutter/material/AlertDialog-class.html)

Future<void> _showPresetDialog(DrinkPresetEntity preset) async {
  final controller = TextEditingController(text: preset.amountMl.toString());

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final text = controller.text;
          final parsed = int.tryParse(text);
          final isValid = parsed != null && parsed >= 50 && parsed <= 2000;
          final showError = text.isNotEmpty && !isValid;

          return AlertDialog(
            title: Text('Edit Preset ${preset.sortOrder + 1}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (ml)',
                errorText: showError ? 'Enter a value between 50 and 2000' : null,
                suffixText: 'ml',
              ),
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isValid
                    ? () {
                        ref.read(settingsRepositoryProvider).updatePreset(
                              preset.id,
                              parsed!,
                            );
                        Navigator.of(dialogContext).pop();
                      }
                    : null, // Disabled when invalid
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
}
```

**Key detail:** Use `StatefulBuilder` inside `showDialog` to get local `setState` for the dialog without making the entire screen stateful for each dialog. Dispose the `TextEditingController` after the dialog closes.

### Pattern 3: DND Toggle with Disabled Rows

**What:** SwitchListTile that controls a boolean, with child rows that become disabled.
**When to use:** DND enabled/disabled with Start/End time rows (D-12, D-13).
**Example:**
```dart
// Source: Flutter API docs (api.flutter.dev/flutter/material/SwitchListTile-class.html)

SwitchListTile(
  title: const Text('Do Not Disturb'),
  subtitle: Text(settings.dndEnabled ? 'On' : 'Off'),
  value: settings.dndEnabled,
  onChanged: (val) {
    ref.read(settingsRepositoryProvider).updateSettings(
          settings.copyWith(dndEnabled: val),
        );
  },
),
// DND time rows -- greyed out when disabled
IgnorePointer(
  ignoring: !settings.dndEnabled,
  child: Opacity(
    opacity: settings.dndEnabled ? 1.0 : 0.38,
    child: Column(
      children: [
        ListTile(
          title: const Text('Start time'),
          trailing: Text(_formatTime(settings.dndStartHour, settings.dndStartMinute)),
          onTap: () => _pickDndTime(isStart: true, settings: settings),
        ),
        ListTile(
          title: const Text('End time'),
          trailing: Text(_formatTime(settings.dndEndHour, settings.dndEndMinute)),
          onTap: () => _pickDndTime(isStart: false, settings: settings),
        ),
      ],
    ),
  ),
),
```

### Pattern 4: Time Picker with Device Format Awareness

**What:** `showTimePicker` that respects the device's 24h/12h preference.
**When to use:** DND start/end time selection (D-13).
**Example:**
```dart
// Source: Flutter API docs (api.flutter.dev/flutter/material/showTimePicker.html)

Future<void> _pickDndTime({required bool isStart, required UserSettingsEntity settings}) async {
  final initial = isStart
      ? TimeOfDay(hour: settings.dndStartHour, minute: settings.dndStartMinute)
      : TimeOfDay(hour: settings.dndEndHour, minute: settings.dndEndMinute);

  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
  );

  if (picked != null) {
    final updated = isStart
        ? settings.copyWith(dndStartHour: picked.hour, dndStartMinute: picked.minute)
        : settings.copyWith(dndEndHour: picked.hour, dndEndMinute: picked.minute);
    ref.read(settingsRepositoryProvider).updateSettings(updated);
  }
}
```

**Note on 24h format:** `showTimePicker` respects `MediaQuery.alwaysUse24HourFormat` automatically from the ambient `MediaQuery`. The device's system setting propagates without explicit configuration. For the display text in the ListTile, use `MediaQuery.alwaysUse24HourFormatOf(context)` to decide between 24h and 12h formatting.

### Anti-Patterns to Avoid

- **Writing to DB on every Slider.onChanged frame:** This fires ~60 times per second during a drag. Use `onChangeEnd` for DB writes and local `setState` for visual updates during drag.
- **Using `ref.watch()` inside callbacks:** Inside `onChangeEnd`, `onChanged`, or `onTap`, always use `ref.read()`. `ref.watch()` is only for the `build` method. [CITED: Riverpod docs -- ref.watch vs ref.read]
- **Forgetting to dispose TextEditingController:** In the preset dialog, the controller must be disposed after `showDialog` completes. Using `StatefulBuilder` avoids needing a full `StatefulWidget` for this.
- **Redundant provider creation:** Do NOT create new providers for settings writes. The `settingsRepositoryProvider` already exists and is `keepAlive: true`. Simply `ref.read(settingsRepositoryProvider)` to get the repository.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Slider snap-to-step | Manual step rounding logic | `Slider(divisions: N)` parameter | Flutter's discrete Slider handles exact snapping natively |
| Time picker UI | Custom hour/minute input fields | `showTimePicker()` | Material time picker handles 12/24h, accessibility, locale |
| Disabled row appearance | Manual color overrides | `IgnorePointer` + `Opacity(opacity: 0.38)` | Standard Material disabled opacity; IgnorePointer prevents tap propagation |
| Dialog local state | Full StatefulWidget for dialog | `StatefulBuilder` inside `showDialog` | Lighter weight; avoids a separate widget class for simple validation state |
| Stream-to-UI reactivity | Manual StreamBuilder | `ref.watch(userSettingsProvider)` | Riverpod handles async states (loading/error/data) and widget lifecycle |

**Key insight:** Phase 3 is entirely UI work atop existing infrastructure. Every write method, stream, provider, and entity already exists. The risk is in the presentation-layer details (slider int/double conversion, dialog state management, disabled row UX), not in data plumbing.

## Common Pitfalls

### Pitfall 1: Slider Double/Int Mismatch

**What goes wrong:** `Slider.value` is `double`, but `UserSettingsEntity.dailyTargetMl` and `notificationIntervalMinutes` are `int`. Directly assigning an int to the Slider value fails at compile time. More subtly, converting back with `.toInt()` on a non-discrete slider could lose precision.
**Why it happens:** Slider is designed for continuous ranges; discrete mode (with `divisions`) still uses doubles internally.
**How to avoid:** Always use `.toDouble()` when reading from entity to Slider, and `.toInt()` when writing from Slider to entity. With `divisions` set, the Slider snaps to exact step values, so `.toInt()` is lossless.
**Warning signs:** Compile errors on `Slider(value: intValue)` or unexpected rounding artifacts.

### Pitfall 2: Slider Value Desync During Drag

**What goes wrong:** If the Slider reads its value directly from the Riverpod provider (`settings.dailyTargetMl.toDouble()`), dragging feels "sticky" because the DB write in `onChangeEnd` triggers a provider rebuild that resets the Slider mid-drag.
**Why it happens:** `ref.watch()` causes the widget to rebuild when the stream emits, but during a drag the value should track the user's finger, not the DB.
**How to avoid:** Use a local `double?` state variable. During drag (`onChanged`), update local state via `setState`. In `onChangeEnd`, write to DB and clear local state to `null`. In `build`, use `localValue ?? dbValue.toDouble()`.
**Warning signs:** Slider "jumps" or feels laggy during drag.

### Pitfall 3: TextEditingController Lifecycle in Dialog

**What goes wrong:** Creating a `TextEditingController` inside `showDialog`'s builder means it is recreated on every rebuild. Or forgetting to dispose it causes a memory leak.
**Why it happens:** `showDialog`'s builder can be called multiple times; dialog content rebuilds.
**How to avoid:** Create the controller before calling `showDialog`, pass it into the builder, and dispose it after `showDialog` completes (in the `then` or after `await`).
**Warning signs:** Text field resets during interaction, or Flutter leak detection warnings.

### Pitfall 4: ref.watch vs ref.read in Callbacks

**What goes wrong:** Using `ref.watch()` inside an `onChanged` or `onTap` callback throws or produces unexpected behavior.
**Why it happens:** `ref.watch()` is only valid inside `build()`. Callbacks execute outside the build phase.
**How to avoid:** Use `ref.read()` in all callbacks. The `build` method uses `ref.watch()` for reactive data. [ASSUMED -- based on Riverpod documentation patterns]
**Warning signs:** `ProviderException` or "Cannot use ref.watch outside of build" errors.

### Pitfall 5: Entity copyWith Gotcha -- Must Pass Full Entity

**What goes wrong:** `SettingsRepository.updateSettings()` takes a full `UserSettingsEntity`, not individual fields. Calling it with a partially constructed entity would overwrite other fields with wrong values.
**Why it happens:** The Drift DAO writes all fields in the companion.
**How to avoid:** Always start from the current entity (from `ref.watch(userSettingsProvider).value`) and use `entity.copyWith(fieldToChange: newValue)`. This preserves all other fields.
**Warning signs:** Changing daily target resets notification interval to some default.

### Pitfall 6: Stale Entity Reference in Async Callbacks

**What goes wrong:** Capturing a `settings` entity reference in a closure, then using it for `copyWith` after an async gap (e.g., after `showTimePicker` returns). If another setting was changed during the picker, the captured entity is stale and the `copyWith` overwrites the concurrent change.
**Why it happens:** `showTimePicker` is async; user could theoretically change another setting while the picker is open.
**How to avoid:** For practical purposes in this app (single user, sequential interactions), this race is extremely unlikely. However, if desired, re-read the current settings from the provider after the async gap: `final current = ref.read(userSettingsProvider).value!;` then `current.copyWith(...)`. The simpler approach (capture before async gap) is acceptable for MVP given the very low risk.
**Warning signs:** Concurrent setting changes lost.

## Code Examples

### Full Settings Screen Skeleton

```dart
// Source: Existing codebase patterns (home_screen.dart) + Flutter API docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local slider state to avoid DB writes during drag
  double? _dailyTargetDrag;
  double? _intervalDrag;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final presetsAsync = ref.watch(drinkPresetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading settings')),
        data: (settings) {
          final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
          return _buildBody(context, settings, presets);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserSettingsEntity settings, List<DrinkPresetEntity> presets) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'DAILY GOAL'),
          _dailyGoalCard(context, settings),
          _sectionLabel(context, 'QUICK-ADD PRESETS'),
          _presetsCard(context, presets),
          _sectionLabel(context, 'NOTIFICATIONS'),
          _notificationsCard(context, settings),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  // ... card builder methods follow the patterns documented above
}
```

### Time Display Helper

```dart
// Source: CONTEXT.md D-13 -- match device 24h/12h setting

String _formatTime(BuildContext context, int hour, int minute) {
  final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
  if (use24h) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  } else {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `withOpacity(0.38)` for disabled | `withValues(alpha: 0.38)` | Flutter 3.44.1 | `withOpacity` deprecated; must use `withValues` [VERIFIED: accumulated context from Phase 2 decision log] |
| `.valueOrNull` on AsyncValue | `.value` (nullable T?) | Riverpod 3.2.1 | `.valueOrNull` does not exist; use `.value` which returns T? [VERIFIED: accumulated context from Phase 2 decision log] |
| `Slider` with `year2023` param | `SliderThemeData` for customization | Flutter 3.x | `year2023` is deprecated; use theme data instead [CITED: api.flutter.dev/flutter/material/Slider-class.html] |

**Deprecated/outdated:**
- `Color.withOpacity()`: Use `Color.withValues(alpha: x)` instead (Flutter 3.44.1+)
- `AsyncValue.valueOrNull`: Does not exist in Riverpod 3.2.1; use `.value` (nullable)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `MediaQuery.alwaysUse24HourFormatOf(context)` is the current static method for querying 24h format | Code Examples | Low -- if API changed, compile error would surface immediately; fallback is `MediaQuery.of(context).alwaysUse24HourFormat` |
| A2 | `StatefulBuilder` inside `showDialog` is the standard lightweight pattern for dialog-local state | Architecture Patterns | Low -- well-established Flutter pattern; alternative is a dedicated StatefulWidget |
| A3 | `IgnorePointer` + `Opacity(opacity: 0.38)` is the standard Material disabled-row pattern | Architecture Patterns | Low -- straightforward Flutter widgets; opacity 0.38 is the M3 disabled alpha |
| A4 | `ref.read()` must be used in callbacks, `ref.watch()` only in `build()` | Pitfalls | Low -- core Riverpod contract; unlikely to change |

## Open Questions (RESOLVED)

1. **Slider label overlay vs inline label** — RESOLVED: Use a separate persistent `Text` widget above the Slider in the Column layout. D-05/D-11 say "updating live as the user drags," implying persistent visibility, not the built-in tooltip overlay which only shows during drag.

2. **Preset dialog pre-fill: text selection on open** — RESOLVED: Pre-select all text via `controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length)` assigned after controller creation. Standard edit-in-place UX so the user can immediately type a replacement value.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- offline app, no auth |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single user, local data |
| V5 Input Validation | Yes | Range validation on Slider (clamped by min/max/divisions) and TextField (50-2000 ml with error display). Repository-level ArgumentError guards already exist from Phase 1 |
| V6 Cryptography | No | N/A -- no encryption needed for settings |

### Known Threat Patterns for Flutter Settings UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Out-of-range input via TextField | Tampering | Client-side validation (50-2000 ml range check) + server-side (repository ArgumentError guard). Slider widgets are inherently bounded by min/max |
| SQL injection via TextField | Tampering | Not applicable -- Drift uses parameterized queries; the `updatePreset(id, amountMl)` method takes typed `int` parameters, not raw SQL strings |

**Assessment:** Security risk for Phase 3 is minimal. All inputs are numeric integers passed through typed Dart parameters to Drift's parameterized query system. No string interpolation into SQL. Existing repository-level validation (`amountMl > 0`, hour/minute range checks) provides defense-in-depth.

## Sources

### Primary (HIGH confidence)
- Existing codebase: `settings_repository.dart`, `user_settings_entity.dart`, `drink_preset_entity.dart`, `stream_providers.dart`, `repository_providers.dart`, `home_screen.dart`, `app_database.dart` -- verified by direct file read
- Flutter API docs: `api.flutter.dev/flutter/material/Slider-class.html` -- Slider parameters, divisions, onChangeEnd [CITED]
- Flutter API docs: `api.flutter.dev/flutter/material/showTimePicker.html` -- showTimePicker signature, 24h format [CITED]
- Flutter API docs: `api.flutter.dev/flutter/material/SwitchListTile-class.html` -- SwitchListTile parameters [CITED]
- Flutter API docs: `api.flutter.dev/flutter/material/AlertDialog-class.html` -- AlertDialog with TextField pattern [CITED]
- CONTEXT.md (Phase 3): All D-01 through D-15 decisions
- CONTEXT.md (Phase 1): D-05 through D-08 default values, D-12 folder structure, D-15 schema

### Secondary (MEDIUM confidence)
- Accumulated project context (STATE.md): `withValues(alpha:)` replacing `withOpacity`, `.value` vs `.valueOrNull` -- verified by Phase 2 execution

### Tertiary (LOW confidence)
- `MediaQuery.alwaysUse24HourFormatOf(context)` static method existence [ASSUMED -- A1]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new packages; all dependencies verified in pubspec.yaml
- Architecture: HIGH -- all integration points verified by reading existing source code; pattern is straightforward (read stream, write via repository)
- Pitfalls: HIGH -- pitfalls derived from concrete code analysis (int/double mismatch, async entity staleness, controller lifecycle) and verified Flutter API behavior

**Research date:** 2026-06-05
**Valid until:** 2026-07-05 (stable -- no rapidly changing dependencies)
