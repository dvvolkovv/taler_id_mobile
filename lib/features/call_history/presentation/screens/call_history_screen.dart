import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';

const _kIncomingColor = Color(0xFF4CAF50);

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  late Future<List<_CallEntry>> _historyFuture;
  Future<_PersonalRoom?>? _personalRoomFuture;
  bool _calling = false;
  bool _creatingTemp = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    _personalRoomFuture = _loadPersonalRoom();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<_CallEntry>> _loadHistory() async {
    final data = await sl<DioClient>().get<dynamic>(
      '/voice/call-history',
      queryParameters: {'page': 0, 'limit': 50},
    );
    final items = data as List? ?? [];
    return items.map((e) => _CallEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<_PersonalRoom?> _loadPersonalRoom() async {
    try {
      final data = await sl<DioClient>().get<Map<String, dynamic>>(
        '/voice/rooms/my',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      return _PersonalRoom(
        code: data['code'] as String,
        link: data['link'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _createTemporaryRoom() async {
    if (_creatingTemp) return;
    setState(() => _creatingTemp = true);
    try {
      final data = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms/temporary',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final code = data['code'] as String;
      final link = data['link'] as String;
      if (mounted) _showTempRoomSheet(code, link);
    } catch (err) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(err.toString())), backgroundColor: AppColors.of(context).error),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingTemp = false);
    }
  }

  void _showTempRoomSheet(String code, String link) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.callHistoryTempMeeting,
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _LinkRow(link: link),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_rounded,
                    label: l10n.callHistoryCopy,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.callHistoryLinkCopied),
                          backgroundColor: colors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_rounded,
                    label: l10n.callHistoryShare,
                    onTap: () => Share.share(link),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: l10n.callHistoryEnter,
                    filled: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/dashboard/voice?publicCode=$code');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.callHistoryLinkCopied),
        backgroundColor: AppColors.of(context).primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _callBack(_CallEntry e) async {
    if (_calling) return;
    final l10n = AppLocalizations.of(context)!;
    if (CallStateService.instance.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.callHistoryAlreadyInCall), backgroundColor: AppColors.of(context).error),
      );
      return;
    }
    if (!e.withAi && (e.conversationId == null || e.conversationId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.callHistoryCouldNotDeterminePeer),
          backgroundColor: AppColors.of(context).error,
        ),
      );
      return;
    }

    setState(() => _calling = true);
    try {
      final res = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms',
        data: {
          'withAi': e.withAi,
          if (e.conversationId != null && e.conversationId!.isNotEmpty)
            'conversationId': e.conversationId,
        },
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      if (e.conversationId != null && e.conversationId!.isNotEmpty) {
        sl<MessengerRemoteDataSource>().sendCallInvite(e.conversationId!, roomName);
      }
      if (mounted) {
        final calleeParam = e.otherPartyName.isNotEmpty
            ? '&callee=${Uri.encodeComponent(e.otherPartyName)}'
            : '';
        final avatarParam = e.otherPartyAvatar != null && e.otherPartyAvatar!.isNotEmpty
            ? '&calleeAvatar=${Uri.encodeComponent(e.otherPartyAvatar!)}'
            : '';
        final calleeIdParam = e.otherPartyId != null && e.otherPartyId!.isNotEmpty
            ? '&calleeId=${e.otherPartyId}'
            : '';
        context.push(
          '/dashboard/voice?room=$roomName'
          '${e.conversationId != null && e.conversationId!.isNotEmpty ? "&convId=${e.conversationId}" : ""}'
          '$calleeParam$avatarParam$calleeIdParam',
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(err.toString())), backgroundColor: AppColors.of(context).error),
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          setState(() {
            _historyFuture = _loadHistory();
            _personalRoomFuture = _loadPersonalRoom();
          });
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              centerTitle: true,
              floating: true,
              snap: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _CallHistoryProfileAvatar(),
              ),
              title: Text(l10n.callHistoryTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: l10n.callHistoryContacts,
                  onPressed: () => context.push('/dashboard/contacts'),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPersonalRoomSection(colors),
                  const SizedBox(height: 12),
                  _buildCreateMeetingButton(colors),
                  const SizedBox(height: 12),
                  _buildMeetingSummariesButton(colors),
                  const SizedBox(height: 8),
                  _buildMeetingRecordingsButton(colors),
                  const SizedBox(height: 24),
                  Text(
                    l10n.callHistoryTab,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryList(colors),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRoomSection(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_PersonalRoom?>(
      future: _personalRoomFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return AppCard(
            child: SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
            ),
          );
        }
        final room = snap.data;
        if (room == null) {
          return AppCard(
            child: Row(
              children: [
                Icon(Icons.link_off_rounded, color: colors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.callHistoryFailedLoadRoom,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () { final f = _loadPersonalRoom(); setState(() { _personalRoomFuture = f; }); },
                  child: Text(l10n.retry, style: TextStyle(color: colors.primary, fontSize: 13)),
                ),
              ],
            ),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.videocam_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.callHistoryYourRoom,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LinkRow(link: room.link),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      label: l10n.callHistoryCopy,
                      onTap: () => _copyLink(room.link),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_rounded,
                      label: l10n.callHistoryShare,
                      onTap: () => Share.share(room.link),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.videocam_rounded,
                      label: l10n.callHistoryEnter,
                      filled: true,
                      onTap: () => context.push('/dashboard/voice?publicCode=${room.code}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateMeetingButton(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _creatingTemp ? null : _createTemporaryRoom,
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _creatingTemp
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                    )
                  : Icon(Icons.add_rounded, color: colors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.callHistoryCreateMeeting,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingSummariesButton(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MeetingSummariesScreen()),
      ),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.smart_toy_outlined, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.callHistoryMeetingSummaries,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingRecordingsButton(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MeetingRecordingsScreen()),
      ),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.callHistoryMeetingRecordings,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<_CallEntry>>(
      future: _historyFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: colors.error, size: 36),
                const SizedBox(height: 8),
                Text(l10n.loadError, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                TextButton(
                  onPressed: () { final f = _loadHistory(); setState(() { _historyFuture = f; }); },
                  child: Text(l10n.retry, style: TextStyle(color: colors.primary)),
                ),
              ],
            ),
          );
        }
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n.callHistoryNoCalls,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ),
          );
        }
        return Column(
          children: entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCallCard(e, colors),
          )).toList(),
        );
      },
    );
  }

  Widget _buildCallCard(_CallEntry e, AppColorsExtension colors) {
    final isMissed = e.isMissed;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CallDetailScreen(callId: e.id)),
      ),
      child: AppCard(
      child: Row(
        children: [
          if (e.otherPartyAvatar != null) ...[
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.primary.withOpacity(0.12),
              backgroundImage: CachedNetworkImageProvider(e.otherPartyAvatar!),
            ),
          ] else ...[
            CircleAvatar(
              radius: 22,
              backgroundColor: isMissed
                  ? colors.error.withOpacity(0.12)
                  : e.isOutgoing
                      ? colors.primary.withOpacity(0.12)
                      : _kIncomingColor.withOpacity(0.12),
              child: e.withAi
                  ? Icon(Icons.smart_toy_outlined, color: colors.primary, size: 20)
                  : Text(
                      e.otherPartyName.isNotEmpty ? e.otherPartyName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: isMissed ? colors.error : e.isOutgoing ? colors.primary : _kIncomingColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.otherPartyName,
                  style: TextStyle(
                    color: isMissed ? colors.error : colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(e.startedAt),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                if (isMissed) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.callHistoryMissed,
                    style: TextStyle(color: colors.error, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
                if (e.hasSummary || e.hasRecording) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (e.hasRecording)
                        _CallBadge(icon: Icons.mic_rounded, label: AppLocalizations.of(context)!.callHistoryRecording, color: Colors.red),
                      if (e.hasSummary)
                        _CallBadge(icon: Icons.description_rounded, label: AppLocalizations.of(context)!.callHistorySummary, color: colors.primary),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (e.durationSec != null && e.durationSec! > 0) ...[
            Text(
              _formatDuration(e.durationSec!),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 8),
          ],
          _calling
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.call_outlined, color: colors.primary, size: 22),
                  tooltip: AppLocalizations.of(context)!.callHistoryCallAgain,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _callBack(e),
                ),
        ],
      ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0 && local.day == now.day) return l10n.callHistoryTodayTime(time);
    if (diff.inDays <= 1 && now.day - local.day == 1) return l10n.callHistoryYesterdayTime(time);
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}, $time';
  }

  String _formatDuration(int sec) {
    if (sec < 60) return '${sec}с';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m < 60) return '${m}м ${s.toString().padLeft(2, '0')}с';
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}ч ${mm.toString().padLeft(2, '0')}м';
  }
}

