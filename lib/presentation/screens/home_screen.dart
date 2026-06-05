import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/water_entry_entity.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late String _dateKey;
  late AppLifecycleListener _lifecycleListener;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _dateKey = todayDateKey();

    _lifecycleListener = AppLifecycleListener(
      onResume: _checkDateChange,
    );

    _midnightTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkDateChange(),
    );
  }

  void _checkDateChange() {
    final newKey = todayDateKey();
    if (newKey != _dateKey && mounted) {
      setState(() => _dateKey = newKey);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final totalAsync = ref.watch(totalMlForDateProvider(_dateKey));
    final entriesAsync = ref.watch(waterEntriesForDateProvider(_dateKey));
    final presetsAsync = ref.watch(drinkPresetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Drinky Drinky')),
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
  }

  Widget _buildContent(
    BuildContext context,
    UserSettingsEntity settings,
    int totalMl,
    List<WaterEntryEntity> entries,
    List<DrinkPresetEntity> presets,
  ) {
    final target = settings.dailyTargetMl;
    final percentage =
        target > 0 ? (totalMl / target).clamp(0.0, 1.0) : 0.0;
    final isGoalMet = totalMl >= target;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: 48), // 2xl top padding
        // Progress Ring (HOME-01, D-03, D-04)
        CircularPercentIndicator(
          radius: 100.0,
          lineWidth: 12.0,
          percent: percentage,
          animation: true,
          animationDuration: 600,
          animateFromLastPercent: true,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: isGoalMet
              ? Colors.green.shade600
              : colorScheme.primary,
          backgroundColor:
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          center: Text(
            isGoalMet && totalMl == target ? 'Goal reached!' : '$totalMl / $target ml',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isGoalMet ? Colors.green.shade600 : null,
            ),
          ),
        ),
        const SizedBox(height: 24), // lg spacing
        // Quick-Add Row (HOME-02)
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
        const SizedBox(height: 32), // xl spacing
        // Timeline Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Today's Intake",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8), // sm spacing
        // Timeline List (HOME-04)
        Expanded(
          child: entries.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final time =
                        '${entry.loggedAt.hour.toString().padLeft(2, '0')}:'
                        '${entry.loggedAt.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      tileColor: colorScheme.surfaceContainerLow,
                      leading: Text(
                        time,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '+${entry.amountMl} ml',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

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
            'Tap a button above to log your first drink today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // HOME-02, HOME-03, D-03, D-05
  void _onQuickAdd(int amountMl) async {
    // Capture date key before async gap (Pitfall 3 / T-02-03)
    final capturedKey = _dateKey;
    final repo = ref.read(waterRepositoryProvider);
    await repo.insertEntry(amountMl, DateTime.now(), capturedKey);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Clear previous SnackBars to prevent queue buildup (D-05, T-02-04)
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('+$amountMl ml added'),
        duration: const Duration(seconds: 5),
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
}
