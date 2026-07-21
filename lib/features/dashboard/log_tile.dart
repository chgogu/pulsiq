import 'package:flutter/material.dart';

import '../../data/mock_data.dart';

const _kindIcons = {
  LogKind.food: Icons.restaurant_outlined,
  LogKind.beverage: Icons.local_cafe_outlined,
  LogKind.hydration: Icons.water_drop_outlined,
  LogKind.exercise: Icons.directions_walk,
};

class LogTile extends StatelessWidget {
  const LogTile({super.key, required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            radius: 19,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              _kindIcons[entry.kind],
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(entry.title, style: theme.textTheme.bodyLarge),
          subtitle: Text(entry.detail),
          trailing: Text(
            entry.time,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
