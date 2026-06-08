# Phase 3: Settings - Context

**Gathered:** 2026-06-05
**Updated:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 replaces the "Coming soon" stub in `SettingsScreen` with a fully functional settings UI. Four user-configurable values:

1. **Daily water target** (SETT-01) — slider on the settings screen (ml only; L display deferred)
2. **Quick-add preset amounts** (SETT-02) — 4 rows, each editable via a dialog
3. **Notification reminder interval** (SETT-03) — slider on the settings screen
4. **DND quiet-hours window** (SETT-04) — toggle + two time-picker rows

All persistence is through the existing `SettingsRepository` (`updateSettings`, `updatePreset`). No notification scheduling logic in this phase — that is Phase 5. The home screen's progress ring and preset buttons update automatically via the existing Riverpod streams (`userSettingsProvider`, `drinkPresetsProvider` — both `keepAlive: true`).

</domain>

<decisions>
## Implementation Decisions

### Screen Layout (D-01 – D-04)
- **D-01:** The Settings screen uses **3 elevated Cards** in a scrollable Column:
  1. **Daily Goal** card — daily target slider
  2. **Quick-Add Presets** card — 4 preset rows
  3. **Notifications** card — interval slider + DND toggle + DND start/end time rows
- **D-02:** Each card has a **visible section title above it** in uppercase (e.g., `DAILY GOAL`), styled as a small caps label — Material 3 settings convention.
- **D-03:** AppBar title: **"Settings"** (standard; matches the tab label).
- **D-04:** Rows inside each card use **`ListTile`** style: `title` = setting name, `subtitle` = current value (where relevant), `trailing` = the control or an edit icon.

### Daily Target Input (D-05 – D-07)
- **D-05:** Daily target is edited via a **`Slider`** widget — same visual pattern as the notification interval slider. A label above the slider shows the current value in ml (e.g., "2000 ml"), updating live as the user drags. On release (`onChangeEnd`), calls `SettingsRepository.updateSettings()`.
- **D-06:** Step size: **250 ml** per division. Divisions: `(10000 - 1000) / 250 = 36`.
- **D-07:** Valid range: **1000 ml – 10 000 ml**. Slider is clamped to these bounds.

### Preset Editing (D-08 – D-10)
- **D-08:** Each preset row is a `ListTile` labeled **"Preset 1"** / "Preset 2" / "Preset 3" / "Preset 4" with the current amount as the subtitle (e.g., "200 ml"). Tapping the row opens an `AlertDialog`.
- **D-09:** The `AlertDialog` contains a `TextField` pre-filled with the current amount (numeric keyboard). Confirm immediately calls `SettingsRepository.updatePreset(id, amountMl)` (live-save). Cancel discards the change.
- **D-10:** Valid range in the dialog: **50 ml – 2000 ml**. Values outside this range show an inline error message inside the dialog; the Confirm button is disabled until the value is valid.

### Notification Interval (D-11)
- **D-11:** The reminder interval is set via a **`Slider`** widget (snapped to 5-minute steps). Range: **5 min – 240 min (4 h)**. A label **above** the slider shows the current value in always-minutes format (e.g., `"30 min"`, `"60 min"`, `"240 min"`). Conversion: `"${value.toInt()} min"`. On slider release (`onChangeEnd`), calls `SettingsRepository.updateSettings()`.

### DND Window (D-12 – D-13)
- **D-12:** A **`SwitchListTile`** at the top of the Notifications card controls `dndEnabled`. Toggling live-saves. When `dndEnabled = false`, the Start time and End time rows are greyed (opacity ≈ 0.38) and non-tappable.
- **D-13:** Start time and End time are `ListTile` rows showing the current value (e.g., "23:00"). Tapping opens the Material **`showTimePicker()`** dialog (24-hour format). On confirm, live-saves `dndStartHour`/`dndStartMinute` or `dndEndHour`/`dndEndMinute` via `updateSettings()`.

### Save Behavior (D-14)
- **D-14:** **Live-save on every change** — no Save button on the screen. Every stepper tap, slider release, dialog confirm, switch toggle, and time-picker confirm writes immediately to the DB via `SettingsRepository`. The home screen reacts automatically through the existing stream.

### Display Format (D-15)
- **D-15:** Daily target shows **ml only** on the settings row (e.g., "2000 ml"). The SETT-01 requirement mentions "displayed also as L" — this is intentionally deferred; no L display in Phase 3. Note for planner: the SETT-01 acceptance criterion "displayed also as L" is not satisfied by Phase 3 and should be called out in UAT.

