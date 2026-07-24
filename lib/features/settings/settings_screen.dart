import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/auth_service.dart';
import '../../billing/subscription_service.dart';
import '../../data/data_manager.dart';
import '../../data/app_version.dart';
import '../../data/providers.dart';
import '../../domain/reminder_rules.dart';
import '../../health/health_providers.dart';
import '../../health/whoop/whoop_providers.dart';
import '../../security/app_lock.dart';
import '../../services/notification_service.dart';

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
            child: ListTile(
              leading: const Icon(Icons.accessibility_new_outlined),
              title: const Text('Body profile'),
              subtitle: Text(
                switch (ref.watch(bodyProfileProvider).value) {
                  final p? =>
                    'Fuel targets personalized — ${p.targetCalories} kcal/day',
                  _ => 'Add height and weight for personalized fuel targets',
                },
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/body'),
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
            child: ListTile(
              leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              title: const Text('PulsIQ Plus'),
              subtitle: Text(ref.watch(isPlusProvider)
                  ? 'Active — cloud AI and photo snap-a-meal on'
                  : 'Sharper meal AI and photo snap-a-meal'),
              trailing: ref.watch(isPlusProvider)
                  ? Text('Active',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700))
                  : const Icon(Icons.chevron_right),
              onTap: () => context.push('/plus'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Integrations'),
              subtitle: Text(_integrationsSummary(ref)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/integrations'),
            ),
          ),
          const SizedBox(height: 12),
          const _RemindersCard(),
          // The "Demo biometrics" and "Preview evening forecast" toggles were
          // development affordances. They're off the shipping build: fake
          // health data in a health app is exactly what App Review looks for,
          // and neither means anything to a real user.
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export my data'),
                  subtitle: const Text('Everything PulsIQ holds, as JSON'),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined,
                      color: theme.colorScheme.error),
                  title: Text('Delete everything',
                      style: TextStyle(color: theme.colorScheme.error)),
                  subtitle:
                      const Text('Wipe all data and keys from this device'),
                  onTap: () => _deleteEverything(context, ref),
                ),
              ],
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
                    // Read from the bundle rather than hardcoded: this said
                    // 0.1.0 while the app shipped as 1.0.0.
                    '${ref.watch(appVersionProvider).value ?? 'PulsIQ'} — '
                    'biometric intelligence in real time.\n\n'
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

/// Names whatever is currently linked, so the row is useful without tapping in.
String _integrationsSummary(WidgetRef ref) {
  final connected = <String>[
    if (ref.watch(whoopConnectedProvider).value ?? false) 'WHOOP',
    if (ref.watch(platformHealthConnectedProvider).value ?? false)
      kIsWeb
          ? 'Health'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'Apple Health'
              : 'Health Connect',
  ];
  if (connected.isEmpty) {
    return 'Connect Apple Health, Health Connect, or WHOOP';
  }
  return '${connected.join(' · ')} connected';
}

/// The two standing daily reminders. Both default ON; toggling either one
/// rebuilds the whole schedule so we can never stack duplicates.
class _RemindersCard extends ConsumerStatefulWidget {
  const _RemindersCard();

  @override
  ConsumerState<_RemindersCard> createState() => _RemindersCardState();
}

class _RemindersCardState extends ConsumerState<_RemindersCard> {
  bool? _water;
  bool? _activity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = ref.read(reminderSchedulerProvider);
    final water = await s.waterRemindersEnabled();
    final activity = await s.activityReminderEnabled();
    if (!mounted) return;
    setState(() {
      _water = water;
      _activity = activity;
    });
  }

  Future<void> _set(String key, bool value) async {
    await ref
        .read(appDatabaseProvider)
        .setSetting(key, value ? 'true' : 'false');
    await ref.read(reminderSchedulerProvider).syncDailyReminders();
  }

  @override
  Widget build(BuildContext context) {
    final waterHours = ReminderRules.hourlyWaterHours();
    final activityHour = ReminderRules.activityHour;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.water_drop_outlined),
            title: const Text('Hourly water reminders'),
            subtitle: Text(
              'Every hour from ${_clock(waterHours.first)} to '
              '${_clock(waterHours.last)}, your local time',
            ),
            value: _water ?? true,
            onChanged: _water == null
                ? null
                : (v) async {
                    setState(() => _water = v);
                    await _set(ReminderScheduler.waterRemindersKey, v);
                  },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.directions_walk),
            title: const Text('Evening move nudge'),
            subtitle: Text(
              '${_clock(activityHour)} reminder to walk, stretch, or train',
            ),
            value: _activity ?? true,
            onChanged: _activity == null
                ? null
                : (v) async {
                    setState(() => _activity = v);
                    await _set(ReminderScheduler.activityReminderKey, v);
                  },
          ),
        ],
      ),
    );
  }

  static String _clock(int hour24) {
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$h ${hour24 < 12 ? 'am' : 'pm'}';
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final json = await ref.read(dataManagerProvider).exportJson();
  if (!context.mounted) return;
  if (kIsWeb) {
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('Export copied to clipboard (JSON).')));
  } else {
    await SharePlus.instance.share(ShareParams(
      text: json,
      subject: 'PulsIQ data export',
    ));
  }
}

Future<void> _deleteEverything(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete everything?'),
      content: const Text(
        'This erases all logs, biometrics, and the encryption keys from '
        'this device. If you have no cloud backup, this cannot be undone.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(dataManagerProvider).deleteEverything();
  await ref.read(authServiceProvider).signOut();
  if (context.mounted) context.go('/onboarding');
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