// ─── Helper widgets ───

class _CallBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CallBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String link;
  const _LinkRow({required this.link});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Text(
        link,
        style: TextStyle(color: colors.primary, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? colors.primary : colors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.white : colors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallHistoryProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cache = sl<CacheService>();
    final profile = cache.getProfile();
    final avatarUrl = profile?['avatarUrl'] as String?;
    final firstName = profile?['firstName'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/dashboard/profile'),
      child: Center(
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.of(context).primary,
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }
}

// ─── Models ───

class _PersonalRoom {
  final String code;
  final String link;
  const _PersonalRoom({required this.code, required this.link});
}

class _CallEntry {
  final String id;
  final String otherPartyName;
  final String? otherPartyAvatar;
  final String? otherPartyId;
  final DateTime startedAt;
  final int? durationSec;
  final bool isOutgoing;
  final bool isMissed;
  final bool withAi;
  final String? conversationId;
  final bool hasSummary;
  final bool hasRecording;

  const _CallEntry({
    required this.id,
    required this.otherPartyName,
    this.otherPartyAvatar,
    this.otherPartyId,
    required this.startedAt,
    this.durationSec,
    required this.isOutgoing,
    this.isMissed = false,
    required this.withAi,
    this.conversationId,
    this.hasSummary = false,
    this.hasRecording = false,
  });

  factory _CallEntry.fromJson(Map<String, dynamic> json) {
    final participants = json['participants'] as List? ?? [];
    final withAi = json['withAi'] as bool? ?? false;
    String name;
    String? avatar;
    if (withAi && participants.isEmpty) {
      name = 'AI-ассистент';
    } else {
      name = participants
          .map((p) => (p as Map)['displayName'] as String? ?? 'Неизвестный')
          .join(', ');
      if (name.isEmpty) name = 'Неизвестный';
      // Take avatar and userId from first participant
      if (participants.isNotEmpty) {
        avatar = (participants.first as Map)['avatarUrl'] as String?;
      }
    }
    final otherPartyId = participants.isNotEmpty
        ? (participants.first as Map)['userId'] as String?
        : null;
    // Check for meeting summary info
    final summary = json['meetingSummary'] as Map<String, dynamic>?;
    final hasSummary = summary != null && (summary['summary'] as String?)?.isNotEmpty == true;
    final hasRecording = summary != null && (summary['recordingUrl'] as String?)?.isNotEmpty == true;

    return _CallEntry(
      id: json['id'] as String? ?? '',
      otherPartyName: name,
      otherPartyAvatar: avatar,
      otherPartyId: otherPartyId,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      durationSec: json['durationSec'] as int?,
      isOutgoing: json['isOutgoing'] as bool? ?? true,
      isMissed: json['isMissed'] as bool? ?? false,
      withAi: withAi,
      conversationId: json['conversationId'] as String?,
      hasSummary: hasSummary,
      hasRecording: hasRecording,
    );
  }
}

// ─── Call Detail Screen ───

class CallDetailScreen extends StatefulWidget {
  final String callId;
  const CallDetailScreen({super.key, required this.callId});
  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription> _subs = [];
  bool _transcribing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _subs.add(_player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    }));
    _subs.add(_player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playerState = PlayerState.stopped; _position = Duration.zero; });
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await sl<DioClient>().get<dynamic>('/voice/call-history/${widget.callId}');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> _togglePlay(String url) async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      setState(() => _position = Duration.zero);
      await _player.play(UrlSource(url));
    }
  }

  Future<void> _requestTranscription(String summaryId) async {
    setState(() { _transcribing = true; });
    try {
      await sl<DioClient>().post<dynamic>('/voice/recordings/$summaryId/transcribe');
      // Reload to show processing state
      setState(() { _future = _load(); });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _transcribing = false; });
    }
  }

  String _fmtPos(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtDuration(int sec) {
    if (sec < 60) return '${sec}с';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m < 60) return '${m}м ${s.toString().padLeft(2, '0')}с';
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}ч ${mm.toString().padLeft(2, '0')}м';
  }

  String _fmtDate(DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final l = dt.toLocal();
    final now = DateTime.now();
    final time = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    if (l.day == now.day && l.month == now.month && l.year == now.year) return l10n.callHistoryTodayTime(time);
    final yesterday = now.subtract(const Duration(days: 1));
    if (l.day == yesterday.day && l.month == yesterday.month && l.year == yesterday.year) return l10n.callHistoryYesterdayTime(time);
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.callHistoryDetails)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 36),
                  const SizedBox(height: 8),
                  Text(l10n.loadError, style: TextStyle(color: colors.textPrimary)),
                  TextButton(
                    onPressed: () { final f = _load(); setState(() { _future = f; }); },
                    child: Text(l10n.retry, style: TextStyle(color: colors.primary)),
                  ),
                ],
              ),
            );
          }
          final data = snap.data!;
          return _buildContent(data, colors);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final startedAt = DateTime.tryParse(data['startedAt'] as String? ?? '')?.toLocal() ?? DateTime.now();
    final durationSec = data['durationSec'] as int?;
    final isOutgoing = data['isOutgoing'] as bool? ?? true;
    final withAi = data['withAi'] as bool? ?? false;
    final participants = (data['participants'] as List?)
        ?.map((p) => Map<String, dynamic>.from(p as Map))
        .toList() ?? [];
    final summary = data['summary'] as Map<String, dynamic>?;
    final recordingUrl = summary?['recordingUrl'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        AppCard(
          child: Column(
            children: [
              Icon(
                isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
                size: 40,
                color: isOutgoing ? colors.primary : _kIncomingColor,
              ),
              const SizedBox(height: 8),
              Text(
                isOutgoing ? l10n.callHistoryOutgoing : l10n.callHistoryIncoming,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _fmtDate(startedAt),
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (durationSec != null && durationSec > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.callHistoryDuration(_fmtDuration(durationSec)),
                    style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              if (withAi) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 16, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(l10n.callHistoryWithAI, style: TextStyle(color: colors.primary, fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Participants
        if (participants.isNotEmpty) ...[
          _SectionHeader(icon: Icons.people_rounded, title: l10n.callHistoryParticipants, colors: colors),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: participants.map((p) {
                final name = p['displayName'] as String? ?? l10n.callHistoryUnknown;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.primary.withOpacity(0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name, style: TextStyle(color: colors.textPrimary, fontSize: 15)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Meeting summary (first, before recording)
        if (summary != null && summary['status'] != 'processing') ...[
          if ((summary['summary'] as String? ?? '').isNotEmpty) ...[
            _SectionHeader(icon: Icons.smart_toy_rounded, title: l10n.callHistoryMeetingSummary, colors: colors),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MeetingSummaryDetailScreen(id: summary['id'] as String)),
              ),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary['summary'] as String,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.arrow_forward_rounded, size: 16, color: colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.callHistoryMoreDetails,
                          style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],

        if (summary != null && summary['status'] == 'processing') ...[
          AppCard(
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.callHistorySummaryProcessing,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Recording
        if (recordingUrl != null && recordingUrl.isNotEmpty) ...[
          _SectionHeader(icon: Icons.fiber_manual_record_rounded, title: l10n.callHistoryMeetingRecording, colors: colors),
          const SizedBox(height: 8),
          AppCard(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    size: 40,
                    color: colors.primary,
                  ),
                  onPressed: () => _togglePlay(recordingUrl),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: colors.primary,
                          inactiveTrackColor: colors.border,
                          thumbColor: colors.primary,
                          overlayColor: colors.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: _duration.inMilliseconds > 0
                              ? (v) => _player.seek(Duration(milliseconds: (v * _duration.inMilliseconds).round()))
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmtPos(_position), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                            Text(
                              _duration > Duration.zero ? _fmtPos(_duration) : '',
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.share_rounded, size: 20, color: colors.textSecondary),
                  onPressed: () => Share.share(recordingUrl),
                  tooltip: l10n.callHistoryShare,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Protocol button — show when recording exists but no transcript yet
        if (recordingUrl != null && recordingUrl.isNotEmpty && summary != null) ...[
          if ((summary['transcript'] as String? ?? '').isEmpty && summary['status'] != 'processing') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _transcribing ? null : () => _requestTranscription(summary['id'] as String),
                icon: _transcribing
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textPrimary))
                    : const Icon(Icons.description_rounded),
                label: Text(_transcribing ? l10n.callHistoryProcessing : l10n.callHistoryCreateTranscript),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final AppColorsExtension colors;
  const _SectionHeader({required this.icon, required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Meeting Summaries Screen ───

class MeetingSummariesScreen extends StatefulWidget {
  const MeetingSummariesScreen({super.key});
  @override
  State<MeetingSummariesScreen> createState() => _MeetingSummariesScreenState();
}

class _MeetingSummariesScreenState extends State<MeetingSummariesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await sl<DioClient>().get<dynamic>('/voice/meetings');
    final items = data as List? ?? [];
    final list = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    // Auto-refresh while there are processing meetings
    final hasProcessing = list.any((e) => e['status'] == 'processing');
    _refreshTimer?.cancel();
    if (hasProcessing && mounted) {
      _refreshTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) { final f = _load(); setState(() { _future = f; }); }
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.callHistoryMeetingSummaries)),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async { final f = _load(); setState(() { _future = f; }); },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary));
            }
            if (snap.hasError) {
              return Center(child: Text(l10n.loadError, style: TextStyle(color: colors.error)));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 48, color: colors.textSecondary),
                        const SizedBox(height: 12),
                        Text(l10n.callHistoryNoSummaries, style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          l10n.callHistoryRecordDuringCall,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _buildSummaryCard(items[i], colors),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> item, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final participants = (item['participants'] as List?)?.join(', ') ?? '';
    final summary = item['summary'] as String? ?? '';
    final durationSec = item['durationSec'] as int?;
    final actionItemsCount = item['actionItemsCount'] as int? ?? 0;
    final createdAt = (DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now()).toLocal();
    final timeStr = '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final durationStr = durationSec != null ? '${durationSec ~/ 60} мин' : '';
    final isProcessing = item['status'] == 'processing';

    return GestureDetector(
      onTap: isProcessing ? null : () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MeetingSummaryDetailScreen(id: item['id'] as String)),
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.callHistoryMeetingTime(timeStr),
                    style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isProcessing) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.callHistoryProcessing, style: TextStyle(color: colors.primary, fontSize: 12)),
                ],
              ],
            ),
            if (participants.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(participants, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (durationStr.isNotEmpty) ...[
                  Text(durationStr, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                if (!isProcessing && actionItemsCount > 0)
                  Text('$actionItemsCount задач', style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                if (isProcessing)
                  Text(l10n.callHistoryTranscribing, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
            if (!isProcessing && summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary.length > 120 ? '${summary.substring(0, 120)}...' : summary,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Meeting Summary Detail Screen ───

class MeetingSummaryDetailScreen extends StatefulWidget {
  final String id;
  const MeetingSummaryDetailScreen({super.key, required this.id});
  @override
  State<MeetingSummaryDetailScreen> createState() => _MeetingSummaryDetailScreenState();
}

class _MeetingSummaryDetailScreenState extends State<MeetingSummaryDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await sl<DioClient>().get<dynamic>('/voice/meetings/${widget.id}');
    _data = Map<String, dynamic>.from(data as Map);
    return _data!;
  }

  void _share() {
    final l10n = AppLocalizations.of(context)!;
    final url = '${AppConfig.baseUrl}/meeting/${widget.id}';
    final summary = _data?['summary'] as String? ?? '';
    final text = summary.isNotEmpty
        ? '${l10n.callHistoryMeetingSummary}:\n${summary.length > 200 ? '${summary.substring(0, 200)}...' : summary}\n\n$url'
        : url;
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.callHistoryMeetingSummary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: l10n.callHistoryShare,
            onPressed: _share,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary));
          }
          if (snap.hasError) {
            return Center(child: Text(l10n.loadError, style: TextStyle(color: colors.error)));
          }
          final data = snap.data!;
          final summary = data['summary'] as String? ?? '';
          final keyPoints = (data['keyPoints'] as List?)?.cast<String>() ?? [];
          final actionItems = (data['actionItems'] as List?) ?? [];
          final decisions = (data['decisions'] as List?)?.cast<String>() ?? [];
          final transcript = data['transcript'] as String? ?? '';
          final participants = (data['participants'] as List?)?.join(', ') ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (participants.isNotEmpty) ...[
                Text(l10n.callHistoryParticipants, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(participants, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                const SizedBox(height: 20),
              ],
              if (summary.isNotEmpty) ...[
                _sectionTitle(l10n.callHistorySummary, Icons.summarize_rounded, colors),
                const SizedBox(height: 8),
                Text(summary, style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5)),
                const SizedBox(height: 20),
              ],
              if (keyPoints.isNotEmpty) ...[
                _sectionTitle(l10n.callHistoryKeyPoints, Icons.lightbulb_outline_rounded, colors),
                const SizedBox(height: 8),
                ...keyPoints.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('  •  ', style: TextStyle(color: colors.primary, fontSize: 14)),
                      Expanded(child: Text(p, style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.4))),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
              ],
              if (actionItems.isNotEmpty) ...[
                _sectionTitle(l10n.callHistoryTasks, Icons.task_alt_rounded, colors),
                const SizedBox(height: 8),
                ...actionItems.map((item) {
                  final task = item is Map ? (item['task'] as String? ?? '') : item.toString();
                  final assignee = item is Map ? (item['assignee'] as String?) : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                          if (assignee != null && assignee.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(l10n.callHistoryAssignedTo(assignee), style: TextStyle(color: colors.primary, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
              if (decisions.isNotEmpty) ...[
                _sectionTitle(l10n.callHistoryDecisions, Icons.check_circle_outline_rounded, colors),
                const SizedBox(height: 8),
                ...decisions.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d, style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.4))),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
              ],
              if (transcript.isNotEmpty) ...[
                _sectionTitle('Транскрипт', Icons.article_outlined, colors),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: Text(l10n.callHistoryShowTranscript, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        transcript,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.6, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, AppColorsExtension colors) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Meeting Recordings Screen ───

class MeetingRecordingsScreen extends StatefulWidget {
  const MeetingRecordingsScreen({super.key});
  @override
  State<MeetingRecordingsScreen> createState() => _MeetingRecordingsScreenState();
}

class _MeetingRecordingsScreenState extends State<MeetingRecordingsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _player = AudioPlayer();
  String? _playingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription> _subs = [];
  final Set<String> _transcribingIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
    _subs.add(_player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    }));
    _subs.add(_player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playingId = null; _position = Duration.zero; });
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(String id, String url) async {
    if (_playingId == id && _playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playingId == id && _playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.stop();
      setState(() { _playingId = id; _position = Duration.zero; });
      await _player.play(UrlSource(url));
    }
  }

  String _formatPos(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await sl<DioClient>().get<dynamic>('/voice/recordings');
    final items = data as List? ?? [];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _formatDate(DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0 && local.day == now.day) return l10n.callHistoryTodayTime(time);
    if (diff.inDays <= 1 && now.day - local.day == 1) return l10n.callHistoryYesterdayTime(time);
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}, $time';
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m < 60) return '${m}м ${s.toString().padLeft(2, '0')}с';
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}ч ${mm.toString().padLeft(2, '0')}м';
  }

  Future<void> _transcribe(String id) async {
    if (_transcribingIds.contains(id)) return;
    setState(() => _transcribingIds.add(id));
    try {
      await sl<DioClient>().post<dynamic>('/voice/recordings/$id/transcribe');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.callHistoryTranscriptCreated),
            backgroundColor: AppColors.of(context).primary,
          ),
        );
        final f = _load();
        setState(() { _future = f; });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _transcribingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.callHistoryMeetingRecordings)),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async { final f = _load(); setState(() { _future = f; }); },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary));
            }
            if (snap.hasError) {
              return Center(child: Text(l10n.loadError, style: TextStyle(color: colors.error)));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.fiber_manual_record_rounded, size: 48, color: colors.textSecondary),
                        const SizedBox(height: 12),
                        Text(l10n.callHistoryNoRecordings, style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          l10n.callHistoryRecordDuringCall,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _buildRecordingCard(items[i], colors),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> item, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final id = item['id'] as String? ?? '';
    final participants = (item['participants'] as List?)?.join(', ') ?? '';
    final durationSec = item['durationSec'] as int?;
    final createdAt = (DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now()).toLocal();
    final recordingUrl = item['recordingUrl'] as String? ?? '';
    final status = item['status'] as String? ?? 'done';
    final hasTranscript = item['hasTranscript'] as bool? ?? false;
    final hasSummary = item['hasSummary'] as bool? ?? false;
    final durationStr = durationSec != null ? _formatDuration(durationSec) : '';
    final isThis = _playingId == id;
    final isPlaying = isThis && _playerState == PlayerState.playing;
    final isTranscribing = _transcribingIds.contains(id) || status == 'processing';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fiber_manual_record_rounded, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.callHistoryRecordingDate(_formatDate(createdAt)),
                  style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (durationStr.isNotEmpty)
                Text(durationStr, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ],
          ),
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(participants, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          // Inline audio player
          if (recordingUrl.isNotEmpty) ...[
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    size: 40,
                    color: colors.primary,
                  ),
                  onPressed: () => _togglePlay(id, recordingUrl),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: colors.primary,
                          inactiveTrackColor: colors.border,
                          thumbColor: colors.primary,
                          overlayColor: colors.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: isThis && _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: isThis && _duration.inMilliseconds > 0
                              ? (v) => _player.seek(Duration(milliseconds: (v * _duration.inMilliseconds).round()))
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isThis ? _formatPos(_position) : '00:00',
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
                            ),
                            Text(
                              isThis && _duration > Duration.zero ? _formatPos(_duration) : '',
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.share_rounded, size: 20, color: colors.textSecondary),
                  onPressed: () => Share.share(
                    '${l10n.callHistoryMeetingRecording} ${_formatDate(createdAt)}\n${l10n.callHistoryParticipants}: $participants\n\n$recordingUrl',
                    subject: l10n.callHistoryMeetingRecording,
                  ),
                  tooltip: l10n.callHistoryShare,
                ),
              ],
            ),
          ] else ...[
            Text(l10n.callHistoryRecordingUnavailable, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
          // Protocol / Transcription button
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasTranscript || hasSummary)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MeetingSummaryDetailScreen(id: id)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          l10n.callHistoryTranscriptReady,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (isTranscribing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(l10n.callHistoryProcessing, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                )
              else if (!hasTranscript)
                TextButton.icon(
                  onPressed: () => _transcribe(id),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(l10n.callHistoryTranscript),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
