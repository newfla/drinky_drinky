import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';

class HydrationCalculatorScreen extends ConsumerStatefulWidget {
  const HydrationCalculatorScreen({super.key, required this.isOnboarding});

  final bool isOnboarding;

  @override
  ConsumerState<HydrationCalculatorScreen> createState() =>
      _HydrationCalculatorScreenState();
}

class _HydrationCalculatorScreenState
    extends ConsumerState<HydrationCalculatorScreen> {
  String? _selectedSex;
  late final TextEditingController _weightController;
  double _climateValue = 1;
  bool _isLoading = false;

  static const _sexFactors = {
    'Maschio': 35.0,
    'Femmina': 31.0,
    'Altro': 33.0,
  };

  static const _climateMultipliers = [1.0, 1.05, 1.1, 1.2, 1.3];
  static const _climateLabels = ['Freddo', 'Mite', 'Caldo', 'Molto caldo', 'Afoso'];

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
    final climateMultiplier = _climateMultipliers[_climateValue.round()];
    final raw = weight * sexFactor * climateMultiplier;
    final rounded = (raw / 50).round() * 50;
    return rounded.clamp(1000, 4000);
  }

  String _formatMl(BuildContext context, int ml) {
    final locale = Localizations.localeOf(context).toString();
    return '${NumberFormat.decimalPattern(locale).format(ml)} ml';
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
          const SnackBar(
            content: Text(
                'Errore durante l\'aggiornamento del target. Riprova.'),
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
          content: Text('Target aggiornato a ${_formatMl(context, recommendedMl)}'),
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

    final weightText = _weightController.text;
    final weightValue = int.tryParse(weightText);
    final weightError =
        weightText.isNotEmpty && (weightValue == null || weightValue <= 0 || weightValue > 300)
            ? 'Inserisci un peso tra 1 e 300 kg'
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcolatore idratazione'),
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
                  'Sesso',
                  style: theme.textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  multiSelectionEnabled: false,
                  segments: const [
                    ButtonSegment(value: 'Maschio', label: Text('Maschio')),
                    ButtonSegment(value: 'Femmina', label: Text('Femmina')),
                    ButtonSegment(value: 'Altro', label: Text('Altro')),
                  ],
                  selected: _selectedSex != null ? {_selectedSex!} : {},
                  onSelectionChanged: (sel) =>
                      setState(() => _selectedSex = sel.firstOrNull),
                ),
                const SizedBox(height: 24),

                // Weight section
                Text(
                  'Peso',
                  style: theme.textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    suffixText: 'kg',
                    errorText: weightError,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // Climate section
                Text(
                  'Clima',
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
                      _climateLabels[v.round()],
                ),
                Center(
                  child: Text(
                    _climateLabels[_climateValue.round()],
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 48),

                // Recommendation display
                Center(
                  child: Column(
                    children: [
                      Text(
                        'La tua raccomandazione',
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
                          'Compila tutti i campi',
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
                    "I tuoi dati (sesso, peso, clima) non vengono salvati ne' trasmessi. "
                    'Il calcolo avviene interamente sul tuo dispositivo.',
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
                    child: const Text('Usa come target'),
                  ),
                ),

                // Onboarding-only: skip button
                if (widget.isOnboarding) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _onSkip,
                    child: const Text('Salta'),
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
