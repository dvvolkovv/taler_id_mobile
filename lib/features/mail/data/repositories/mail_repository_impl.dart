import 'dart:typed_data';

import '../../domain/entities/mail_entities.dart';
import '../../domain/repositories/i_mail_repository.dart';
import '../datasources/mail_remote_datasource.dart';

class MailRepositoryImpl implements IMailRepository {
  final MailRemoteDataSource _remote;
  MailRepositoryImpl(this._remote);

  @override
  Future<MailAvailabilityEntity> checkAvailability(String localpart) =>
      _remote.checkAvailability(localpart);

  @override
  Future<MailAccountEntity> createAccount(String localpart) =>
      _remote.createAccount(localpart);

  @override
  Future<MailAccountEntity> getAccount() => _remote.getAccount();

  @override
  Future<({List<MailListItemEntity> items, int? nextCursor})> getMessages(
          {int? beforeUid}) =>
      _remote.getMessages(beforeUid: beforeUid);

  @override
  Future<MailMessageEntity> getMessage(int uid) => _remote.getMessage(uid);

  @override
  Future<Uint8List> downloadAttachment(int uid, int index) =>
      _remote.downloadAttachment(uid, index);

  @override
  Future<void> sendMessage({
    required String to,
    required String subject,
    required String text,
    String? inReplyTo,
    List<({String filename, String contentBase64})> attachments = const [],
  }) =>
      _remote.sendMessage(
          to: to,
          subject: subject,
          text: text,
          inReplyTo: inReplyTo,
          attachments: attachments);

  @override
  Future<void> setSeen(int uid, bool seen) => _remote.setSeen(uid, seen);

  @override
  Future<void> deleteMessage(int uid) => _remote.deleteMessage(uid);

  @override
  Future<MailAppPasswordEntity> createAppPassword(String label) =>
      _remote.createAppPassword(label);

  @override
  Future<List<MailAppPasswordEntity>> listAppPasswords() =>
      _remote.listAppPasswords();

  @override
  Future<void> revokeAppPassword(String id) => _remote.revokeAppPassword(id);
}
