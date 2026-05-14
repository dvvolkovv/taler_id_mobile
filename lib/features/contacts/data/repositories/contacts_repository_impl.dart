// lib/features/contacts/data/repositories/contacts_repository_impl.dart
import 'dart:async';
import '../../../../core/storage/outbox_op.dart';
import '../../../../core/storage/outbox_queue.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/domain/entities/conversation_entity.dart';
import '../../domain/entities/contact_item_entity.dart';
import '../../domain/repositories/i_contacts_repository.dart';
import '../datasources/contacts_local_datasource.dart';
import 'package:uuid/uuid.dart';

class ContactsRepositoryImpl implements IContactsRepository {
  final ContactsLocalDataSource _local;
  final MessengerRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final Uuid _uuid = const Uuid();

  ContactsRepositoryImpl({
    required ContactsLocalDataSource local,
    required MessengerRemoteDataSource remote,
    required OutboxQueue outbox,
  })  : _local = local,
        _remote = remote,
        _outbox = outbox;

  @override
  Stream<List<ContactItemEntity>> watchAll() => _local.watchAll();

  @override
  Future<void> refresh() async {
    try {
      final res = await Future.wait([
        _remote.getContactRequests(),
        _remote.getConversations(),
        _remote.getSentContactRequests(),
      ]);
      final incomingRaw = res[0] as List<Map<String, dynamic>>;
      final convs = res[1] as List<ConversationEntity>;
      final sentRaw = res[2] as List<Map<String, dynamic>>;

      final keep = <String>{};

      for (final r in incomingRaw) {
        final req = Map<String, dynamic>.from(r);
        if ((req['status'] as String? ?? 'PENDING') != 'PENDING') continue;
        final userId = req['senderId'] as String? ?? '';
        if (userId.isEmpty) continue;
        keep.add(userId);
        await _upsertPreservingPending(ContactItemEntity(
          userId: userId,
          name: req['senderName'] as String? ?? '',
          username: req['senderUsername'] as String?,
          avatarUrl: req['senderAvatar'] as String?,
          status: ContactStatus.incoming,
          requestId: req['id'] as String?,
        ));
      }

      for (final conv in convs) {
        if (conv.type.toUpperCase() != 'DIRECT') continue;
        final userId = conv.otherUserId ?? '';
        if (userId.isEmpty) continue;
        if (keep.contains(userId)) continue; // incoming wins
        keep.add(userId);
        await _upsertPreservingPending(ContactItemEntity(
          userId: userId,
          name: conv.otherUserName ?? '',
          username: null, // ConversationEntity does not expose otherUserUsername
          avatarUrl: conv.otherUserAvatar,
          status: ContactStatus.accepted,
          conversationId: conv.id,
        ));
      }

      for (final r in sentRaw) {
        final req = Map<String, dynamic>.from(r);
        if ((req['status'] as String? ?? 'PENDING') != 'PENDING') continue;
        final userId = req['receiverId'] as String? ?? '';
        if (userId.isEmpty) continue;
        if (keep.contains(userId)) continue;
        keep.add(userId);
        await _upsertPreservingPending(ContactItemEntity(
          userId: userId,
          name: req['receiverName'] as String? ?? '',
          username: req['receiverUsername'] as String?,
          avatarUrl: req['receiverAvatar'] as String?,
          status: ContactStatus.pending,
          requestId: req['id'] as String?,
          requestSentAt: DateTime.tryParse(req['updatedAt'] as String? ?? '') ??
              DateTime.tryParse(req['createdAt'] as String? ?? ''),
        ));
      }

      // Drop local items that the server no longer mentions (unless they have localPending).
      final existing = await _local.getAll();
      for (final old in existing) {
        if (old.localPending) continue;
        if (!keep.contains(old.userId)) {
          await _local.remove(old.userId);
        }
      }
    } catch (_) {
      // offline / failure → keep local intact
    }
  }

  Future<void> _upsertPreservingPending(ContactItemEntity incoming) async {
    final existing = await _local.getById(incoming.userId);
    if (existing != null && existing.localPending) return;
    await _local.upsert(incoming);
  }

  @override
  Future<Map<String, dynamic>> sendContactRequest(String receiverId) {
    return _remote.sendContactRequest(receiverId);
  }

  @override
  Future<void> acceptContactRequest(String requestId, String userId) async {
    final current = await _local.getById(userId);
    if (current != null) {
      await _local.upsert(current.copyWith(
        status: ContactStatus.accepted,
        localPending: true,
      ));
    }
    await _squashAndEnqueue(requestId, 'accept');
  }

  @override
  Future<void> rejectContactRequest(String requestId, String userId) async {
    await _local.remove(userId);
    await _squashAndEnqueue(requestId, 'reject');
  }

  Future<void> _squashAndEnqueue(String requestId, String action) async {
    final ops = await _outbox.pending();
    for (final op in ops) {
      if (op.feature == 'contacts' && op.entityId == requestId) {
        await _outbox.remove(op.opId);
      }
    }
    await _outbox.enqueue(OutboxOp(
      opId: _uuid.v4(),
      feature: 'contacts',
      op: OutboxOpKind.update,
      entityId: requestId,
      payload: {'action': action},
      createdAt: DateTime.now().toUtc(),
    ));
  }

  @override
  Stream<int> watchPendingCount() async* {
    yield (await _local.getAll()).where((c) => c.localPending).length;
    await for (final list in _local.watchAll()) {
      yield list.where((c) => c.localPending).length;
    }
  }
}
