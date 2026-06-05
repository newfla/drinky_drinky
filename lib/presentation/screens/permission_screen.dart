import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/stream_providers.dart';
import '../../core/services/notification_service.dart';

/// First-launch permission explanation screen (D-01, D-02, NOTF-02).
///
/// Shown once before any system permission prompt. The user can either grant
/// notification permission ("Enable Reminders") or defer it ("Skip for now").
/// After either action, the screen marks itself as shown via SharedPreferences
/// so the GoRouter redirect never fires again.
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Stay hydrated with reminders',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Drinky Drinky sends you gentle reminders to drink water throughout the day.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _onEnableReminders,
                  child: const Text('Enable Reminders'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _onSkip,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onEnableReminders() async {
    setState(() => _isLoading = true);

    final granted = await NotificationService.instance.requestPermission();

    if (!mounted) return;

    // Mark permission screen as shown (T-05-03: use namespaced key).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drinky_permissionScreenShown', true);

    if (!mounted) return;

    // D-02: Show confirmation message before navigating.
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Reminders enabled! You can adjust them anytime in Settings.'
              : 'No problem — you can enable reminders later in your device Settings.',
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // D-05: Schedule first window immediately after permission is granted.
    if (granted) {
      final settings = ref.read(userSettingsProvider).value;
      if (settings != null) {
        await NotificationService.instance.scheduleWindow(settings);
      }
    }

    if (!mounted) return;
    context.go('/');
  }

  Future<void> _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drinky_permissionScreenShown', true);

    if (!mounted) return;
    context.go('/');
  }
}