### Claude's Discretion
- Exact card elevation and padding (use M3 defaults — `Card` with `elevation: 1` or `2`, `margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8)`).
- Error state color for the preset dialog text field (use M3 `colorScheme.error`).
- Whether the DND time rows show 12h or 24h format — match the device's system time format via `MediaQuery.alwaysUse24HourFormat`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — SETT-01 through SETT-04 (the 4 requirements this phase must satisfy)
- `.planning/ROADMAP.md` — Phase 3 section: goal, success criteria, mode

### Prior Phase Decisions
- `.planning/phases/01-data-foundation/01-CONTEXT.md` — D-05 (default target 2000 ml), D-06 (preset defaults 200/300/400/500 ml), D-07 (notification interval default 60 min), D-08 (DND default 23:00–07:00, enabled), D-12 (layer-first folder structure)
- `.planning/phases/02-core-tracking-ui/02-CONTEXT.md` — D-01 through D-07 (navigation shell, GoRouter shape, UI design contract reference)

### Code Integration Points
- `lib/data/repositories/settings_repository.dart` — `updateSettings(UserSettingsEntity)` and `updatePreset(id, amountMl)` are the two write methods Phase 3 calls. Already validated inputs with `ArgumentError` guards.
- `lib/domain/entities/user_settings_entity.dart` — Freezed entity: `dailyTargetMl`, `notificationIntervalMinutes`, `dndStartHour`, `dndStartMinute`, `dndEndHour`, `dndEndMinute`, `dndEnabled`. Use `entity.copyWith(...)` for incremental updates.
- `lib/domain/entities/drink_preset_entity.dart` — Freezed entity: `id`, `amountMl`, `sortOrder`. The `id` field is needed to call `updatePreset`.
- `lib/core/providers/stream_providers.dart` — `userSettingsProvider` and `drinkPresetsProvider` (both `keepAlive: true`) are the streams the Settings screen watches. Changes propagate to HomeScreen automatically.
- `lib/core/providers/repository_providers.dart` — `settingsRepositoryProvider` for write operations.
- `lib/presentation/screens/settings_screen.dart` — current stub (`StatelessWidget` with "Coming soon"). Replace with a `ConsumerWidget` or `ConsumerStatefulWidget`.

### Stack Reference
- `CLAUDE.md` — Tech Stack table (flutter_riverpod 3.x, Drift 2.33, Freezed 3.x versions). No new packages required for Phase 3.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `userSettingsProvider` (stream, keepAlive) — watch current settings; use `.value` (nullable) for async state.
- `drinkPresetsProvider` (stream, keepAlive) — watch all 4 presets sorted by `sortOrder`.
- `settingsRepositoryProvider` — for write operations (`updateSettings`, `updatePreset`).
- `UserSettingsEntity.copyWith(...)` — use to create updated entity for stepper/slider changes before calling `updateSettings`.

### Established Patterns
- Riverpod code-gen: `ConsumerWidget` / `ConsumerStatefulWidget` + `ref.watch(...)`. No hooks.
- Layer-first folders: new widgets go in `lib/presentation/screens/settings_screen.dart` (and extracted sub-widgets in `lib/presentation/widgets/` if needed).
- Live-stream reactivity: the HomeScreen already reacts to `userSettingsProvider` changes — no manual notification needed after `updateSettings`.

### Integration Points
- The `SettingsScreen` is already registered in the GoRouter as a shell branch (`/settings` route). No router changes needed.
- The `NavigationBar` shell in `HomeScreen`/`app_router.dart` provides the scaffold; `SettingsScreen` provides only its own body (no duplicate AppBar/NavigationBar).

</code_context>

<specifics>
## Specific Ideas

- Both sliders (daily target and notification interval) use the same pattern: label above, `Slider` below, `onChangeEnd` to save.
- Daily target slider: `divisions = (10000 - 1000) / 250 = 36`. Label format: `"${value.toInt()} ml"`.
- Notification interval slider: `divisions = (240 - 5) / 5 = 47`. Label format: `"${value.toInt()} min"`. Store as integer minutes in DB.
- Preset dialog: disable the Confirm button while the text field value is outside 50–2000 ml range and show an error message under the field.
- DND time rows use `showTimePicker(context: context, initialTime: TimeOfDay(hour: ..., minute: ...))`. Match 24h/12h to device system setting via `MediaQuery.alwaysUse24HourFormat`.
- When DND is disabled (`dndEnabled = false`), wrap Start/End rows in an `IgnorePointer` with `Opacity(opacity: 0.38, ...)` — standard Material disabled state.
- SETT-01 "displayed also as L": intentionally deferred (D-15). UAT for this phase should mark this criterion as skipped/deferred.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 3-settings*
*Context gathered: 2026-06-05*
