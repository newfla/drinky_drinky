import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/entities/drink_preset_entity.dart';

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

class _PresetEditDialog extends StatefulWidget {
  const _PresetEditDialog({required this.ref, required this.preset});
  final WidgetRef ref;
  final DrinkPresetEntity preset;

  @override
  State<_PresetEditDialog> createState() => _PresetEditDialogState();
}

class _PresetEditDialogState extends State<_PresetEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.preset.amountMl.toString());
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
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
    final isValid = parsed != null && parsed >= 50 && parsed <= 2000;
    final showError = text.isNotEmpty && !isValid;

    return AlertDialog(
      title: Text('Edit Preset ${widget.preset.sortOrder + 1}'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Amount (ml)',
          suffixText: 'ml',
          errorText: showError ? 'Enter a value between 50 and 2000' : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isValid
              ? () {
                  widget.ref
                      .read(settingsRepositoryProvider)
                      .updatePreset(widget.preset.id, parsed);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
