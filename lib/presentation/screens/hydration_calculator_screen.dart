import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/entities/hydration_enums.dart';
import '../../l10n/l10n_extensions.dart';

class HydrationCalculatorScreen extends ConsumerStatefulWidget {
  const HydrationCalculatorScreen({super.key, required this.isOnboarding});

  final bool isOnboarding;

  @override
  ConsumerState<HydrationCalculatorScreen> createState() =>
      _HydrationCalculatorScreenState();
}

class _HydrationCalculatorScreenState
    extends ConsumerState<HydrationCalculatorScreen> {
  BiologicalSex? _selectedSex;
  late final TextEditingController _weightController;
  double _climateValue = 1;
  bool _isLoading = false;

  static const _sexFactors = {
    BiologicalSex.male: 35.0,
    BiologicalSex.female: 31.0,
    BiologicalSex.other: 33.0,
  };

  static const _climateMultipliers = {
    ClimateLevel.cold: 1.0,
    ClimateLevel.mild: 1.05,
    ClimateLevel.warm: 1.1,
    ClimateLevel.veryWarm: 1.2,
    ClimateLevel.humid: 1.3,
  };

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  /// Computes the recommended daily water intake in ml.
  /// Returns null if any required field is incomplete or invalid.
  int? _computeRecommendation() {
    if (_selectedSex == null) return null;

    final weight = int.tryParse(_weightController.text);
    if (weight == null || weight <= 0 || weight > 300) return null;

    final sexFactor = _sexFactors[_selectedSex!]!;
    final climateLevel = ClimateLevel.values[_climateValue.round()];
    final climateMultiplier = _climateMultipliers[climateLevel]!;
    final raw = weight * sexFactor * climateMultiplier;
    final rounded = (raw / 50).round() * 50;
    return rounded.clamp(1000, 4000);
  }

  List<String> _climateDisplayLabels(BuildContext context) => [
    context.l10n.climateCold,
    context.l10n.climateMild,
    context.l10n.climateWarm,
    context.l10n.climateVeryWarm,
    context.l10n.climateHumid,
  ];

  String _formatMl(BuildContext context, int ml) {
    final locale = Localizations.localeOf(context).toString();
    return '${NumberFormat.decimalPattern(locale).format(ml)} ${context.l10n.mlUnit}';
  }

  Future<void> _onUseAsTarget(int recommendedMl) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateTargetWithHistory(recommendedMl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.targetUpdateError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    if (widget.isOnboarding) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('drinky_calculatorShown', true);
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.targetUpdated(_formatMl(context, recommendedMl))),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

    if (widget.isOnboarding) {
      context.go('/');
    } else {
      context.pop();
    }
  }

  Future<void> _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drinky_calculatorShown', true);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recommendation = _computeRecommendation();
    final climateLabels = _climateDisplayLabels(context);

    final weightText = _weightController.text;
    final weightValue = int.tryParse(weightText);
    final weightError =
        weightText.isNotEmpty && (weightValue == null || weightValue <= 0 || weightValue > 300)
            ? context.l10n.weightValidationError
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.calculatorTitle),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Sex section
                Text(
                  context.l10n.sexLabel,
                  style: theme.textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SegmentedButton<BiologicalSex>(
                  emptySelectionAllowed: true,
                  multiSelectionEnabled: false,
                  segments: [
                    ButtonSegment(value: BiologicalSex.male, label: Text(context.l10n.sexMale)),
                    ButtonSegment(value: BiologicalSex.female, label: Text(context.l10n.sexFemale)),
                    ButtonSegment(value: BiologicalSex.other, label: Text(context.l10n.sexOther)),
                  ],
                  selected: _selectedSex != null ? {_selectedSex!} : {},
                  onSelectionChanged: (sel) =>
                      setState(() => _selectedSex = sel.firstOrNull),
                ),
                const SizedBox(height: 24),

                // Weight section
                Text(
                  context.l10n.weightLabel,
                  style: theme.textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.weightInputLabel,
                    suffixText: context.l10n.weightUnit,
                    errorText: weightError,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // Climate section
                Text(
                  context.l10n.climateLabel,
                  style: theme.textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _climateValue,
                  min: 0,
                  max: 4,
                  divisions: 4,
                  onChanged: (val) => setState(() => _climateValue = val),
                  semanticFormatterCallback: (v) =>
                      climateLabels[v.round()],
                ),
                Center(
                  child: Text(
                    climateLabels[_climateValue.round()],
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 48),

                // Recommendation display
                Center(
                  child: Column(
                    children: [
                      Text(
                        context.l10n.yourRecommendation,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      if (recommendation != null)
                        Text(
                          _formatMl(context, recommendation),
                          style: theme.textTheme.headlineLarge!.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          context.l10n.fillAllFields,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Privacy disclaimer
                Center(
                  child: Text(
                    context.l10n.privacyDisclaimer,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Primary action button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: recommendation != null && !_isLoading
                        ? () => _onUseAsTarget(recommendation)
                        : null,
                    child: Text(context.l10n.useAsTarget),
                  ),
                ),

                // Onboarding-only: skip button
                if (widget.isOnboarding) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _onSkip,
                    child: Text(context.l10n.skipButton),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
