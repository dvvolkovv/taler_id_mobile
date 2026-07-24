import 'dart:typed_data';

import '../entities/mail_entities.dart';
import '../entities/mail_folder_entity.dart';

abstract class IMailRepository {
  Future<MailAvailabilityEntity> checkAvailability(String localpart);
  Future<MailAccountEntity> createAccount(String localpart);
  Future<MailAccountEntity> getAccount();
  Future<List<MailFolderEntity>> getFolders();
  Future<void> createFolder(String name);
  Future<void> deleteFolder(String path);
  Future<({List<MailListItemEntity> items, int? nextCursor})> getMessages(
      {int? beforeUid, String folder = 'INBOX'});
  Future<MailMessageEntity> getMessage(int uid, {String folder = 'INBOX'});
  Future<Uint8List> downloadAttachment(int uid, int index,
      {String folder = 'INBOX'});
  Future<void> sendMessage({
    required String to,
    required String subject,
    required String text,
    String? inReplyTo,
    List<({String filename, String contentBase64})> attachments,
  });
  Future<void> moveMessage(int uid,
      {String fromFolder = 'INBOX', required String toFolder});
  Future<int?> saveDraft(
      {String? to, String? subject, String? text, int? replaceUid});
  Future<int> getUnreadCount();
  Future<void> setSeen(int uid, bool seen, {String folder = 'INBOX'});
  Future<void> deleteMessage(int uid, {String folder = 'INBOX'});
  Future<MailAppPasswordEntity> createAppPassword(String label);
  Future<List<MailAppPasswordEntity>> listAppPasswords();
  Future<void> revokeAppPassword(String id);
}
