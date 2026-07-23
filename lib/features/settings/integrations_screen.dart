import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/health_providers.dart';
import '../../health/whoop/whoop_providers.dart';

/// One place to connect every biometric source. Each provider is a tile with
/// its own connect/disconnect flow; the app reads from whichever is connected
/// (see `healthSourceProvider` for precedence).
class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final healthConnected =
        ref.watch(platformHealthConnectedProvider).value ?? false;
    final whoopConnected = ref.watch(whoopConnectedProvider).value ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Integrations'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'Connect the wearables and health platforms you already use. '
              'PulsIQ reads from them — it never writes back.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),

          // Apple Health — iOS only.
          if (_isIOS || kIsWeb)
            _IntegrationTile(
              icon: Icons.favorite_outline,
              name: 'Apple Health',
              provides: 'Heart rate, HRV, resting HR, sleep, steps, workouts',
              connected: healthConnected,
              available: _isIOS,
              unavailableNote: 'Available on iPhone.',
              onConnect: () => _connectPlatformHealth(context, ref),
              onDisconnect: () => _disconnectPlatformHealth(context, ref),
            ),

          // Google Health Connect — Android only.
          if (_isAndroid || kIsWeb)
            _IntegrationTile(
              icon: Icons.health_and_safety_outlined,
              name: 'Google Health Connect',
              provides: 'Heart rate, HRV, resting HR, sleep, steps, exercise',
              connected: healthConnected,
              available: _isAndroid,
              unavailableNote: 'Available on Android.',
              onConnect: () => _connectPlatformHealth(context, ref),
              onDisconnect: () => _disconnectPlatformHealth(context, ref),
            ),

          // WHOOP — any platform, via its own API.
          _WhoopTile(connected: whoopConnected),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'When more than one source is connected, WHOOP leads for '
              'recovery and strain. Steps come from Apple Health or Health '
              'Connect — WHOOP doesn\'t expose them.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectPlatformHealth(
      BuildContext context, WidgetRef ref) async {
    final granted = await ref.read(healthConnectorProvider)();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(granted
            ? 'Connected — pulling your telemetry now.'
            : 'Permission not granted. You can enable it in the Health app '
                'under Sharing → Apps.'),
      ));
  }

  Future<void> _disconnectPlatformHealth(
      BuildContext context, WidgetRef ref) async {
    await ref.read(healthDisconnectProvider)();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Disconnected. Revoke access fully in the Health app.'),
      ));
  }
}

class _IntegrationTile extends StatefulWidget {
  const _IntegrationTile({
    required this.icon,
    required this.name,
    required this.provides,
    required this.connected,
    required this.available,
    required this.unavailableNote,
    required this.onConnect,
    required this.onDisconnect,
  });

  final IconData icon;
  final String name;
  final String provides;
  final bool connected;
  final bool available;
  final String unavailableNote;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  @override
  State<_IntegrationTile> createState() => _IntegrationTileState();
}

class _IntegrationTileState extends State<_IntegrationTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.name,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (widget.connected) ...[
                          const SizedBox(width: 8),
                          const _ConnectedChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.available
                          ? widget.provides
                          : widget.unavailableNote,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!widget.available)
                const SizedBox.shrink()
              else if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                TextButton(
                  onPressed: () => _run(widget.connected
                      ? widget.onDisconnect
                      : widget.onConnect),
                  child: Text(widget.connected ? 'Disconnect' : 'Connect'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedChip extends StatelessWidget {
  const _ConnectedChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.brightness == Brightness.dark
        ? Colors.greenAccent.shade200
        : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Connected',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: green, fontWeight: FontWeight.w700)),
    );
  }
}

/// WHOOP has its own OAuth flow, so it gets a dedicated tile.
class _WhoopTile extends ConsumerStatefulWidget {
  const _WhoopTile({required this.connected});

  final bool connected;

  @override
  ConsumerState<_WhoopTile> createState() => _WhoopTileState();
}

class _WhoopTileState extends ConsumerState<_WhoopTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.watch_outlined,
                  size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('WHOOP',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (widget.connected) ...[
                          const SizedBox(width: 8),
                          const _ConnectedChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Recovery, strain, HRV, resting HR, sleep',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                TextButton(
                  onPressed: widget.connected ? _disconnect : _connect,
                  child: Text(widget.connected ? 'Disconnect' : 'Connect'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    final ok = await ref.read(whoopConnectorProvider)();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok
            ? 'WHOOP connected — your pulse now leads the dashboard.'
            : 'WHOOP sign-in didn\'t complete. Make sure the analysis server '
                'is running and try again.'),
      ));
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await ref.read(whoopDisconnectProvider)();
    if (mounted) setState(() => _busy = false);
  }
}
