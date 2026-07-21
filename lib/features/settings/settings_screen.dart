import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_service.dart';
import '../../data/forecast_providers.dart';
import '../../data/providers.dart';
import '../../health/health_providers.dart';
import '../../security/app_lock.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider).value;
    final lockEnabled = ref.watch(appLockEnabledProvider).value ?? true;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(auth?.signedIn == true
                  ? (auth!.displayName?.isNotEmpty == true
                      ? auth.displayName!
                      : auth.method.name)
                  : 'Not signed in'),
              subtitle: Text(auth?.method == AuthMethod.local
                  ? 'Local profile — connect an account for encrypted backup'
                  : 'Signed in with ${auth?.method.name ?? 'nothing yet'}'),
              trailing: auth?.signedIn == true
                  ? TextButton(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/sign-in');
                      },
                      child: const Text('Sign out'),
                    )
                  : TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Sign in'),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric app lock'),
              subtitle: Text(kIsWeb
                  ? 'Available on iOS and Android'
                  : 'Face ID / Touch ID / fingerprint gate on open'),
              value: lockEnabled && !kIsWeb,
              onChanged: kIsWeb
                  ? null
                  : (v) async {
                      await ref
                          .read(appDatabaseProvider)
                          .setSetting(appLockSettingKey, v ? 'true' : 'false');
                      ref.invalidate(appLockEnabledProvider);
                    },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.science_outlined),
              title: const Text('Demo biometrics'),
              subtitle:
                  const Text('Generated wearable data for previews/dev'),
              value: ref.watch(demoHealthEnabledProvider).value ?? false,
              onChanged: (v) async {
                await ref
                    .read(appDatabaseProvider)
                    .setSetting(demoHealthSettingKey, v ? 'true' : 'false');
                ref.invalidate(demoHealthEnabledProvider);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.nightlight_round),
              title: const Text('Preview evening forecast'),
              subtitle: const Text('Show tonight\'s forecast card any time'),
              value: ref.watch(forceForecastProvider),
              onChanged: (v) =>
                  ref.read(forceForecastProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Privacy'),
              subtitle: const Text('Audit trail of every health-data access'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/privacy'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    'PulsIQ 0.1.0 — biometric intelligence in real time.\n\n'
                    'PulsIQ is a wellness companion, not a medical device. '
                    'Nothing in this app is medical advice.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audit = ref.watch(auditTrailProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Privacy — audit trail'),
        backgroundColor: Colors.transparent,
      ),
      body: switch (audit) {
        AsyncData(value: final events) when events.isEmpty => Center(
            child: Text(
              'No data access recorded yet.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        AsyncData(value: final events) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: events.length,
            itemBuilder: (_, i) {
              final e = events[i];
              return ListTile(
                dense: true,
                leading: Icon(
                  switch (e.action) {
                    'delete' => Icons.delete_outline,
                    'read' => Icons.visibility_outlined,
                    _ => Icons.edit_outlined,
                  },
                  size: 18,
                ),
                title: Text('${e.action} · ${e.dataType}'),
                subtitle: Text('${e.source} — ${e.purpose}'),
                trailing: Text(
                  '${e.at.month}/${e.at.day} '
                  '${e.at.hour}:${e.at.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
