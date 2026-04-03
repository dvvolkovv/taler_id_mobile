import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class _Topic {
  final String id;
  final String title;
  final String icon;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  int unreadCount;

  _Topic({
    required this.id,
    required this.title,
    required this.icon,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'icon': icon,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'unreadCount': unreadCount,
  };

  factory _Topic.fromMap(Map<String, dynamic> m) => _Topic(
    id: m['id'] as String,
    title: m['title'] as String,
    icon: m['icon'] as String? ?? '💬',
    lastMessage: m['lastMessage'] as String?,
    lastMessageAt: m['lastMessageAt'] != null ? DateTime.tryParse(m['lastMessageAt'] as String) : null,
    unreadCount: m['unreadCount'] as int? ?? 0,
  );
}

class TopicsListScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;

  const TopicsListScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
  });

  @override
  State<TopicsListScreen> createState() => _TopicsListScreenState();
}

class _TopicsListScreenState extends State<TopicsListScreen> {
  static const _boxName = 'group_topics';
  List<_Topic> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<Box> _getBox() async {
    try {
      return Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      return await Hive.openBox(_boxName);
    }
  }

  Future<void> _loadTopics() async {
    final box = await _getBox();
    final raw = box.get(widget.conversationId);
    if (raw != null) {
      final list = (raw as List).map((e) => _Topic.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      if (mounted) setState(() => _topics = list);
    } else {
      // Create default "General" topic
      final general = _Topic(id: 'general', title: AppLocalizations.of(context)!.messengerTopicDefault, icon: '💬');
      setState(() => _topics = [general]);
      _saveTopics();
    }
  }

  Future<void> _saveTopics() async {
    final box = await _getBox();
    await box.put(widget.conversationId, _topics.map((t) => t.toMap()).toList());
  }

  void _showCreateTopicDialog() {
    final colors = AppColors.of(context);
    final titleCtrl = TextEditingController();
    String selectedIcon = '💬';
    final icons = ['💬', '📢', '🔧', '🎮', '📚', '🎵', '🎨', '💡', '🔥', '⭐', '📋', '🏗️'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.card,
          title: Text(AppLocalizations.of(context)!.messengerTopicNew, style: TextStyle(color: colors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.messengerTopicNameHint,
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.messengerTopicIcon, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) => GestureDetector(
                  onTap: () => setDialogState(() => selectedIcon = icon),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: selectedIcon == icon ? colors.primary.withValues(alpha: 0.2) : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: selectedIcon == icon ? Border.all(color: colors.primary, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final topic = _Topic(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  icon: selectedIcon,
                );
                setState(() => _topics.add(topic));
                _saveTopics();
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context)!.create),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontSize: 16)),
            Text(AppLocalizations.of(context)!.messengerTopicCount(_topics.length), style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: colors.background,
      ),
      body: _topics.isEmpty
          ? Center(
              child: Text(AppLocalizations.of(context)!.messengerNoTopics, style: TextStyle(color: colors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final timeStr = topic.lastMessageAt != null
                    ? DateFormat('HH:mm').format(topic.lastMessageAt!.toLocal())
                    : '';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: colors.card,
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(topic.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(topic.title, style: TextStyle(
                    color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: topic.lastMessage != null
                      ? Text(topic.lastMessage!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13))
                      : Text(AppLocalizations.of(context)!.messengerNoMessages, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (timeStr.isNotEmpty)
                        Text(timeStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                      if (topic.unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${topic.unreadCount}',
                              style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    context.push(
                      '/dashboard/messenger/${widget.conversationId}',
                      extra: {'topicId': topic.id, 'topicTitle': '${topic.icon} ${topic.title}'},
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTopicDialog,
        backgroundColor: colors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
