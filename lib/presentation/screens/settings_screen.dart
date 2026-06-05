import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../widgets/preset_edit_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Local slider state during drag to avoid DB writes on every frame.
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
        error: (e, _) => const Center(
          child: Text('Something went wrong loading your data.'),
        ),
        data: (settings) {
          final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
          return _buildBody(context, settings, presets);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserSettingsEntity settings,
    List<DrinkPresetEntity> presets,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'DAILY GOAL'),
          _dailyGoalCard(context, settings),
          _sectionLabel(context, 'QUICK-ADD PRESETS'),
          _presetsCard(context, presets),
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

  Widget _dailyGoalCard(BuildContext context, UserSettingsEntity settings) {
    final currentTarget =
        _dailyTargetDrag ?? settings.dailyTargetMl.toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${currentTarget.toInt()} ml',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: currentTarget,
              min: 1000,
              max: 10000,
              divisions: 36,
              onChanged: (val) {
                setState(() => _dailyTargetDrag = val);
              },
              onChangeEnd: (val) {
                setState(() => _dailyTargetDrag = null);
                ref.read(settingsRepositoryProvider).updateSettings(
                      settings.copyWith(dailyTargetMl: val.toInt()),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetsCard(BuildContext context, List<DrinkPresetEntity> presets) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: presets.map((preset) {
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
}
