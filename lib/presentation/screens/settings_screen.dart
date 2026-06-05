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

  Widget _notificationsCard(
    BuildContext context,
    UserSettingsEntity settings,
  ) {
    final currentInterval =
        _intervalDrag ?? settings.notificationIntervalMinutes.toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interval slider (D-11)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentInterval.toInt()} min',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: currentInterval,
                  min: 5,
                  max: 240,
                  divisions: 47,
                  onChanged: (val) {
                    setState(() => _intervalDrag = val);
                  },
                  onChangeEnd: (val) {
                    setState(() => _intervalDrag = null);
                    ref.read(settingsRepositoryProvider).updateSettings(
                          settings.copyWith(
                            notificationIntervalMinutes: val.toInt(),
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
          // DND toggle (D-12)
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
          // DND time rows (D-12/D-13) -- greyed out when disabled
          IgnorePointer(
            ignoring: !settings.dndEnabled,
            child: Opacity(
              opacity: settings.dndEnabled ? 1.0 : 0.38,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Start time'),
                    trailing: Text(
                      _formatTime(
                        context,
                        settings.dndStartHour,
                        settings.dndStartMinute,
                      ),
                    ),
                    onTap: () =>
                        _pickDndTime(isStart: true, settings: settings),
                  ),
                  ListTile(
                    title: const Text('End time'),
                    trailing: Text(
                      _formatTime(
                        context,
                        settings.dndEndHour,
                        settings.dndEndMinute,
                      ),
                    ),
                    onTap: () =>
                        _pickDndTime(isStart: false, settings: settings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDndTime({
    required bool isStart,
    required UserSettingsEntity settings,
  }) async {
    final initial = isStart
        ? TimeOfDay(
            hour: settings.dndStartHour, minute: settings.dndStartMinute)
        : TimeOfDay(
            hour: settings.dndEndHour, minute: settings.dndEndMinute);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null && mounted) {
      final updated = isStart
          ? settings.copyWith(
              dndStartHour: picked.hour, dndStartMinute: picked.minute)
          : settings.copyWith(
              dndEndHour: picked.hour, dndEndMinute: picked.minute);
      ref.read(settingsRepositoryProvider).updateSettings(updated);
    }
  }

  String _formatTime(BuildContext context, int hour, int minute) {
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    if (use24h) {
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    } else {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }
  }
}
