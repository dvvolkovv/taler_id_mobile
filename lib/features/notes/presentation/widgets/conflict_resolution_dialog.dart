// lib/features/notes/presentation/widgets/conflict_resolution_dialog.dart
import 'package:flutter/material.dart';
import '../../domain/entities/note_entity.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final NoteEntity local;
  final Future<void> Function(ConflictResolution) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.local,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final server = local.conflictedWith ?? <String, dynamic>{};
    return AlertDialog(
      title: const Text('Конфликт синхронизации'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заметка была изменена на другом устройстве, пока ваши изменения ждали отправки.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _version('Моя версия', local.title, local.content, Colors.blue),
            const SizedBox(height: 12),
            _version('Версия с сервера', server['title'] as String? ?? '',
                server['content'] as String? ?? '', Colors.green),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await onResolve(ConflictResolution.acceptServer);
          },
          child: const Text('Принять серверную'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await onResolve(ConflictResolution.keepMine);
          },
          child: const Text('Оставить мою'),
        ),
      ],
    );
  }

  Widget _version(String label, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(content, maxLines: 5, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
