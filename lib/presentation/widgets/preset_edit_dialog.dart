import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/entities/drink_preset_entity.dart';

/// Shows an [AlertDialog] for editing a single preset amount with validation.
///
/// The dialog pre-fills the current [preset] amount and validates that the
/// entered value is between 50 and 2000 ml. The Confirm button is disabled
/// when the value is invalid. On confirm, the preset is immediately saved
/// via [SettingsRepository.updatePreset].
Future<void> showPresetEditDialog(
  BuildContext context,
  WidgetRef ref,
  DrinkPresetEntity preset,
) async {
  final controller = TextEditingController(text: preset.amountMl.toString());
  // Pre-select all text so the user can immediately type a replacement value.
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final text = controller.text;
          final parsed = int.tryParse(text);
          final isValid = parsed != null && parsed >= 50 && parsed <= 2000;
          final showError = text.isNotEmpty && !isValid;
          // Capture validated value to avoid null assertion below.
          final validatedAmount = isValid ? parsed : null;

          return AlertDialog(
            title: Text('Edit Preset ${preset.sortOrder + 1}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount (ml)',
                suffixText: 'ml',
                errorText:
                    showError ? 'Enter a value between 50 and 2000' : null,
              ),
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: validatedAmount != null
                    ? () {
                        ref
                            .read(settingsRepositoryProvider)
                            .updatePreset(preset.id, validatedAmount);
                        Navigator.of(dialogContext).pop();
                      }
                    : null,
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
