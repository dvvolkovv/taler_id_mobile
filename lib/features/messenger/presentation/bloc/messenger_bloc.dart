import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/repositories/i_messenger_repository.dart'
    show IMessengerRepository, MeshInboundMessage, MeshOutboundMessage;
import '../../../../core/services/messenger_cache_service.dart';
import '../../../../core/services/pending_message_service.dart';
import '../../../../core/services/share_suggestions_service.dart';
import '../../data/services/pending_mesh_send_queue.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/sync_cursor_storage.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/mesh/services/device_key_sync_service.dart';
import '../../../../core/notifications/desktop/desktop_notifications_service.dart';
import '../../../../core/platform/platform_utils.dart';
import 'messenger_event.dart';
import 'messenger_state.dart';

class MessengerBloc extends Bloc<MessengerEvent, MessengerState>
    with WidgetsBindingObserver {
  final IMessengerRepository _repo;
  final MessengerCacheService _cache = sl<MessengerCacheService>();
  final PendingMessageService _pending = sl<PendingMessageService>();
  final PendingMeshSendQueue _pendingMeshQueue = sl<PendingMeshSendQueue>();
  StreamSubscription? _msgSub;
  StreamSubscription? _callSub;
  StreamSubscription? _msgUpdatedSub;
  StreamSubscription? _msgsReadSub;
  StreamSubscription? _groupUpdatedSub;
  StreamSubscription? _groupMemberAddedSub;
  StreamSubscription? _groupMemberRemovedSub;
  StreamSubscription? _groupRoleChangedSub;
  StreamSubscription? _groupCreatedSub;
  StreamSubscription? _groupDeletedSub;
  StreamSubscription? _groupCallStartedSub;
  StreamSubscription? _groupCallEndedSub;
  StreamSubscription? _msgDeletedSub;
  StreamSubscription? _msgAckedSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _contactReqSub;
  StreamSubscription? _contactAccSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _socketErrorSub;
  StreamSubscription? _reconnectSub;
  StreamSubscription? _disconnectSub;
  StreamSubscription? _analystChunkSub;
  StreamSubscription? _analystSeamSub;
  StreamSubscription? _meshMsgSub;
  StreamSubscription? _meshOutSub;
  final Map<String, Timer> _typingTimers = {}; // auto-clear typing after timeout
  late final SyncCursorStorage _syncCursorStorage = sl<SyncCursorStorage>();
  bool _syncInProgress = false;

  /// Tracks pending clientTempIds that have been emitted to the server and
  /// are awaiting a `new_message` broadcast. Prevents _resendPending() from
  /// re-emitting the same message on every reconnect cycle — even when the
  /// socket flaps multiple times before the server ACK round-trips.
  final Set<String> _inFlightTempIds = {};

  /// Phase 2 — window for cross-transport dedup heuristic. When a logical
  /// message arrives via mesh and the server echo (or vice versa) within
  /// this window with matching (senderId, content), the second copy is
  /// dropped. Tuned for typical mobile network jitter; double-taps within
  /// this window will silently dedup (intentional false-positive).
  static const Duration _crossTransportDedupWindow = Duration(seconds: 10);

  MessengerBloc({required IMessengerRepository repo})
      : _repo = repo,
        super(const MessengerState()) {
    on<ConnectMessenger>(_onConnect);
    on<DisconnectMessenger>((_, emit) {
      sl<MessengerRemoteDataSource>().disconnect();
      emit(state.copyWith(isConnected: false));
    });
    on<LoadConversations>(_onLoadConversations);
    on<OpenConversation>(_onOpenConversation);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SearchUsers>(_onSearchUsers);
    on<StartConversationWith>(_onStartConversationWith);
    on<ClearNewConversation>((_, emit) =>
        emit(state.copyWith(clearNewConversation: true)));
    on<CallInviteReceived>(_onCallInviteReceived);
    on<DismissCallInvite>((_, emit) {
      // Also remove any locally-injected call_invite_* system rows from
      // conversation histories — the user has acted on them (accepted,
      // rejected, or timed out).
      final cleaned = <String, List<MessageEntity>>{};
      state.messages.forEach((convId, msgs) {
        cleaned[convId] = msgs.where((m) => !m.id.startsWith('call_invite_')).toList();
      });
      emit(state.copyWith(clearCallInvite: true, messages: cleaned));
    });
    on<MessageUpdated>(_onMessageUpdated);
    on<MessagesRead>(_onMessagesRead);
    on<MarkConversationRead>(_onMarkConversationRead);
    // Group handlers
    on<CreateGroup>(_onCreateGroup);
    on<LoadGroupMembers>(_onLoadGroupMembers);
    on<AddGroupMembers>(_onAddGroupMembers);
    on<RemoveGroupMember>(_onRemoveGroupMember);
    on<ChangeGroupRole>(_onChangeGroupRole);
    on<UpdateGroupInfo>(_onUpdateGroupInfo);
    on<LeaveGroup>(_onLeaveGroup);
    on<DeleteGroup>(_onDeleteGroup);
    on<UpdateGroupSettings>(_onUpdateGroupSettings);
    on<GroupEventReceived>(_onGroupEventReceived);
    on<MuteConversation>(_onMuteConversation);
    on<UnmuteConversation>(_onUnmuteConversation);
    on<GroupCallStarted>(_onGroupCallStarted);
    on<GroupCallEnded>(_onGroupCallEnded);
    on<ForwardMessage>(_onForwardMessage);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<MessageDeleted>(_onMessageDeleted);
    on<TypingReceived>(_onTypingReceived);
    on<SendTyping>(_onSendTyping);
    on<SendContactRequest>(_onSendContactRequest);
    on<LoadContactRequests>(_onLoadContactRequests);
    on<AcceptContactRequest>(_onAcceptContactRequest);
    on<RejectContactRequest>(_onRejectContactRequest);
    on<ContactRequestReceived>(_onContactRequestReceived);
    on<ContactRequestAccepted>(_onContactRequestAccepted);
    on<LoadSentContactRequests>(_onLoadSentContactRequests);
    on<ReactToMessage>(_onReactToMessage);
    on<ReactionUpdated>(_onReactionUpdated);
    on<LoadBadgeCounts>(_onLoadBadgeCounts);
    on<UpdateBadgeCounts>(_onUpdateBadgeCounts);
    on<SocketErrorReceived>((event, emit) => emit(state.copyWith(socketError: event.message)));
    on<ClearSocketError>((_, emit) => emit(state.copyWith(clearSocketError: true)));
    on<AnalystChunkReceived>(_onAnalystChunk);
    on<AnalystSeamReceived>(_onAnalystSeam);
    on<AnalystPendingTextCleared>(_onAnalystPendingTextCleared);
    // Phase 1e — mesh inbound pipeline; UI rendering is Phase 1f.
    on<MeshMessageReceived>(_onMeshMessageReceived);
    // Phase 1h — mesh outbound: replace temp_* bubble with mesh-out entity.
    on<MeshMessageSent>(_onMeshMessageSent);
    // Sync delta handler — drains /messenger/sync with pagination.
    on<SyncMessagesRequested>(_onSyncMessages);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _onConnect(
      ConnectMessenger event, Emitter<MessengerState> emit) async {
    await _repo.connect(event.accessToken);
    // Flush any pending messages (queued while offline) now that we're connected.
    _resendPending();
    add(const SyncMessagesRequested());
    // Re-send on each reconnect too.
    _reconnectSub?.cancel();
    _reconnectSub = sl<MessengerRemoteDataSource>().reconnectStream.listen((_) {
      debugPrint('[mesh-reconnect] socket reconnected — resending pending + refreshing contact keys');
      _resendPending();
      _refreshMeshContactKeys();
      add(const SyncMessagesRequested());
    });
    // Clear in-flight set on disconnect so the next reconnect re-emits any
    // pending messages. Without this, a message that was emitted into a
    // dying socket gets stuck in-flight forever (until app restart) — the
    // server side dedup (Redis, 1h TTL) protects against duplicates.
    _disconnectSub?.cancel();
    _disconnectSub =
        sl<MessengerRemoteDataSource>().disconnectStream.listen((_) {
      _inFlightTempIds.clear();
    });
    _msgSub?.cancel();
    _msgSub = _repo.messageStream.listen((msg) => add(MessageReceived(msg)));
    _callSub?.cancel();
    _callSub = _repo.callInviteStream.listen((data) => add(CallInviteReceived(data)));
    _msgUpdatedSub?.cancel();
    _msgUpdatedSub = _repo.messageUpdatedStream.listen((data) {
      final id = data['id'] as String?;
      if (id != null) {
        add(MessageUpdated(id,
          isDelivered: data['isDelivered'] as bool?,
          isRead: data['isRead'] as bool?,
          content: data['content'] as String?,
          isEdited: data['isEdited'] as bool?,
        ));
      }
    });
    _msgsReadSub?.cancel();
    _msgsReadSub = _repo.messagesReadStream.listen((data) {
      final convId = data['conversationId'] as String?;
      final ids = (data['messageIds'] as List?)?.cast<String>() ?? [];
      if (convId != null && ids.isNotEmpty) {
        add(MessagesRead(convId, ids));
      }
    });
    // Group socket listeners
    _groupUpdatedSub?.cancel();
    _groupUpdatedSub = _repo.groupUpdatedStream.listen((data) {
      add(GroupEventReceived('group_updated', data));
    });
    _groupMemberAddedSub?.cancel();
    _groupMemberAddedSub = _repo.groupMemberAddedStream.listen((data) {
      add(GroupEventReceived('group_member_added', data));
    });
    _groupMemberRemovedSub?.cancel();
    _groupMemberRemovedSub = _repo.groupMemberRemovedStream.listen((data) {
      add(GroupEventReceived('group_member_removed', data));
    });
    _groupRoleChangedSub?.cancel();
    _groupRoleChangedSub = _repo.groupRoleChangedStream.listen((data) {
      add(GroupEventReceived('group_role_changed', data));
    });
    _groupCreatedSub?.cancel();
    _groupCreatedSub = _repo.groupCreatedStream.listen((data) {
      add(GroupEventReceived('group_created', data));
    });
    _groupDeletedSub?.cancel();
    _groupDeletedSub = _repo.groupDeletedStream.listen((data) {
      add(GroupEventReceived('group_deleted', data));
    });
    _groupCallStartedSub?.cancel();
    _groupCallStartedSub = _repo.groupCallStartedStream.listen((data) {
      final convId = data['conversationId'] as String?;
      final roomName = data['roomName'] as String?;
      if (convId != null && roomName != null) {
        add(GroupCallStarted(conversationId: convId, roomName: roomName));
      }
    });
    _groupCallEndedSub?.cancel();
    _groupCallEndedSub = _repo.groupCallEndedStream.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null) {
        add(GroupCallEnded(convId));
      }
    });
    _msgDeletedSub?.cancel();
    _msgDeletedSub = _repo.messageDeletedStream.listen((data) {
      final msgId = data['messageId'] as String?;
      final convId = data['conversationId'] as String?;
      if (msgId != null && convId != null) {
        add(MessageDeleted(messageId: msgId, conversationId: convId));
      }
    });
    _msgAckedSub?.cancel();
    _msgAckedSub = _repo.messageAckedStream.listen((data) {
      final tempId = data['clientTempId'] as String?;
      if (tempId == null) return;
      // Server confirmed receipt (`message_acked`). Stop in-flight tracking
      // so a future reconnect storm doesn't double-emit. We do NOT drop the
      // persistent pending entry here — the ack means "the socket frame
      // landed", but the corresponding `new_message` echo may still be in
      // flight. If we cleared `_pending` now and the app restarted before
      // the echo arrived, the bubble would vanish on next chat open
      // (because `_appendPending` would find nothing in Hive and the
      // server's GET /messages list wouldn't yet include the new id).
      // The persistent entry is dropped only by `_onMessageReceived` when
      // the echo arrives, and the server's Redis 1h dedup catches any
      // duplicate that a between-restart resend triggers.
      _inFlightTempIds.remove(tempId);
      debugPrint('[MessengerBloc] message_acked: cleared in-flight tempId=$tempId (pending kept until echo)');
    });
    _typingSub?.cancel();
    _typingSub = _repo.typingStream.listen((data) {
      final convId = data['conversationId'] as String?;
      final userId = data['userId'] as String?;
      final userName = data['userName'] as String?;
      final isTyping = data['isTyping'] as bool? ?? false;
      if (convId != null && userId != null) {
        add(TypingReceived(
          conversationId: convId,
          userId: userId,
          userName: userName,
          isTyping: isTyping,
          typingText: data['typingText'] as String?,
          topicId: data['topicId'] as String?,
        ));
      }
    });
    _contactReqSub?.cancel();
    _contactReqSub = _repo.contactRequestStream.listen((data) {
      add(ContactRequestReceived(data));
    });
    _contactAccSub?.cancel();
    _contactAccSub = _repo.contactAcceptedStream.listen((data) {
      add(ContactRequestAccepted(data));
    });
    _socketErrorSub?.cancel();
    _socketErrorSub = _repo.socketErrorStream.listen((msg) => add(SocketErrorReceived(msg)));
    _reactionSub?.cancel();
    _reactionSub = _repo.reactionUpdatedStream.listen((data) {
      final msgId = data['messageId'] as String?;
      final convId = data['conversationId'] as String?;
      final reactions = (data['reactions'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];
      if (msgId != null && convId != null) {
        add(ReactionUpdated(messageId: msgId, conversationId: convId, reactions: reactions));
      }
    });
    _analystChunkSub?.cancel();
    _analystChunkSub = _repo.analystChunkStream.listen(
      (c) => add(AnalystChunkReceived(conversationId: c.conversationId, text: c.text)),
    );
    _analystSeamSub?.cancel();
    _analystSeamSub = _repo.analystSeamStream.listen(
      (s) => add(AnalystSeamReceived(seam: s)),
    );
    // Phase 1e: subscribe to the mesh inbound stream so messages are no
    // longer silently dropped when a peer sends via the local network.
    _meshMsgSub?.cancel();
    _meshMsgSub = _repo.meshMessageStream.listen((msg) {
      add(MeshMessageReceived(
        conversationId: msg.conversationId,
        contactUserId: msg.contactUserId,
        text: msg.text,
        receivedAt: msg.receivedAt,
      ));
    });
    // Phase 1h: subscribe to mesh outbound stream so temp_* bubbles are
    // replaced with mesh-out MessageEntity after a successful mesh send.
    _meshOutSub?.cancel();
    _meshOutSub = _repo.meshOutboundStream.listen((msg) {
      add(MeshMessageSent(
        id: msg.id,
        conversationId: msg.conversationId,
        contactUserId: msg.contactUserId,
        clientTempId: msg.clientTempId,
        text: msg.text,
        sentAt: msg.sentAt,
      ));
    });
    emit(state.copyWith(
      isConnected: true,
      currentUserId: event.userId ?? state.currentUserId,
    ));
    add(LoadConversations());
    add(LoadContactRequests());
    add(LoadBadgeCounts());
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<MessengerState> emit) async {
    // 1. Load from cache instantly
    final cached = _cache.getConversations();
    if (cached != null && cached.isNotEmpty && state.conversations.isEmpty) {
      try {
        final cachedConvs = cached.map((e) => ConversationEntity.fromJson(e)).toList();
        _sortConversations(cachedConvs);
        emit(state.copyWith(conversations: cachedConvs, isLoading: true));
      } catch (_) {}
    } else {
      emit(state.copyWith(isLoading: true));
    }

    // 2. Fetch from server and merge
    try {
      final convs = await _repo.getConversations();
      _sortConversations(convs);
      final activeCalls = Map<String, String>.from(state.activeGroupCalls);
      for (final c in convs) {
        if (c.activeCallRoomName != null) {
          activeCalls[c.id] = c.activeCallRoomName!;
        }
      }
      emit(state.copyWith(conversations: convs, isLoading: false, activeGroupCalls: activeCalls, clearError: true));
      // Save to cache (fire-and-forget)
      _cache.saveConversations(convs.map((c) => c.toJson()).toList());
    } catch (e) {
      // If cache was shown, just stop loading; otherwise show error
      if (state.conversations.isNotEmpty) {
        emit(state.copyWith(isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  void _sortConversations(List<ConversationEntity> convs) {
    convs.sort((a, b) {
      final aTime = a.lastMessageAt;
      final bTime = b.lastMessageAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> _onOpenConversation(
      OpenConversation event, Emitter<MessengerState> emit) async {
    _repo.joinConversation(event.conversationId);

    // 1. Load from cache instantly, merged with mesh history.
    final cachedMsgs = _cache.getMessages(event.conversationId);
    if (cachedMsgs != null &&
        cachedMsgs.isNotEmpty &&
        (state.messages[event.conversationId]?.isEmpty ?? true)) {
      try {
        final serverCached =
            cachedMsgs.map((e) => MessageEntity.fromJson(e)).toList();
        final merged = _mergeSortedById(
          serverCached,
          _loadMeshHistory(event.conversationId),
        );
        final newMessages = Map<String, List<MessageEntity>>.from(state.messages);
        newMessages[event.conversationId] = merged;
        emit(state.copyWith(messages: newMessages, isLoading: true));
      } catch (_) {
        emit(state.copyWith(isLoading: true));
      }
    } else {
      emit(state.copyWith(isLoading: true));
    }

    // 2. Fetch from server and merge with mesh history.
    try {
      final result = await _repo.getMessages(event.conversationId, topicId: event.topicId);
      final rawMessages = result['messages'] as List? ?? [];
      final knownStatus = <String, ({bool isRead, bool isDelivered})>{
        for (final m in state.messages[event.conversationId] ?? [])
          m.id: (isRead: m.isRead, isDelivered: m.isDelivered),
      };
      final msgs = rawMessages.map((e) {
        final m = MessageEntity.fromJson(Map<String, dynamic>.from(e as Map));
        final known = knownStatus[m.id];
        if (known != null) {
          return m.copyWith(
            isRead: m.isRead || known.isRead,
            isDelivered: m.isDelivered || known.isDelivered,
          );
        }
        return m;
      }).toList();
      final nextCursor = result['nextCursor'] as String?;
      final newMessages =
          Map<String, List<MessageEntity>>.from(state.messages);
      final serverList = msgs.reversed.toList();
      // Preserve any locally-injected live call invite cards — they aren't
      // persisted server-side but should stay visible until the invite is
      // handled.
      for (final m in state.messages[event.conversationId] ?? <MessageEntity>[]) {
        if (m.id.startsWith('call_invite_') && m.isSystem) {
          serverList.add(m);
        }
      }
      // Re-append any unsent pending messages for this conversation so the
      // user sees them with a clock icon.
      _appendPending(event.conversationId, serverList);
      // Phase 1f — merge mesh history so the chat renders both kinds.
      final meshMsgs = _loadMeshHistory(event.conversationId);
      final merged = _mergeSortedById(serverList, meshMsgs);
      newMessages[event.conversationId] = merged;
      final newCursors = Map<String, String?>.from(state.nextCursors);
      newCursors[event.conversationId] = nextCursor;
      emit(state.copyWith(
          messages: newMessages, nextCursors: newCursors, isLoading: false));
      // Save only the server portion to cache (mesh has its own persistence).
      _cache.saveMessages(event.conversationId,
          serverList.map((m) => m.toJson()).toList());
    } catch (e) {
      // API failed (backend down, network error, etc). Surface any locally
      // persisted pending messages so the user keeps seeing what they typed
      // — otherwise messages typed during an outage appear to "vanish" on
      // reopen, which we observed during the 2026-04-24 PROD outage.
      final base = List<MessageEntity>.from(
          state.messages[event.conversationId] ?? const <MessageEntity>[]);
      _appendPending(event.conversationId, base);
      if (base.isNotEmpty) {
        final newMessages = Map<String, List<MessageEntity>>.from(state.messages);
        newMessages[event.conversationId] = base;
        emit(state.copyWith(
            messages: newMessages, isLoading: false, clearError: true));
      } else {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  /// Merges persisted pending messages for [conversationId] into [target],
  /// skipping items already present (by id) or duplicated by server-returned
  /// content (same senderId + content). Mutates [target] in place.
  void _appendPending(String conversationId, List<MessageEntity> target) {
    final pendingMaps = _pending.getForConversation(conversationId);
    for (final p in pendingMaps) {
      final tempId = p['id'] as String? ?? '';
      if (tempId.isEmpty) continue;
      if (target.any((m) => m.id == tempId)) continue;
      final dup = target.any((m) =>
          m.senderId == (p['senderId'] as String? ?? '') &&
          m.content == (p['content'] as String? ?? ''));
      if (dup) continue;
      target.add(MessageEntity(
        id: tempId,
        conversationId: conversationId,
        senderId: p['senderId'] as String? ?? state.currentUserId ?? 'me',
        content: p['content'] as String? ?? '',
        sentAt: DateTime.tryParse(p['sentAt'] as String? ?? '') ?? DateTime.now(),
        fileUrl: p['fileUrl'] as String?,
        fileName: p['fileName'] as String?,
        fileSize: p['fileSize'] as int?,
        fileType: p['fileType'] as String?,
        s3Key: p['s3Key'] as String?,
        thumbnailSmallUrl: p['thumbnailSmallUrl'] as String?,
        thumbnailMediumUrl: p['thumbnailMediumUrl'] as String?,
        thumbnailLargeUrl: p['thumbnailLargeUrl'] as String?,
        fileRecordId: p['fileRecordId'] as String?,
        topicId: p['topicId'] as String?,
      ));
    }
  }

  // Phase 1f helpers.
  List<MessageEntity> _loadMeshHistory(String convId) {
    try {
      return _cache
          .getMeshMessagesFor(convId)
          .map((m) => MessageEntity.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e, st) {
      debugPrint('[mesh-bloc] _loadMeshHistory($convId) failed: $e\n$st');
      return const [];
    }
  }

  List<MessageEntity> _mergeSortedById(
      List<MessageEntity> a, List<MessageEntity> b) {
    final seen = <String>{};
    final out = <MessageEntity>[];
    for (final m in [...a, ...b]) {
      if (seen.add(m.id)) out.add(m);
    }
    // Phase 2 dedup hygiene: drop mesh entries that have a server-
    // delivered counterpart (matching senderId + content within 10s).
    // The bloc's live-event dedup in _onMeshMessageReceived prevents
    // the bubble from rendering at runtime, but the adapter's
    // persistLocal already wrote the mesh entry to Hive before the
    // bloc decision — so the stale pair resurfaces on chat reload via
    // getMeshMessagesFor. Applying the same heuristic at merge time
    // keeps the UI consistent without invasive cache surgery.
    final filtered = <MessageEntity>[];
    for (final m in out) {
      if (m.transport == 'mesh') {
        final serverMatch = out.any((s) =>
            s.transport != 'mesh' &&
            !s.id.startsWith('temp_') &&
            s.senderId == m.senderId &&
            s.content == m.content &&
            s.sentAt.difference(m.sentAt).abs() < _crossTransportDedupWindow);
        if (serverMatch) continue;
      }
      filtered.add(m);
    }
    filtered.sort((x, y) => x.sentAt.compareTo(y.sentAt));
    return filtered;
  }


  /// Re-emit all persisted pending messages over the socket. Safe to call
  /// multiple times — each tempId is tracked in [_inFlightTempIds] so a
  /// reconnect storm cannot trigger the same message to be emitted twice.
  /// The entry is removed from the set when the matching `new_message`
  /// broadcast arrives back (see [_onMessageReceived]).
  void _resendPending() {
    final items = _pending.getAll();
    for (final m in items) {
      final tempId = m['id'] as String?;
      if (tempId == null) continue;
      if (_inFlightTempIds.contains(tempId)) {
        debugPrint('[MessengerBloc] Skip resend: $tempId already in flight');
        continue;
      }
      final convId = m['conversationId'] as String?;
      final content = m['content'] as String?;
      if (convId == null || content == null) continue;
      _inFlightTempIds.add(tempId);
      _repo.sendMessage(
        convId,
        content,
        fileUrl: m['fileUrl'] as String?,
        fileName: m['fileName'] as String?,
        fileSize: m['fileSize'] as int?,
        fileType: m['fileType'] as String?,
        s3Key: m['s3Key'] as String?,
        thumbnailSmallUrl: m['thumbnailSmallUrl'] as String?,
        thumbnailMediumUrl: m['thumbnailMediumUrl'] as String?,
        thumbnailLargeUrl: m['thumbnailLargeUrl'] as String?,
        fileRecordId: m['fileRecordId'] as String?,
        topicId: m['topicId'] as String?,
        clientTempId: tempId,
      );
    }
  }

  /// Phase 1i — after socket reconnect, re-fetch each DIRECT contact's
  /// device keys so the in-memory ContactKeyStore gets populated even if
  /// the initial ChatRoomScreen.initState fetch failed (server was down).
  /// This makes mesh usable without requiring the user to leave and
  /// re-enter the chat.
  void _refreshMeshContactKeys() {
    try {
      if (!sl.isRegistered<DeviceKeySyncService>()) return;
      final sync = sl<DeviceKeySyncService>();
      final seen = <String>{};
      for (final c in state.conversations) {
        if (c.type != 'DIRECT') continue;
        final uid = c.otherUserId;
        if (uid == null || uid.isEmpty) continue;
        if (!seen.add(uid)) continue;
        // Fire-and-forget. DeviceKeySyncService has its own [mesh-sync]
        // debug logging; errors are logged there.
        // ignore: unawaited_futures
        sync.fetchContactKeys(uid).catchError((e, _) {
          debugPrint('[mesh-reconnect] fetchContactKeys($uid) still failing: $e');
        });
      }
    } catch (e) {
      debugPrint('[mesh-reconnect] _refreshMeshContactKeys error: $e');
    }
  }

  void _onCallInviteReceived(CallInviteReceived event, Emitter<MessengerState> emit) {
    // Keep the existing standard incoming-call flow (CallKit / dialog).
    emit(state.copyWith(pendingCallInvite: event.data));

    // Desktop toast: surface a native OS notification for the incoming call.
    // On desktop there is no CallKit — the OS toast + window raise is the
    // primary incoming-call UI signal.
    if (PlatformUtils.instance.isDesktop) {
      _maybeShowDesktopCallInvite(event.data);
    }

    // Additionally inject a local "call invite" message into the conversation
    // so the user can accept/reject it from the chat as well. The message is
    // not persisted to the server — it disappears on next server sync once
    // the real missed/accepted-call system message arrives.
    final convId = event.data['conversationId'] as String?;
    if (convId == null || convId.isEmpty) return;
    final roomName = event.data['roomName'] as String? ?? '';
    final fromName = event.data['fromUserName'] as String? ?? '';
    final fromId = event.data['fromUserId'] as String? ?? '';
    final e2eeKey = event.data['e2eeKey'] as String?;
    final tempId = 'call_invite_$roomName';
    final payload = {
      'action': 'call_invite',
      'roomName': roomName,
      'fromUserId': fromId,
      'fromUserName': fromName,
      if (e2eeKey != null) 'e2eeKey': e2eeKey,
    };
    final msg = MessageEntity(
      id: tempId,
      conversationId: convId,
      senderId: fromId,
      senderName: fromName.isNotEmpty ? fromName : null,
      content: jsonEncode(payload),
      sentAt: DateTime.now(),
      isSystem: true,
    );
    final existing = List<MessageEntity>.from(state.messages[convId] ?? []);
    existing.removeWhere((m) => m.id == tempId);
    existing.add(msg);
    final newMessages = Map<String, List<MessageEntity>>.from(state.messages);
    newMessages[convId] = existing;
    emit(state.copyWith(messages: newMessages));
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<MessengerState> emit) async {
    final tempId = 'temp_${const Uuid().v4()}';
    final tempMsg = MessageEntity(
      id: tempId,
      conversationId: event.conversationId,
      senderId: state.currentUserId ?? 'me',
      content: event.content,
      sentAt: DateTime.now(),
      fileUrl: event.fileUrl,
      fileName: event.fileName,
      fileSize: event.fileSize,
      fileType: event.fileType,
      s3Key: event.s3Key,
      thumbnailSmallUrl: event.thumbnailSmallUrl,
      thumbnailMediumUrl: event.thumbnailMediumUrl,
      thumbnailLargeUrl: event.thumbnailLargeUrl,
      fileRecordId: event.fileRecordId,
      topicId: event.topicId,
    );
    final existing =
        List<MessageEntity>.from(state.messages[event.conversationId] ?? []);
    existing.add(tempMsg);
    final newMessages =
        Map<String, List<MessageEntity>>.from(state.messages);
    newMessages[event.conversationId] = existing;
    emit(state.copyWith(messages: newMessages));

    // Persist temp message to cache so it survives app kill — without this,
    // a kill during outage made messages "vanish" on next open.
    _cache.appendMessage(event.conversationId, tempMsg.toJson());

    // Persist to local pending queue BEFORE hitting the socket — if the
    // process dies between emit and Hive flush, the message is lost. We saw
    // this in the 2026-04-24 PROD outage: an unawaited save() lost a message
    // that the socket emit then dropped into a dead connection.
    await _pending.save(tempId, {
      'conversationId': event.conversationId,
      'content': event.content,
      'fileUrl': event.fileUrl,
      'fileName': event.fileName,
      'fileSize': event.fileSize,
      'fileType': event.fileType,
      's3Key': event.s3Key,
      'thumbnailSmallUrl': event.thumbnailSmallUrl,
      'thumbnailMediumUrl': event.thumbnailMediumUrl,
      'thumbnailLargeUrl': event.thumbnailLargeUrl,
      'fileRecordId': event.fileRecordId,
      'topicId': event.topicId,
      'sentAt': tempMsg.sentAt.toIso8601String(),
      'senderId': tempMsg.senderId,
    });

    // Mark as in-flight BEFORE emitting so subsequent _resendPending() calls
    // (triggered by a socket reconnect burst) cannot duplicate this emit.
    _inFlightTempIds.add(tempId);
    _repo.sendMessage(
      event.conversationId,
      event.content,
      fileUrl: event.fileUrl,
      fileName: event.fileName,
      fileSize: event.fileSize,
      fileType: event.fileType,
      s3Key: event.s3Key,
      thumbnailSmallUrl: event.thumbnailSmallUrl,
      thumbnailMediumUrl: event.thumbnailMediumUrl,
      thumbnailLargeUrl: event.thumbnailLargeUrl,
      fileRecordId: event.fileRecordId,
      topicId: event.topicId,
      clientTempId: tempId,
    );

    // Donate to iOS share sheet suggestions
    final conv = state.conversations.where((c) => c.id == event.conversationId).firstOrNull;
    if (conv != null) {
      final name = conv.type == 'GROUP'
          ? (conv.name ?? 'Group')
          : (conv.otherUserName ?? '');
      final avatar = conv.type == 'GROUP' ? conv.avatarUrl : conv.otherUserAvatar;
      ShareSuggestionsService.donateConversation(
        conversationId: event.conversationId,
        displayName: name,
        avatarUrl: avatar,
      );
    }
  }

  void _onMessageReceived(
      MessageReceived event, Emitter<MessengerState> emit) {
    final msg = event.message;
    debugPrint('[MessengerBloc] MessageReceived: id=${msg.id} convId=${msg.conversationId} content=${msg.content?.substring(0, (msg.content?.length ?? 0).clamp(0, 30))}');
    final existing =
        List<MessageEntity>.from(state.messages[msg.conversationId] ?? []);
    if (existing.any((m) => m.id == msg.id)) {
      debugPrint('[MessengerBloc] Duplicate message, skipping');
      return;
    }
    // Phase 2: drop server echo when a mesh entry with matching senderId +
    // content exists within a 10-second window.
    final meshDup = existing.any((m) =>
        m.transport == 'mesh' &&
        m.senderId == msg.senderId &&
        m.content == msg.content &&
        m.sentAt.difference(msg.sentAt).abs() < _crossTransportDedupWindow);
    if (meshDup) {
      debugPrint('[MessengerBloc] Server echo deduped against mesh entry, skipping');
      return;
    }
    final removed = <String>[];
    existing.removeWhere((m) {
      final match = m.id.startsWith('temp_') &&
          m.senderId == msg.senderId &&
          m.content == msg.content;
      if (match) removed.add(m.id);
      return match;
    });
    // Clear these from the persistent pending queue — server has acknowledged.
    // Also clear from in-flight set so a future _resendPending() can emit them
    // if they're ever re-queued. Mesh-pending drain: server echo ⇒ message
    // reached the broker and was routed to all online recipients; mesh
    // fanout retry is no longer required for this clientId. (Edge case:
    // multi-device user with one device offline — server only delivered to
    // online devices; the mesh-only path to the offline device is bypassed.
    // Acceptable today since most users have one device per account.)
    for (final tempId in removed) {
      _pending.remove(tempId);
      _inFlightTempIds.remove(tempId);
      _pendingMeshQueue.remove(tempId);
    }
    existing.add(msg);
    final newMessages =
        Map<String, List<MessageEntity>>.from(state.messages);
    newMessages[msg.conversationId] = existing;
    Map<String, String>? nextPendingText;
    if (msg.isSystem && state.pendingAnalystText.containsKey(msg.conversationId)) {
      nextPendingText = Map<String, String>.from(state.pendingAnalystText)..remove(msg.conversationId);
    }
    emit(state.copyWith(
      messages: newMessages,
      pendingAnalystText: nextPendingText ?? state.pendingAnalystText,
    ));
    // Cache the new message
    _cache.appendMessage(msg.conversationId, msg.toJson());
    add(LoadConversations());

    // Desktop toast: show OS notification when window is not focused.
    // Skipped for system messages (call_invite injections, analyst turns) and
    // messages sent by this user.
    if (PlatformUtils.instance.isDesktop &&
        !msg.isSystem &&
        msg.senderId != state.currentUserId) {
      _maybeShowDesktopMessageNotification(msg);
    }
  }

  void _maybeShowDesktopMessageNotification(MessageEntity msg) async {
    try {
      final isFocused = await windowManager.isFocused();
      if (!isFocused) {
        final senderName =
            (msg.senderName?.isNotEmpty ?? false) ? msg.senderName! : 'Сообщение';
        final content = msg.fileName != null && msg.fileName!.isNotEmpty
            ? msg.fileName!
            : (msg.content?.isNotEmpty ?? false)
                ? msg.content!
                : '📎 Вложение';
        await DesktopNotificationsService.instance.showMessage(
          title: senderName,
          body: content,
          routePayload: 'chat:${msg.conversationId}',
        );
      }
    } catch (e) {
      debugPrint('[DesktopNotif] showMessage failed: $e');
    }
  }

  void _maybeShowDesktopCallInvite(Map<String, dynamic> data) async {
    try {
      final isFocused = await windowManager.isFocused();
      final callerName = (data['fromUserName'] as String?)?.isNotEmpty == true
          ? data['fromUserName'] as String
          : 'Неизвестный';
      final roomName = data['roomName'] as String? ?? '';
      await DesktopNotificationsService.instance.showCallInvite(
        callerName: callerName,
        routePayload: 'call:$roomName',
      );
      // If window is not focused, raise it so the in-app call dialog becomes
      // visible immediately.
      if (!isFocused) {
        await windowManager.show();
        await windowManager.focus();
      }
    } catch (e) {
      debugPrint('[DesktopNotif] showCallInvite failed: $e');
    }
  }

  final Set<String> _loadingMore = {};

  Future<void> _onLoadMoreMessages(
      LoadMoreMessages event, Emitter<MessengerState> emit) async {
    final cursor = state.nextCursors[event.conversationId];
    if (cursor == null) return;
    // Prevent concurrent loads for the same conversation
    if (_loadingMore.contains(event.conversationId)) return;
    _loadingMore.add(event.conversationId);
    try {
      final result =
          await _repo.getMessages(event.conversationId, cursor: cursor);
      final rawMessages = result['messages'] as List? ?? [];
      final newMsgs = rawMessages
          .map((e) =>
              MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final nextCursor = result['nextCursor'] as String?;
      final existing = List<MessageEntity>.from(
          state.messages[event.conversationId] ?? []);
      // Deduplicate: collect existing IDs, only add new ones
      final existingIds = existing.map((m) => m.id).toSet();
      final deduped = newMsgs.where((m) => !existingIds.contains(m.id)).toList();
      final allMessages =
          Map<String, List<MessageEntity>>.from(state.messages);
      allMessages[event.conversationId] = [
        ...deduped.reversed.toList(),
        ...existing,
      ];
      final newCursors = Map<String, String?>.from(state.nextCursors);
      newCursors[event.conversationId] = nextCursor;
      emit(state.copyWith(messages: allMessages, nextCursors: newCursors));
    } catch (_) {}
    _loadingMore.remove(event.conversationId);
  }

  Future<void> _onSearchUsers(
      SearchUsers event, Emitter<MessengerState> emit) async {
    if (event.query.length < 2) {
      emit(state.copyWith(searchResults: []));
      return;
    }
    emit(state.copyWith(isLoading: true));
    try {
      final results = await _repo.searchUsers(event.query);
      emit(state.copyWith(searchResults: results, isLoading: false, clearError: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onStartConversationWith(
      StartConversationWith event, Emitter<MessengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final conv = await _repo.createConversation(event.userId);
      emit(state.copyWith(
          isLoading: false, newConversationId: conv.id));
      add(LoadConversations());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onMessageUpdated(MessageUpdated event, Emitter<MessengerState> emit) {
    final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
    for (final convId in allMessages.keys) {
      final msgs = List<MessageEntity>.from(allMessages[convId]!);
      final idx = msgs.indexWhere((m) => m.id == event.messageId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(
          isDelivered: event.isDelivered ?? msgs[idx].isDelivered,
          isRead: event.isRead ?? msgs[idx].isRead,
          content: event.content ?? msgs[idx].content,
          isEdited: event.isEdited ?? msgs[idx].isEdited,
        );
        allMessages[convId] = msgs;
        emit(state.copyWith(messages: allMessages));
        return;
      }
    }
  }

  void _onMessagesRead(MessagesRead event, Emitter<MessengerState> emit) {
    final msgs = List<MessageEntity>.from(state.messages[event.conversationId] ?? []);
    bool changed = false;
    for (int i = 0; i < msgs.length; i++) {
      if (event.messageIds.contains(msgs[i].id)) {
        msgs[i] = msgs[i].copyWith(isRead: true, isDelivered: true);
        changed = true;
      }
    }
    if (changed) {
      final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
      allMessages[event.conversationId] = msgs;
      emit(state.copyWith(messages: allMessages));
    }
  }

  void _onMarkConversationRead(MarkConversationRead event, Emitter<MessengerState> emit) {
    _repo.markRead(event.conversationId);
    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    emit(state.copyWith(conversations: updatedConvs));
  }

  // ─── Group handlers ───

  Future<void> _onCreateGroup(CreateGroup event, Emitter<MessengerState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final conv = await _repo.createGroupConversation(event.name, event.participantIds);
      emit(state.copyWith(isLoading: false, newConversationId: conv.id));
      add(LoadConversations());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadGroupMembers(LoadGroupMembers event, Emitter<MessengerState> emit) async {
    try {
      final members = await _repo.getGroupMembers(event.conversationId);
      final newGroupMembers = Map<String, List<GroupMemberEntity>>.from(state.groupMembers);
      newGroupMembers[event.conversationId] = members;
      emit(state.copyWith(groupMembers: newGroupMembers));
    } catch (_) {}
  }

  Future<void> _onAddGroupMembers(AddGroupMembers event, Emitter<MessengerState> emit) async {
    try {
      await _repo.addGroupMembers(event.conversationId, event.userIds);
      add(LoadGroupMembers(event.conversationId));
      add(LoadConversations());
    } catch (_) {}
  }

  Future<void> _onRemoveGroupMember(RemoveGroupMember event, Emitter<MessengerState> emit) async {
    try {
      await _repo.removeGroupMember(event.conversationId, event.userId);
      add(LoadGroupMembers(event.conversationId));
      add(LoadConversations());
    } catch (_) {}
  }

  Future<void> _onChangeGroupRole(ChangeGroupRole event, Emitter<MessengerState> emit) async {
    try {
      await _repo.changeGroupMemberRole(event.conversationId, event.userId, event.role);
      add(LoadGroupMembers(event.conversationId));
    } catch (_) {}
  }

  Future<void> _onUpdateGroupInfo(UpdateGroupInfo event, Emitter<MessengerState> emit) async {
    try {
      await _repo.updateGroupInfo(event.conversationId, name: event.name, avatarUrl: event.avatarUrl, description: event.description);
      add(LoadConversations());
    } catch (_) {}
  }

  Future<void> _onLeaveGroup(LeaveGroup event, Emitter<MessengerState> emit) async {
    try {
      await _repo.leaveGroup(event.conversationId);
      add(LoadConversations());
    } catch (_) {}
  }

  Future<void> _onDeleteGroup(DeleteGroup event, Emitter<MessengerState> emit) async {
    try {
      await _repo.deleteGroup(event.conversationId);
      add(LoadConversations());
    } catch (_) {}
  }

  Future<void> _onUpdateGroupSettings(UpdateGroupSettings event, Emitter<MessengerState> emit) async {
    try {
      await _repo.updateGroupInfo(
        event.conversationId,
        slowMode: event.slowMode,
        topicsEnabled: event.topicsEnabled,
        autoDeleteDays: event.autoDeleteDays,
      );
      add(LoadConversations());
    } catch (_) {}
  }

  void _onGroupEventReceived(GroupEventReceived event, Emitter<MessengerState> emit) {
    add(LoadConversations());
    final convId = event.data['conversationId'] as String?;
    if (convId != null && state.groupMembers.containsKey(convId)) {
      add(LoadGroupMembers(convId));
    }
  }

  void _onTypingReceived(TypingReceived event, Emitter<MessengerState> emit) {
    // Don't show own typing
    if (event.userId == state.currentUserId) return;
    final updated = Map<String, Map<String, String>>.from(
      state.typingUsers.map((k, v) => MapEntry(k, Map<String, String>.from(v))),
    );
    // Use topicId as key suffix to isolate typing per topic
    final key = event.topicId != null ? '${event.conversationId}:${event.topicId}' : event.conversationId;
    if (event.isTyping) {
      updated.putIfAbsent(key, () => {});
      updated[key]![event.userId] = event.typingText ?? event.userName ?? '';
      // Auto-clear after 5 seconds
      final timerKey = '${event.conversationId}_${event.userId}';
      _typingTimers[timerKey]?.cancel();
      _typingTimers[timerKey] = Timer(const Duration(seconds: 5), () {
        add(TypingReceived(
          conversationId: event.conversationId,
          userId: event.userId,
          isTyping: false,
        ));
      });
    } else {
      updated[key]?.remove(event.userId);
      if (updated[key]?.isEmpty ?? false) {
        updated.remove(key);
      }
      // Also clear from conversation-level key (for backward compat)
      updated[event.conversationId]?.remove(event.userId);
      if (updated[event.conversationId]?.isEmpty ?? false) {
        updated.remove(event.conversationId);
      }
      final timerKey = '${event.conversationId}_${event.userId}';
      _typingTimers[timerKey]?.cancel();
      _typingTimers.remove(timerKey);
    }
    emit(state.copyWith(typingUsers: updated));
  }

  void _onSendTyping(SendTyping event, Emitter<MessengerState> emit) {
    _repo.sendTyping(event.conversationId, event.isTyping);
  }

  // ─── Contact request handlers ───

  Future<void> _onSendContactRequest(SendContactRequest event, Emitter<MessengerState> emit) async {
    try {
      await _repo.sendContactRequest(event.receiverId);
      emit(state.copyWith(contactRequestSent: event.receiverId));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Already contacts') || msg.contains('already sent')) {
        // Auto-accept / already contacts — try creating conversation directly
        add(StartConversationWith(event.receiverId));
      } else {
        emit(state.copyWith(error: msg));
      }
    }
  }

  Future<void> _onLoadContactRequests(LoadContactRequests event, Emitter<MessengerState> emit) async {
    try {
      final requests = await _repo.getContactRequests();
      final pending = requests.where((r) =>
          (r['status'] as String? ?? 'PENDING') == 'PENDING').length;
      emit(state.copyWith(
        contactRequests: requests,
        pendingContactRequests: pending,
      ));
    } catch (e) {
      debugPrint('[MessengerBloc] LoadContactRequests error: $e');
    }
  }

  Future<void> _onAcceptContactRequest(AcceptContactRequest event, Emitter<MessengerState> emit) async {
    // Optimistic: drop the row immediately so the UI reacts without waiting
    // for the server round-trip.
    final optimistic = state.contactRequests.where((r) => r['id'] != event.requestId).toList();
    final pending = optimistic.where((r) =>
        (r['status'] as String? ?? 'PENDING') == 'PENDING').length;
    emit(state.copyWith(contactRequests: optimistic, pendingContactRequests: pending));
    try {
      final result = await _repo.acceptContactRequest(event.requestId);
      final convId = result['conversationId'] as String?;
      if (convId != null) {
        emit(state.copyWith(newConversationId: convId));
        add(LoadConversations());
      }
    } catch (_) {
      // If the server rejects the accept, leave the optimistic update in
      // place — user will see the entry disappear regardless. A later
      // LoadContactRequests sync would restore it if still pending.
    }
  }

  Future<void> _onRejectContactRequest(RejectContactRequest event, Emitter<MessengerState> emit) async {
    final optimistic = state.contactRequests.where((r) => r['id'] != event.requestId).toList();
    final pending = optimistic.where((r) =>
        (r['status'] as String? ?? 'PENDING') == 'PENDING').length;
    emit(state.copyWith(contactRequests: optimistic, pendingContactRequests: pending));
    try {
      await _repo.rejectContactRequest(event.requestId);
    } catch (_) {}
  }

  void _onContactRequestReceived(ContactRequestReceived event, Emitter<MessengerState> emit) {
    // Avoid duplicates if the same request arrives via both socket and a
    // subsequent LoadContactRequests refresh.
    final id = event.data['id'];
    final filtered = state.contactRequests.where((r) => r['id'] != id).toList();
    final updated = [event.data, ...filtered];
    final pending = updated.where((r) =>
        (r['status'] as String? ?? 'PENDING') == 'PENDING').length;
    emit(state.copyWith(
      contactRequests: updated,
      pendingContactRequests: pending,
    ));
  }

  void _onContactRequestAccepted(ContactRequestAccepted event, Emitter<MessengerState> emit) {
    // Refresh all lists — another device may have accepted/rejected
    add(LoadConversations());
    add(LoadSentContactRequests());
    add(LoadContactRequests());
    emit(state.copyWith(clearContactRequestSent: true));
  }

  Future<void> _onLoadSentContactRequests(LoadSentContactRequests event, Emitter<MessengerState> emit) async {
    try {
      final requests = await _repo.getSentContactRequests();
      emit(state.copyWith(sentContactRequests: requests, clearContactRequestSent: true));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _msgSub?.cancel();
    _callSub?.cancel();
    _msgUpdatedSub?.cancel();
    _msgsReadSub?.cancel();
    _groupUpdatedSub?.cancel();
    _groupMemberAddedSub?.cancel();
    _groupMemberRemovedSub?.cancel();
    _groupRoleChangedSub?.cancel();
    _groupCreatedSub?.cancel();
    _groupDeletedSub?.cancel();
    _groupCallStartedSub?.cancel();
    _groupCallEndedSub?.cancel();
    _msgDeletedSub?.cancel();
    _msgAckedSub?.cancel();
    _typingSub?.cancel();
    _contactReqSub?.cancel();
    _contactAccSub?.cancel();
    _reactionSub?.cancel();
    _reconnectSub?.cancel();
    _disconnectSub?.cancel();
    _analystChunkSub?.cancel();
    _analystSeamSub?.cancel();
    _meshMsgSub?.cancel();
    _meshOutSub?.cancel();
    for (final timer in _typingTimers.values) { timer.cancel(); }
    _repo.dispose();
    return super.close();
  }

  // ─── Mute handlers ───

  Future<void> _onMuteConversation(MuteConversation event, Emitter<MessengerState> emit) async {
    try {
      final result = await _repo.muteConversation(event.conversationId, durationMinutes: event.durationMinutes);
      final mutedUntil = result['mutedUntil'] != null ? DateTime.parse(result['mutedUntil'] as String) : null;
      final updated = state.conversations.map((c) {
        if (c.id == event.conversationId) {
          return c.copyWith(isMuted: true, mutedUntil: mutedUntil);
        }
        return c;
      }).toList();
      emit(state.copyWith(conversations: updated));
    } catch (_) {}
  }

  Future<void> _onUnmuteConversation(UnmuteConversation event, Emitter<MessengerState> emit) async {
    try {
      await _repo.unmuteConversation(event.conversationId);
      final updated = state.conversations.map((c) {
        if (c.id == event.conversationId) {
          return c.copyWith(isMuted: false, mutedUntil: null);
        }
        return c;
      }).toList();
      emit(state.copyWith(conversations: updated));
    } catch (_) {}
  }

  // ─── Group call handlers ───

  void _onGroupCallStarted(GroupCallStarted event, Emitter<MessengerState> emit) {
    final updated = Map<String, String>.from(state.activeGroupCalls);
    updated[event.conversationId] = event.roomName;
    emit(state.copyWith(activeGroupCalls: updated));
  }

  void _onGroupCallEnded(GroupCallEnded event, Emitter<MessengerState> emit) {
    final updated = Map<String, String>.from(state.activeGroupCalls);
    updated.remove(event.conversationId);
    emit(state.copyWith(activeGroupCalls: updated));
  }

  Future<void> _onForwardMessage(ForwardMessage event, Emitter<MessengerState> emit) async {
    try {
      final msg = event.message;
      _repo.sendMessage(
        event.targetConversationId,
        msg.content,
        fileUrl: msg.fileUrl,
        fileName: msg.fileName,
        fileSize: msg.fileSize,
        fileType: msg.fileType,
        s3Key: msg.s3Key,
        thumbnailSmallUrl: msg.thumbnailSmallUrl,
        thumbnailMediumUrl: msg.thumbnailMediumUrl,
        thumbnailLargeUrl: msg.thumbnailLargeUrl,
        fileRecordId: msg.fileRecordId,
      );
    } catch (_) {}
  }

  void _onEditMessage(EditMessage event, Emitter<MessengerState> emit) {
    final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
    final msgs = List<MessageEntity>.from(allMessages[event.conversationId] ?? []);
    final idx = msgs.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      msgs[idx] = msgs[idx].copyWith(content: event.newContent, isEdited: true);
      allMessages[event.conversationId] = msgs;
      emit(state.copyWith(messages: allMessages));
    }
    _repo.editMessage(event.conversationId, event.messageId, event.newContent);
  }

  void _onDeleteMessage(DeleteMessage event, Emitter<MessengerState> emit) {
    // Optimistic: remove from local state immediately
    final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
    final msgs = List<MessageEntity>.from(allMessages[event.conversationId] ?? []);
    msgs.removeWhere((m) => m.id == event.messageId);
    allMessages[event.conversationId] = msgs;
    emit(state.copyWith(messages: allMessages));
    _repo.deleteMessage(event.conversationId, event.messageId, event.forEveryone ? 'all' : 'self');
    // Refresh conversation list to update last message preview
    add(LoadConversations());
  }

  // ─── Reaction handlers ───

  void _onReactToMessage(ReactToMessage event, Emitter<MessengerState> emit) {
    _repo.reactToMessage(event.conversationId, event.messageId, event.emoji);
  }

  void _onReactionUpdated(ReactionUpdated event, Emitter<MessengerState> emit) {
    final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
    final msgs = List<MessageEntity>.from(allMessages[event.conversationId] ?? []);
    final idx = msgs.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      msgs[idx] = msgs[idx].copyWith(reactions: event.reactions);
      allMessages[event.conversationId] = msgs;
      emit(state.copyWith(messages: allMessages));
    }
  }

  void _onMessageDeleted(MessageDeleted event, Emitter<MessengerState> emit) {
    final allMessages = Map<String, List<MessageEntity>>.from(state.messages);
    final msgs = List<MessageEntity>.from(allMessages[event.conversationId] ?? []);
    msgs.removeWhere((m) => m.id == event.messageId);
    allMessages[event.conversationId] = msgs;
    emit(state.copyWith(messages: allMessages));
    add(LoadConversations());
  }

  // Phase 1f: handler for mesh-delivered inbound messages. Inserts the
  // message as a MessageEntity(transport: 'mesh') into the correct
  // conversation's message list, deduplicating by deterministic id and
  // keeping the list sorted by sentAt.
  void _onMeshMessageReceived(
      MeshMessageReceived event, Emitter<MessengerState> emit) {
    final list = state.messages[event.conversationId] ?? const [];
    // Phase 2: drop mesh inbound when a server-delivered entry with matching
    // senderId + content exists within a 10-second window.
    // Note: `transport != 'mesh'` includes null (server-delivered messages
    // have no `transport` field) AND any future non-mesh transport string.
    final serverDup = list.any((m) =>
        m.transport != 'mesh' &&
        !m.id.startsWith('temp_') &&
        m.senderId == event.contactUserId &&
        m.content == event.text &&
        m.sentAt.difference(event.receivedAt).abs() < _crossTransportDedupWindow);
    if (serverDup) {
      debugPrint('[MessengerBloc] Mesh inbound deduped against server entry, skipping');
      return;
    }
    final msgId =
        'mesh-in-${event.contactUserId}-${event.receivedAt.millisecondsSinceEpoch}';
    final incoming = MessageEntity(
      id: msgId,
      conversationId: event.conversationId,
      senderId: event.contactUserId,
      content: event.text,
      sentAt: event.receivedAt,
      transport: 'mesh',
    );
    final updated = Map<String, List<MessageEntity>>.from(state.messages);
    final existing =
        List<MessageEntity>.from(updated[event.conversationId] ?? const []);
    // Dedup by id (adapter may have already persisted + re-delivered on restart).
    if (existing.any((m) => m.id == msgId)) return;
    existing.add(incoming);
    existing.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    updated[event.conversationId] = existing;
    emit(state.copyWith(messages: updated));
  }

  // Phase 1h: handler for mesh-delivered outbound messages. Replaces the
  // optimistic `temp_*` bubble with a permanent `mesh-out-*` MessageEntity
  // carrying `transport: 'mesh'`, and deduplicates on the mesh id.
  void _onMeshMessageSent(
      MeshMessageSent event, Emitter<MessengerState> emit) {
    final myUserId = state.currentUserId ?? 'me';
    final entity = MessageEntity(
      id: event.id,
      conversationId: event.conversationId,
      senderId: myUserId,
      content: event.text,
      sentAt: event.sentAt,
      transport: 'mesh',
    );
    final updated = Map<String, List<MessageEntity>>.from(state.messages);
    final list = List<MessageEntity>.from(updated[event.conversationId] ?? const []);
    // Remove the optimistic temp_* bubble if present.
    if (event.clientTempId != null && event.clientTempId!.isNotEmpty) {
      list.removeWhere((m) => m.id == event.clientTempId);
    }
    // Dedup by mesh id (if this event fires twice).
    if (list.any((m) => m.id == entity.id)) {
      updated[event.conversationId] = list;
      emit(state.copyWith(messages: updated));
      return;
    }
    list.add(entity);
    list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    updated[event.conversationId] = list;
    emit(state.copyWith(messages: updated));
  }

  Future<void> _onLoadBadgeCounts(LoadBadgeCounts event, Emitter<MessengerState> emit) async {
    try {
      final client = sl<DioClient>();
      // Load missed calls
      int missedCalls = 0;
      try {
        final callData = await client.get<dynamic>(
          '/voice/call-history',
          queryParameters: {'page': 0, 'limit': 50},
        );
        final items = callData as List? ?? [];
        missedCalls = items.where((e) {
          final m = e as Map<String, dynamic>;
          return m['isMissed'] == true;
        }).length;
      } catch (_) {}

      // Load pending calendar invites
      int calendarInvites = 0;
      try {
        final invData = await client.get<dynamic>('/calendar/invites');
        final invites = invData as List? ?? [];
        calendarInvites = invites.where((e) {
          final m = e as Map<String, dynamic>;
          return (m['status'] as String? ?? 'PENDING') == 'PENDING';
        }).length;
      } catch (_) {}

      // Pending contact requests count
      final pendingContacts = state.contactRequests.where((r) =>
        (r['status'] as String? ?? 'PENDING') == 'PENDING'
      ).length;

      // Compare with persisted "seen" counts — only show badge for NEW items
      final storage = sl<SecureStorageService>();
      final seenMissed = await storage.getSeenMissedCalls();
      final seenInvites = await storage.getSeenCalendarInvites();
      final newMissed = missedCalls > seenMissed ? missedCalls - seenMissed : 0;
      final newInvites = calendarInvites > seenInvites ? calendarInvites - seenInvites : 0;

      emit(state.copyWith(
        missedCallsCount: newMissed,
        pendingCalendarInvites: newInvites,
        pendingContactRequests: pendingContacts,
      ));
    } catch (_) {}
  }

  // ─── AI Analyst handlers ───

  Future<void> _onAnalystChunk(AnalystChunkReceived e, Emitter<MessengerState> emit) async {
    final current = state.pendingAnalystText[e.conversationId] ?? '';
    emit(state.copyWith(pendingAnalystText: {
      ...state.pendingAnalystText,
      e.conversationId: current + e.text,
    }));
  }

  Future<void> _onAnalystSeam(AnalystSeamReceived e, Emitter<MessengerState> emit) async {
    emit(state.copyWith(analystSeams: {
      ...state.analystSeams,
      e.seam.messageId: e.seam,
    }));
  }

  Future<void> _onAnalystPendingTextCleared(AnalystPendingTextCleared e, Emitter<MessengerState> emit) async {
    if (!state.pendingAnalystText.containsKey(e.conversationId)) return;
    final next = Map<String, String>.from(state.pendingAnalystText)..remove(e.conversationId);
    emit(state.copyWith(pendingAnalystText: next));
  }

  Future<void> _onSyncMessages(
    SyncMessagesRequested event,
    Emitter<MessengerState> emit,
  ) async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      var cursor = await _syncCursorStorage.read();
      if (cursor == null) {
        // First run — no stored cursor yet; fetch with no cursor to get
        // an initial checkpoint for future delta syncs.
        final SyncResult init = await _repo.sync(limit: 200);
        if (init.nextCursor != null) {
          await _syncCursorStorage.write(init.nextCursor!);
        }
        return;
      }
      // Delta run — paginate until hasMore=false (capped at 10 pages).
      for (var page = 0; page < 10; page++) {
        final SyncResult res = await _repo.sync(cursor: cursor, limit: 200);
        for (final m in res.messages) {
          add(MessageReceived(m));
        }
        if (res.nextCursor != null) {
          cursor = res.nextCursor!;
          await _syncCursorStorage.write(cursor);
        }
        if (!res.hasMore) break;
      }
    } catch (e) {
      debugPrint('[messenger-sync] failed: $e');
    } finally {
      _syncInProgress = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      add(const SyncMessagesRequested());
    }
  }

  Future<void> _onUpdateBadgeCounts(UpdateBadgeCounts event, Emitter<MessengerState> emit) async {
    final storage = sl<SecureStorageService>();
    // When clearing badges (user opened tab), save current total as "seen"
    if (event.missedCallsCount == 0) {
      try {
        final client = sl<DioClient>();
        final callData = await client.get<dynamic>('/voice/call-history', queryParameters: {'page': 0, 'limit': 50});
        final total = (callData as List? ?? []).where((e) => (e as Map<String, dynamic>)['isMissed'] == true).length;
        await storage.setSeenMissedCalls(total);
      } catch (_) {}
    }
    if (event.pendingCalendarInvites == 0) {
      try {
        final client = sl<DioClient>();
        final invData = await client.get<dynamic>('/calendar/invites');
        final total = (invData as List? ?? []).where((e) => ((e as Map<String, dynamic>)['status'] as String? ?? 'PENDING') == 'PENDING').length;
        await storage.setSeenCalendarInvites(total);
      } catch (_) {}
    }
    emit(state.copyWith(
      missedCallsCount: event.missedCallsCount,
      pendingCalendarInvites: event.pendingCalendarInvites,
      pendingContactRequests: event.pendingContactRequests,
    ));
  }
}
