import 'dart:async';
import '../../../../core/platform/platform_utils.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/theme/linkified_text.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:share_plus/share_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/utils/share_helper.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:camera/camera.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/markdown_color_extension.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart';
import '../../../../core/services/wallpaper_service.dart';
import '../../../../core/theme/chat_wallpaper_painters.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/message_draft_service.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/services/chunked_upload_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/reply_preview_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import 'user_profile_screen.dart';
import '../../utils/unread_anchor.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/channel_details.dart';
import '../../domain/entities/conversation_read_state.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../widgets/typing_dots.dart';
import '../widgets/message_info_sheet.dart';
import '../widgets/analyst_streaming_bubble.dart';
import '../widgets/analyst_seam_widget.dart';
import '../widgets/pinned_banner.dart';
import '../../domain/entities/analyst_events.dart';
import '../../utils/recipient_filters.dart';
import '../../../../core/mesh/services/device_key_sync_service.dart';
import '../../../../features/mesh/presentation/bloc/mesh_status_bloc.dart';
import '../../../../features/mesh/domain/entities/mesh_status.dart';
import '../widgets/chat_transport_badge.dart';
import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../../../core/voice/mesh_peer_eligibility_watcher.dart';
import '../../../../core/voice/mesh_voice_ui_coordinator.dart';
import '../../../voice/presentation/widgets/ios_mesh_onboarding_tooltip.dart';
import '../../../voice/presentation/widgets/mesh_eligibility_dot.dart';
import 'chat_room_auto_pick.dart';
import 'pinned_messages_screen.dart';
import '../../../presence/presentation/widgets/presence_label.dart';

/// Per-process cache of "user explicitly used LiveKit with this peer at time T".
/// Drives the 30-minute sticky-LK heuristic in chatRoomAutoPickDecision.
/// In-memory only: a cold restart resets the heuristic, which is acceptable.
final Map<String, int> _recentLkCallMs = {};

