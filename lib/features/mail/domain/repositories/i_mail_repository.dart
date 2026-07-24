import 'dart:typed_data';

import '../entities/mail_entities.dart';

abstract class IMailRepository {
  Future<MailAvailabilityEntity> checkAvailability(String localpart);
  Future<MailAccountEntity> createAccount(String localpart);
  Future<MailAccountEntity> getAccount();
  Future<({List<MailListItemEntity> items, int? nextCursor})> getMessages(
      {int? beforeUid});
  Future<MailMessageEntity> getMessage(int uid);
  Future<Uint8List> downloadAttachment(int uid, int index);
  Future<void> sendMessage({
    required String to,
    required String subject,
    required String text,
    String? inReplyTo,
    List<({String filename, String contentBase64})> attachments,
  });
  Future<void> setSeen(int uid, bool seen);
  Future<void> deleteMessage(int uid);
  Future<MailAppPasswordEntity> createAppPassword(String label);
  Future<List<MailAppPasswordEntity>> listAppPasswords();
  Future<void> revokeAppPassword(String id);
}
