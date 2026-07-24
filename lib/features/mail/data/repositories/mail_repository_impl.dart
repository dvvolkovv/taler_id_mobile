import 'dart:typed_data';

import '../../domain/entities/mail_entities.dart';
import '../../domain/entities/mail_folder_entity.dart';
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
  Future<List<MailFolderEntity>> getFolders() => _remote.getFolders();

  @override
  Future<void> createFolder(String name) => _remote.createFolder(name);

  @override
  Future<void> deleteFolder(String path) => _remote.deleteFolder(path);

  @override
  Future<({List<MailListItemEntity> items, int? nextCursor})> getMessages(
          {int? beforeUid, String folder = 'INBOX'}) =>
      _remote.getMessages(beforeUid: beforeUid, folder: folder);

  @override
  Future<MailMessageEntity> getMessage(int uid, {String folder = 'INBOX'}) =>
      _remote.getMessage(uid, folder: folder);

  @override
  Future<Uint8List> downloadAttachment(int uid, int index,
          {String folder = 'INBOX'}) =>
      _remote.downloadAttachment(uid, index, folder: folder);

  @override
  Future<void> moveMessage(int uid,
          {String fromFolder = 'INBOX', required String toFolder}) =>
      _remote.moveMessage(uid, fromFolder: fromFolder, toFolder: toFolder);

  @override
  Future<int?> saveDraft(
          {String? to, String? subject, String? text, int? replaceUid}) =>
      _remote.saveDraft(
          to: to, subject: subject, text: text, replaceUid: replaceUid);

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

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
  Future<void> setSeen(int uid, bool seen, {String folder = 'INBOX'}) =>
      _remote.setSeen(uid, seen, folder: folder);

  @override
  Future<void> deleteMessage(int uid, {String folder = 'INBOX'}) =>
      _remote.deleteMessage(uid, folder: folder);

  @override
  Future<MailAppPasswordEntity> createAppPassword(String label) =>
      _remote.createAppPassword(label);

  @override
  Future<List<MailAppPasswordEntity>> listAppPasswords() =>
      _remote.listAppPasswords();

  @override
  Future<void> revokeAppPassword(String id) => _remote.revokeAppPassword(id);
}