/// Read-receipt helper (Task 12): whether any *other* participant has read
/// up to message [m], based on their read cursors. Used for both 1:1 and
/// group ticks (two ticks once anyone has read).
bool _readIn1to1(MessageEntity m, List<ParticipantCursor> cursors, String myId) =>
    cursors.any((c) => c.userId != myId && c.lastReadAt != null && !c.lastReadAt!.isBefore(m.sentAt));

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final List? sharedFiles;
  final String? topicId;
  final String? topicTitle;
  /// Deep-link target: message to scroll to and highlight after load
  /// (assistant action bubbles, Task 9).
  final String? highlightMessageId;
  const ChatRoomScreen({super.key, required this.conversationId, this.sharedFiles, this.topicId, this.topicTitle, this.highlightMessageId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final TextEditingController _ctrl;
  late final ScrollController _scrollCtrl;
  final _recorder = AudioRecorder();
  /// ID of video note that should auto-play next
  final ValueNotifier<String?> _autoPlayVideoNote = ValueNotifier(null);
  bool _isRecording = false;
  String? _recordingPath;
  double _prevKeyboardHeight = 0;
  Timer? _draftSyncTimer;
  /// Незавершённый @логин под курсором; null — подсказки не показываем.
  String? _mentionQuery;
  bool _membersRequested = false;
  MessageEntity? _replyTo;
  String? _replyToSenderName;
  MessageEntity? _editingMessage;

  /// Мультивыбор. Пустое множество означает, что режим выключен — отдельного
  /// флага нет намеренно, чтобы эти два состояния не могли разъехаться.
  final Set<String> _selectedIds = <String>{};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  /// Потолок выделения совпадает с лимитом пачки на сервере: лучше не дать
  /// выделить лишнее, чем получить отказ уже после нажатия «Переслать».
  static const _selectionLimit = 50;

  /// id первого непрочитанного сообщения — перед ним рисуется линия
  /// «Непрочитанные сообщения».
  ///
  /// Вычисляется один раз за открытие чата и дальше не двигается: иначе линия
  /// уползала бы вниз от каждого входящего, и вернуться к месту, где человек
  /// остановился, стало бы невозможно. [_unreadAnchorResolved] отличает
  /// «ещё не считали» от «посчитали и непрочитанных не было».
  String? _unreadAnchorId;
  bool _unreadAnchorResolved = false;
  bool _socketDisconnected = false;
  StreamSubscription? _disconnectSub;
  StreamSubscription? _reconnectSub;
  StreamSubscription? _outboundListenSub;
  StreamSubscription? _conversationReadSub;
  // Per-participant read cursors for this conversation (Task 12 receipts UI):
  // loaded once via fetchConversationReadState, then kept live from the
  // conversation_read socket stream.
  List<ParticipantCursor> _cursors = [];
  Timer? _typingTimer;
  bool _isTypingSent = false;
  late final MessengerBloc _messengerBloc;
  // Pending attachments (inline preview before send)
  final List<_PendingFile> _pendingFiles = [];
  // Block/contact status for DIRECT conversations
  bool _iBlockedThem = false;
  bool _theyBlockedMe = false;
  bool _isContact = true; // assume contact until loaded
  // Search in chat
  bool _searchMode = false;
  String _searchText = '';
  List<int> _searchMatchChronIndices = [];
  int _searchCurrentMatchIdx = -1;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, GlobalKey> _messageKeys = {};
  // Deep-link highlight (assistant action bubble → jump to message)
  bool _deepLinkHighlightDone = false;
  int _deepLinkLoadAttempts = 0;
  // Scroll-to-bottom button
  bool _showScrollToBottom = false;

  // Pinned messages bar (Task 12). Loaded lazily whenever the resolved
  // conversation's `pinnedCount` no longer matches `_pinsLoadedForCount` —
  // see `_loadPins` for why the count itself is never rendered.
  List<MessageEntity> _pins = [];
  int _pinsLoadedForCount = 0;

  // Viewport-driven read-horizon reporting (Telegram-style): tracks the
  // furthest incoming message actually scrolled into view, debounced.
  DateTime? _maxSeenAt;
  String? _maxSeenId;
  Timer? _readDebounce;

  void _onMessageSeen(MessageEntity m) {
    // VisibilityDetector can fire a late callback after this screen is disposed;
    // without this guard it would schedule a fresh 400ms timer that dispose
    // already ran past (dispose cancels the existing one), emitting one stale
    // mark_read. Harmless (monotonic server-side) but untidy — bail if gone.
    if (!mounted) return;
    if (_maxSeenAt == null || m.sentAt.isAfter(_maxSeenAt!)) {
      _maxSeenAt = m.sentAt;
      _maxSeenId = m.id;
    }
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_maxSeenAt != null && _maxSeenId != null) {
        sl<MessengerRemoteDataSource>()
            .emitMarkRead(widget.conversationId, _maxSeenAt!, _maxSeenId!);
      }
    });
  }

  /// Synthetic ConversationEntity used when a CHANNEL is opened via a deep
  /// link / directory and the user is not yet a member — so the conversation
  /// isn't in MessengerBloc.state.conversations. Fetched once on open.
  ConversationEntity? _channelFallbackConv;

  /// Locate the active conversation object, falling back to the synthesized
  /// CHANNEL entity when the user is not a participant.
  ConversationEntity? _resolveConv(List<ConversationEntity> convs) {
    for (final c in convs) {
      if (c.id == widget.conversationId) return c;
    }
    return _channelFallbackConv;
  }

  Future<void> _fetchChannelFallbackIfNeeded() async {
    // Only fetch if conversation is not already in the bloc.
    final inBloc = _messengerBloc.state.conversations
        .any((c) => c.id == widget.conversationId);
    if (inBloc) return;
    try {
      final ChannelDetails d =
          await sl<MessengerRemoteDataSource>().getChannelDetails(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _channelFallbackConv = ConversationEntity(
          id: d.id,
          participantIds: const [],
          type: 'CHANNEL',
          name: d.name,
          description: d.description,
          avatarUrl: d.avatarUrl,
          myRole: d.myRole,
          subscribersCount: d.subscribersCount,
          isSubscribed: d.isSubscribed,
        );
      });
    } catch (_) {
      // Not a channel (or 404) — leave fallback null; existing code handles it.
    }
  }

  // Stable key for persisting unsent drafts (topics get their own draft).
  String get _draftKey => widget.topicId != null
      ? '${widget.conversationId}:${widget.topicId}'
      : widget.conversationId;

  @override
  void initState() {
    super.initState();
    _messengerBloc = context.read<MessengerBloc>();
    // Черновик: сервер — источник правды (он же виден со второго устройства),
    // локальный Hive остаётся запасным на случай, когда список бесед ещё не
    // загружен или сети не было.
    //
    // Серверный черновик хранится на беседе целиком, поэтому у топиков он
    // по-прежнему только локальный — иначе черновики разных топиков затирали
    // бы друг друга.
    final localDraft = sl<MessageDraftService>().getDraft(_draftKey);
    String? serverDraft;
    if (widget.topicId == null) {
      for (final c in _messengerBloc.state.conversations) {
        if (c.id == widget.conversationId) {
          serverDraft = c.draft;
          break;
        }
      }
    }
    _ctrl = TextEditingController(text: serverDraft ?? localDraft ?? '');
    _ctrl.addListener(_onTextChanged);
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScrollChanged);
    _messengerBloc.add(OpenConversation(widget.conversationId, topicId: widget.topicId));
    // NOTE: read-state is now reported per viewport visibility (see
    // _onMessageSeen/VisibilityDetector in the message list below), not
    // blanket-marked on open — matches Telegram-style read horizons.
    _loadBlockStatus();
    // Handle shared files from external apps
    if (widget.sharedFiles != null && widget.sharedFiles!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addSharedFiles(widget.sharedFiles!);
      });
    }
    // Phase 1e — prime mesh auth by fetching this contact's device certs.
    // Fire-and-forget; failures don't block chat UX.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactId = _resolveContactUserId();
      if (contactId == null) return;
      debugPrint('[mesh-chat] ChatRoomScreen opening — calling fetchContactKeys($contactId)');
      sl<DeviceKeySyncService>().fetchContactKeys(contactId).then((_) {
        debugPrint('[mesh-chat] fetchContactKeys($contactId) completed');
      }).catchError((Object e, StackTrace st) {
        debugPrint('[mesh-chat] fetchContactKeys($contactId) FAILED: $e');
      });
    });
    // Listen for socket connectivity changes
    final ds = sl<MessengerRemoteDataSource>();
    _disconnectSub = ds.disconnectStream.listen((_) {
      if (mounted) setState(() => _socketDisconnected = true);
    });
    _reconnectSub = ds.reconnectStream.listen((_) {
      if (mounted) setState(() => _socketDisconnected = false);
    });
    _fetchChannelFallbackIfNeeded();
    _outboundListenSub = ds.outboundListenStream.listen((data) {
      if (!mounted) return;
      final businessName = data['businessName'] as String? ?? '';
      final token = data['token'] as String? ?? '';
      final wsUrl = data['wsUrl'] as String? ?? '';
      if (token.isEmpty || wsUrl.isEmpty) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _OutboundListenSheet(
          businessName: businessName,
          token: token,
          wsUrl: wsUrl,
        ),
      );
    });
    // Read-receipt cursors: initial fetch + live updates (Task 12).
    _loadReadCursors();
    _conversationReadSub = ds.conversationReadStream.listen((data) {
      if (!mounted) return;
      final convId = data['conversationId'] as String?;
      if (convId != widget.conversationId) return;
      final userId = data['userId'] as String?;
      if (userId == null) return;
      final lastReadAtRaw = data['lastReadAt'] as String?;
      final lastReadAt = lastReadAtRaw != null ? DateTime.tryParse(lastReadAtRaw) : null;
      setState(() {
        final updated = ParticipantCursor(userId: userId, lastReadAt: lastReadAt);
        final idx = _cursors.indexWhere((c) => c.userId == userId);
        if (idx >= 0) {
          _cursors[idx] = updated;
        } else {
          _cursors = [..._cursors, updated];
        }
      });
    });
  }

  /// Loads this conversation's participant read cursors (used for own-message
  /// receipts: 1:1 colored ticks + group "Seen by N"). Non-fatal on failure —
  /// footers just fall back to whatever the legacy per-message isRead signal
  /// already provides until this succeeds.
  Future<void> _loadReadCursors() async {
    try {
      final raw = await sl<MessengerRemoteDataSource>()
          .fetchConversationReadState(widget.conversationId);
      if (!mounted) return;
      setState(() => _cursors = parseParticipantCursors(raw));
    } catch (e) {
      debugPrint('[ChatRoomScreen] fetchConversationReadState failed: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kh = MediaQuery.of(context).viewInsets.bottom;
    if (kh > _prevKeyboardHeight) {
      // With reverse:true, bottom of chat is offset 0
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _prevKeyboardHeight = kh;
  }

  void _setReply(MessageEntity msg, String? senderName) {
    setState(() {
      _replyTo = msg;
      _replyToSenderName = senderName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
      _replyToSenderName = null;
    });
  }

  void _startEditing(MessageEntity message) {
    setState(() {
      _editingMessage = message;
      _replyTo = null;
      _replyToSenderName = null;
    });
    _ctrl.text = message.content;
    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
  }

  void _cancelEditing() {
    setState(() => _editingMessage = null);
    _ctrl.clear();
  }

  void _handleMenuAction(String action, bool isMuted) {
    if (action == 'mute') {
      if (isMuted) {
        context.read<MessengerBloc>().add(UnmuteConversation(widget.conversationId));
      } else {
        _showMuteDurationSheet();
      }
    } else if (action == 'channel_settings') {
      context.push('/dashboard/messenger/${widget.conversationId}/channel-settings');
    } else if (action == 'channel_delete') {
      _confirmDeleteChannel();
    } else if (action == 'channel_unsubscribe') {
      _confirmUnsubscribeChannel();
    }
  }

  Future<void> _confirmDeleteChannel() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.channelsDelete),
        content: Text(l10n.channelsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.channelsDelete,
              style: TextStyle(color: AppColors.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sl<MessengerRemoteDataSource>().deleteChannel(widget.conversationId);
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
    }
  }

  Future<void> _confirmUnsubscribeChannel() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.channelsUnsubscribe),
        content: Text(l10n.channelsUnsubscribe),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.channelsUnsubscribe,
              style: TextStyle(color: AppColors.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sl<MessengerRemoteDataSource>().unsubscribeFromChannel(widget.conversationId);
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
    }
  }

  Future<void> _subscribeChannel() async {
    try {
      await sl<MessengerRemoteDataSource>().subscribeToChannel(widget.conversationId);
      if (!mounted) return;
      context.read<MessengerBloc>().add(LoadConversations());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
    }
  }

  void _showMuteDurationSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.muteNotifications,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor1Hour, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 60));
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor8Hours, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 480));
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor2Days, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 2880));
              },
            ),
            ListTile(
              leading: Icon(Icons.volume_off, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteForever, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _joinActiveCall(String roomName) async {
    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatAlreadyInCall),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }
    if (mounted) {
      final conv = context.read<MessengerBloc>().state.conversations
          .where((c) => c.id == widget.conversationId)
          .firstOrNull;
      final calleeName = conv?.type == 'GROUP' ? conv?.name : conv?.otherUserName;
      final calleeAvatar = conv?.type == 'GROUP' ? conv?.avatarUrl : conv?.otherUserAvatar;
      final calleeParam = calleeName != null && calleeName.isNotEmpty
          ? '&callee=${Uri.encodeComponent(calleeName)}'
          : '';
      final avatarParam = calleeAvatar != null && calleeAvatar.isNotEmpty
          ? '&calleeAvatar=${Uri.encodeComponent(calleeAvatar)}'
          : '';
      var calleeId = conv?.type == 'DIRECT' ? conv?.otherUserId : null;
      if (calleeId == null && conv != null && conv.type == 'DIRECT' && conv.participantIds.length == 2) {
        final myId = await sl<SecureStorageService>().getUserId();
        if (myId != null) {
          calleeId = conv.participantIds.firstWhere((id) => id != myId, orElse: () => '');
          if (calleeId!.isEmpty) calleeId = null;
        }
      }
      final calleeIdParam = calleeId != null && calleeId.isNotEmpty
          ? '&calleeId=$calleeId'
          : '';
      context.push('/dashboard/voice?room=$roomName&convId=${widget.conversationId}$calleeParam$avatarParam$calleeIdParam');
    }
  }

  Future<void> _loadBlockStatus() async {
    try {
      final conv = context.read<MessengerBloc>().state.conversations
          .where((c) => c.id == widget.conversationId)
          .firstOrNull;
      final otherUserId = conv?.otherUserId;
      if (otherUserId == null || conv?.type != 'DIRECT') return;
      final cs = await sl<DioClient>().get(
        '/messenger/contacts/check/$otherUserId',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (mounted) {
        setState(() {
          _iBlockedThem = cs['iBlockedThem'] as bool? ?? false;
          _theyBlockedMe = cs['isBlocked'] as bool? ?? false;
          _isContact = cs['isContact'] as bool? ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _showTransportPopup() async {
    // Desktop: mesh transport unavailable — go straight to LK.
    if (!PlatformUtils.instance.isMobile) {
      return _startLkCall();
    }
    final l10n = AppLocalizations.of(context)!;
    final conv = _resolveConv(context.read<MessengerBloc>().state.conversations);
    if (conv?.type != 'DIRECT') return;
    final otherUserId = conv?.otherUserId;
    if (otherUserId == null) return;

    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.callConflictAlreadyInCall),
        backgroundColor: AppColors.of(context).error,
      ));
      return;
    }

    final watcher = sl<MeshPeerEligibilityWatcher>();
    final isMeshAvailable = watcher.isUserOnline(otherUserId);

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.callPopupTransportTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                key: const Key('chat-popup-mesh'),
                leading: Icon(
                  Icons.wifi_tethering,
                  color: isMeshAvailable ? Colors.green : Colors.grey,
                ),
                title: Text(l10n.callPopupTransportMesh),
                subtitle: isMeshAvailable
                    ? null
                    : Text(l10n.callPopupTransportMeshUnavailable),
                enabled: isMeshAvailable,
                onTap: !isMeshAvailable
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        await IosMeshOnboardingTooltip.showIfNeeded(context);
                        if (mounted) await _startMeshCall(otherUserId);
                      },
              ),
              ListTile(
                key: const Key('chat-popup-lk'),
                leading: Icon(Icons.phone, color: AppColors.of(context).primary),
                title: Text(l10n.callPopupTransportLk),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startLkCall();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _callStarting = false;
  Future<void> _autoPickCall() async {
    // Debounce: without this, a second tap during the async room-create starts a
    // SECOND simultaneous call to the same destination (two rooms/rings, crossed
    // teardowns). Reset in finally so a later, legitimate call still works.
    if (_callStarting) return;
    _callStarting = true;
    try {
      await _autoPickCallInner();
    } finally {
      _callStarting = false;
    }
  }

  Future<void> _autoPickCallInner() async {
    // Desktop: mesh transport unavailable — always use LK.
    if (!PlatformUtils.instance.isMobile) {
      return _startLkCall();
    }
    final l10n = AppLocalizations.of(context)!;
    final conv = _resolveConv(context.read<MessengerBloc>().state.conversations);
    final otherUserId = conv?.type == 'DIRECT' ? conv?.otherUserId : null;
    final watcher = sl<MeshPeerEligibilityWatcher>();

    final decision = chatRoomAutoPickDecision(
      convType: conv?.type,
      otherUserId: otherUserId,
      isInCall: CallStateService.instance.isInCall,
      canAddLine: CallStateService.instance.canAddLine,
      isUserOnline: otherUserId != null && watcher.isUserOnline(otherUserId),
      recentLkCallMs: otherUserId == null ? null : _recentLkCallMs[otherUserId],
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );

    switch (decision) {
      case AutoPickDecision.conflict:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.callConflictAlreadyInCall),
          backgroundColor: AppColors.of(context).error,
        ));
        return;
      case AutoPickDecision.lk:
        return _startLkCall();
      case AutoPickDecision.mesh:
        await IosMeshOnboardingTooltip.showIfNeeded(context);
        if (mounted) await _startMeshCall(otherUserId!);
        return;
    }
  }

  Future<void> _startMeshCall(String userId) async {
    final keyStore = sl<HiveContactKeyStore>();
    // Phase 3d hotfix: prefer a device the watcher has CURRENTLY discovered
    // on the local network. Server data sometimes returns multiple userPks
    // per contact (re-registration / multi-account history); the previous
    // logic picked the first device sorted by hex under the primary userPk
    // only, which often pointed to an offline phone — Noise handshake then
    // hung the full 10s before falling back to LK.
    final watcher = sl<MeshPeerEligibilityWatcher>();
    final online = watcher.onlineDevicesForUser(userId);
    if (online.isNotEmpty) {
      final pick = (online.toList()
            ..sort((a, b) => a.toHex().compareTo(b.toHex())))
          .first;
      try {
        await sl<MeshVoiceUiCoordinator>().placeCall(pick);
        return;
      } catch (e) {
        debugPrint('[chat-room] mesh placeCall (online) failed: $e — falling back to LK');
        return _startLkCall();
      }
    }
    // No discovered device — fall back to the legacy "primary userPk" path
    // (still useful when the watcher hasn't bridged yet but a stored cert
    // has a known device). If even that has nothing, hand off to LK.
    final userPk = keyStore.userPkForContactUserId(userId);
    if (userPk == null) {
      debugPrint('[chat-room] mesh fallback: userPk for $userId not in store, falling back to LK');
      return _startLkCall();
    }
    final devices = keyStore.devicesFor(userPk);
    if (devices.isEmpty) return _startLkCall();
    final ordered = devices.toList()
      ..sort((a, b) => a.toHex().compareTo(b.toHex()));
    try {
      await sl<MeshVoiceUiCoordinator>().placeCall(ordered.first);
    } catch (e) {
      debugPrint('[chat-room] mesh placeCall failed: $e — falling back to LK');
      return _startLkCall();
    }
  }

  Future<void> _startLkCall() async {
    debugPrint('[ChatRoom] _startLkCall called');
    // Record this LK call for the 30-minute sticky-transport heuristic.
    final convForRecency = _resolveConv(context.read<MessengerBloc>().state.conversations);
    if (convForRecency?.type == 'DIRECT' && convForRecency?.otherUserId != null) {
      _recentLkCallMs[convForRecency!.otherUserId!] = DateTime.now().millisecondsSinceEpoch;
    }
    // Guard: only block when max lines reached
    if (CallStateService.instance.isInCall && !CallStateService.instance.canAddLine) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatAlreadyInCall),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }

    // Resolve callee display info from LOCAL state (fast) and navigate to the
    // call screen IMMEDIATELY with no room yet (outgoing=1). The screen shows
    // "Calling…" instantly and does the room-create + call_invite itself —
    // removing the ~10s dead-tap where createRoom blocked before any UI appeared.
    final allConvs = context.read<MessengerBloc>().state.conversations;
    final _conv = allConvs.where((c) => c.id == widget.conversationId).firstOrNull;
    final calleeName = _conv?.type == 'GROUP' ? _conv?.name : _conv?.otherUserName;
    final calleeAvatar = _conv?.type == 'GROUP' ? _conv?.avatarUrl : _conv?.otherUserAvatar;
    final calleeParam = calleeName != null && calleeName.isNotEmpty
        ? '&callee=${Uri.encodeComponent(calleeName)}'
        : '';
    final avatarParam = calleeAvatar != null && calleeAvatar.isNotEmpty
        ? '&calleeAvatar=${Uri.encodeComponent(calleeAvatar)}'
        : '';
    var calleeId = _conv?.type == 'DIRECT' ? _conv?.otherUserId : null;
    if (calleeId == null && _conv != null && _conv.type == 'DIRECT' && _conv.participantIds.length == 2) {
      final myId = await sl<SecureStorageService>().getUserId();
      if (myId != null) {
        calleeId = _conv.participantIds.firstWhere((id) => id != myId, orElse: () => '');
        if (calleeId!.isEmpty) calleeId = null;
      }
    }
    final calleeIdParam = calleeId != null && calleeId.isNotEmpty
        ? '&calleeId=$calleeId'
        : '';
    if (mounted) {
      context.push('/dashboard/voice?convId=${widget.conversationId}$calleeParam$avatarParam$calleeIdParam&outgoing=1');
    }
  }

  void _showAttachMenu() {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachItem(
                    ctx: ctx,
                    icon: Icons.photo_library_rounded,
                    color: const Color(0xFF4CAF50),
                    label: l10n.chatPhotoVideo,
                    onTap: _pickMediaFromGallery,
                  ),
                  _attachItem(
                    ctx: ctx,
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFF2196F3),
                    label: l10n.chatCamera,
                    onTap: _pickFromCamera,
                  ),
                  _attachItem(
                    ctx: ctx,
                    icon: Icons.insert_drive_file_rounded,
                    color: const Color(0xFFFF9800),
                    label: l10n.chatFile,
                    onTap: _pickFile,
                  ),
                  _attachItem(
                    ctx: ctx,
                    icon: Icons.person_rounded,
                    color: const Color(0xFF9C27B0),
                    label: l10n.chatContact,
                    onTap: _pickContact,
                  ),
                  _attachItem(
                    ctx: ctx,
                    icon: Icons.poll_rounded,
                    color: const Color(0xFFE91E63),
                    label: l10n.messengerPoll,
                    onTap: _showCreatePoll,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachItem({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreatePoll() {
    final colors = AppColors.of(context);
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];
    bool isAnonymous = false;
    bool isMultiple = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.messengerCreatePoll, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: questionCtrl,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.messengerPollQuestion,
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(optionCtrls.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: optionCtrls[i],
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.messengerPollOption(i + 1),
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
                          ),
                        ),
                      ),
                      if (optionCtrls.length > 2)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: colors.error),
                          onPressed: () => setSheetState(() => optionCtrls.removeAt(i)),
                        ),
                    ],
                  ),
                )),
                if (optionCtrls.length < 10)
                  TextButton.icon(
                    onPressed: () => setSheetState(() => optionCtrls.add(TextEditingController())),
                    icon: Icon(Icons.add, color: colors.primary),
                    label: Text(AppLocalizations.of(context)!.messengerPollAddOption, style: TextStyle(color: colors.primary)),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.messengerPollAnonymous, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                  value: isAnonymous,
                  activeColor: colors.primary,
                  onChanged: (v) => setSheetState(() => isAnonymous = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.messengerPollMultiple, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                  value: isMultiple,
                  activeColor: colors.primary,
                  onChanged: (v) => setSheetState(() => isMultiple = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.black),
                    onPressed: () async {
                      final question = questionCtrl.text.trim();
                      final options = optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                      if (question.isEmpty || options.length < 2) return;
                      Navigator.pop(ctx);
                      try {
                        await sl<DioClient>().post(
                          '/messenger/conversations/${widget.conversationId}/poll',
                          data: {
                            'question': question,
                            'options': options,
                            'isAnonymous': isAnonymous,
                            'isMultiple': isMultiple,
                          },
                          fromJson: (d) => d,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.messengerPollCreateError), backgroundColor: colors.error),
                          );
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.create, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMediaFromGallery() async {
    setState(() => _isPreparing = true);
    try {
      final assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 9,
          requestType: RequestType.common,
          themeColor: AppColors.of(context).primary,
        ),
      );
      if (!mounted) return;
      if (assets == null || assets.isEmpty) return;
      for (final asset in assets) {
        final file = await asset.file;
        if (file == null || !mounted) continue;
        final type = asset.type == AssetType.video ? 'video' : 'image';
        setState(() {
          _pendingFiles.add(_PendingFile(path: file.path, name: asset.title ?? file.path.split('/').last, type: type));
        });
      }
    } catch (_) {
      // ignore picker errors
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _pendingFiles.add(_PendingFile(path: picked.path, name: picked.name, type: 'image'));
    });
  }

  void _addSharedFiles(List sharedFiles) {
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    final textParts = <String>[];
    setState(() {
      for (final file in sharedFiles) {
        // 1.0.69 fix: detect text / url shares (e.g. "Share new meeting link"
        // from VoiceCallScreen) and append them to the compose field instead
        // of treating the URL string as a file path. Without this, the room
        // link was uploaded as an attachment, which silently failed (no valid
        // file at that path) and nothing appeared in the chat.
        if (file is SharedMediaFile &&
            (file.type == SharedMediaType.text ||
                file.type == SharedMediaType.url)) {
          if (file.path.isNotEmpty) textParts.add(file.path);
          // iOS sometimes sends an accompanying message alongside a URL share.
          final msg = file.message;
          if (msg != null && msg.isNotEmpty && msg != file.path) {
            textParts.add(msg);
          }
          continue;
        }
        var path = (file is SharedMediaFile)
            ? file.path
            : (file.path as String? ?? '');
        if (path.isEmpty) continue;
        // Normalize: strip file:// prefix
        if (path.startsWith('file://')) path = Uri.parse(path).toFilePath();
        final name = path.split('/').last;
        final ext = name.split('.').last.toLowerCase();
        String? typeOverride;
        if (imageExts.contains(ext)) typeOverride = 'image';
        if (videoExts.contains(ext)) typeOverride = 'video';
        _pendingFiles.add(_PendingFile(path: path, name: name, type: typeOverride));
      }
      if (textParts.isNotEmpty) {
        // Append shared text into the compose field. Preserve any draft the
        // user already had — separate with a newline. Don't auto-send: text
        // shares are typically previews the user wants to confirm before
        // sending (vs. file shares which auto-upload).
        final existing = _ctrl.text;
        final addition = textParts.join('\n');
        _ctrl.text = existing.isEmpty ? addition : '$existing\n$addition';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      }
    });
    // Auto-send only file attachments — text shares stay in compose for review.
    if (_pendingFiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingFiles.isNotEmpty) _sendPendingAttachment();
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isPreparing = true);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
    } catch (_) {
      // ignore picker errors
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
    if (!mounted || result == null || result!.files.isEmpty) return;
    final pickedFiles = result!.files;
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    setState(() {
      for (final file in pickedFiles) {
        if (file.path == null) continue;
        final ext = file.name.split('.').last.toLowerCase();
        String? typeOverride;
        if (imageExts.contains(ext)) typeOverride = 'image';
        if (videoExts.contains(ext)) typeOverride = 'video';
        _pendingFiles.add(_PendingFile(path: file.path!, name: file.name, type: typeOverride));
      }
    });
  }

  void _pickContact() {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<MessengerBloc>();
    final convs = bloc.state.conversations.where((c) => c.type == 'DIRECT').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.chatSelectContact,
                    style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              if (convs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.chatNoContacts, style: TextStyle(color: colors.textSecondary)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: convs.length,
                    itemBuilder: (context, i) {
                      final c = convs[i];
                      final name = c.otherUserName ?? l10n.chatUser;
                      final avatar = c.otherUserAvatar;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primary,
                          backgroundImage: avatar != null && avatar.isNotEmpty
                              ? CachedNetworkImageProvider(avatar)
                              : null,
                          child: (avatar == null || avatar.isEmpty)
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(name, style: TextStyle(color: colors.textPrimary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          final contactJson = jsonEncode({'name': name, 'userId': c.otherUserId, 'avatar': c.otherUserAvatar ?? ''});
                          context.read<MessengerBloc>().add(SendMessage(widget.conversationId, '[CONTACT]$contactJson'));
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelPendingAttachment([int? index]) {
    setState(() {
      if (index != null) {
        _pendingFiles.removeAt(index);
      } else {
        _pendingFiles.clear();
      }
    });
  }

  Future<void> _sendPendingAttachment() async {
    if (_pendingFiles.isEmpty) return;
    final files = List<_PendingFile>.from(_pendingFiles);
    final caption = _ctrl.text.trim();
    setState(() => _pendingFiles.clear());
    _ctrl.clear();
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      try {
        await _uploadAndSendFile(f.path, f.name, typeOverride: f.type, caption: i == 0 && caption.isNotEmpty ? caption : null);
      } catch (_) {
        // Continue uploading remaining files even if one fails
      }
    }
  }

  bool _isPreparing = false;
  double? _uploadProgress;
  CancelToken? _uploadCancelToken;

  void _cancelUpload() {
    _uploadCancelToken?.cancel('User cancelled');
    _uploadCancelToken = null;
    setState(() => _uploadProgress = null);
  }

  Future<void> _uploadAndSendFile(String filePath, String fileName, {String? typeOverride, String? caption}) async {
    if (!File(filePath).existsSync()) return;
    _uploadCancelToken = CancelToken();
    setState(() => _uploadProgress = 0);
    try {
      final result = await ChunkedUploadService.upload(
        filePath: filePath,
        fileName: fileName,
        cancelToken: _uploadCancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() => _uploadProgress = null);
      // Use client-side type if known, fallback to backend
      final fileType = typeOverride ?? result.fileType;
      // Fix fileUrl if backend returns hardcoded prod URL on staging
      var fileUrl = result.fileUrl;
      final baseUrl = AppConfig.baseUrl;
      if (!fileUrl.startsWith(baseUrl)) {
        final uri = Uri.parse(fileUrl);
        final baseUri = Uri.parse(baseUrl);
        fileUrl = fileUrl.replaceFirst('${uri.scheme}://${uri.host}', '${baseUri.scheme}://${baseUri.host}');
      }
      final isMedia = fileType == 'image' || fileType == 'video' || fileType == 'audio';
      final String msgContent = caption ?? (isMedia ? '' : fileName);
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        msgContent,
        replyToId: _replyTo?.id,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: result.fileSize,
        fileType: fileType,
        s3Key: result.s3Key,
        thumbnailSmallUrl: result.thumbnailSmallUrl,
        thumbnailMediumUrl: result.thumbnailMediumUrl,
        thumbnailLargeUrl: result.thumbnailLargeUrl,
        fileRecordId: result.fileRecordId,
        topicId: widget.topicId,
      ));
      _cancelReply();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadProgress = null);
      _uploadCancelToken = null;
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      final errMsg = (e is DioException && e.response?.statusCode != null)
          ? 'Server error (${e.response!.statusCode}). Try again later.'
          : 'Upload failed. Check your connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_editingMessage != null) {
      final msg = _editingMessage!;
      context.read<MessengerBloc>().add(EditMessage(
        conversationId: msg.conversationId,
        messageId: msg.id,
        newContent: text,
      ));
      _ctrl.clear();
      _cancelEditing();
      return;
    }
    // Цитата больше не вклеивается в текст: ответ — это связь между строками,
    // а не префикс. Сервер вернёт превью оригинала в самом сообщении.
    context.read<MessengerBloc>().add(SendMessage(
          widget.conversationId,
          text,
          topicId: widget.topicId,
          replyToId: _replyTo?.id,
        ));
    // Stop typing indicator on send
    if (_isTypingSent) {
      _isTypingSent = false;
      _typingTimer?.cancel();
      context.read<MessengerBloc>().add(SendTyping(conversationId: widget.conversationId, isTyping: false));
    }
    _ctrl.clear();
    // Сообщение ушло — черновика больше нет. Без этого на другом устройстве
    // висел бы текст, который здесь уже отправлен.
    _draftSyncTimer?.cancel();
    if (widget.topicId == null) {
      _messengerBloc.add(SaveDraft(conversationId: widget.conversationId, text: ''));
    }
    _cancelReply();
    // With reverse:true, new messages appear at offset 0
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission || !mounted) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _isRecording = true; _recordingPath = path; });
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await _recorder.stop();
    setState(() { _isRecording = false; });
    if (path == null || !mounted) return;
    try {
      final client = sl<DioClient>();
      final file = File(path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.m4a'),
      });
      final res = await client.post(
        '/messenger/files',
        data: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        l10n.chatVoiceMessage,
        fileUrl: res['fileUrl'] as String,
        fileName: res['fileName'] as String,
        fileSize: res['fileSize'] as int?,
        fileType: 'audio',
        topicId: widget.topicId,
      ));
      file.deleteSync();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  String? _videoNoteLocalPath; // local path for preview while uploading
  double? _videoNoteProgress;
  bool _videoRecording = false; // inline video recorder is active
  final GlobalKey<_VideoNoteOverlayState> _videoOverlayKey = GlobalKey();

  /// Show inline video recorder overlay (called on long press of video button)
  void _startVideoRecording() {
    setState(() => _videoRecording = true);
  }

  /// Stop recording and send (called on long press release)
  void _stopVideoRecording() {
    _videoOverlayKey.currentState?.stopAndSend();
  }

  /// Called when video recording is done with a file path
  Future<void> _onVideoRecorded(String path) async {
    setState(() { _videoRecording = false; _videoNoteLocalPath = path; _videoNoteProgress = 0; });
    try {
      final client = sl<DioClient>();
      final ext = path.split('.').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'video_note.$ext'),
      });
      final res = await client.uploadFile<Map<String, dynamic>>(
        '/messenger/files',
        formData: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
        onProgress: (sent, total) {
          if (mounted && total > 0) setState(() => _videoNoteProgress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() { _videoNoteLocalPath = null; _videoNoteProgress = null; });
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        AppLocalizations.of(context)!.messengerVideoMessage,
        fileUrl: res['fileUrl'] as String,
        fileName: res['fileName'] as String,
        fileSize: res['fileSize'] as int?,
        fileType: 'video_note',
        thumbnailSmallUrl: res['thumbnailSmallUrl'] as String?,
        thumbnailMediumUrl: res['thumbnailMediumUrl'] as String?,
        topicId: widget.topicId,
      ));
      try { File(path).deleteSync(); } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() { _videoNoteLocalPath = null; _videoNoteProgress = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.messengerVideoRecordError), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _onVideoCancelled() {
    setState(() => _videoRecording = false);
  }

  /// Returns the other user's userId for 1:1 (DIRECT) chats, null for groups/bots.
  String? _resolveContactUserId() {
    final conv = _messengerBloc.state.conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    return conv?.type == 'DIRECT' ? conv?.otherUserId : null;
  }

  /// Returns (badgeState, visibleCount, totalCount) for ChatTransportBadge.
  /// Group chats use meshGroup + counts; 1:1 chats use the existing logic.
  (TransportBadgeState, int?, int?) _selectBadgeState(
      MeshStatus meshState, bool socketConnected) {
    final conv = _messengerBloc.state.conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    final isGroup = conv?.type == 'GROUP';
    if (isGroup && conv != null) {
      final myUserId = _messengerBloc.state.currentUserId;
      final others =
          conv.participantIds.where((p) => p != myUserId).toList();
      final visibleCount =
          sl<MeshStatusBloc>().visibleParticipantsOf(others).length;
      final totalCount = others.length;
      if (socketConnected) {
        return (TransportBadgeState.server, null, null);
      }
      if (visibleCount > 0) {
        return (TransportBadgeState.meshGroup, visibleCount, totalCount);
      }
      return (TransportBadgeState.queued, null, null);
    }
    // 1:1 path — unchanged
    final contactId = _resolveContactUserId();
    final peerVisible = contactId != null &&
        (meshState.visibilityByContactUserId[contactId] ?? false);
    final badgeState = socketConnected
        ? TransportBadgeState.server
        : (peerVisible ? TransportBadgeState.mesh : TransportBadgeState.queued);
    return (badgeState, null, null);
  }

  /// Отправка черновика на сервер с задержкой.
  ///
  /// Без неё каждое нажатие клавиши превращалось бы в запрос. Полторы секунды
  /// тишины — компромисс: на другом устройстве черновик появляется почти
  /// сразу, а сеть не захлёбывается.
  ///
  /// У топиков серверного черновика нет (см. initState), поэтому и синхронизировать
  /// нечего.
  void _scheduleDraftSync() {
    if (widget.topicId != null) return;
    _draftSyncTimer?.cancel();
    _draftSyncTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _messengerBloc.add(SaveDraft(
        conversationId: widget.conversationId,
        text: _ctrl.text,
      ));
    });
  }

  /// Ловит незавершённый `@логин` слева от курсора.
  ///
  /// Смотрим именно на позицию курсора, а не на весь текст: иначе подсказки
  /// вылезали бы при правке начала сообщения, где упоминание давно дописано.
  void _updateMentionQuery() {
    final sel = _ctrl.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }
    final upToCursor = _ctrl.text.substring(0, sel.baseOffset);
    final match = RegExp(r'(?<![\w@])@([A-Za-z0-9_]{0,32})$').firstMatch(upToCursor);
    final next = match?.group(1);
    if (next != _mentionQuery) setState(() => _mentionQuery = next);
  }

  /// Кандидаты на подстановку: участники этой беседы, у которых есть логин.
  List<GroupMemberEntity> _mentionCandidates(MessengerState state) {
    final q = _mentionQuery;
    if (q == null) return const [];
    final members = state.groupMembers[widget.conversationId] ?? const [];
    final lower = q.toLowerCase();
    final me = state.currentUserId;
    return members
        .where((m) => (m.username ?? '').isNotEmpty && m.userId != me)
        .where((m) {
          if (lower.isEmpty) return true;
          final u = m.username!.toLowerCase();
          final name = [m.firstName, m.lastName].whereType<String>().join(' ').toLowerCase();
          return u.startsWith(lower) || name.contains(lower);
        })
        .take(6)
        .toList();
  }

  /// Подставляет выбранный логин вместо набранного куска.
  void _insertMention(String username) {
    final sel = _ctrl.selection;
    final upToCursor = _ctrl.text.substring(0, sel.baseOffset);
    final match = RegExp(r'(?<![\w@])@([A-Za-z0-9_]{0,32})$').firstMatch(upToCursor);
    if (match == null) return;
    final before = _ctrl.text.substring(0, match.start);
    final after = _ctrl.text.substring(sel.baseOffset);
    final inserted = '@$username ';
    _ctrl.value = TextEditingValue(
      text: '$before$inserted$after',
      selection: TextSelection.collapsed(offset: before.length + inserted.length),
    );
    setState(() => _mentionQuery = null);
  }

  void _onTextChanged() {
    _updateMentionQuery();
    // Локально — сразу: это дешёво и переживает убийство приложения.
    sl<MessageDraftService>().saveDraft(_draftKey, _ctrl.text);
    _scheduleDraftSync();
    final bloc = context.read<MessengerBloc>();
    if (_ctrl.text.isNotEmpty && !_isTypingSent) {
      _isTypingSent = true;
      bloc.add(SendTyping(conversationId: widget.conversationId, isTyping: true));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTypingSent) {
        _isTypingSent = false;
        bloc.add(SendTyping(conversationId: widget.conversationId, isTyping: false));
      }
    });
  }

  @override
  void dispose() {
    // Send typing stop on exit — use cached bloc reference (context is deactivated in dispose)
    if (_isTypingSent) {
      _messengerBloc.add(SendTyping(conversationId: widget.conversationId, isTyping: false));
    }
    // Clear unread count and refresh conversations list on exit
    _messengerBloc.add(MarkConversationRead(widget.conversationId));
    _messengerBloc.add(LoadConversations());
    _typingTimer?.cancel();
    // Незавершённый debounce отправляем немедленно: иначе выход из чата в
    // первые полторы секунды после набора терял бы черновик для других
    // устройств.
    if (_draftSyncTimer?.isActive ?? false) {
      _draftSyncTimer!.cancel();
      if (widget.topicId == null) {
        _messengerBloc.add(SaveDraft(
          conversationId: widget.conversationId,
          text: _ctrl.text,
        ));
      }
    }
    _draftSyncTimer?.cancel();
    _readDebounce?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _disconnectSub?.cancel();
    _reconnectSub?.cancel();
    _outboundListenSub?.cancel();
    _conversationReadSub?.cancel();
    super.dispose();
  }

  bool _loadingOlder = false;
  bool _hasMoreMessages = true;
  DateTime? _lastLoadTime;
  /// Locally cached message list — survives BlocBuilder rebuilds without scroll jump
  List<MessageEntity> _cachedMessages = [];
  String? _lastKnownCursor;
  double? _scrollOffsetBeforeLoad;

  void _syncMessages(List<MessageEntity> blocMessages, String? cursor) {
    final grew = blocMessages.length > _cachedMessages.length;
    _cachedMessages = List.from(blocMessages);
    _lastKnownCursor = cursor;
    _hasMoreMessages = cursor != null;
    // If list grew and we saved offset before load — restore it after layout
    if (grew && _scrollOffsetBeforeLoad != null) {
      final savedOffset = _scrollOffsetBeforeLoad!;
      _scrollOffsetBeforeLoad = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollCtrl.hasClients) return;
        // Clamp to valid range
        final clamped = savedOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
        _scrollCtrl.jumpTo(clamped);
      });
    }
  }

  void _onScrollChanged() {
    if (!_scrollCtrl.hasClients) return;
    final show = _scrollCtrl.offset > 200;
    if (show != _showScrollToBottom) setState(() => _showScrollToBottom = show);
    if (!_loadingOlder && _hasMoreMessages) {
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      if (_scrollCtrl.offset > maxScroll - 300) {
        final now = DateTime.now();
        if (_lastLoadTime != null && now.difference(_lastLoadTime!).inMilliseconds < 1000) return;
        _lastLoadTime = now;
        _loadingOlder = true;
        // Save current offset so we can restore scroll position after new items load
        _scrollOffsetBeforeLoad = _scrollCtrl.offset;
        _messengerBloc.add(LoadMoreMessages(widget.conversationId));
      }
    }
  }

  void _enterSearchMode() => setState(() {
        _searchMode = true;
        _searchText = '';
        _searchMatchChronIndices = [];
        _searchCurrentMatchIdx = -1;
      });

  void _exitSearchMode() {
    _searchCtrl.clear();
    setState(() {
      _searchMode = false;
      _searchText = '';
      _searchMatchChronIndices = [];
      _searchCurrentMatchIdx = -1;
    });
  }

  void _performSearch(String query) {
    final messages = _messengerBloc.state.messages[widget.conversationId] ?? [];
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() {
        _searchText = '';
        _searchMatchChronIndices = [];
        _searchCurrentMatchIdx = -1;
      });
      return;
    }
    final indices = <int>[];
    for (int i = 0; i < messages.length; i++) {
      if (!messages[i].isSystem &&
          messages[i].content.toLowerCase().contains(q)) {
        indices.add(i);
      }
    }
    setState(() {
      _searchText = query;
      _searchMatchChronIndices = indices;
      _searchCurrentMatchIdx = indices.isNotEmpty ? indices.length - 1 : -1;
    });
    if (indices.isNotEmpty) _scrollToChronIndex(indices.last);
  }

  /// Deep-link jump: after messages load, scroll to and highlight
  /// [ChatRoomScreen.highlightMessageId] reusing the search-match mechanics
  /// (`_searchMatchChronIndices` + `_searchCurrentMatchIdx` +
  /// `_scrollToChronIndex`). If the message isn't in the loaded page,
  /// paginate older pages up to 5 times, then give up silently.
  ///
  /// Returns true when it acted this pass (highlighted the target or
  /// dispatched another page load) — caller then skips auto-scroll-to-bottom.
  bool _maybeHighlightDeepLinkedMessage(MessengerState state) {
    final targetId = widget.highlightMessageId;
    if (targetId == null || _deepLinkHighlightDone || _searchMode) return false;
    final messages = state.messages[widget.conversationId] ?? [];
    if (messages.isEmpty) return false;
    final idx = messages.indexWhere((m) => m.id == targetId);
    if (idx >= 0) {
      _deepLinkHighlightDone = true;
      setState(() {
        _searchMatchChronIndices = [idx];
        _searchCurrentMatchIdx = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToChronIndex(idx);
      });
      return true;
    }
    final cursor = state.nextCursors[widget.conversationId];
    if (cursor != null && _deepLinkLoadAttempts < 5) {
      _deepLinkLoadAttempts++;
      _messengerBloc.add(LoadMoreMessages(widget.conversationId));
      return true;
    }
    // Message not reachable — give up silently.
    _deepLinkHighlightDone = true;
    return false;
  }

  void _scrollToChronIndex(int chronIdx) {
    final messages = _messengerBloc.state.messages[widget.conversationId] ?? [];
    if (chronIdx < 0 || chronIdx >= messages.length) return;
    final key = _messageKeys[messages[chronIdx].id];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  /// Pinned-bar "jump" callback (Task 12) — reuses the same search-match
  /// highlight + scroll mechanics as `_maybeHighlightDeepLinkedMessage`
  /// above. If the pin isn't in the currently loaded page, tell the user
  /// instead of silently doing nothing (Task 13 review): pins live
  /// indefinitely while the message list is only paginated to recent
  /// history, so tapping an older pinned row — reachable from the full
  /// PinnedMessagesScreen list, not just the banner — is a routine case,
  /// not an edge case.
  /// TODO(follow-up): paginate backwards to the target message instead of
  /// just notifying — bigger change than this task should carry.
  /// Шапка режима мультивыбора: счётчик и действия над пачкой.
  PreferredSizeWidget _buildSelectionAppBar() {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text(
        l10n.chatSelectedCount(_selectedIds.length),
        style: TextStyle(color: colors.textPrimary, fontSize: 17),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          tooltip: l10n.chatCopy,
          onPressed: _copySelection,
        ),
        IconButton(
          icon: const Icon(Icons.shortcut_rounded),
          tooltip: l10n.chatForward,
          onPressed: _forwardSelection,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: l10n.delete,
          color: Colors.red.shade400,
          onPressed: _deleteSelection,
        ),
      ],
    );
  }


  /// Находит первое непрочитанное входящее и запоминает его как якорь линии.
  ///
  /// Считается по собственному курсору чтения из read-state, а не по
  /// `unreadCount` беседы: счётчик обновляется двумя писателями без порядка
  /// между ними и может быть временно неверным, а курсор — это факт.
  ///
  /// Свои сообщения пропускаем: линия «непрочитанные» перед собственной
  /// репликой бессмысленна.
  void _resolveUnreadAnchor(List<MessageEntity> messages, String? myId) {
    if (_unreadAnchorResolved || messages.isEmpty || myId == null) return;
    final mine = _cursors.where((c) => c.userId == myId).toList();
    if (mine.isEmpty) return; // read-state ещё не приехал — попробуем позже
    final anchor = findFirstUnreadMessageId(
      messages: messages,
      myUserId: myId,
      lastReadAt: mine.first.lastReadAt,
    );
    _unreadAnchorResolved = true;
    if (anchor == null) return;
    _unreadAnchorId = anchor;

    // Открываем чат на линии, а не в самом низу: смысл разделителя в том,
    // чтобы человек начал читать оттуда, где остановился.
    final idx = messages.indexWhere((m) => m.id == anchor);
    if (idx < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToChronIndex(idx);
    });
  }

  void _toggleSelect(String messageId) {
    setState(() {
      if (_selectedIds.contains(messageId)) {
        _selectedIds.remove(messageId);
        return;
      }
      if (_selectedIds.length >= _selectionLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.chatSelectionLimit(_selectionLimit),
            ),
          ),
        );
        return;
      }
      _selectedIds.add(messageId);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  /// Сообщения выделенной пачки в том порядке, в каком они лежат в ленте:
  /// пересылать вперемешку нельзя, иначе разговор в чате-получателе
  /// перестраивается.
  List<MessageEntity> _selectedMessagesInOrder() {
    final all = _messengerBloc.state.messages[widget.conversationId] ?? [];
    return all.where((m) => _selectedIds.contains(m.id)).toList();
  }

  void _forwardSelection() {
    final ids = _selectedMessagesInOrder().map((m) => m.id).toList();
    if (ids.isEmpty) return;
    showForwardPicker(context, ids);
    _clearSelection();
  }

  void _copySelection() {
    final text = _selectedMessagesInOrder()
        .map((m) => m.content)
        .where((c) => c.trim().isNotEmpty)
        .join('\n');
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.chatCopied)),
    );
  }

  Future<void> _deleteSelection() async {
    final l10n = AppLocalizations.of(context)!;
    final ids = _selectedMessagesInOrder().map((m) => m.id).toList();
    if (ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.chatDeleteMessage,
            style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(
          l10n.chatSelectedCount(ids.length),
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final id in ids) {
      _messengerBloc.add(DeleteMessage(
        conversationId: widget.conversationId,
        messageId: id,
        forEveryone: false,
      ));
    }
    _clearSelection();
  }

  /// Открывает профиль по @логину из упоминания.
  ///
  /// Логин приходится разрешать в id запросом: в самом сообщении лежат только
  /// id упомянутых, без привязки к тому, какой логин какому соответствует.
  Future<void> _openProfileByHandle(String handle) async {
    try {
      final found = await sl<MessengerRemoteDataSource>().searchUsers(handle);
      final lower = handle.toLowerCase();
      UserSearchEntity? exact;
      for (final u in found) {
        if ((u.username ?? '').toLowerCase() == lower) {
          exact = u;
          break;
        }
      }
      if (!mounted) return;
      if (exact == null) {
        // Логин мог смениться или человек удалился — молчать здесь хуже, чем
        // сказать, что открывать нечего.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatMentionNotFound)),
        );
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: exact!.id),
      ));
    } catch (e) {
      debugPrint('[chat] open profile by handle failed: $e');
    }
  }

  void _onPinJump(String messageId) => _jumpToMessage(
        messageId,
        notLoadedText: AppLocalizations.of(context)!.pinnedMessageNotLoaded,
      );

  /// Переход к цитируемому оригиналу по тапу на блок цитаты.
  void _onQuoteJump(String messageId) => _jumpToMessage(
        messageId,
        notLoadedText:
            AppLocalizations.of(context)!.chatReplyOriginalNotLoaded,
      );

  /// Прокрутка к сообщению с подсветкой.
  ///
  /// Подсветка переиспользует машинерию поиска — отсюда и оговорка ниже: пока
  /// поиск открыт, он владеет счётчиком совпадений, и прыжок со стороны
  /// перебил бы его стрелки. Та же защита стоит в _maybeHighlightDeepLinkedMessage.
  void _jumpToMessage(String messageId, {required String notLoadedText}) {
    if (_searchMode) return;
    final messages = _messengerBloc.state.messages[widget.conversationId] ?? [];
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) {
      // Оригинал вне загруженного окна истории — честно об этом говорим,
      // вместо того чтобы молча ничего не сделать.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notLoadedText)),
      );
      return;
    }
    setState(() {
      _searchMatchChronIndices = [idx];
      _searchCurrentMatchIdx = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToChronIndex(idx);
    });
  }

  /// Loads (or refreshes) the pinned list once [pinnedCount] no longer
  /// matches what's already loaded (or was last attempted).
  ///
  /// `pinnedCount` has two writers — the REST response and the device's own
  /// socket echo — with no ordering guarantee between them, so it can be
  /// briefly wrong. It is therefore used ONLY as a trigger to refetch the
  /// list; the bar always renders `pins.length`, never `pinnedCount` itself.
  /// A stale count then costs one redundant request instead of a wrong UI.
  ///
  /// [pinnedCount] doubles as a generation token: if a newer call overtakes
  /// this one while the request is in flight, the newer call's response is
  /// authoritative and this one's result is dropped instead of racing it.
  /// On failure the key is released (`-1`, never a real count) so the next
  /// rebuild can retry — otherwise one failed fetch would leave the bar
  /// stale until the count happened to change again.
  Future<void> _loadPins(int pinnedCount) async {
    if (_pinsLoadedForCount == pinnedCount) return;
    _pinsLoadedForCount = pinnedCount;
    if (pinnedCount == 0) {
      // Known-empty — no need to round-trip the server to learn that.
      if (mounted) setState(() => _pins = const []);
      return;
    }
    try {
      final pins =
          await sl<IMessengerRepository>().getPinnedMessages(widget.conversationId);
      if (!mounted || _pinsLoadedForCount != pinnedCount) return;
      setState(() => _pins = pins);
    } catch (_) {
      // The bar is decoration on top of a working chat — no error surfaced,
      // just release the key (if a newer generation hasn't already moved it)
      // so a future rebuild retries instead of staying stuck.
      if (_pinsLoadedForCount == pinnedCount) _pinsLoadedForCount = -1;
    }
  }

  /// Dismiss the pinned bar for this user. Sends the `pinnedAt` of the
  /// newest loaded pin that actually carries one (pins are newest-first) as
  /// `upTo`. Without it the server falls back to ITS newest pin's
  /// timestamp, which could silently swallow a pin that arrived while the
  /// request was in flight and that this client never showed.
  void _onPinDismiss() {
    if (_pins.isEmpty) return;
    // `pinnedAt` is nullable on MessageEntity in general (unpinned messages
    // carry null); every entry in `_pins` came from getPinnedMessages, so it
    // should always be set here. Guard anyway instead of trusting that
    // invariant blindly: skip forward to the newest pin that does carry a
    // timestamp rather than send `upTo: null`, which would silently reopen
    // the exact swallow-a-pin race this parameter exists to close.
    final upTo = _pins.map((p) => p.pinnedAt).firstWhere(
          (at) => at != null,
          orElse: () => null,
        );
    _messengerBloc.add(DismissPins(widget.conversationId, upTo: upTo));
  }

  /// Opens the full pinned-messages list (Task 13). See [canPinIn]
  /// (`pinned_messages_screen.dart`) for the permission rule this mirrors.
  /// A returned message id (row tap) reuses the banner's own jump mechanics
  /// via `_onPinJump`; a plain back-press pops null and is a no-op.
  Future<void> _onOpenPinnedList() async {
    final conv = _resolveConv(_messengerBloc.state.conversations);
    final canUnpin = canPinIn(conv);
    final messageId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PinnedMessagesScreen(
          conversationId: widget.conversationId,
          canUnpin: canUnpin,
        ),
      ),
    );
    // The chat screen can be torn down while the pinned list is open (the
    // user navigates elsewhere via some other path) — _onPinJump's
    // setState would throw setState() after dispose() otherwise. Same
    // rationale as PinnedMessagesScreen._load()'s own `mounted` guard.
    if (!mounted || messageId == null) return;
    _onPinJump(messageId);
  }

  void _goToOlderMatch() {
    if (_searchMatchChronIndices.isEmpty || _searchCurrentMatchIdx <= 0) return;
    final newIdx = _searchCurrentMatchIdx - 1;
    setState(() => _searchCurrentMatchIdx = newIdx);
    _scrollToChronIndex(_searchMatchChronIndices[newIdx]);
  }

  void _goToNewerMatch() {
    if (_searchMatchChronIndices.isEmpty ||
        _searchCurrentMatchIdx >= _searchMatchChronIndices.length - 1) return;
    final newIdx = _searchCurrentMatchIdx + 1;
    setState(() => _searchCurrentMatchIdx = newIdx);
    _scrollToChronIndex(_searchMatchChronIndices[newIdx]);
  }

  /// Build composer footer for CHANNEL conversations based on myRole.
  /// - OWNER / ADMIN: full message input (they can post to subscribers).
  /// - SUBSCRIBER: compact read-only bar with an "Unsubscribe" button.
  /// - null (not a participant): full-width "Subscribe" button.
  Widget _buildChannelComposer(ConversationEntity? conv) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final role = conv?.myRole;

    if (role == 'OWNER' || role == 'ADMIN') {
      return _InputBar(
        controller: _ctrl,
        onSend: _pendingFiles.isNotEmpty ? _sendPendingAttachment : _sendMessage,
        onAttach: _showAttachMenu,
        isRecording: _isRecording,
        onRecordStart: _startRecording,
        onRecordStop: _stopRecordingAndSend,
        onVideoNote: _startVideoRecording,
        onVideoRecordStart: _startVideoRecording,
        onVideoRecordStop: _stopVideoRecording,
      );
    }

    if (role == 'SUBSCRIBER') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(
            top: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.channelsSubscribedLabel,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _confirmUnsubscribeChannel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(l10n.channelsUnsubscribe),
              ),
            ],
          ),
        ),
      );
    }

    // Not a participant — offer to subscribe.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _subscribeChannel,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.channelsSubscribe,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // В режиме выделения «назад» снимает выделение, а не выкидывает из чата:
      // иначе случайный свайп теряет отмеченную пачку.
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _clearSelection();
      },
      child: Stack(
      children: [
        // Per-chat wallpaper (app-wide selection from Settings)
        Positioned.fill(
          child: ValueListenableBuilder<String?>(
            valueListenable: WallpaperService.instance.current,
            builder: (context, wp, _) {
              if (wp == null || wp.isEmpty) {
                return ColoredBox(color: AppColors.of(context).background);
              }
              final isDark = Theme.of(context).brightness == Brightness.dark;
              // Procedural telegram-style pattern
              if (WallpaperService.isPatternId(wp)) {
                final palette = paletteById(wp);
                if (palette == null) {
                  return ColoredBox(color: AppColors.of(context).background);
                }
                return CustomPaint(
                  painter: ChatWallpaperPainter(
                    palette: palette,
                    isDark: isDark,
                  ),
                );
              }
              // Photo wallpaper
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    WallpaperService.assetFor(wp),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: AppColors.of(context).background,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).background.withValues(
                        alpha: isDark ? 0.55 : 0.35,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _selectionMode
          ? _buildSelectionAppBar()
          : AppBar(
        leading: _searchMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSearchMode,
              )
            : null,
        automaticallyImplyLeading: !_searchMode,
        title: _searchMode
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(
                    color: AppColors.of(context).textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.messengerSearchInChat,
                  hintStyle:
                      TextStyle(color: AppColors.of(context).textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : BlocBuilder<MessengerBloc, MessengerState>(
                buildWhen: (prev, curr) =>
                    prev.conversations != curr.conversations,
                builder: (context, state) {
                  final conv = _resolveConv(state.conversations);
                  final l10n = AppLocalizations.of(context)!;
                  final isSaved = conv?.type == 'SAVED';
                  final isGroup = conv?.type == 'GROUP';
                  final isChannel = conv?.type == 'CHANNEL';
                  final isAiAnalyst = conv?.type == 'AI_ANALYST';
                  final isAiInformer = conv?.type == 'AI_INFORMER';
                  final name = isAiInformer
                      ? l10n.informerBotTitle
                      : isAiAnalyst
                      ? l10n.aiAnalystTitle
                      : isSaved
                          ? l10n.messengerSavedSection
                          : (isGroup || isChannel)
                              ? (conv?.name ?? l10n.chatGroup)
                              : conv?.otherUserName;
                  final avatarUrl = (isAiAnalyst || isAiInformer)
                      ? null
                      : (isGroup || isChannel) ? conv?.avatarUrl : conv?.otherUserAvatar;
                  final otherUserId = conv?.otherUserId;
                  return GestureDetector(
              onTap: isChannel
                  ? ((conv?.myRole == 'OWNER' || conv?.myRole == 'ADMIN')
                      ? () => context.push('/dashboard/messenger/${widget.conversationId}/channel-settings')
                      : null)
                  : isGroup
                      ? () => context.push('/dashboard/messenger/${widget.conversationId}/settings')
                      : otherUserId != null
                          ? () => context.push('/dashboard/user/$otherUserId')
                          : null,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSaved ? const Color(0xFFA855F7) : AppColors.of(context).primary,
                        width: 2,
                      ),
                      boxShadow: isSaved
                          ? [
                              BoxShadow(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: isSaved
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 18),
                          )
                        : isAiAnalyst
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.of(context).primary, AppColors.of(context).primary.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          )
                        : isAiInformer
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFB300), Color(0xFFFF7043)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.radar, color: Colors.white, size: 18),
                          )
                        : CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.of(context).primary.withValues(alpha: (isGroup || isChannel) ? 0.4 : 0.2),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 36, height: 36, fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => isChannel
                                        ? Icon(Icons.campaign_rounded, color: AppColors.of(context).primary, size: 18)
                                        : isGroup
                                            ? Icon(Icons.group_rounded, color: AppColors.of(context).primary, size: 18)
                                            : Text(
                                                name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: TextStyle(color: AppColors.of(context).primary, fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                  ),
                                )
                              : isChannel
                                  ? Icon(Icons.campaign_rounded, color: AppColors.of(context).primary, size: 18)
                                  : isGroup
                                      ? Icon(Icons.group_rounded, color: AppColors.of(context).primary, size: 18)
                                      : Text(
                                          name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(color: AppColors.of(context).primary, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.topicTitle != null
                              ? widget.topicTitle!
                              : (name != null && name.isNotEmpty ? name : l10n.chatDialog),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.topicTitle != null && name != null)
                          Text(
                            name,
                            style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, fontWeight: FontWeight.normal),
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (isChannel && conv != null)
                          Text(
                            '${conv.subscribersCount ?? 0} ${l10n.channelsSubscribers}',
                            style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, fontWeight: FontWeight.normal),
                          )
                        else if (isGroup && conv != null)
                          Text(
                            AppLocalizations.of(context)!.participantsCount(conv.participantCount),
                            style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, fontWeight: FontWeight.normal),
                          ),
                        if (!isGroup && !isChannel && !isSaved && conv?.otherUserStatus != null && conv!.otherUserStatus!.isNotEmpty)
                          Text(
                            conv.otherUserStatus!,
                            style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, fontWeight: FontWeight.normal),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (conv?.type == 'DIRECT' && otherUserId != null)
                          PresenceLabel(
                            userId: otherUserId,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
                },
              ),
        actions: _searchMode
            ? [
                if (_searchMatchChronIndices.isNotEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${_searchMatchChronIndices.length - _searchCurrentMatchIdx}/${_searchMatchChronIndices.length}',
                        style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: _goToOlderMatch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: _goToNewerMatch,
                  ),
                ],
              ]
            : [
                BlocBuilder<MeshStatusBloc, MeshStatus>(
                  bloc: sl<MeshStatusBloc>(),
                  builder: (context, meshState) {
                    final socketConnected = sl<MessengerRemoteDataSource>().isSocketConnected;
                    final (badgeState, visibleCount, totalCount) =
                        _selectBadgeState(meshState, socketConnected);
                    return Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: ChatTransportBadge(
                        state: badgeState,
                        visibleCount: visibleCount,
                        totalCount: totalCount,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _enterSearchMode,
                ),
                BlocBuilder<MessengerBloc, MessengerState>(
                  buildWhen: (prev, curr) =>
                      prev.conversations != curr.conversations,
                  builder: (context, state) {
                    final conv = _resolveConv(state.conversations);
                    // Hide call button for AI bots and channels
                    if (conv?.type != 'AI_ANALYST' &&
                        conv?.type != 'AI_INFORMER' &&
                        conv?.type != 'CHANNEL')
                      // InkWell natively handles both onTap and onLongPress.
                      // GestureDetector wrapping IconButton lost the long-press
                      // because IconButton's internal InkWell wins the gesture
                      // arena on tap-down — the outer GestureDetector never sees it.
                      return Tooltip(
                        message: AppLocalizations.of(context)!.chatCall,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            InkWell(
                              onTap: _autoPickCall,
                              onLongPress: _showTransportPopup,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.phone_outlined),
                              ),
                            ),
                            // Mesh eligibility dot — mobile only (no mesh on desktop).
                            if (PlatformUtils.instance.isMobile &&
                                conv?.type == 'DIRECT' &&
                                conv?.otherUserId != null)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: IgnorePointer(
                                  child: MeshEligibilityDot(userId: conv!.otherUserId!),
                                ),
                              ),
                          ],
                        ),
                      );
                    return const SizedBox.shrink();
                  },
                ),
                BlocBuilder<MessengerBloc, MessengerState>(
                  buildWhen: (prev, curr) =>
                      prev.conversations != curr.conversations,
                  builder: (context, state) {
                    final conv = _resolveConv(state.conversations);
                    final isMuted = conv?.isMuted ?? false;
                    final l10n = AppLocalizations.of(context)!;
                    final isChannel = conv?.type == 'CHANNEL';
                    final role = conv?.myRole;
                    return PopupMenuButton<String>(
                      icon: Icon(
                        isMuted ? Icons.volume_off : Icons.more_vert,
                        color: isMuted
                            ? AppColors.of(context).textSecondary
                            : null,
                      ),
                      onSelected: (value) => _handleMenuAction(value, isMuted),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'mute',
                          child: Row(
                            children: [
                              Icon(
                                isMuted ? Icons.volume_up : Icons.volume_off,
                                size: 20,
                                color: AppColors.of(context).textPrimary,
                              ),
                              const SizedBox(width: 12),
                              Text(isMuted
                                  ? l10n.unmuteNotifications
                                  : l10n.muteNotifications),
                            ],
                          ),
                        ),
                        if (isChannel && (role == 'OWNER' || role == 'ADMIN'))
                          PopupMenuItem(
                            value: 'channel_settings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_rounded,
                                  size: 20,
                                  color: AppColors.of(context).textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(l10n.channelsSettings),
                              ],
                            ),
                          ),
                        if (isChannel && role == 'SUBSCRIBER')
                          PopupMenuItem(
                            value: 'channel_unsubscribe',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  size: 20,
                                  color: AppColors.of(context).error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.channelsUnsubscribe,
                                  style: TextStyle(color: AppColors.of(context).error),
                                ),
                              ],
                            ),
                          ),
                        if (isChannel && role == 'OWNER')
                          PopupMenuItem(
                            value: 'channel_delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: AppColors.of(context).error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.channelsDelete,
                                  style: TextStyle(color: AppColors.of(context).error),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
      ),
      body: BlocListener<MessengerBloc, MessengerState>(
        listenWhen: (prev, curr) {
          final prevCount = prev.messages[widget.conversationId]?.length ?? 0;
          final currCount = curr.messages[widget.conversationId]?.length ?? 0;
          return currCount > prevCount || curr.socketError != prev.socketError;
        },
        listener: (context, state) {
          if (state.socketError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.socketError!), backgroundColor: AppColors.of(context).error),
            );
            context.read<MessengerBloc>().add(const ClearSocketError());
            return;
          }
          // Mark new incoming messages as read immediately since chat is open
          context.read<MessengerBloc>().add(MarkConversationRead(widget.conversationId));
          // Deep-link: jump to a specific message once it is loaded.
          // While paginating towards it (or right after highlighting it),
          // skip the auto-scroll-to-bottom below.
          if (_maybeHighlightDeepLinkedMessage(state)) return;
          // With reverse:true the list starts at bottom — only scroll if user scrolled up
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollCtrl.hasClients) return;
            if (_scrollCtrl.offset > 0) {
              _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        },
        child: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final allMsgs = state.messages[widget.conversationId] ?? [];
          final blocMessages = widget.topicId != null
              ? allMsgs.where((m) => m.topicId == widget.topicId).toList()
              : allMsgs;
          final cursor = state.nextCursors[widget.conversationId];
          _syncMessages(blocMessages, cursor);
          final messages = _cachedMessages;
          // Reset loading flag silently (no setState — avoid rebuild/scroll jump)
          if (_loadingOlder) {
            _loadingOlder = false;
          }
          final conv = _resolveConv(state.conversations);
          final isGroup = conv?.type == 'GROUP';
          final otherUserName = conv?.otherUserName;
          final activeRoomName = state.activeGroupCalls[widget.conversationId];
          // Pinned messages bar (Task 12): kick off a (re)load whenever the
          // conversation's pinnedCount moves, and work out visibility from
          // the loaded list — never from pinnedCount (see _loadPins).
          if (conv != null) unawaited(_loadPins(conv.pinnedCount));
          // Список участников нужен подсказкам упоминаний. Только для групп:
          // у канала подписчиков могут быть тысячи, а постить туда всё равно
          // могут единицы, и подсказывать там некому.
          if (conv?.type == 'GROUP' && !_membersRequested) {
            _membersRequested = true;
            context.read<MessengerBloc>().add(LoadGroupMembers(widget.conversationId));
          }
          final pinsDismissedAt = conv?.pinsDismissedAt;
          final newestPinAt = _pins.isNotEmpty ? _pins.first.pinnedAt : null;
          final pinsBarHidden = pinsDismissedAt != null &&
              (newestPinAt == null || !newestPinAt.isAfter(pinsDismissedAt));
          final showPinsBar = _pins.isNotEmpty && !pinsBarHidden;
          return Column(
            children: [
              // Connectivity warning banner — shown at TOP when socket disconnected
              if (_socketDisconnected)
                _ConnectivityBanner(),
              // Pinned messages bar (Task 12)
              if (showPinsBar)
                PinnedBanner(
                  pins: _pins,
                  onJump: _onPinJump,
                  onDismiss: _onPinDismiss,
                  onOpenList: _onOpenPinnedList,
                ),
              // Active call banner for group conversations
              if (isGroup && activeRoomName != null)
                _ActiveCallBanner(
                  onJoin: () => _joinActiveCall(activeRoomName),
                ),
              Expanded(
                child: Stack(
                  children: [
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: messages.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.chatStartConversation,
                          style:
                              TextStyle(color: AppColors.of(context).textSecondary),
                        ),
                      )
                    : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                      child: Builder(builder: (context) {
                        final pendingText = state.pendingAnalystText[widget.conversationId] ?? '';
                        final hasStreaming = conv?.type == 'AI_ANALYST' && pendingText.isNotEmpty;
                        // Один раз за открытие чата, до построения строк: линия
                        // должна быть готова к моменту, когда до неё дойдёт
                        // отрисовка.
                        _resolveUnreadAnchor(messages, state.currentUserId);
                        return ListView.builder(
                        key: const PageStorageKey('chat_messages'),
                        controller: _scrollCtrl,
                        reverse: true,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + (hasStreaming ? 1 : 0),
                        findChildIndexCallback: (key) {
                          if (key is ValueKey<String>) {
                            final id = key.value;
                            for (int i = 0; i < messages.length; i++) {
                              if (messages[messages.length - 1 - i].id == id) return i + (hasStreaming ? 1 : 0);
                            }
                          }
                          return null;
                        },
                        itemBuilder: (context, index) {
                          // Streaming bubble at top (index 0 in reversed list = newest)
                          if (hasStreaming && index == 0) {
                            return AnalystStreamingBubble(text: pendingText);
                          }
                          // messages[] is chronological (index 0 = oldest).
                          // reversed list: index 0 = newest (displayed at bottom).
                          final messageIndex = hasStreaming ? index - 1 : index;
                          final chronIdx = messages.length - 1 - messageIndex;
                          final msg = messages[chronIdx];
                          final isMe = _isMyMessage(msg, state);

                          // Adjacent messages for grouping
                          final prevChron = chronIdx > 0 ? messages[chronIdx - 1] : null; // visually above
                          final nextChron = chronIdx < messages.length - 1 ? messages[chronIdx + 1] : null; // visually below

                          // Date separator logic (same as before)
                          final msgDate = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
                          bool showDate = false;
                          if (messageIndex == messages.length - 1) {
                            showDate = true;
                          } else {
                            final prevDate = DateTime(prevChron!.sentAt.year, prevChron.sentAt.month, prevChron.sentAt.day);
                            showDate = msgDate != prevDate;
                          }

                          // Group context: consecutive messages from same sender.
                          // In AI_ANALYST chats, system messages are bot replies
                          // and should group normally, not break grouping.
                          final analystChat = conv?.type == 'AI_ANALYST';
                          final breakOnSystem = !analystChat;
                          final isFirstInGroup = showDate ||
                              prevChron == null ||
                              (breakOnSystem && prevChron.isSystem) ||
                              (breakOnSystem && msg.isSystem) ||
                              (analystChat
                                  ? prevChron.isSystem != msg.isSystem // group by bot vs user
                                  : prevChron.senderId != msg.senderId);
                          final isLastInGroup = nextChron == null ||
                              (breakOnSystem && nextChron.isSystem) ||
                              (breakOnSystem && msg.isSystem) ||
                              (analystChat
                                  ? nextChron.isSystem != msg.isSystem
                                  : nextChron.senderId != msg.senderId) ||
                              DateTime(nextChron.sentAt.year, nextChron.sentAt.month, nextChron.sentAt.day) != msgDate;

                          // Show sender name only on first message of a group (incoming group chats)
                          final sName = isMe
                              ? null
                              : (!isGroup
                                  ? otherUserName
                                  : (isFirstInGroup ? (msg.senderName ?? otherUserName) : null));

                          // GlobalKey for search scroll-to
                          final msgKey = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
                          // Search highlight state
                          final isCurrentMatch = _searchMatchChronIndices.isNotEmpty &&
                              _searchCurrentMatchIdx >= 0 &&
                              _searchMatchChronIndices[_searchCurrentMatchIdx] == chronIdx;
                          final isAnyMatch = _searchText.isNotEmpty &&
                              !msg.isSystem &&
                              msg.content.toLowerCase().contains(_searchText.toLowerCase());

                          final messageBubble = _MessageBubble(
                                message: msg,
                                isMe: (msg.isSystem && (conv?.type == 'AI_ANALYST' || conv?.type == 'AI_INFORMER')) ? false
                                    : isMe,
                                isGroup: isGroup,
                                isAiAnalyst: conv?.type == 'AI_ANALYST' || conv?.type == 'AI_INFORMER',
                                senderName: msg.isSystem && conv?.type == 'AI_ANALYST'
                                    ? AppLocalizations.of(context)!.aiAnalystTitle
                                    : msg.isSystem && conv?.type == 'AI_INFORMER'
                                    ? AppLocalizations.of(context)!.informerBotTitle
                                    : sName,
                                isFirstInGroup: isFirstInGroup,
                                isLastInGroup: isLastInGroup,
                                isSearchMatch: isAnyMatch,
                                isCurrentSearchMatch: isCurrentMatch,
                                allMessages: messages,
                                onReply: msg.isSystem ? null : () => _setReply(msg, isMe ? AppLocalizations.of(context)!.chatYou : sName),
                                onEdit: (isMe && !msg.isSystem && msg.fileUrl == null) ? () => _startEditing(msg) : null,
                                onReact: msg.isSystem ? null : (emoji) {
                                  context.read<MessengerBloc>().add(ReactToMessage(
                                    conversationId: msg.conversationId,
                                    messageId: msg.id,
                                    emoji: emoji,
                                  ));
                                },
                                // Task 14: same gate as the backend's `_assertCanPin` (via
                                // canPinIn), plus a client-side-only system-message exclusion —
                                // the backend rejects pinning a system message with a 400, so
                                // offering it here would be a guaranteed error.
                                onTogglePin: (msg.isSystem || !canPinIn(conv))
                                    ? null
                                    : () {
                                        context.read<MessengerBloc>().add(
                                              msg.pinnedAt == null
                                                  ? PinMessage(
                                                      conversationId: msg.conversationId,
                                                      messageId: msg.id,
                                                    )
                                                  : UnpinMessage(
                                                      conversationId: msg.conversationId,
                                                      messageId: msg.id,
                                                    ),
                                            );
                                      },
                                currentUserId: state.currentUserId,
                                onStartCall: (msg.isSystem && !isMe && (msg.content.contains('Пропущенный звонок') || msg.content.contains('Missed call') || msg.content.contains(AppLocalizations.of(context)!.messengerMissedCall))) ? _startLkCall : null,
                                autoPlayVideoNote: _autoPlayVideoNote,
                                readCursors: _cursors,
                                onQuoteTap: _onQuoteJump,
                                onMentionTap: _openProfileByHandle,
                                isSelected: _selectedIds.contains(msg.id),
                                selectionMode: _selectionMode,
                                // Системные строки выделять нечего — их нельзя
                                // ни переслать, ни осмысленно скопировать.
                                onToggleSelect: msg.isSystem
                                    ? null
                                    : () => _toggleSelect(msg.id),
                              );

                          // Report read-horizon as incoming (non-own) bubbles actually
                          // scroll into view — Telegram-style, replaces blanket mark-on-open.
                          final myId = state.currentUserId;
                          final wrappedBubble = VisibilityDetector(
                            key: ValueKey('vis-${msg.id}'),
                            onVisibilityChanged: (info) {
                              if (info.visibleFraction > 0.6 && msg.senderId != myId) {
                                _onMessageSeen(msg);
                              }
                            },
                            // Подсветка выделения кладётся на всю ширину строки,
                            // а не на сам пузырь: так видно, что отмечено
                            // сообщение целиком, включая пустое поле рядом.
                            child: _selectedIds.contains(msg.id)
                                ? ColoredBox(
                                    color: AppColors.of(context)
                                        .primary
                                        .withValues(alpha: 0.16),
                                    child: messageBubble,
                                  )
                                : messageBubble,
                          );

                          // AI_ANALYST bot messages: show seam widget above the bubble
                          if (analystChat && msg.isSystem) {
                            final liveSeam = state.analystSeams[msg.id];
                            final metaSeam = AnalystSeam.fromMetadata(
                              conversationId: msg.conversationId,
                              messageId: msg.id,
                              metadata: msg.metadata,
                            );
                            final seam = liveSeam ?? metaSeam;
                            if (seam != null) {
                              return Column(
                                key: ValueKey<String>(msg.id),
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showDate) _DateSeparator(date: msg.sentAt),
                                  if (msg.id == _unreadAnchorId) const _UnreadSeparator(),
                                  AnalystSeamWidget(seam: seam),
                                  wrappedBubble,
                                ],
                              );
                            }
                          }

                          return Column(
                            key: ValueKey<String>(msg.id),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDate) _DateSeparator(date: msg.sentAt),
                              if (msg.id == _unreadAnchorId) const _UnreadSeparator(),
                              wrappedBubble,
                            ],
                          );
                        },
                      );
                      }),
                    ),
                ),
                    // Scroll-to-bottom button
                    if (_showScrollToBottom)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Material(
                          color: AppColors.of(context).card,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _scrollCtrl.animateTo(0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.of(context).primary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Подсказки упоминаний — прямо над полем ввода, чтобы палец
              // дотягивался, а список сообщений не съезжал.
              BlocBuilder<MessengerBloc, MessengerState>(
                builder: (context, state) {
                  final candidates = _mentionCandidates(state);
                  if (candidates.isEmpty) return const SizedBox.shrink();
                  final colors = AppColors.of(context);
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border(top: BorderSide(color: colors.background)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      itemBuilder: (context, i) {
                        final m = candidates[i];
                        final name = [m.firstName, m.lastName]
                            .whereType<String>()
                            .join(' ')
                            .trim();
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.primary.withValues(alpha: 0.2),
                            backgroundImage: (m.avatarUrl ?? '').isNotEmpty
                                ? NetworkImage(m.avatarUrl!)
                                : null,
                            child: (m.avatarUrl ?? '').isEmpty
                                ? Text(
                                    (name.isNotEmpty ? name : m.username!)
                                        .characters
                                        .first
                                        .toUpperCase(),
                                    style: TextStyle(color: colors.primary, fontSize: 13))
                                : null,
                          ),
                          title: Text(name.isEmpty ? '@${m.username}' : name,
                              style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                          subtitle: name.isEmpty
                              ? null
                              : Text('@${m.username}',
                                  style: TextStyle(
                                      color: colors.textSecondary, fontSize: 12)),
                          onTap: () => _insertMention(m.username!),
                        );
                      },
                    ),
                  );
                },
              ),
              if (_editingMessage != null)
                _EditPreviewBar(
                  message: _editingMessage!,
                  onCancel: _cancelEditing,
                ),
              if (_replyTo != null)
                _ReplyPreviewBar(
                  message: _replyTo!,
                  senderName: _replyToSenderName,
                  onCancel: _cancelReply,
                ),
              // Typing indicator
              BlocBuilder<MessengerBloc, MessengerState>(
                buildWhen: (prev, curr) {
                  final key = widget.topicId != null ? '${widget.conversationId}:${widget.topicId}' : widget.conversationId;
                  return prev.typingUsers[key] != curr.typingUsers[key];
                },
                builder: (context, state) {
                  final key = widget.topicId != null ? '${widget.conversationId}:${widget.topicId}' : widget.conversationId;
                  final typers = state.typingUsers[key];
                  if (typers == null || typers.isEmpty) return const SizedBox.shrink();
                  final l10n = AppLocalizations.of(context)!;
                  final values = typers.values.where((n) => n.isNotEmpty).toList();
                  // Check if any value is a custom typingText (contains emoji or status)
                  final customText = values.firstWhere(
                    (v) => v.contains('🔍') || v.contains('🌐') || v.contains('📊') || v.contains('📋') || v.contains('🤔') || v.contains('🚀'),
                    orElse: () => '',
                  );
                  final text = customText.isNotEmpty
                      ? customText
                      : values.isEmpty
                          ? l10n.chatIsTyping
                          : values.length == 1
                              ? l10n.chatUserIsTyping(values.first)
                              : l10n.chatUsersAreTyping(values.join(', '));
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).card,
                      border: Border(
                        top: BorderSide(color: AppColors.of(context).border, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 16,
                          child: TypingDots(color: AppColors.of(context).primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_pendingFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).card,
                    border: Border(top: BorderSide(color: AppColors.of(context).border, width: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_file_rounded, size: 14, color: AppColors.of(context).textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_pendingFiles.length} ${_pendingFiles.length == 1 ? 'файл' : 'файла'}',
                            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _pendingFiles.clear()),
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: TextStyle(color: AppColors.of(context).error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pendingFiles.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            if (i == _pendingFiles.length) {
                              return GestureDetector(
                                onTap: _showAttachMenu,
                                child: Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.of(context).primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.3), width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_rounded, color: AppColors.of(context).primary, size: 26),
                                      const SizedBox(height: 2),
                                      Text('Ещё', style: TextStyle(color: AppColors.of(context).primary, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final f = _pendingFiles[i];
                            final isImage = f.type == 'image';
                            final isVideo = f.type == 'video';
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (isImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(f.path), width: 72, height: 72, fit: BoxFit.cover),
                                  )
                                else if (isVideo)
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.videocam_rounded, color: Colors.white70, size: 32),
                                  )
                                else
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.of(context).surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.of(context).border),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.of(context).primary.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.insert_drive_file_rounded, color: AppColors.of(context).primary, size: 20),
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            f.name.length > 10 ? '${f.name.substring(0, 8)}…' : f.name,
                                            style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 9, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Positioned(
                                  top: -5, right: -5,
                                  child: GestureDetector(
                                    onTap: () => _cancelPendingAttachment(i),
                                    child: Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.of(context).error,
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isPreparing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.of(context).card,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.of(context).primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.chatPreparingFile,
                        style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (_uploadProgress != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.of(context).card,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.chatUploading((_uploadProgress! * 100).toInt()),
                              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                minHeight: 4,
                                backgroundColor: AppColors.of(context).textSecondary.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.of(context).primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _cancelUpload,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.of(context).error.withOpacity(0.15),
                          ),
                          child: Icon(Icons.close, size: 18, color: AppColors.of(context).error),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_videoNoteLocalPath != null && _videoNoteProgress != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.of(context).card,
                  child: Row(
                    children: [
                      // Video thumbnail preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: SizedBox(
                          width: 56, height: 56,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: AppColors.of(context).surface, child: const Icon(Icons.videocam_rounded, color: Colors.white38, size: 24)),
                              Center(
                                child: SizedBox(
                                  width: 28, height: 28,
                                  child: CircularProgressIndicator(
                                    value: _videoNoteProgress,
                                    strokeWidth: 3,
                                    backgroundColor: AppColors.of(context).textSecondary.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.of(context).primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.chatUploading((_videoNoteProgress! * 100).toInt()),
                          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_iBlockedThem || _theyBlockedMe)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: AppColors.of(context).card,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block_rounded, size: 16, color: AppColors.of(context).textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _iBlockedThem
                            ? AppLocalizations.of(context)!.chatBlockedByYou
                            : AppLocalizations.of(context)!.chatYouAreBlocked,
                        style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else if (!_isContact && conv?.type != 'CHANNEL')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: AppColors.of(context).card,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_disabled_rounded, size: 16, color: AppColors.of(context).textSecondary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.chatNotContacts,
                          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (conv?.type == 'CHANNEL')
                _buildChannelComposer(conv)
              else
                _InputBar(
                  controller: _ctrl,
                  onSend: _pendingFiles.isNotEmpty ? _sendPendingAttachment : _sendMessage,
                  onAttach: _showAttachMenu,
                  isRecording: _isRecording,
                  onRecordStart: _startRecording,
                  onRecordStop: _stopRecordingAndSend,
                  onVideoNote: _startVideoRecording,
                  onVideoRecordStart: _startVideoRecording,
                  onVideoRecordStop: _stopVideoRecording,
                ),
            ],
          );
        },
        ),
      ),
    ),
        // Video note recorder overlay
        if (_videoRecording)
          Positioned.fill(
            child: _VideoNoteOverlay(
              key: _videoOverlayKey,
              onDone: _onVideoRecorded,
              onSegmentDone: _onVideoRecorded,
              onCancel: _onVideoCancelled,
            ),
          ),
      ],
      ),
    );
  }

  bool _isMyMessage(MessageEntity msg, MessengerState state) {
    final uid = state.currentUserId;
    if (uid == null) return msg.id.startsWith('temp_');
    return msg.senderId == uid;
  }
}

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFB71C1C),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.connectionUnstable,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCallBanner extends StatelessWidget {
  final VoidCallback onJoin;
  const _ActiveCallBanner({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.callInProgress,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: onJoin,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(AppLocalizations.of(context)!.joinCall, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Линия «Непрочитанные сообщения» перед первым непрочитанным.
///
/// В отличие от разделителя дат тянется на всю ширину: это граница чтения, а не
/// метка, и её должно быть видно боковым зрением при прокрутке.
class _UnreadSeparator extends StatelessWidget {
  const _UnreadSeparator();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.primary.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              AppLocalizations.of(context)!.chatUnreadDivider,
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.primary.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDay == today) {
      label = AppLocalizations.of(context)!.today;
    } else if (msgDay == yesterday) {
      label = AppLocalizations.of(context)!.yesterday;
    } else if (date.year == now.year) {
      label = DateFormat('d MMMM', Localizations.localeOf(context).languageCode).format(date);
    } else {
      label = DateFormat('d MMMM y', Localizations.localeOf(context).languageCode).format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Шапка «Переслано от X» над телом пересланного сообщения.
class _ForwardedHeader extends StatelessWidget {
  final String name;
  const _ForwardedHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shortcut_rounded, size: 13, color: colors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.chatForwardedFrom(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Блок цитаты внутри пузыря: полоска, имя автора оригинала и его начало.
///
/// Тап уводит к оригиналу. Если оригинал уже удалили, показываем это прямо в
/// цитате, а не пустую строку — иначе ответ выглядит как ответ в никуда.
class _ReplyQuote extends StatelessWidget {
  final ReplyPreviewEntity reply;
  final bool isMe;
  final VoidCallback? onTap;
  const _ReplyQuote({required this.reply, required this.isMe, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = isMe ? colors.textPrimary : colors.primary;

    String body;
    if (reply.isDeleted) {
      body = l10n.chatOriginalDeleted;
    } else if (reply.content.trim().isNotEmpty) {
      body = reply.content.trim();
    } else if (reply.fileType == 'image') {
      body = '🖼 ${reply.fileName ?? ''}'.trim();
    } else if (reply.fileType == 'audio') {
      body = '🎤';
    } else if (reply.fileName != null) {
      body = '📎 ${reply.fileName}';
    } else {
      body = l10n.chatFileAttachment;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reply.senderName != null && reply.senderName!.isNotEmpty)
              Text(
                reply.senderName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.25,
                fontStyle:
                    reply.isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;
  final String? senderName;
  final bool isGroup;
  final bool isAiAnalyst;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isSearchMatch;
  final bool isCurrentSearchMatch;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final void Function(String emoji)? onReact;
  final String? currentUserId;
  final List<MessageEntity> allMessages;
  final VoidCallback? onStartCall;
  final ValueNotifier<String?>? autoPlayVideoNote;
  /// Other participants' read cursors for this conversation — drives the
  /// own-message receipt footer (1:1 colored ticks / group "Seen by N").
  final List<ParticipantCursor> readCursors;
  /// Task 14: pins or unpins [message], whichever `message.pinnedAt` says is
  /// next. Null hides the menu entry entirely — same convention as [onEdit]
  /// — which the call site uses both for system messages (the backend
  /// rejects pinning those with a 400) and for conversations where
  /// `canPinIn` (`pinned_messages_screen.dart`) says the current user isn't
  /// allowed to pin/unpin here.
  final VoidCallback? onTogglePin;
  /// Переход к цитируемому оригиналу. Null — цитата не кликабельна.
  final void Function(String messageId)? onQuoteTap;
  /// Тап по @упоминанию — открыть профиль этого человека.
  final void Function(String handle)? onMentionTap;
  /// Мультивыбор. [onToggleSelect] null — выделять в этой беседе нельзя
  /// (системные строки и AI-ветки), пункт меню тогда не показывается.
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onToggleSelect;
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.senderName,
    this.isGroup = false,
    this.isAiAnalyst = false,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.isSearchMatch = false,
    this.isCurrentSearchMatch = false,
    this.onReply,
    this.onEdit,
    this.onReact,
    this.currentUserId,
    this.allMessages = const [],
    this.onStartCall,
    this.autoPlayVideoNote,
    this.readCursors = const [],
    this.onTogglePin,
    this.onQuoteTap,
    this.onMentionTap,
    this.isSelected = false,
    this.selectionMode = false,
    this.onToggleSelect,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  double _dragOffset = 0;
  bool _replyTriggered = false;
  static const _replyThreshold = 56.0;
  static const _maxDrag = 72.0;

  static const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
  static const _videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};

  String _effectiveFileType(MessageEntity msg) {
    final ft = msg.fileType;
    if (ft == 'image' || ft == 'video' || ft == 'audio') return ft!;
    // Detect by URL or fileName extension
    final name = (msg.fileName ?? msg.fileUrl ?? '').split('?').first.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : '';
    if (_imageExts.contains(ext)) return 'image';
    if (_videoExts.contains(ext)) return 'video';
    return 'document';
  }

  @override
  Widget build(BuildContext context) {
    // In AI Analyst conversations, system messages are bot responses —
    // render them as regular left-aligned bubbles, not centered labels.
    if (widget.message.isSystem && !widget.isAiAnalyst) {
      return _buildSystemMessage(context);
    }

    // Video note: render as bare circle without bubble frame
    if (widget.message.fileUrl != null && widget.message.fileType == 'video_note') {
      return _buildVideoNoteMessage(context);
    }

    return GestureDetector(
      // В режиме выделения обычный тап переключает отметку, а не открывает
      // вложение: иначе выделять пачку картинок было бы невозможно.
      onTap: widget.selectionMode && widget.onToggleSelect != null
          ? widget.onToggleSelect
          : null,
      // Долгое нажатие по-прежнему открывает меню действий — выделение
      // добавлено туда пунктом, а не вместо него.
      onLongPress: () => _showMessageActions(context),
      onSecondaryTap: () => _showMessageActions(context),
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0 || _dragOffset > 0) {
          final newOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
          if (newOffset >= _replyThreshold && !_replyTriggered) {
            _replyTriggered = true;
            HapticFeedback.mediumImpact();
          }
          setState(() => _dragOffset = newOffset);
        }
      },
      onHorizontalDragEnd: (_) {
        if (_replyTriggered && widget.onReply != null) {
          widget.onReply!();
        }
        setState(() {
          _dragOffset = 0;
          _replyTriggered = false;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = 0;
          _replyTriggered = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_dragOffset > 4)
            Positioned(
              left: 4,
              top: 0,
              bottom: 8,
              child: Center(
                child: Icon(
                  Icons.reply_rounded,
                  color: AppColors.of(context).primary.withValues(
                      alpha: (_dragOffset / _replyThreshold).clamp(0.0, 1.0)),
                  size: 22,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset * 0.65, 0),
            child: Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: widget.isCurrentSearchMatch
              ? null
              : (widget.isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E3A5F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null),
          color: widget.isCurrentSearchMatch
              ? (widget.isMe
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.7)
                  : Colors.amber.withValues(alpha: 0.15))
              : (widget.isMe
                  ? null
                  : AppColors.of(context).card),
          boxShadow: [
            BoxShadow(
              color: widget.isMe
                  ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: widget.isMe ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: widget.isMe
              ? (widget.isLastInGroup
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    )
                  : BorderRadius.circular(18))
              : (widget.isLastInGroup
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    )
                  : BorderRadius.circular(18)),
          border: widget.isCurrentSearchMatch
              ? Border.all(
                  color: Colors.amber.withValues(alpha: 0.8), width: 1.5)
              : widget.isSearchMatch
                  ? Border.all(
                      color: Colors.amber.withValues(alpha: 0.4), width: 1)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isMe && widget.senderName != null && widget.senderName!.isNotEmpty && widget.isFirstInGroup)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.senderName!,
                  style: TextStyle(
                    color: rainbowColorFor(widget.senderName!),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (widget.message.forwardedFrom?.name != null &&
                widget.message.forwardedFrom!.name!.isNotEmpty)
              _ForwardedHeader(name: widget.message.forwardedFrom!.name!),
            if (widget.message.replyTo != null)
              _ReplyQuote(
                reply: widget.message.replyTo!,
                isMe: widget.isMe,
                onTap: widget.onQuoteTap == null
                    ? null
                    : () => widget.onQuoteTap!(widget.message.replyTo!.id),
              ),
            if (widget.message.fileUrl != null && widget.message.fileType == 'video_note')
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _FullScreenVideoPlayer(videoUrl: widget.message.fileUrl!),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipOval(
                    child: SizedBox(
                      width: 200, height: 200,
                      child: widget.message.thumbnailMediumUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: widget.message.thumbnailMediumUrl!,
                                  fit: BoxFit.cover,
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: AppColors.of(context).surface,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_circle_outline, size: 48, color: Colors.white70),
                                    const SizedBox(height: 4),
                                    Text(AppLocalizations.of(context)!.messengerVideoMessage, style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              )
            else if (widget.message.fileUrl != null && _effectiveFileType(widget.message) == 'image')
              GestureDetector(
                onTap: () {
                  final imageMessages = widget.allMessages
                      .where((m) => m.fileUrl != null && _effectiveFileType(m) == 'image')
                      .toList();
                  final idx = imageMessages.indexWhere((m) => m.id == widget.message.id);
                  Navigator.of(context).push(PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    transitionDuration: const Duration(milliseconds: 280),
                    pageBuilder: (_, __, ___) => _FullScreenImageGallery(
                      imageUrls: imageMessages.map((m) => m.fileUrl!).toList(),
                      heroTags: imageMessages.map((m) => 'img_${m.id}').toList(),
                      initialIndex: idx >= 0 ? idx : 0,
                    ),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Hero(
                    tag: 'img_${widget.message.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 220,
                        height: 160,
                        child: CachedNetworkImage(
                          imageUrl: widget.message.thumbnailLargeUrl ?? widget.message.fileUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.of(context).primary,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.of(context).textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (widget.message.fileUrl != null && _effectiveFileType(widget.message) == 'video')
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _FullScreenVideoPlayer(videoUrl: widget.message.fileUrl!),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 220,
                      height: 160,
                      child: widget.message.thumbnailMediumUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.message.thumbnailMediumUrl!,
                              fit: BoxFit.cover,
                              width: 220,
                              height: 160,
                              placeholder: (_, __) => Container(
                                color: Colors.black26,
                                child: const Center(child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white70)),
                              ),
                              errorWidget: (_, __, ___) => _VideoThumbnail(videoUrl: widget.message.fileUrl!),
                            )
                          : _VideoThumbnail(videoUrl: widget.message.fileUrl!),
                    ),
                  ),
                ),
              )
            else if (widget.message.fileUrl != null && _effectiveFileType(widget.message) == 'audio')
              _AudioMessagePlayer(fileUrl: widget.message.fileUrl!, isMe: widget.isMe)
            else if (widget.message.fileUrl != null)
              _DocumentBubble(
                fileUrl: widget.message.fileUrl!,
                fileName: widget.message.fileName ?? widget.message.content,
                fileSize: widget.message.fileSize,
              )
            else if (widget.message.content.startsWith('[POLL]'))
              _PollWidget(message: widget.message, isMe: widget.isMe)
            else if (widget.message.content.startsWith('[CONTACT]'))
              _ContactCardWidget(content: widget.message.content)
            else if (widget.isAiAnalyst ||
                (widget.message.isSystem &&
                    widget.message.content.contains('[ACTION:')))
              // AI bot responses are markdown — render with
              // flutter_markdown for headers, bold, code blocks, lists,
              // clickable links, and action buttons [ACTION:xxx].
              // The isSystem+[ACTION:] fallback covers the case where the
              // conversation entity isn't in bloc state yet (desktop opens a
              // chat pane before the list loads → conv?.type == null and
              // informer buttons degraded to raw text).
              AiBotContent(
                content: widget.message.content,
                conversationId: widget.message.conversationId,
                topicId: widget.message.topicId,
              )
            else if (false) // placeholder — old AI_ANALYST markdown block kept below
              MarkdownBody(
                data: widget.message.content,
                selectable: true,
                softLineBreak: true,
                onTapLink: (text, href, title) {
                  if (href == null) return;
                  final uri = Uri.tryParse(href.startsWith('http') ? href : 'https://$href');
                  if (uri != null) launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14, height: 1.45),
                  h1: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                  h2: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  h3: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  strong: TextStyle(color: AppColors.of(context).textPrimary, fontWeight: FontWeight.w700),
                  em: TextStyle(color: AppColors.of(context).textPrimary, fontStyle: FontStyle.italic),
                  a: TextStyle(color: AppColors.of(context).primary, decoration: TextDecoration.underline),
                  code: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    backgroundColor: AppColors.of(context).background,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.of(context).background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.of(context).primary, width: 3),
                    ),
                  ),
                  blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                  listBullet: TextStyle(color: AppColors.of(context).textSecondary),
                ),
              )
            else
              _LinkifiedText(
                text: widget.message.content,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : AppColors.of(context).textPrimary,
                  fontSize: 14,
                ),
                linkStyle: TextStyle(
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.of(context).primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
                // Своё упоминание выделяем жирным: в длинной группе взгляд
                // должен цепляться именно за него, а не за любое обращение.
                mentionStyle: TextStyle(
                  color: widget.isMe
                      ? Colors.white
                      : AppColors.of(context).primary,
                  fontSize: 14,
                  fontWeight: (widget.currentUserId != null &&
                          widget.message.mentionedUserIds
                              .contains(widget.currentUserId))
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                onMentionTap: widget.onMentionTap,
              ),
            // Show caption under image/video if content differs from fileName
            if (widget.message.fileUrl != null &&
                (_effectiveFileType(widget.message) == 'image' || _effectiveFileType(widget.message) == 'video') &&
                widget.message.content.isNotEmpty &&
                widget.message.content != widget.message.fileName)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.message.content,
                  style: TextStyle(
                    color: widget.isMe ? Colors.white : AppColors.of(context).textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.message.transport == 'mesh') ...[
                  Text(
                    AppLocalizations.of(context)!.chatViaMesh,
                    style: TextStyle(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (widget.message.isEdited) ...[
                  Text(
                    AppLocalizations.of(context)!.chatEdited,
                    style: TextStyle(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  DateFormat('HH:mm').format(widget.message.sentAt.toLocal()),
                  style: TextStyle(
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  Builder(builder: (_) {
                    final isPending = widget.message.id.startsWith('temp_');
                    final myId = widget.currentUserId ?? '';
                    // Read horizon (Task 12): any other participant whose
                    // cursor has advanced past this message's sentAt.
                    // Groups use the same tick semantics as 1:1 — one tick
                    // when delivered, two ticks once ANYONE has read; the
                    // per-user read list lives in the long-press info sheet.
                    // The inline "Seen by N" counter was dropped (2026-07-17).
                    final read = widget.message.isRead ||
                        _readIn1to1(widget.message, widget.readCursors, myId);
                    final IconData icon;
                    if (isPending) {
                      icon = Icons.access_time_rounded; // clock — not yet sent
                    } else if (read) {
                      icon = Icons.done_all_rounded; // two ticks — read
                    } else {
                      icon = Icons.done_rounded; // one tick — delivered to server
                    }
                    final color = read
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6);
                    return Icon(icon, size: 14, color: color);
                  }),
                ],
              ],
            ),
          ],
        ),
      ),
      if (widget.message.reactions.isNotEmpty)
        _ReactionsRow(
          reactions: widget.message.reactions,
          currentUserId: widget.currentUserId,
          onTap: widget.onReact,
        ),
      SizedBox(height: widget.isLastInGroup ? 8 : 2),
        ],
      ),
          ),
          ),
        ],
      ),
    );
  }

  static const _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  void _showMessageActions(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (widget.onReact != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _quickEmojis.map((emoji) {
                    final myReaction = widget.message.reactions.any(
                      (r) => r['emoji'] == emoji && r['userId'] == widget.currentUserId,
                    );
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onReact!(emoji);
                      },
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: myReaction
                              ? colors.primary.withValues(alpha: 0.2)
                              : colors.background,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 16),
            ],
            if (widget.onReply != null)
              ListTile(
                leading: Icon(Icons.reply_rounded, color: colors.primary),
                title: Text(l10n.chatReply, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReply!();
                },
              ),
            if (widget.onToggleSelect != null)
              ListTile(
                leading: Icon(Icons.checklist_rounded, color: colors.textSecondary),
                title: Text(l10n.chatSelect, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onToggleSelect!();
                },
              ),
            // Task 14: pin/unpin — widget.onTogglePin is already null for
            // system messages and for conversations the current user can't
            // pin in (see the call site's canPinIn gate), so no extra
            // condition is needed here.
            if (widget.onTogglePin != null)
              ListTile(
                leading: Icon(
                  widget.message.pinnedAt == null ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: colors.primary,
                ),
                title: Text(
                  widget.message.pinnedAt == null ? l10n.pinAction : l10n.unpinAction,
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onTogglePin!();
                },
              ),
            // Task 13: read-by + reactions info, only makes sense on the
            // user's own (non-system) messages — mirrors "Seen by N"/ticks,
            // which are also isMe-only.
            if (widget.isMe && !widget.message.isSystem)
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: colors.textSecondary),
                title: Text(l10n.messageInfo, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMessageInfo(context);
                },
              ),
            if (widget.isMe && widget.message.fileUrl == null && widget.message.content.isNotEmpty && widget.onEdit != null)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: colors.primary),
                title: Text(l10n.chatEdit, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onEdit!();
                },
              ),
            if (widget.message.fileUrl == null && widget.message.content.isNotEmpty)
              ListTile(
                leading: Icon(Icons.copy_rounded, color: colors.textSecondary),
                title: Text(l10n.chatCopy, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: widget.message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.chatCopied), duration: const Duration(seconds: 2)),
                  );
                },
              ),
            if (widget.message.fileUrl != null)
              ListTile(
                leading: Icon(Icons.download_rounded, color: colors.textSecondary),
                title: Text(l10n.chatSaveMedia, style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _saveFile(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.forward_rounded, color: colors.textSecondary),
              title: Text(l10n.chatForward, style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showForwardPicker(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              title: Text(l10n.delete, style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Task 13: opens the message-info sheet (read-by + reactions) for this
  /// (own) message. `widget.readCursors` is the same live-kept cursor list
  /// already used for the 1:1 ticks / "Seen by N" footer above (loaded via
  /// `MessengerRemoteDataSource.fetchConversationReadState` in
  /// `_ChatRoomScreenState._loadReadCursors` and reconciled from the
  /// `conversation_read` socket stream) — reused as-is rather than
  /// re-fetched, so the sheet always reflects the freshest known cursors
  /// without an extra round-trip on every long-press.
  void _showMessageInfo(BuildContext context) {
    final colors = AppColors.of(context);
    final myId = widget.currentUserId;
    final cursors = myId == null
        ? widget.readCursors
        : widget.readCursors.where((c) => c.userId != myId).toList();

    // Best-effort display names: every message carries its sender's name
    // (MessageEntity.senderName, backend-populated), so union across the
    // conversation's messages covers any participant who has sent at least
    // one message. Participants who only read (never sent) fall back to
    // their raw userId inside MessageInfoSheet — no full participant/name
    // roster is available on this screen.
    final nameById = <String, String>{};
    for (final m in widget.allMessages) {
      final n = m.senderName;
      if (n != null && n.isNotEmpty) nameById[m.senderId] = n;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MessageInfoSheet(
        message: widget.message,
        cursors: cursors,
        nameById: nameById,
      ),
    );
  }

  Future<void> _saveFile(BuildContext context) async {
    final url = widget.message.fileUrl;
    if (url == null) return;
    final fileType = _effectiveFileType(widget.message);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.chatSaving), duration: const Duration(seconds: 1)),
      );

      if (PlatformUtils.instance.isDesktop) {
        // Desktop: Gal (gallery) has no macOS/Windows/Linux implementation —
        // use a native "Save as" dialog instead and write the bytes ourselves
        // (file_picker's saveFile only returns the chosen path on desktop).
        final ext = fileType == 'image'
            ? '.jpg'
            : fileType == 'video'
                ? '.mp4'
                : '';
        final fileName = widget.message.fileName ??
            'taler_${DateTime.now().millisecondsSinceEpoch}$ext';
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final res = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(res.data ?? const []);
        final savePath = await FilePicker.platform.saveFile(
          fileName: safeName,
        );
        if (savePath == null) return; // user cancelled — not an error
        await File(savePath).writeAsBytes(bytes);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.chatFileSaved}: $savePath'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      if (fileType == 'image' || fileType == 'video') {
        // Download to temp, then save to gallery
        final dir = await getTemporaryDirectory();
        final ext = fileType == 'image' ? '.jpg' : '.mp4';
        final fileName = widget.message.fileName ?? 'taler_${DateTime.now().millisecondsSinceEpoch}$ext';
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final filePath = '${dir.path}/save_$safeName';
        await Dio().download(url, filePath);

        if (fileType == 'image') {
          await Gal.putImage(filePath);
        } else {
          await Gal.putVideo(filePath);
        }
        // Clean up temp file
        try { await File(filePath).delete(); } catch (_) {}

        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatSavedToGallery), duration: const Duration(seconds: 2)),
        );
      } else {
        // Document / audio — download and open
        final dir = await getTemporaryDirectory();
        final fileName = widget.message.fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final filePath = '${dir.path}/messenger_files/$safeName';
        await Directory('${dir.path}/messenger_files').create(recursive: true);
        await Dio().download(url, filePath);
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      if (e.toString().contains('access')) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatNoSavePermission), duration: const Duration(seconds: 3)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.chatFileSaveError), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _showDeleteConfirm(BuildContext context) {
    final bloc = context.read<MessengerBloc>();
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.chatDeleteMessage,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text(l10n.chatDeleteForMe, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(DeleteMessage(
                  conversationId: widget.message.conversationId,
                  messageId: widget.message.id,
                  forEveryone: false,
                ));
              },
            ),
            if (widget.isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: Text(l10n.chatDeleteForEveryone, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DeleteMessage(
                    conversationId: widget.message.conversationId,
                    messageId: widget.message.id,
                    forEveryone: true,
                  ));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showForwardPicker(BuildContext context) =>
      showForwardPicker(context, [widget.message.id]);

  Widget _buildVideoNoteMessage(BuildContext context) {
    final colors = AppColors.of(context);
    const size = 200.0;
    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      onSecondaryTap: () => _showMessageActions(context),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender name for group chats
              if (!widget.isMe && widget.senderName != null && widget.senderName!.isNotEmpty && widget.isFirstInGroup)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(widget.senderName!, style: TextStyle(color: rainbowColorFor(widget.senderName!), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              _VideoNoteCirclePlayer(
                videoUrl: widget.message.fileUrl!,
                thumbnailUrl: widget.message.thumbnailMediumUrl,
                size: size,
                messageId: widget.message.id,
                autoPlayNotifier: widget.autoPlayVideoNote,
                onCompleted: () {
                  // allMessages is newest-first (reversed ListView). Next to play = older = idx+1.
                  final videoNotes = widget.allMessages
                      .where((m) => m.fileUrl != null && m.fileType == 'video_note')
                      .toList();
                  final idx = videoNotes.indexWhere((m) => m.id == widget.message.id);
                  if (idx >= 0 && idx + 1 < videoNotes.length) {
                    widget.autoPlayVideoNote?.value = videoNotes[idx + 1].id;
                  } else {
                    widget.autoPlayVideoNote?.value = null;
                  }
                },
              ),
              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat.Hm().format(widget.message.sentAt.toLocal()),
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.message.id.startsWith('temp_') ? Icons.access_time : Icons.done_all,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    String text;
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(widget.message.content) as Map<String, dynamic>;
      final action = data['action'] as String?;
      final actor = data['actor'] as String? ?? '';
      final target = data['target'] as String? ?? '';
      final role = data['role'] as String? ?? '';
      final l10n = AppLocalizations.of(context)!;
      switch (action) {
        case 'group_created': text = l10n.groupCreated; break;
        case 'member_added': text = l10n.memberJoined(target); break;
        case 'member_left': text = l10n.memberLeftGroup(actor); break;
        case 'member_removed': text = l10n.memberWasRemoved(target); break;
        case 'role_changed': text = l10n.roleChangedTo(target, role); break;
        case 'message_pinned': text = l10n.messagePinnedBy(actor); break;
        case 'call_invite':
          return _buildCallInviteCard(context, data);
        default: text = widget.message.content;
      }
    } catch (_) {
      text = widget.message.content;
    }

    final isMissedCall = text.contains('Пропущенный звонок') || text.contains('Missed call') || text.contains(AppLocalizations.of(context)!.messengerMissedCall);
    final colors = AppColors.of(context);

    if (isMissedCall) {
      final timeStr = DateFormat('HH:mm').format(widget.message.sentAt.toLocal());
      // senderId = initiator (caller). isMe=true means current user is the caller.
      if (widget.isMe) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_forwarded_rounded, color: colors.textSecondary, size: 14),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.callNoAnswer,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(width: 6),
                Text(timeStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        );
      }
      // Callee sees missed call with callback button
      return Center(
        child: GestureDetector(
          onTap: widget.onStartCall,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_missed_rounded, color: colors.error, size: 16),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(timeStr, style: TextStyle(color: colors.error.withValues(alpha: 0.7), fontSize: 11)),
                const SizedBox(width: 8),
                Icon(Icons.call_rounded, color: colors.primary, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCallInviteCard(BuildContext context, Map<String, dynamic> data) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fromName = data['fromUserName'] as String? ?? '';
    final roomName = data['roomName'] as String? ?? '';
    final e2eeKey = data['e2eeKey'] as String?;

    void accept() {
      final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
      final calleeParam = fromName.isNotEmpty ? '&callee=${Uri.encodeComponent(fromName)}' : '';
      context.read<MessengerBloc>().add(DismissCallInvite());
      context.push(
        '/dashboard/voice?room=$roomName&convId=${widget.message.conversationId}&incoming=1$e2eeParam$calleeParam',
      );
    }

    void reject() {
      context.read<MessengerBloc>().add(DismissCallInvite());
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary.withValues(alpha: 0.18), colors.accent.withValues(alpha: 0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_rounded, color: colors.primary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fromName.isNotEmpty
                        ? '${l10n.dashboardIncomingCall} · $fromName'
                        : l10n.dashboardIncomingCall,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: reject,
                  icon: Icon(Icons.call_end_rounded, size: 16, color: colors.error),
                  label: Text(l10n.reject, style: TextStyle(color: colors.error, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: accept,
                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                  label: Text(l10n.accept, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCardWidget extends StatelessWidget {
  final String content;
  const _ContactCardWidget({required this.content});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    try {
      final jsonStr = content.substring('[CONTACT]'.length);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = data['name'] as String? ?? AppLocalizations.of(context)!.chatContact;
      final userId = data['userId'] as String? ?? '';
      final avatar = data['avatar'] as String? ?? '';

      return GestureDetector(
        onTap: userId.isNotEmpty
            ? () => GoRouter.of(context).push('/dashboard/user/$userId')
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: rainbowColorFor(name), width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary,
                  backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                  child: avatar.isEmpty
                      ? Icon(Icons.person_rounded, color: Colors.black, size: 22)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(AppLocalizations.of(context)!.chatContactTapToOpen,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      );
    } catch (_) {
      return Text(content, style: TextStyle(color: colors.textPrimary, fontSize: 14));
    }
  }
}

// _LinkifiedText is now a shared widget: see core/theme/linkified_text.dart
// Kept as a thin typedef so existing call-sites compile without changes.
typedef _LinkifiedText = LinkifiedText;

class _CallOptionsSheet extends StatefulWidget {
  const _CallOptionsSheet();

  @override
  State<_CallOptionsSheet> createState() => _CallOptionsSheetState();
}

class _CallOptionsSheetState extends State<_CallOptionsSheet> {
  bool _withAi = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voiceCallSettings,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _withAi,
              onChanged: (v) => setState(() => _withAi = v),
              activeColor: AppColors.of(context).primary,
              title: Text(
                l10n.voiceEnableAI,
                style: TextStyle(color: AppColors.of(context).textPrimary),
              ),
              subtitle: Text(
                _withAi
                    ? l10n.voiceAIParticipating
                    : l10n.voiceNormalCall,
                style: TextStyle(
                    color: AppColors.of(context).textSecondary, fontSize: 12),
              ),
              secondary: Icon(
                Icons.smart_toy_outlined,
                color: _withAi ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _withAi),
              icon: const Icon(Icons.call_rounded, color: Colors.black),
              label: Text(
                l10n.chatCall,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Показывает выбор беседы и пересылает туда [messageIds].
///
/// Одна на два вызова — из меню одного сообщения и из мультивыбора: логика
/// «переслать и сразу открыть чат-получатель» должна быть одинаковой, иначе
/// пачка и одиночка ведут себя по-разному без всякой причины.
void showForwardPicker(BuildContext context, List<String> messageIds) {
  if (messageIds.isEmpty) return;
  final bloc = context.read<MessengerBloc>();
  final conversations = filterRecipients(bloc.state.conversations);
  final rootContext = context;

  void forwardTo(String convId) {
    bloc.add(ForwardMessages(
      messageIds: messageIds,
      targetConversationId: convId,
    ));
    // Открываем чат-получатель, чтобы пользователь оказался прямо на
    // пересланном и мог дописать сопровождение.
    if (rootContext.mounted) {
      rootContext.push('/dashboard/messenger/$convId');
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.of(context).card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ForwardPickerSheet(
      conversations: conversations,
      onSelected: forwardTo,
      onSelectSaved: () async {
        try {
          final res = await sl<DioClient>().post(
            '/messenger/saved',
            fromJson: (d) => Map<String, dynamic>.from(d as Map),
          );
          final convId = res['conversationId'] as String?;
          if (convId == null) return;
          forwardTo(convId);
        } catch (_) {}
      },
    ),
  );
}

class _ForwardPickerSheet extends StatefulWidget {
  final List<ConversationEntity> conversations;
  final void Function(String conversationId) onSelected;
  final VoidCallback? onSelectSaved;

  const _ForwardPickerSheet({
    required this.conversations,
    required this.onSelected,
    this.onSelectSaved,
  });

  @override
  State<_ForwardPickerSheet> createState() => _ForwardPickerSheetState();
}

class _ForwardPickerSheetState extends State<_ForwardPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.conversations.where((c) {
      final name = c.name ?? c.otherUserName ?? '';
      return name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.chatForwardTo,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.chatSearchHint,
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              // +1 for the Saved/Favorites entry at the top (hide while searching).
              itemCount: filtered.length + ((widget.onSelectSaved != null && _query.isEmpty) ? 1 : 0),
              itemBuilder: (_, i) {
                final hasSaved = widget.onSelectSaved != null && _query.isEmpty;
                if (hasSaved && i == 0) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFA855F7), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                          ),
                        ),
                        child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    title: Text(l10n.messengerSavedSection, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(l10n.messengerSavedSubtitle, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectSaved?.call();
                    },
                  );
                }
                final idx = hasSaved ? i - 1 : i;
                final conv = filtered[idx];
                final name = conv.name ?? conv.otherUserName ?? l10n.chatDialog;
                final avatarUrl = conv.type == 'DIRECT' ? conv.otherUserAvatar : conv.avatarUrl;
                final ringColor = rainbowColorFor(name.isNotEmpty ? name : conv.id);
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: ringColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: avatarUrl != null
                            ? null
                            : RadialGradient(
                                center: const Alignment(-0.3, -0.4),
                                radius: 1.1,
                                colors: [
                                  Color.lerp(ringColor, Colors.white, 0.28)!,
                                  ringColor,
                                  Color.lerp(ringColor, Colors.black, 0.38)!,
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                      ),
                      child: avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                    ),
                  ),
                  title: Text(name, style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelected(conv.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isRecording;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;
  final VoidCallback? onVideoNote;
  final VoidCallback? onVideoRecordStart;
  final VoidCallback? onVideoRecordStop;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.isRecording,
    required this.onRecordStart,
    required this.onRecordStop,
    this.onVideoNote,
    this.onVideoRecordStart,
    this.onVideoRecordStop,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  /// true = mic mode (default), false = video mode
  bool _micMode = true;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!PlatformUtils.instance.isDesktop) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final cmdPressed = keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight) ||
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
    if (cmdPressed) {
      final controller = widget.controller;
      final sel = controller.selection;
      final start = sel.start < 0 ? controller.text.length : sel.start;
      final end = sel.end < 0 ? controller.text.length : sel.end;
      final newText = controller.text.replaceRange(start, end, '\n');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + 1),
      );
      return KeyEventResult.handled;
    }
    widget.onSend();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.isRecording ? null : widget.onAttach,
            icon: Icon(Icons.attach_file_rounded, color: colors.textSecondary),
          ),
          Expanded(
            child: widget.isRecording
                ? Row(
                    children: [
                      Icon(Icons.circle, color: colors.error, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        _micMode
                            ? AppLocalizations.of(context)!.chatRecording
                            : AppLocalizations.of(context)!.chatRecording,
                        style: TextStyle(color: colors.error, fontSize: 14),
                      ),
                    ],
                  )
                : Focus(
                    onKeyEvent: _handleKey,
                    child: TextField(
                      controller: widget.controller,
                      style: TextStyle(color: colors.textPrimary),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.chatMessageHint,
                        hintStyle: TextStyle(color: colors.textSecondary),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
          ),
          // Mic / Video toggle button:
          // - Tap: switch between mic ↔ video mode
          // - Long press mic: record voice (release = send)
          // - Long press video: record video note (release = stop & send)
          GestureDetector(
            onTap: () {
              if (widget.isRecording) return;
              setState(() => _micMode = !_micMode);
            },
            onLongPressStart: (_) {
              if (_micMode) {
                widget.onRecordStart();
              } else {
                widget.onVideoRecordStart?.call();
              }
            },
            onLongPressEnd: (_) {
              if (_micMode) {
                widget.onRecordStop();
              } else {
                widget.onVideoRecordStop?.call();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isRecording
                      ? Icons.stop_circle_rounded
                      : _micMode
                          ? Icons.mic_rounded
                          : Icons.videocam_rounded,
                  key: ValueKey(widget.isRecording ? 'stop' : _micMode ? 'mic' : 'video'),
                  color: widget.isRecording
                      ? colors.error
                      : _micMode
                          ? colors.textSecondary
                          : colors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          if (!widget.isRecording)
            IconButton(
              onPressed: widget.onSend,
              icon: Icon(Icons.send_rounded, color: colors.primary),
            ),
        ],
      ),
    ),
    );
  }
}

class _ReplyPreviewBar extends StatelessWidget {
  final MessageEntity message;
  final String? senderName;
  final VoidCallback onCancel;
  const _ReplyPreviewBar({required this.message, this.senderName, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final preview = message.fileUrl != null
        ? '📎 ${message.fileName ?? l10n.chatFile}'
        : message.content;
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName ?? '',
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _EditPreviewBar extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onCancel;
  const _EditPreviewBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final preview = message.content;
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, color: colors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.chatEditing,
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _DocumentBubble extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  const _DocumentBubble({required this.fileUrl, required this.fileName, this.fileSize});
  @override
  State<_DocumentBubble> createState() => _DocumentBubbleState();
}

class _DocumentBubbleState extends State<_DocumentBubble> {
  double? _progress;
  bool _downloading = false;

  String get _sizeLabel {
    if (widget.fileSize == null) return '';
    final kb = widget.fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _openFile() async {
    final dir = await getTemporaryDirectory();
    final safeName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final filePath = '${dir.path}/messenger_files/$safeName';
    final file = File(filePath);

    // Use cached file if exists
    if (await file.exists()) {
      await OpenFilex.open(filePath);
      return;
    }

    setState(() { _downloading = true; _progress = 0; });

    try {
      await Directory('${dir.path}/messenger_files').create(recursive: true);
      await Dio().download(
        widget.fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (!mounted) return;
      setState(() { _downloading = false; _progress = null; });
      await OpenFilex.open(filePath);
    } catch (e) {
      if (!mounted) return;
      setState(() { _downloading = false; _progress = null; });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatFileDownloadError),
          action: SnackBarAction(label: l10n.retry, onPressed: _openFile),
        ),
      );
    }
  }

  static Color _extColor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf': return const Color(0xFFE53935);
      case 'doc': case 'docx': return const Color(0xFF1565C0);
      case 'xls': case 'xlsx': return const Color(0xFF2E7D32);
      case 'ppt': case 'pptx': return const Color(0xFFEF6C00);
      case 'zip': case 'rar': case '7z': return const Color(0xFF6A1B9A);
      case 'mp3': case 'wav': case 'ogg': return const Color(0xFF00838F);
      default: return const Color(0xFF455A64);
    }
  }

  static IconData _extIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'xls': case 'xlsx': return Icons.table_chart_rounded;
      case 'ppt': case 'pptx': return Icons.slideshow_rounded;
      case 'zip': case 'rar': case '7z': return Icons.folder_zip_rounded;
      case 'mp3': case 'wav': case 'ogg': return Icons.audio_file_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _extColor(widget.fileName);
    final icon = _extIcon(widget.fileName);
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: _downloading ? null : _openFile,
      child: Container(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with download progress overlay
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (_downloading)
                    SizedBox(
                      width: 44, height: 44,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 2.5,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (_sizeLabel.isNotEmpty) ...[
                        Text(_sizeLabel, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                        const SizedBox(width: 6),
                      ],
                      if (_downloading)
                        Text(
                          '${((_progress ?? 0) * 100).toInt()}%',
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                        )
                      else
                        Icon(Icons.download_rounded, size: 13, color: colors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumb;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final data = await vt.VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 440,
        quality: 75,
      );
      if (mounted && data != null) {
        setState(() {
          _thumb = data;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        if (_thumb != null)
          Image.memory(_thumb!, fit: BoxFit.cover)
        else
          Container(
            color: Colors.black87,
            child: Center(
              child: _loaded
                  ? Icon(Icons.videocam_rounded, color: Colors.white54, size: 48)
                  : CircularProgressIndicator(strokeWidth: 2, color: AppColors.of(context).primary),
            ),
          ),
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  final String fileUrl;
  final bool isMe;
  const _AudioMessagePlayer({required this.fileUrl, required this.isMe});

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  late final List<double> _waveform;

  @override
  void initState() {
    super.initState();
    _waveform = _buildWaveform(widget.fileUrl);
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
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

  /// Deterministic pseudo-random waveform from URL hash.
  static List<double> _buildWaveform(String url) {
    var h = url.hashCode;
    return List.generate(28, (_) {
      h = ((h * 1664525 + 1013904223) & 0x7FFFFFFF);
      return 0.15 + (h & 0xFF) / 255.0 * 0.85;
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      try {
        final file = await DefaultCacheManager().getSingleFile(widget.fileUrl);
        await _player.play(DeviceFileSource(file.path));
      } catch (_) {
        await _player.play(UrlSource(widget.fileUrl));
      }
      await _player.setPlaybackRate(_speed);
      setState(() => _playing = true);
    }
  }

  Future<void> _toggleSpeed() async {
    final newSpeed = _speed == 1.0 ? 2.0 : 1.0;
    setState(() => _speed = newSpeed);
    if (_playing) await _player.setPlaybackRate(newSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onBubble = widget.isMe;
    final waveActive = onBubble ? Colors.white : colors.primary;
    final waveInactive = onBubble
        ? Colors.white.withValues(alpha: 0.35)
        : colors.primary.withValues(alpha: 0.3);
    final timeColor = onBubble
        ? Colors.white.withValues(alpha: 0.65)
        : colors.textSecondary;

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final displayTime =
        _duration > Duration.zero ? _fmt(_playing ? _position : _duration) : '0:00';

    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: waveActive.withValues(alpha: onBubble ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: waveActive,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 28,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      bars: _waveform,
                      progress: progress,
                      activeColor: waveActive,
                      inactiveColor: waveInactive,
                    ),
                    size: const Size(double.infinity, 28),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(displayTime,
                        style: TextStyle(color: timeColor, fontSize: 11)),
                    GestureDetector(
                      onTap: _toggleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: waveActive.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _speed == 1.0 ? '1×' : '2×',
                          style: TextStyle(
                              color: waveActive,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
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

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = bars.length;
    if (n == 0) return;
    final totalBarWidth = size.width / n;
    final barW = totalBarWidth * 0.55;
    final gap = totalBarWidth * 0.45;

    for (int i = 0; i < n; i++) {
      final x = i * (barW + gap);
      final barH = bars[i] * size.height;
      final y = (size.height - barH) / 2;
      final isPast = i / n <= progress;
      final paint = Paint()
        ..color = isPast ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barW, barH), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}

class _ReactionsRow extends StatelessWidget {
  final List<Map<String, dynamic>> reactions;
  final String? currentUserId;
  final void Function(String emoji)? onTap;
  const _ReactionsRow({required this.reactions, this.currentUserId, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Group reactions by emoji: { emoji: [userId, ...] }
    final grouped = <String, List<String>>{};
    for (final r in reactions) {
      final emoji = r['emoji'] as String? ?? '';
      final userId = r['userId'] as String? ?? '';
      grouped.putIfAbsent(emoji, () => []).add(userId);
    }
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: grouped.entries.map((entry) {
          final isMine = entry.value.contains(currentUserId);
          return GestureDetector(
            onTap: onTap != null ? () => onTap!(entry.key) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMine
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.card,
                borderRadius: BorderRadius.circular(12),
                border: isMine
                    ? Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  if (entry.value.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${entry.value.length}',
                      style: TextStyle(
                        color: isMine ? colors.primary : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Fullscreen Image Gallery ────────────────────────────

class _FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final List<String>? heroTags;
  final int initialIndex;
  const _FullScreenImageGallery({required this.imageUrls, this.heroTags, this.initialIndex = 0});

  @override
  State<_FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final heroTag = widget.heroTags != null && i < widget.heroTags!.length
                  ? widget.heroTags![i]
                  : null;
              final img = CachedNetworkImage(
                imageUrl: widget.imageUrls[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
              );
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: heroTag != null
                      ? Hero(tag: heroTag, child: img)
                      : img,
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 26),
                  onPressed: _sharing ? null : _shareCurrentImage,
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 26),
                  onPressed: _saving ? null : _saveCurrentImage,
                ),
              ],
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _saving = false;
  bool _sharing = false;

  Future<void> _shareCurrentImage() async {
    setState(() => _sharing = true);
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/share_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(widget.imageUrls[_currentIndex], filePath);
      if (mounted) await shareFiles(context, [XFile(filePath)]);
      try { await File(filePath).delete(); } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _sharing = false);
  }

  Future<void> _saveCurrentImage() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/save_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(widget.imageUrls[_currentIndex], filePath);
      await Gal.putImage(filePath);
      try { await File(filePath).delete(); } catch (_) {}
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatSavedToGallery), duration: const Duration(seconds: 2)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatSavingError), duration: const Duration(seconds: 2)),
      );
    }
    if (mounted) setState(() => _saving = false);
  }
}

// ─── Fullscreen Video Player ─────────────────────────────

class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  vp.VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _savingVideo = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Use network URL directly — more reliable on iOS than cache manager for videos
    try {
      _ctrl = vp.VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: const {'User-Agent': 'TalerID/1.0'},
      );
      await _ctrl!.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      _ctrl!.play();
      _ctrl!.addListener(_onVideoUpdate);
      _scheduleHideControls();
    } catch (e) {
      // Fallback: try via cache
      try {
        final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
        if (!mounted) return;
        _ctrl?.dispose();
        _ctrl = vp.VideoPlayerController.file(file);
        await _ctrl!.initialize();
        if (!mounted) return;
        setState(() => _initialized = true);
        _ctrl!.play();
        _ctrl!.addListener(_onVideoUpdate);
        _scheduleHideControls();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.messengerVideoPlaybackError)),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  Future<void> _saveVideo() async {
    setState(() => _savingVideo = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Request permission first
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          messenger.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.messengerGalleryAccessError)),
          );
          if (mounted) setState(() => _savingVideo = false);
          return;
        }
      }
      final dir = await getTemporaryDirectory();
      final ext = widget.videoUrl.split('?').first.split('.').last;
      final filePath = '${dir.path}/save_vid_${DateTime.now().millisecondsSinceEpoch}.${ext.isNotEmpty ? ext : 'mp4'}';
      await Dio().download(widget.videoUrl, filePath);
      await Gal.putVideo(filePath);
      try { await File(filePath).delete(); } catch (_) {}
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatVideoSavedToGallery), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.chatSavingError}: $e'), duration: const Duration(seconds: 3)),
      );
    }
    if (mounted) setState(() => _savingVideo = false);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl?.removeListener(_onVideoUpdate);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: _initialized && _ctrl != null
                  ? AspectRatio(
                      aspectRatio: _ctrl!.value.aspectRatio,
                      child: vp.VideoPlayer(_ctrl!),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            if (_showControls) ...[
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                  onPressed: _savingVideo ? null : _saveVideo,
                ),
              ),
              if (_initialized)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 48,
                        icon: Icon(
                          _ctrl!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
                          _scheduleHideControls();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDuration(_ctrl!.value.position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Expanded(
                            child: Slider(
                              value: _ctrl!.value.duration.inMilliseconds > 0
                                  ? _ctrl!.value.position.inMilliseconds / _ctrl!.value.duration.inMilliseconds
                                  : 0,
                              onChanged: (v) {
                                _ctrl!.seekTo(Duration(
                                  milliseconds: (v * _ctrl!.value.duration.inMilliseconds).toInt(),
                                ));
                                _scheduleHideControls();
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                            ),
                          ),
                          Text(
                            _formatDuration(_ctrl!.value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PollWidget extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;
  const _PollWidget({required this.message, required this.isMe});

  @override
  State<_PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<_PollWidget> {
  Map<String, dynamic>? _pollData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    try {
      final data = await sl<DioClient>().get(
        '/messenger/messages/${widget.message.id}/poll',
        fromJson: (d) => d as Map<String, dynamic>,
      );
      if (mounted) setState(() { _pollData = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(String optionId) async {
    try {
      final data = await sl<DioClient>().post(
        '/messenger/polls/$optionId/vote',
        fromJson: (d) => d as Map<String, dynamic>,
      );
      if (mounted) setState(() => _pollData = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (_loading) return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2));
    if (_pollData == null) return Text(AppLocalizations.of(context)!.messengerPollUnavailable, style: TextStyle(color: colors.textSecondary));

    final question = _pollData!['question'] as String? ?? '';
    final options = (_pollData!['options'] as List?) ?? [];
    final isMultiple = _pollData!['isMultiple'] as bool? ?? false;
    final totalVotes = options.fold<int>(0, (sum, o) => sum + ((o['votes'] as List?)?.length ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.poll_rounded, size: 16, color: widget.isMe ? Colors.white70 : colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(question, style: TextStyle(
                color: widget.isMe ? Colors.white : colors.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w600,
              )),
            ),
          ],
        ),
        if (isMultiple)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(AppLocalizations.of(context)!.messengerPollMultipleNote, style: TextStyle(
              color: widget.isMe ? Colors.white54 : colors.textSecondary, fontSize: 11)),
          ),
        const SizedBox(height: 8),
        ...options.map<Widget>((o) {
          final optionId = o['id'] as String;
          final text = o['text'] as String? ?? '';
          final votes = (o['votes'] as List?) ?? [];
          final voteCount = votes.length;
          final fraction = totalVotes > 0 ? voteCount / totalVotes : 0.0;
          final myVote = votes.any((v) => v['userId'] == context.read<MessengerBloc>().state.currentUserId);

          return GestureDetector(
            onTap: () => _vote(optionId),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (widget.isMe ? Colors.white : colors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: myVote ? Border.all(color: widget.isMe ? Colors.white : colors.primary, width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(text, style: TextStyle(
                          color: widget.isMe ? Colors.white : colors.textPrimary, fontSize: 13))),
                        Text('$voteCount', style: TextStyle(
                          color: widget.isMe ? Colors.white70 : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0, top: 0, bottom: 0,
                    child: Container(
                      width: (MediaQuery.of(context).size.width * 0.6) * fraction,
                      decoration: BoxDecoration(
                        color: (widget.isMe ? Colors.white : colors.primary).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        Text(AppLocalizations.of(context)!.messengerPollVotes(totalVotes), style: TextStyle(
          color: widget.isMe ? Colors.white54 : colors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _PendingFile {
  final String path;
  final String name;
  final String? type;
  const _PendingFile({required this.path, required this.name, this.type});
}

// ── Inline video note recorder (circular camera overlay) ──

class _VideoNoteOverlay extends StatefulWidget {
  final void Function(String path) onDone;
  final void Function(String path)? onSegmentDone; // send segment, keep recording
  final VoidCallback onCancel;
  const _VideoNoteOverlay({super.key, required this.onDone, this.onSegmentDone, required this.onCancel});

  @override
  State<_VideoNoteOverlay> createState() => _VideoNoteOverlayState();
}

class _VideoNoteOverlayState extends State<_VideoNoteOverlay> with SingleTickerProviderStateMixin {
  CameraController? _cam;
  bool _initializing = true;
  bool _recording = false;
  bool _stopping = false;
  Timer? _timer;
  int _seconds = 0;
  static const _maxSeconds = 60;
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: _maxSeconds));
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) { widget.onCancel(); return; }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cam = CameraController(front, ResolutionPreset.medium, enableAudio: true);
      await _cam!.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
      _startRecording();
    } catch (e) {
      debugPrint('[VideoNote] Camera init error: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _startRecording() async {
    if (_cam == null || !_cam!.value.isInitialized) return;
    try {
      await _cam!.startVideoRecording();
      _stopping = false;
      setState(() => _recording = true);
      _ringCtrl.forward(from: 0);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= _maxSeconds) _autoSegment();
      });
    } catch (e) {
      debugPrint('[VideoNote] Start recording error: $e');
      if (mounted) widget.onCancel();
    }
  }

  /// Auto-send current segment and start recording the next one
  Future<void> _autoSegment() async {
    if (_stopping || !_recording) return;
    _stopping = true;
    _timer?.cancel();
    _ringCtrl.stop();
    try {
      final xfile = await _cam!.stopVideoRecording();
      final ext = xfile.path.split('.').last;
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/video_note_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(xfile.path).copy(outPath);
      // Send this segment but keep overlay open
      if (widget.onSegmentDone != null) {
        widget.onSegmentDone!(outPath);
      } else {
        widget.onDone(outPath);
      }
      // Reset and start next recording immediately
      if (mounted && widget.onSegmentDone != null) {
        setState(() { _seconds = 0; _recording = false; });
        await _startRecording();
      }
    } catch (e) {
      debugPrint('[VideoNote] Auto-segment error: $e');
      if (mounted) widget.onCancel();
    }
  }

  /// Final stop — user released the button
  Future<void> stopAndSend() async {
    if (_stopping || !_recording) return;
    _stopping = true;
    _timer?.cancel();
    _ringCtrl.stop();
    try {
      final xfile = await _cam!.stopVideoRecording();
      final ext = xfile.path.split('.').last;
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/video_note_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(xfile.path).copy(outPath);
      if (mounted) widget.onDone(outPath);
    } catch (e) {
      debugPrint('[VideoNote] Stop recording error: $e');
      if (mounted) widget.onCancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringCtrl.dispose();
    _cam?.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.65;

    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            SizedBox(
              width: circleSize + 12,
              height: circleSize + 12,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  SizedBox(
                    width: circleSize + 12,
                    height: circleSize + 12,
                    child: AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) => CircularProgressIndicator(
                        value: _ringCtrl.value,
                        strokeWidth: 4,
                        backgroundColor: colors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.error),
                      ),
                    ),
                  ),
                  // Camera preview
                  ClipOval(
                    child: SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: _initializing || _cam == null
                          ? Container(
                              color: colors.surface,
                              child: Center(child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2)),
                            )
                          : FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cam!.value.previewSize?.height ?? circleSize,
                                height: _cam!.value.previewSize?.width ?? circleSize,
                                child: CameraPreview(_cam!),
                              ),
                            ),
                    ),
                  ),
                  // Timer badge
                  if (_recording)
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(_timeStr, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Отпустите для отправки', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ── Circular video note player with progress ring (draggable) ──

class _VideoNoteCirclePlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double size;
  final String? messageId;
  final ValueNotifier<String?>? autoPlayNotifier;
  final VoidCallback? onCompleted;
  const _VideoNoteCirclePlayer({required this.videoUrl, this.thumbnailUrl, this.size = 200, this.messageId, this.autoPlayNotifier, this.onCompleted});

  @override
  State<_VideoNoteCirclePlayer> createState() => _VideoNoteCirclePlayerState();
}

class _VideoNoteCirclePlayerState extends State<_VideoNoteCirclePlayer> {
  vp.VideoPlayerController? _ctrl;
  bool _playing = false;
  bool _initialized = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    widget.autoPlayNotifier?.addListener(_onAutoPlay);
  }

  void _onAutoPlay() {
    if (widget.autoPlayNotifier?.value == widget.messageId) {
      _initAndPlay();
    }
  }

  @override
  void dispose() {
    widget.autoPlayNotifier?.removeListener(_onAutoPlay);
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _initAndPlay() async {
    if (_ctrl != null) {
      if (_playing) {
        _ctrl!.pause();
        setState(() => _playing = false);
      } else {
        _ctrl!.play();
        setState(() => _playing = true);
      }
      return;
    }
    setState(() {}); // show loading
    try {
      debugPrint('[VideoNote] Loading: ${widget.videoUrl}');
      // Download to local cache first for reliable iOS playback
      final cacheManager = DefaultCacheManager();
      final fileInfo = await cacheManager.downloadFile(widget.videoUrl);
      debugPrint('[VideoNote] Cached at: ${fileInfo.file.path}');
      _ctrl = vp.VideoPlayerController.file(
        fileInfo.file,
        videoPlayerOptions: vp.VideoPlayerOptions(mixWithOthers: true),
      );
      await _ctrl!.initialize();
      debugPrint('[VideoNote] Initialized: ${_ctrl!.value.size}');
      _ctrl!.setLooping(false);
      _ctrl!.setVolume(1.0);
      _completed = false;
      _ctrl!.addListener(_onVideoUpdate);
      await _ctrl!.play();
      if (mounted) setState(() { _initialized = true; _playing = true; });
    } catch (e) {
      debugPrint('[VideoNote] Play error: $e');
      try {
        _ctrl = vp.VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: vp.VideoPlayerOptions(mixWithOthers: true),
        );
        await _ctrl!.initialize();
        _ctrl!.setLooping(false);
        _completed = false;
        _ctrl!.addListener(_onVideoUpdate);
        await _ctrl!.play();
        if (mounted) setState(() { _initialized = true; _playing = true; });
      } catch (e2) {
        debugPrint('[VideoNote] Network fallback also failed: $e2');
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    setState(() {});
    final v = _ctrl?.value;
    if (v != null && v.isInitialized && !v.isPlaying && v.position >= v.duration && v.duration > Duration.zero && !_completed) {
      _completed = true;
      setState(() => _playing = false);
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = (_ctrl != null && _initialized && _ctrl!.value.duration.inMilliseconds > 0)
        ? _ctrl!.value.position.inMilliseconds / _ctrl!.value.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: _initAndPlay,
      child: SizedBox(
        width: widget.size + 6,
        height: widget.size + 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            SizedBox(
              width: widget.size + 6,
              height: widget.size + 6,
              child: CircularProgressIndicator(
                value: progress.toDouble(),
                strokeWidth: 3,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            // Video / thumbnail
            ClipOval(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: _initialized && _ctrl != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _ctrl!.value.size.width,
                          height: _ctrl!.value.size.height,
                          child: vp.VideoPlayer(_ctrl!),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.thumbnailUrl != null)
                            CachedNetworkImage(imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
                          else
                            Container(color: colors.surface),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline audio player for call recordings ──

// ── Live listen-in sheet (connects to LiveKit room as listener) ──

class _OutboundListenSheet extends StatefulWidget {
  final String businessName;
  final String token;
  final String wsUrl;
  const _OutboundListenSheet({required this.businessName, required this.token, required this.wsUrl});
  @override
  State<_OutboundListenSheet> createState() => _OutboundListenSheetState();
}

class _OutboundListenSheetState extends State<_OutboundListenSheet> with SingleTickerProviderStateMixin {
  lk.Room? _room;
  bool _connecting = true;
  String? _error;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _connect();
  }

  Future<void> _connect() async {
    try {
      final room = lk.Room();
      await room.connect(
        widget.wsUrl,
        widget.token,
        connectOptions: const lk.ConnectOptions(autoSubscribe: true),
      );
      if (mounted) setState(() { _room = room; _connecting = false; });
    } catch (e) {
      debugPrint('[ListenSheet] connect error: $e');
      if (mounted) setState(() { _error = e.toString(); _connecting = false; });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _room?.disconnect().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_connecting) ...[
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text('Подключение к разговору...', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ] else if (_error != null) ...[
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text('Ошибка подключения', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
          ] else ...[
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.08 + 0.12 * _pulseCtrl.value),
                ),
                child: Icon(Icons.headphones_rounded, color: colors.primary, size: 38),
              ),
            ),
            const SizedBox(height: 16),
            Text('Слушаем разговор', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              widget.businessName,
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.call_end_rounded),
              label: const Text('Отключиться'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingPlayer extends StatefulWidget {
  final String url;
  const _RecordingPlayer({required this.url});

  @override
  State<_RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<_RecordingPlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  bool _downloading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
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
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
    } else {
      if (mounted) setState(() => _loading = true);
      try {
        try {
          final file = await DefaultCacheManager().getSingleFile(widget.url);
          await _player.play(DeviceFileSource(file.path));
        } catch (_) {
          await _player.play(UrlSource(widget.url));
        }
        if (mounted) setState(() { _playing = true; _loading = false; });
      } catch (e) {
        if (mounted) setState(() => _loading = false);
        debugPrint('[RecordingPlayer] Error: $e');
      }
    }
  }

  Future<void> _seek(double value) async {
    final pos = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    await _player.seek(pos);
  }

  Future<void> _download() async {
    if (_downloading) return;
    if (mounted) setState(() => _downloading = true);
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.url);
      if (!mounted) return;
      await shareFiles(
        context,
        [XFile(file.path, mimeType: 'audio/mpeg', name: 'запись.mp3')],
      );
    } catch (e) {
      debugPrint('[RecordingPlayer] Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final timeStr = _fmt(_playing || _position > Duration.zero ? _position : _duration);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _loading ? null : _toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                    )
                  : Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.primary.withValues(alpha: 0.2),
                    thumbColor: colors.primary,
                    overlayColor: colors.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: _duration > Duration.zero ? _seek : null,
                    min: 0,
                    max: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _duration > Duration.zero ? '$timeStr / ${_fmt(_duration)}' : '–:––',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _downloading ? null : _download,
            icon: _downloading
                ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary),
                  )
                : Icon(Icons.download_rounded, color: colors.textSecondary, size: 20),
            tooltip: 'Скачать',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── AI Bot content with markdown + action buttons ──

class AiBotContent extends StatelessWidget {
  final String content;
  final String conversationId;
  final String? topicId;
  const AiBotContent({super.key, required this.content, required this.conversationId, this.topicId});

  static DateTime _lastActionTap = DateTime(2000);

  static final _recordingRegex = RegExp(r'\[▶ Слушать / Скачать\]\(([^)]+)\)');

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // Split content into text and action buttons
    final actionRegex = RegExp(r'\[ACTION:(.+?)\]');
    final listenRegex = RegExp(r'\[LISTEN:[^\]]+\]');
    final actions = actionRegex.allMatches(content).map((m) => m.group(1)!).toList();

    // Extract recording URLs before stripping
    final recordingUrls = _recordingRegex
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();

    final textContent = content
        .replaceAll(actionRegex, '')
        .replaceAll(listenRegex, '')
        .replaceAll(_recordingRegex, '')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (textContent.isNotEmpty)
          MarkdownBody(
            data: textContent,
            selectable: true,
            softLineBreak: true,
            extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              [
                ColorTextInlineSyntax(),
                ColorBadgeInlineSyntax(),
                ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                md.AutolinkExtensionSyntax(),
              ],
            ),
            builders: {
              'color_text': ColorTextBuilder(context),
              'color_badge': ColorBadgeBuilder(context),
            },
            onTapLink: (text, href, title) {
              if (href == null) return;
              final uri = Uri.tryParse(href.startsWith('http') ? href : 'https://$href');
              if (uri != null) launchUrl(uri, mode: LaunchMode.inAppBrowserView);
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.45),
              h1: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              h2: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              h3: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              strong: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
              a: TextStyle(color: colors.primary, decoration: TextDecoration.underline),
              listBullet: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
        for (final url in recordingUrls) _RecordingPlayer(url: url),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _ActionCardButton(
                  action: actions[i],
                  onTap: () {
                    final now = DateTime.now();
                    if (now.difference(_lastActionTap).inMilliseconds < 1500) return;
                    _lastActionTap = now;
                    context.read<MessengerBloc>().add(
                          SendMessage(conversationId, actions[i], topicId: topicId),
                        );
                  },
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Pretty full-width action button used for AI bot replies. Each action gets
/// a colored gradient, an icon picked from the label content, and a chevron
/// on the right so it reads as a tappable card rather than a chip.
class _ActionCardButton extends StatelessWidget {
  final String action;
  final VoidCallback onTap;
  const _ActionCardButton({required this.action, required this.onTap});

  ({Color color, IconData icon}) _pickStyle(String a) {
    final s = a.toLowerCase();
    // Emoji-prefixed labels (Informer + future bots) take priority.
    if (a.contains('📋')) return (color: const Color(0xFF6366F1), icon: Icons.list_alt_rounded);
    if (a.contains('💰')) return (color: const Color(0xFFFFB300), icon: Icons.account_balance_wallet_rounded);
    if (a.contains('🏦')) return (color: const Color(0xFF14B8A6), icon: Icons.account_balance_rounded);
    if (a.contains('🔄')) return (color: const Color(0xFFEF4444), icon: Icons.refresh_rounded);
    if (a.contains('🎧')) return (color: const Color(0xFF8B5CF6), icon: Icons.headphones_rounded);
    // Word-based fallbacks for legacy AI Обзвон / AI Аналитик buttons.
    if (s.contains('достаточно') || s.contains('стоп')) {
      return (color: const Color(0xFFF59E0B), icon: Icons.stop_rounded);
    }
    if (s.contains('сводка') || s.contains('итоги')) {
      return (color: const Color(0xFF3B82F6), icon: Icons.analytics_rounded);
    }
    if (s.contains('продолжить') || s.contains('начинай')) {
      return (color: const Color(0xFF34D399), icon: Icons.play_arrow_rounded);
    }
    if (s.contains('ищи') || s.contains('search')) {
      return (color: const Color(0xFF8B5CF6), icon: Icons.search_rounded);
    }
    return (color: const Color(0xFF34D399), icon: Icons.check_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final style = _pickStyle(action);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [style.color, style.color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: style.color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
