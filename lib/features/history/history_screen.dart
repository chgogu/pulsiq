import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../dashboard/log_tile.dart';
import 'day_log.dart';

/// Browsable 1-year log history, grouped by day (newest first). Read path
/// only — editing/deleting reuses [LogTile]'s existing behaviour.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(logHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: switch (history) {
        AsyncData(value: final items) when items.isEmpty => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Your logged days will appear here.\n'
                'Everything you log is kept for a year.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        AsyncData(value: final items) => _HistoryList(days: groupIntoDays(items)),
        AsyncError() => Center(
            child: Text("Couldn't load your history.",
                style: theme.textTheme.bodyMedium),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.days});

  final List<DayLog> days;

  @override
  Widget build(BuildContext context) {
    final summary = YearSummary.from(days);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _SummaryStrip(summary: summary),
        const SizedBox(height: 12),
        for (final day in days) ...[
          _DayHeader(day: day),
          for (final item in day.items) LogTile(item: item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final YearSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      '${summary.daysLogged} '
          '${summary.daysLogged == 1 ? 'day' : 'days'} logged',
      if (summary.avgKcalOnLoggedDays > 0)
        '~${_thousands(summary.avgKcalOnLoggedDays)} kcal/day',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.insights_outlined,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(parts.join('  ·  '),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DayLog day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = <String>[
      if (day.calories > 0) '${_thousands(day.calories)} kcal',
      if (day.foodCount > 0)
        '${day.foodCount} ${day.foodCount == 1 ? 'item' : 'items'}',
      if (day.waterMl > 0) _liters(day.waterMl),
      if (day.exerciseMinutes > 0) '${day.exerciseMinutes} min',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dayLabel(day.day),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (summary.isNotEmpty)
            Text(summary,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

String _thousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _liters(int ml) {
  final l = ml / 1000;
  return l >= 10 || l == l.roundToDouble()
      ? '${l.round()} L'
      : '${l.toStringAsFixed(1)} L';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_weekdays[day.weekday - 1]}, ${_months[day.month - 1]} ${day.day}';
}
