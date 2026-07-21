import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/log_repository.dart';
import '../../data/providers.dart';
import '../logging/entry_sheet.dart';

const _kindIcons = {
  LogKind.food: Icons.restaurant_outlined,
  LogKind.beverage: Icons.local_cafe_outlined,
  LogKind.hydration: Icons.water_drop_outlined,
  LogKind.exercise: Icons.directions_walk,
};

class LogTile extends ConsumerWidget {
  const LogTile({super.key, required this.item});

  final LogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('${item.kind.name}-${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          ref.read(logRepositoryProvider).deleteItem(item);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('${item.title} removed')));
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer),
        ),
        child: Card(
          child: ListTile(
            onTap: () => showEntrySheet(context, existing: item),
            leading: CircleAvatar(
              radius: 19,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                _kindIcons[item.kind],
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(item.title, style: theme.textTheme.bodyLarge),
            subtitle: Text(item.detail),
            trailing: Text(
              _formatTime(item.loggedAt),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}
