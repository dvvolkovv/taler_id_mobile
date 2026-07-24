import 'package:flutter/material.dart';

import '../../domain/entities/mail_entities.dart';

class MailTile extends StatelessWidget {
  final MailListItemEntity item;
  final VoidCallback onTap;

  const MailTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bold = item.seen ? FontWeight.normal : FontWeight.bold;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child:
            Text(item.from.isNotEmpty ? item.from[0].toUpperCase() : '?'),
      ),
      title: Text(item.from,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: bold)),
          Text(item.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatDate(item.date), style: theme.textTheme.bodySmall),
          if (item.hasAttachments) const Icon(Icons.attach_file, size: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }
}
