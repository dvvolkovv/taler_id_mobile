import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../../../../core/services/messenger_cache_service.dart';
import '../../../../core/services/pending_message_service.dart';
import '../../../../core/services/share_suggestions_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import 'messenger_event.dart';
import 'messenger_state.dart';

class MessengerBloc extends Bloc<MessengerEvent, MessengerState> {
  final IMessengerRepository _repo;
  final MessengerCacheService _cache = sl<MessengerCacheService>();
  final PendingMessageService _pending = sl<PendingMessageService>();
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
  StreamSubscription? _typingSub;
  StreamSubscription? _contactReqSub;
  StreamSubscription? _contactAccSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _socketErrorSub;
  StreamSubscription? _reconnectSub;
  final Map<String, Timer> _typingTimers = {}; // auto-clear typing after timeout

  MessengerBloc({required IMessengerRepository repo})
      : _repo = repo,
        super(const MessengerState()) {
    on<ConnectMessenger>(_onConnect);
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
  }

  Future<void> _onConnect(
      ConnectMessenger event, Emitter<MessengerState> emit) async {
    await _repo.connect(event.accessToken);
    // Flush any pending messages (queued while offline) now that we're connected.
    _resendPending();
    // Re-send on each reconnect too.
    _reconnectSub?.cancel();
    _reconnectSub = sl<MessengerRemoteDataSource>().reconnectStream.listen((_) {
      _resendPending();
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

    // 1. Load from cache instantly
    final cachedMsgs = _cache.getMessages(event.conversationId);
    if (cachedMsgs != null && cachedMsgs.isNotEmpty && (state.messages[event.conversationId]?.isEmpty ?? true)) {
      try {
        final msgs = cachedMsgs.map((e) => MessageEntity.fromJson(e)).toList();
        final newMessages = Map<String, List<MessageEntity>>.from(state.messages);
        newMessages[event.conversationId] = msgs;
        emit(state.copyWith(messages: newMessages, isLoading: true));
      } catch (_) {
        emit(state.copyWith(isLoading: true));
      }
    } else {
      emit(state.copyWith(isLoading: true));
    }

    // 2. Fetch from server and merge
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
      final pendingMaps = _pending.getForConversation(event.conversationId);
      for (final p in pendingMaps) {
        final tempId = p['id'] as String? ?? '';
        if (tempId.isEmpty) continue;
        // Skip if the server already returned a message with the same content.
        final dup = serverList.any((m) =>
            m.senderId == (p['senderId'] as String? ?? '') &&
            m.content == (p['content'] as String? ?? ''));
        if (dup) continue;
        serverList.add(MessageEntity(
          id: tempId,
          conversationId: event.conversationId,
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
      newMessages[event.conversationId] = serverList;
      final newCursors = Map<String, String?>.from(state.nextCursors);
      newCursors[event.conversationId] = nextCursor;
      emit(state.copyWith(
          messages: newMessages, nextCursors: newCursors, isLoading: false));
      // Save to cache (fire-and-forget)
      _cache.saveMessages(event.conversationId,
          newMessages[event.conversationId]!.map((m) => m.toJson()).toList());
    } catch (e) {
      // If cache was shown, just stop loading
      if (state.messages[event.conversationId]?.isNotEmpty ?? false) {
        emit(state.copyWith(isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  /// Re-emit all persisted pending messages over the socket. Safe to call
  /// multiple times — if the server has already received a duplicate, the
  /// `MessageReceived` handler will clear the temp row regardless.
  void _resendPending() {
    final items = _pending.getAll();
    for (final m in items) {
      final convId = m['conversationId'] as String?;
      final content = m['content'] as String?;
      if (convId == null || content == null) continue;
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
        clientTempId: m['id'] as String?,
      );
    }
  }

  void _onCallInviteReceived(CallInviteReceived event, Emitter<MessengerState> emit) {
    // Keep the existing standard incoming-call flow (CallKit / dialog).
    emit(state.copyWith(pendingCallInvite: event.data));

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

  void _onSendMessage(SendMessage event, Emitter<MessengerState> emit) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
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

    // Persist to local pending queue so it survives app restarts / offline.
    _pending.save(tempId, {
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
    final removed = <String>[];
    existing.removeWhere((m) {
      final match = m.id.startsWith('temp_') &&
          m.senderId == msg.senderId &&
          m.content == msg.content;
      if (match) removed.add(m.id);
      return match;
    });
    // Clear these from the persistent pending queue — server has acknowledged.
    for (final tempId in removed) {
      _pending.remove(tempId);
    }
    existing.add(msg);
    final newMessages =
        Map<String, List<MessageEntity>>.from(state.messages);
    newMessages[msg.conversationId] = existing;
    emit(state.copyWith(messages: newMessages));
    // Cache the new message
    _cache.appendMessage(msg.conversationId, msg.toJson());
    add(LoadConversations());
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
    if (event.isTyping) {
      updated.putIfAbsent(event.conversationId, () => {});
      updated[event.conversationId]![event.userId] = event.userName ?? '';
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
    _typingSub?.cancel();
    _contactReqSub?.cancel();
    _contactAccSub?.cancel();
    _reactionSub?.cancel();
    _reconnectSub?.cancel();
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
