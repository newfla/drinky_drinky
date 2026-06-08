# Phase 7: Intake Redesign - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 3 modified files
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/presentation/screens/home_screen.dart` | component | request-response | itself (current state) | exact |
| `lib/presentation/screens/settings_screen.dart` | component | request-response | itself (current state) | exact |
| `lib/data/database/app_database.dart` | config | CRUD | itself (current state) | exact |

## Pattern Assignments

### `lib/presentation/screens/home_screen.dart` (component, request-response)

**Analog:** `lib/presentation/widgets/preset_edit_dialog.dart` (for StatefulWidget with TextEditingController pattern)

**StatefulWidget with controller lifecycle** (preset_edit_dialog.dart lines 27-44):
```dart
class _PresetEditDialogState extends State<_PresetEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.preset.amountMl.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
```

**Validation + disabled button pattern** (preset_edit_dialog.dart lines 48-51, 71-79):
```dart
final text = _controller.text;
final parsed = int.tryParse(text);
final isValid = parsed != null && parsed >= 50 && parsed <= 2000;

// ...
FilledButton(
  onPressed: isValid
      ? () {
          // action
          Navigator.of(context).pop();
        }
      : null,
  child: const Text('Confirm'),
),
```

**Quick-add Row pattern to replicate inside sheet** (home_screen.dart lines 151-166):
```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    children: presets.map((preset) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilledButton(
            onPressed: () => _onQuickAdd(preset.amountMl),
            child: Text('+${preset.amountMl} ml'),
          ),
        ),
      );
    }).toList(),
  ),
),
```

**Undo SnackBar + mounted guard pattern** (home_screen.dart lines 248-274):
```dart
void _onQuickAdd(int amountMl) async {
  final capturedKey = _dateKey;
  final repo = ref.read(waterRepositoryProvider);
  await repo.insertEntry(amountMl, DateTime.now(), capturedKey);

  if (!mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('+$amountMl ml added'),
      duration: const Duration(seconds: 5),
      persist: false,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await repo.deleteLastEntry(capturedKey);
        },
      ),
    ),
  );
}
```

**Scaffold structure to add FAB to** (home_screen.dart lines 90-106):
```dart
return Scaffold(
  appBar: AppBar(title: const Text('Drinky Drinky')),
  // ADD: floatingActionButton property here
  body: settingsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => const Center(
      child: Text('Something went wrong loading your data.'),
    ),
    data: (settings) {
      final totalMl = totalAsync.value ?? 0;
      final entries = (entriesAsync.value ?? <WaterEntryEntity>[]).reversed.toList();
      final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
      return _buildContent(context, settings, totalMl, entries, presets);
    },
  ),
);
```

---

### `lib/presentation/screens/settings_screen.dart` (component, request-response)

**Analog:** itself

**Presets card -- add .take(3)** (settings_screen.dart lines 125-139):
```dart
Widget _presetsCard(BuildContext context, List<DrinkPresetEntity> presets) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      children: presets.map((preset) {  // <-- change to presets.take(3).map(...)
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

---

### `lib/data/database/app_database.dart` (config, CRUD)

**Analog:** itself

**Seed block to modify** (app_database.dart lines 44-52):
```dart
// Seed default drink presets (200/300/400/500ml).
await batch((batch) {
  batch.insertAll(drinkPresets, [
    DrinkPresetsCompanion.insert(amountMl: 200, sortOrder: 0),
    DrinkPresetsCompanion.insert(amountMl: 300, sortOrder: 1),
    DrinkPresetsCompanion.insert(amountMl: 400, sortOrder: 2),
    DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 3),
  ]);
});
// CHANGE TO: 3 presets (150/250/500), remove sortOrder 3
```

---

## Shared Patterns

### Callback-to-Parent (sheet does not own DB logic)
**Source:** `lib/presentation/widgets/preset_edit_dialog.dart` lines 7-16
**Apply to:** New `_IntakeBottomSheet` widget in home_screen.dart
```dart
// The dialog receives ref + data from parent, calls back via Navigator.pop
// The sheet should receive presets list + onAdd callback, NOT ref
Future<void> showPresetEditDialog(
  BuildContext context,
  WidgetRef ref,
  DrinkPresetEntity preset,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _PresetEditDialog(ref: ref, preset: preset),
  );
}
```

### TextEditingController Lifecycle
**Source:** `lib/presentation/widgets/preset_edit_dialog.dart` lines 28-44
**Apply to:** `_IntakeBottomSheet` StatefulWidget
- Create in `initState`, dispose in `dispose`
- Use `onChanged: (_) => setState(() {})` to trigger rebuild for validation

### Input Validation with Disabled Button
**Source:** `lib/presentation/widgets/preset_edit_dialog.dart` lines 48-51
**Apply to:** Custom ml input in `_IntakeBottomSheet`
- `int.tryParse` + range check (1-9999 for sheet, vs 50-2000 for preset edit)
- `FilledButton.onPressed: null` when invalid

## No Analog Found

No files without analogs. All 3 modified files are self-analogous (modifications to existing code), and the new `_IntakeBottomSheet` widget follows the established `_PresetEditDialog` pattern exactly.

## Metadata

**Analog search scope:** `lib/presentation/`, `lib/data/database/`
**Files scanned:** 4 (home_screen.dart, settings_screen.dart, preset_edit_dialog.dart, app_database.dart)
**Pattern extraction date:** 2026-06-08
