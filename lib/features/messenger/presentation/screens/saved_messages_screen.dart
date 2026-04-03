import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  static const _boxName = 'saved_messages';
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    Box box;
    try {
      box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      box = await Hive.openBox(_boxName);
    }
    final items = box.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(a['sentAt'] as String? ?? '') ?? DateTime(0);
        final bTime = DateTime.tryParse(b['sentAt'] as String? ?? '') ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
    if (mounted) setState(() => _messages = items);
  }

  Future<void> _deleteMessage(String id) async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    await box.delete(id);
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messengerSavedTitle),
        backgroundColor: colors.background,
      ),
      body: _messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: colors.textSecondary),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.messengerNoSavedMessages, style: TextStyle(color: colors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.messengerSavedHint,
                      style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final content = msg['content'] as String? ?? '';
                final sender = msg['senderName'] as String? ?? '';
                final sentAt = DateTime.tryParse(msg['sentAt'] as String? ?? '')?.toLocal();
                final timeStr = sentAt != null ? DateFormat('dd.MM.yyyy HH:mm').format(sentAt) : '';
                final fileUrl = msg['fileUrl'] as String?;
                final fileName = msg['fileName'] as String?;
                final id = msg['id'] as String? ?? '';

                return Dismissible(
                  key: ValueKey(id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  onDismissed: (_) => _deleteMessage(id),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(sender, style: TextStyle(
                              color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(timeStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (fileUrl != null)
                          Row(
                            children: [
                              Icon(Icons.attach_file, size: 14, color: colors.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  fileName ?? AppLocalizations.of(context)!.messengerDefaultFile,
                                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (content.isNotEmpty)
                          Text(content, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
