import 'dart:typed_data';

import '../../../../core/api/dio_client.dart';
import '../../domain/entities/mail_entities.dart';

class MailRemoteDataSource {
  final DioClient _http;

  MailRemoteDataSource(this._http);

  Future<MailAvailabilityEntity> checkAvailability(String localpart) =>
      _http.get<MailAvailabilityEntity>(
        '/mail/availability',
        queryParameters: {'localpart': localpart},
        fromJson: (d) =>
            MailAvailabilityEntity.fromJson(Map<String, dynamic>.from(d as Map)),
      );

  Future<MailAccountEntity> createAccount(String localpart) =>
      _http.post<MailAccountEntity>(
        '/mail/account',
        data: {'localpart': localpart},
        fromJson: (d) =>
            MailAccountEntity.fromJson(Map<String, dynamic>.from(d as Map)),
      );

  Future<MailAccountEntity> getAccount() => _http.get<MailAccountEntity>(
        '/mail/account',
        fromJson: (d) =>
            MailAccountEntity.fromJson(Map<String, dynamic>.from(d as Map)),
      );

  Future<({List<MailListItemEntity> items, int? nextCursor})> getMessages(
      {int? beforeUid}) async {
    final data = await _http.get<Map<String, dynamic>>(
      '/mail/messages',
      queryParameters: {if (beforeUid != null) 'beforeUid': beforeUid},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return (
      items: (data['items'] as List? ?? [])
          .map((m) =>
              MailListItemEntity.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      nextCursor: (data['nextCursor'] as num?)?.toInt(),
    );
  }

  Future<MailMessageEntity> getMessage(int uid) =>
      _http.get<MailMessageEntity>(
        '/mail/messages/$uid',
        fromJson: (d) =>
            MailMessageEntity.fromJson(Map<String, dynamic>.from(d as Map)),
      );

  Future<Uint8List> downloadAttachment(int uid, int index) =>
      _http.getBytes('/mail/messages/$uid/attachments/$index');

  Future<void> sendMessage({
    required String to,
    required String subject,
    required String text,
    String? inReplyTo,
    List<({String filename, String contentBase64})> attachments = const [],
  }) =>
      _http.post(
        '/mail/messages',
        data: {
          'to': to,
          'subject': subject,
          'text': text,
          if (inReplyTo != null) 'inReplyTo': inReplyTo,
          if (attachments.isNotEmpty)
            'attachments': attachments
                .map((a) =>
                    {'filename': a.filename, 'contentBase64': a.contentBase64})
                .toList(),
        },
        fromJson: (d) => d,
      );

  Future<void> setSeen(int uid, bool seen) => _http.post(
        '/mail/messages/$uid/${seen ? 'read' : 'unread'}',
        data: const {},
        fromJson: (d) => d,
      );

  Future<void> deleteMessage(int uid) =>
      _http.deleteWithResponse('/mail/messages/$uid', fromJson: (d) => d);

  Future<MailAppPasswordEntity> createAppPassword(String label) =>
      _http.post<MailAppPasswordEntity>(
        '/mail/app-passwords',
        data: {'label': label},
        fromJson: (d) =>
            MailAppPasswordEntity.fromJson(Map<String, dynamic>.from(d as Map)),
      );

  Future<List<MailAppPasswordEntity>> listAppPasswords() =>
      _http.get<List<MailAppPasswordEntity>>(
        '/mail/app-passwords',
        fromJson: (d) => (d as List)
            .map((p) =>
                MailAppPasswordEntity.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
      );

  Future<void> revokeAppPassword(String id) =>
      _http.deleteWithResponse('/mail/app-passwords/$id', fromJson: (d) => d);
}
