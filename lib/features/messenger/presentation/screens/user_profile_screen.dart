import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  // Contact status
  bool _isContact = false;
  String? _pendingRequest; // 'sent' | 'received' | null
  String? _requestId;
  bool _contactActionLoading = false;

  // Conversation for shared media
  String? _conversationId;

  // Shared media tab controller
  late TabController _mediaTabCtrl;

  @override
  void initState() {
    super.initState();
    _mediaTabCtrl = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _mediaTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final client = sl<DioClient>();
    try {
      final results = await Future.wait([
        client.get('/profile/${widget.userId}', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
        client.get('/messenger/contacts/check/${widget.userId}', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0];
          final cs = results[1];
          _isContact = cs['isContact'] as bool? ?? false;
          _pendingRequest = cs['pendingRequest'] as String?;
          _requestId = cs['requestId'] as String?;
          _loading = false;
        });
        _findConversation();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _findConversation() {
    try {
      final convs = context.read<MessengerBloc>().state.conversations;
      final conv = convs.where((c) => c.type == 'DIRECT' && c.otherUserId == widget.userId).firstOrNull;
      if (conv != null && mounted) {
        setState(() => _conversationId = conv.id);
      }
    } catch (_) {}
  }

  Future<void> _sendContactRequest() async {
    setState(() => _contactActionLoading = true);
    try {
      final client = sl<DioClient>();
      await client.post(
        '/messenger/contacts/request',
        data: {'receiverId': widget.userId},
        fromJson: (d) => d,
      );
      if (mounted) setState(() { _pendingRequest = 'sent'; _contactActionLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  Future<void> _acceptContactRequest() async {
    if (_requestId == null || _contactActionLoading) return;
    setState(() => _contactActionLoading = true);
    try {
      final client = sl<DioClient>();
      await client.patch(
        '/messenger/contacts/requests/$_requestId/accept',
        fromJson: (d) => d,
      );
      if (mounted) setState(() { _isContact = true; _pendingRequest = null; _requestId = null; _contactActionLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _contactActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
        );
      }
    }
  }

  Future<String?> _getOrCreateConversation() async {
    // If we already know the conversation ID, return it
    if (_conversationId != null) return _conversationId;
    try {
      final ds = sl<MessengerRemoteDataSource>();
      final conv = await ds.createConversation(widget.userId);
      if (mounted) {
        setState(() => _conversationId = conv.id);
        context.read<MessengerBloc>().add(LoadConversations());
      }
      return conv.id;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userProfileFailedOpenChat),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _openChat() async {
    final convId = await _getOrCreateConversation();
    if (convId != null && mounted) {
      context.push('/dashboard/messenger/$convId');
    }
  }

  Future<void> _startDirectCall() async {
    if (CallStateService.instance.isInCall) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatAlreadyInCall),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }

    final convId = await _getOrCreateConversation();
    if (convId == null || !mounted) return;

    try {
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/rooms',
        data: {'withAi': false, 'conversationId': convId},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      sl<MessengerRemoteDataSource>().sendCallInvite(convId, roomName);

      final firstName = _profile?['firstName'] as String? ?? '';
      final lastName = _profile?['lastName'] as String? ?? '';
      final calleeName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
      final calleeParam = calleeName.isNotEmpty
          ? '&callee=${Uri.encodeComponent(calleeName)}'
          : '';
      final avatarUrl = _profile?['avatarUrl'] as String?;
      final avatarParam = avatarUrl != null && avatarUrl.isNotEmpty
          ? '&calleeAvatar=${Uri.encodeComponent(avatarUrl)}'
          : '';
      if (mounted) {
        context.push('/dashboard/voice?room=$roomName&convId=$convId$calleeParam$avatarParam');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatCallError(e.toString())),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  void _shareContact() {
    final firstName = _profile?['firstName'] as String? ?? '';
    final lastName = _profile?['lastName'] as String? ?? '';
    final username = _profile?['username'] as String?;
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.share_rounded, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.userProfileShareContact, style: TextStyle(color: AppColors.of(context).textPrimary)),
              subtitle: Text(AppLocalizations.of(context)!.userProfileShareContactDesc, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                final shareText = username != null
                    ? 'Контакт в Taler ID: $fullName (@$username)\nhttps://id.taler.tirol/u/$username'
                    : 'Контакт в Taler ID: $fullName';
                Share.share(shareText);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: AppColors.of(context).primary),
              title: Text(AppLocalizations.of(context)!.userProfileCopyLink, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                final link = username != null
                    ? 'https://id.taler.tirol/u/$username'
                    : fullName;
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.userProfileCopied), duration: const Duration(seconds: 1)),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _profile?['firstName'] as String? ?? '';
    final lastName = _profile?['lastName'] as String? ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final username = _profile?['username'] as String?;
    final avatarUrl = _profile?['avatarUrl'] as String?;
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : l10n.userProfileTitle),
        backgroundColor: AppColors.of(context).surface,
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareContact,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
                      const SizedBox(height: 16),
                      Text(l10n.userProfileLoadError,
                          style: TextStyle(color: AppColors.of(context).textPrimary)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.2),
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Text(
                                    initials,
                                    style: TextStyle(
                                        color: AppColors.of(context).primary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Text(
                                initials,
                                style: TextStyle(
                                    color: AppColors.of(context).primary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (fullName.isNotEmpty)
                      Center(
                        child: Text(
                          fullName,
                          style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (username != null && username.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '@$username',
                          style: TextStyle(
                              color: AppColors.of(context).textSecondary, fontSize: 15),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildActionButtons(colors),
                    const SizedBox(height: 24),
                    // Inline shared media with tabs
                    if (_conversationId != null)
                      _InlineSharedMedia(conversationId: _conversationId!, tabController: _mediaTabCtrl),
                  ],
                ),
    );
  }

  Widget _buildActionButtons(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    if (_contactActionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isContact) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black),
              label: Text(l10n.userProfileMessage, style: const TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startDirectCall,
              icon: const Icon(Icons.call_outlined, color: Colors.black),
              label: Text(l10n.userProfileCall, style: const TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (_pendingRequest == 'sent') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.hourglass_empty_rounded, color: colors.textSecondary),
          label: Text(l10n.userProfileRequestSent, style: TextStyle(color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (_pendingRequest == 'received') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acceptContactRequest,
              icon: const Icon(Icons.check_rounded, color: Colors.black),
              label: Text(l10n.userProfileAccept, style: const TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              label: Text(l10n.userProfileDecline, style: TextStyle(color: colors.textSecondary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // No contact — show Add button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendContactRequest,
        icon: const Icon(Icons.person_add_outlined, color: Colors.black),
        label: Text(l10n.userProfileAddToContacts, style: const TextStyle(color: Colors.black)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Inline shared media widget with tabs: Медиа / Файлы / Ссылки / Записи / Резюме
class _InlineSharedMedia extends StatefulWidget {
  final String conversationId;
  final TabController tabController;

  const _InlineSharedMedia({required this.conversationId, required this.tabController});

  @override
  State<_InlineSharedMedia> createState() => _InlineSharedMediaState();
}

class _InlineSharedMediaState extends State<_InlineSharedMedia> {
  final _mediaItems = <_MediaItem>[];
  final _docItems = <_MediaItem>[];
  final _linkItems = <_MediaItem>[];
  final _recordings = <Map<String, dynamic>>[];
  final _summaries = <Map<String, dynamic>>[];
  bool _mediaLoading = true;
  bool _docsLoading = true;
  bool _linksLoading = true;
  bool _callsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final client = sl<DioClient>();
    final convId = widget.conversationId;
    try {
      final results = await Future.wait([
        client.get('/messenger/conversations/$convId/media?type=media', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
        client.get('/messenger/conversations/$convId/media?type=documents', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
        client.get('/messenger/conversations/$convId/media?type=links', fromJson: (d) => Map<String, dynamic>.from(d as Map)),
      ]);
      if (mounted) {
        setState(() {
          _mediaItems.addAll((results[0]['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)));
          _docItems.addAll((results[1]['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)));
          _linkItems.addAll((results[2]['items'] as List).map((e) => _MediaItem.fromJson(e as Map<String, dynamic>)));
          _mediaLoading = false;
          _docsLoading = false;
          _linksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _mediaLoading = false; _docsLoading = false; _linksLoading = false; });
    }
    // Load call history for this conversation
    _loadCallHistory(client, convId);
  }

  Future<void> _loadCallHistory(DioClient client, String convId) async {
    try {
      final data = await client.get<dynamic>(
        '/voice/call-history',
        queryParameters: {'page': 0, 'limit': 100},
      );
      final items = (data as List?) ?? [];
      if (mounted) {
        final calls = items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((c) => c['conversationId'] == convId)
            .toList();
        final recs = <Map<String, dynamic>>[];
        final sums = <Map<String, dynamic>>[];
        for (final c in calls) {
          final summary = c['meetingSummary'] as Map<String, dynamic>?;
          if (summary != null) {
            final recordingUrl = summary['recordingUrl'] as String?;
            if (recordingUrl != null && recordingUrl.isNotEmpty) {
              recs.add({...c, 'recordingUrl': recordingUrl});
            }
            final summaryText = summary['summary'] as String?;
            if (summaryText != null && summaryText.isNotEmpty) {
              sums.add({...c, 'summaryText': summaryText});
            }
          }
        }
        setState(() {
          _recordings.addAll(recs);
          _summaries.addAll(sums);
          _callsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _callsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasContent = _mediaItems.isNotEmpty || _docItems.isNotEmpty ||
        _linkItems.isNotEmpty || _recordings.isNotEmpty || _summaries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: widget.tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: '${l10n.userProfileMediaTab}${_mediaLoading ? '' : ' (${_mediaItems.length})'}'),
            Tab(text: '${l10n.userProfileFilesTab}${_docsLoading ? '' : ' (${_docItems.length})'}'),
            Tab(text: '${l10n.userProfileLinksTab}${_linksLoading ? '' : ' (${_linkItems.length})'}'),
            Tab(text: '${l10n.userProfileRecordingsTab}${_callsLoading ? '' : ' (${_recordings.length})'}'),
            Tab(text: '${l10n.userProfileSummariesTab}${_callsLoading ? '' : ' (${_summaries.length})'}'),
          ],
        ),
        SizedBox(
          height: !hasContent && !_mediaLoading ? 80 : 260,
          child: TabBarView(
            controller: widget.tabController,
            children: [
              _buildMediaGrid(colors),
              _buildDocsList(colors),
              _buildLinksList(colors),
              _buildRecordingsList(colors),
              _buildSummariesList(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid(AppColorsExtension colors) {
    if (_mediaLoading) return const Center(child: CircularProgressIndicator());
    if (_mediaItems.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoMedia, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final item = _mediaItems[index];
        final thumb = item.thumbnailMediumUrl ?? item.thumbnailSmallUrl ?? item.fileUrl;
        if (thumb == null) return const SizedBox();
        return GestureDetector(
          onTap: () {
            if (item.fileUrl != null) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _FullScreenMediaView(item: item),
              ));
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Widget _buildDocsList(AppColorsExtension colors) {
    if (_docsLoading) return const Center(child: CircularProgressIndicator());
    if (_docItems.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoFiles, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _docItems.length,
      itemBuilder: (context, index) {
        final item = _docItems[index];
        final ext = item.fileName?.split('.').last.toUpperCase() ?? 'FILE';
        return ListTile(
          dense: true,
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(ext.length > 4 ? ext.substring(0, 4) : ext,
                  style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          title: Text(item.fileName ?? 'Файл',
              style: TextStyle(color: colors.textPrimary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }

  Widget _buildLinksList(AppColorsExtension colors) {
    if (_linksLoading) return const Center(child: CircularProgressIndicator());
    if (_linkItems.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoLinks, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _linkItems.length,
      itemBuilder: (context, index) {
        final item = _linkItems[index];
        final url = _extractUrl(item.content ?? '');
        return ListTile(
          dense: true,
          leading: Icon(Icons.link, color: colors.primary, size: 20),
          title: Text(url ?? item.content ?? '',
              style: TextStyle(color: colors.primary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }

  Widget _buildRecordingsList(AppColorsExtension colors) {
    if (_callsLoading) return const Center(child: CircularProgressIndicator());
    if (_recordings.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoRecordings, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final rec = _recordings[index];
        final createdAt = rec['startedAt'] as String?;
        final date = createdAt != null ? DateTime.tryParse(createdAt) : null;
        final dateStr = date != null ? DateFormat('dd.MM.yy HH:mm').format(date.toLocal()) : '';
        final url = rec['recordingUrl'] as String?;
        return _RecordingTile(
          dateStr: dateStr,
          recordingUrl: url ?? '',
          colors: colors,
        );
      },
    );
  }

  Widget _buildSummariesList(AppColorsExtension colors) {
    if (_callsLoading) return const Center(child: CircularProgressIndicator());
    if (_summaries.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.userProfileNoSummaries, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: _summaries.length,
      itemBuilder: (context, index) {
        final sum = _summaries[index];
        final text = sum['summaryText'] as String? ?? '';
        final createdAt = sum['startedAt'] as String?;
        final date = createdAt != null ? DateTime.tryParse(createdAt) : null;
        final dateStr = date != null ? DateFormat('dd.MM.yy HH:mm').format(date.toLocal()) : '';
        return ListTile(
          dense: true,
          leading: Icon(Icons.summarize_rounded, color: colors.primary, size: 20),
          title: Text(
            text.length > 60 ? '${text.substring(0, 60)}...' : text,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: dateStr.isNotEmpty ? Text(dateStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)) : null,
          onTap: () => _showSummaryDetail(context, text, dateStr),
        );
      },
    );
  }

  void _showSummaryDetail(BuildContext context, String text, String dateStr) {
    final colors = AppColors.of(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Text('${AppLocalizations.of(context)!.userProfileMeetingSummary}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
            style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.userProfileCopied), backgroundColor: colors.primary, duration: const Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(text, style: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5)),
        ),
      ),
    ));
  }

  String? _extractUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match?.group(0);
  }
}

class _MediaItem {
  final String id;
  final String? content;
  final DateTime? sentAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final String? thumbnailSmallUrl;
  final String? thumbnailMediumUrl;
  final String? thumbnailLargeUrl;

  _MediaItem({
    required this.id, this.content, this.sentAt, this.fileUrl,
    this.fileName, this.fileSize, this.fileType,
    this.thumbnailSmallUrl, this.thumbnailMediumUrl, this.thumbnailLargeUrl,
  });

  factory _MediaItem.fromJson(Map<String, dynamic> json) => _MediaItem(
    id: json['id'] as String,
    content: json['content'] as String?,
    sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null,
    fileUrl: json['fileUrl'] as String?,
    fileName: json['fileName'] as String?,
    fileSize: json['fileSize'] as int?,
    fileType: json['fileType'] as String?,
    thumbnailSmallUrl: json['thumbnailSmallUrl'] as String?,
    thumbnailMediumUrl: json['thumbnailMediumUrl'] as String?,
    thumbnailLargeUrl: json['thumbnailLargeUrl'] as String?,
  );
}

class _RecordingTile extends StatefulWidget {
  final String dateStr;
  final String recordingUrl;
  final AppColorsExtension colors;

  const _RecordingTile({required this.dateStr, required this.recordingUrl, required this.colors});

  @override
  State<_RecordingTile> createState() => _RecordingTileState();
}

class _RecordingTileState extends State<_RecordingTile> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_playing) {
                await _player.pause();
              } else {
                if (_position == Duration.zero) {
                  await _player.play(UrlSource(widget.recordingUrl));
                } else {
                  await _player.resume();
                }
              }
            },
            child: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: colors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.textSecondary.withValues(alpha: 0.2),
                    thumbColor: colors.primary,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    onChanged: (v) {
                      final newPos = Duration(milliseconds: (v * _duration.inMilliseconds).toInt());
                      _player.seek(newPos);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position), style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    Text(widget.dateStr, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    Text(_fmt(_duration), style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenMediaView extends StatelessWidget {
  final _MediaItem item;
  const _FullScreenMediaView({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(item.fileName ?? '', style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: item.thumbnailLargeUrl ?? item.fileUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
