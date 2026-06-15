import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers/repository_providers.dart';
import '../../l10n/l10n_extensions.dart';
import '../../core/providers/stream_providers.dart';
import '../../core/services/notification_service.dart';
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

  /// Whether notification permission is currently denied (D-03).
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.permissionGranted();
    if (mounted) setState(() => _permissionDenied = !granted);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final presetsAsync = ref.watch(drinkPresetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.l10n.errorLoadingData),
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
          _sectionLabel(context, context.l10n.sectionDailyGoal),
          _dailyGoalCard(context, settings),
          _sectionLabel(context, context.l10n.sectionQuickAddPresets),
          _presetsCard(context, presets),
          _sectionLabel(context, context.l10n.sectionNotifications),
          _notificationsCard(context, settings),
          _sectionLabel(context, context.l10n.sectionHydration),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: Text(context.l10n.recalculateHydration),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/calculator', extra: false),
            ),
          ),
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
              context.l10n.amountMl(currentTarget.toInt()),
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
                ref.read(settingsRepositoryProvider).updateTargetWithHistory(val.toInt());
              },
            ),
            const Divider(),
            SwitchListTile(
              title: Text(context.l10n.applyFromTomorrow),
              subtitle: Text(
                settings.applyFromTomorrow
                    ? context.l10n.applyFromTomorrowSubtitle
                    : context.l10n.applyFromTodaySubtitle,
              ),
              value: settings.applyFromTomorrow,
              onChanged: (val) {
                ref.read(settingsRepositoryProvider).updateSettings(
                      settings.copyWith(applyFromTomorrow: val),
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
        children: presets.take(3).map((preset) {
          return ListTile(
            title: Text(context.l10n.presetTitle(preset.sortOrder + 1)),
            subtitle: Text(context.l10n.amountMl(preset.amountMl)),
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
          // Permission-denied banner (D-03)
          if (_permissionDenied)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.notificationsDisabledBanner,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: Text(
                      context.l10n.openButton,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Interval slider (D-11)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.intervalMinutes(currentInterval.toInt()),
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
                    // D-05: Reschedule on interval change.
                    NotificationService.instance.scheduleWindow(
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
            title: Text(context.l10n.doNotDisturb),
            subtitle: Text(settings.dndEnabled ? context.l10n.toggleOn : context.l10n.toggleOff),
            value: settings.dndEnabled,
            onChanged: (val) {
              ref.read(settingsRepositoryProvider).updateSettings(
                    settings.copyWith(dndEnabled: val),
                  );
              // D-05: Reschedule on DND toggle.
              NotificationService.instance.scheduleWindow(
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
                    title: Text(context.l10n.startTime),
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
                    title: Text(context.l10n.endTime),
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
      // D-05: Reschedule on DND time change.
      NotificationService.instance.scheduleWindow(updated);
    }
  }

  String _formatTime(BuildContext context, int hour, int minute) {
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    if (use24h) {
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    } else {
      final localizations = MaterialLocalizations.of(context);
      final period = hour >= 12 ? localizations.postMeridiemAbbreviation : localizations.anteMeridiemAbbreviation;
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }
  }
}
