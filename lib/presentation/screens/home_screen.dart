import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/water_entry_entity.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _rescheduleNotifications();
      },
    );
  }

  void _rescheduleNotifications() async {
    final settings = ref.read(userSettingsProvider).value;
    if (settings == null) return;
    await NotificationService.instance.scheduleWindow(settings);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayKey = ref.watch(todayDateKeyProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final totalAsync = ref.watch(totalMlForDateProvider(todayKey));
    final entriesAsync = ref.watch(waterEntriesForDateProvider(todayKey));
    final presetsAsync = ref.watch(drinkPresetsProvider);

    // NOTF-03 / D-07: Goal-reached auto-stop — cancel all pending notifications
    // when today's total first crosses the daily target (while app is open).
    // Guard: target > 0 prevents cancelling when no target is set.
    // Crossing check: only fires on the transition from below → at/above target
    // to avoid calling cancelAll() on every subsequent log entry.
    ref.listen<AsyncValue<int>>(
      totalMlForDateProvider(todayKey),
      (previous, next) {
        final prev = previous?.value ?? 0;
        final curr = next.value ?? 0;
        final target =
            ref.read(effectiveTargetForDateProvider(todayKey)).value ?? 0;
        if (target > 0 && prev < target && curr >= target) {
          NotificationService.instance.cancelAll();
        }
      },
    );

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
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('Something went wrong loading your data. Please restart the app.'),
        ),
        data: (settings) {
          final totalMl = totalAsync.value ?? 0;
          final entries = (entriesAsync.value ?? <WaterEntryEntity>[]).reversed.toList();
          final target = ref.watch(effectiveTargetForDateProvider(todayKey)).value ?? 2000;

          return _buildContent(context, settings, totalMl, entries, target);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserSettingsEntity settings,
    int totalMl,
    List<WaterEntryEntity> entries,
    int target,
  ) {
    final percentage =
        target > 0 ? (totalMl / target).clamp(0.0, 1.0) : 0.0;
    final isGoalMet = totalMl >= target;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goalMetColor = theme.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade600;

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
              ? goalMetColor
              : colorScheme.primary,
          backgroundColor:
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          center: Text(
            totalMl == target ? 'Goal reached!' : '${_formatLiters(context, totalMl)} / ${_formatLiters(context, target)} L',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isGoalMet ? goalMetColor : null,
            ),
          ),
        ),
        const SizedBox(height: 32), // xl spacing (ring to timeline)
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
            'Tap the + button to log your first drink today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLiters(BuildContext context, int ml) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    return formatter.format(ml / 1000);
  }

  // HOME-02, HOME-03, D-03, D-05
  void _onQuickAdd(int amountMl) async {
    // Capture date key before async gap (Pitfall 3 / T-02-03)
    final capturedKey = ref.read(todayDateKeyProvider);
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
}

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
    final parsed = int.tryParse(_controller.text);
    final isValid = parsed != null && parsed >= 1 && parsed <= 9999;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
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
