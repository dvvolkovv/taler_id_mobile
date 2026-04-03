import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';

class _Topic {
  final String id;
  final String title;
  final String icon;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderName;
  final String? lastMessageSenderId;
  final bool lastMessageIsDelivered;
  final bool lastMessageIsRead;
  final int unreadCount;

  _Topic({
    required this.id,
    required this.title,
    required this.icon,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderName,
    this.lastMessageSenderId,
    this.lastMessageIsDelivered = false,
    this.lastMessageIsRead = false,
    this.unreadCount = 0,
  });

  factory _Topic.fromMap(Map<String, dynamic> m) => _Topic(
    id: m['id'] as String,
    title: m['title'] as String,
    icon: m['icon'] as String? ?? '💬',
    lastMessage: m['lastMessageContent'] as String?,
    lastMessageAt: m['lastMessageAt'] != null ? DateTime.tryParse(m['lastMessageAt'] as String) : null,
    lastMessageSenderName: m['lastMessageSenderName'] as String?,
    lastMessageSenderId: m['lastMessageSenderId'] as String?,
    lastMessageIsDelivered: m['lastMessageIsDelivered'] as bool? ?? false,
    lastMessageIsRead: m['lastMessageIsRead'] as bool? ?? false,
    unreadCount: 0,
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
  List<_Topic> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final client = sl<DioClient>();
      final data = await client.get<List<dynamic>>(
        '/messenger/conversations/${widget.conversationId}/topics',
        fromJson: (d) => d as List<dynamic>,
      );
      final topics = data.map((e) => _Topic.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      if (topics.isEmpty) {
        // Create default "General" topic on backend
        final created = await client.post<Map<String, dynamic>>(
          '/messenger/conversations/${widget.conversationId}/topics',
          data: {'title': 'Общая', 'icon': '💬'},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        if (mounted) setState(() { _topics = [_Topic.fromMap(created)]; _loading = false; });
      } else {
        if (mounted) setState(() { _topics = topics; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final client = sl<DioClient>();
                  final created = await client.post<Map<String, dynamic>>(
                    '/messenger/conversations/${widget.conversationId}/topics',
                    data: {'title': title, 'icon': selectedIcon},
                    fromJson: (d) => Map<String, dynamic>.from(d as Map),
                  );
                  if (mounted) setState(() => _topics.add(_Topic.fromMap(created)));
                } catch (_) {}
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? Center(
                  child: Text(AppLocalizations.of(context)!.messengerNoTopics, style: TextStyle(color: colors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _topics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    final currentUserId = context.read<MessengerBloc>().state.currentUserId;
                    final isMe = topic.lastMessageSenderId != null && topic.lastMessageSenderId == currentUserId;
                    final now = DateTime.now();
                    final msgAt = topic.lastMessageAt?.toLocal();
                    String timeStr = '';
                    if (msgAt != null) {
                      final isToday = msgAt.year == now.year && msgAt.month == now.month && msgAt.day == now.day;
                      final isThisYear = msgAt.year == now.year;
                      timeStr = isToday
                          ? DateFormat('HH:mm').format(msgAt)
                          : isThisYear
                              ? DateFormat('d MMM', 'ru').format(msgAt)
                              : DateFormat('d.MM.yy').format(msgAt);
                    }
                    // subtitle: "Имя: текст" или просто "текст"
                    Widget? subtitleWidget;
                    if (topic.lastMessage != null) {
                      final senderLabel = isMe
                          ? AppLocalizations.of(context)!.you
                          : (topic.lastMessageSenderName?.split(' ').first ?? '');
                      subtitleWidget = RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            if (isMe) ...[
                              if (topic.lastMessageIsRead)
                                WidgetSpan(child: Icon(Icons.done_all, size: 14, color: colors.primary))
                              else if (topic.lastMessageIsDelivered)
                                WidgetSpan(child: Icon(Icons.done_all, size: 14, color: colors.textSecondary))
                              else
                                WidgetSpan(child: Icon(Icons.done, size: 14, color: colors.textSecondary)),
                            ],
                            if (senderLabel.isNotEmpty) ...[
                              TextSpan(
                                text: ' $senderLabel: ',
                                style: TextStyle(color: isMe ? colors.textSecondary : colors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ] else
                              const TextSpan(text: ' '),
                            TextSpan(
                              text: topic.lastMessage!,
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }
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
                      subtitle: subtitleWidget,
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
                      onTap: () async {
                        await context.push(
                          '/dashboard/messenger/${widget.conversationId}',
                          extra: {'topicId': topic.id, 'topicTitle': '${topic.icon} ${topic.title}'},
                        );
                        if (mounted) _loadTopics();
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
