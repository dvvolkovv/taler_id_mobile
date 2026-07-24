class MailAccountEntity {
  final String address;
  final String localpart;
  final String domain;
  final String status; // PROVISIONING | ACTIVE | SUSPENDED
  final MailClientSettings? clientSettings;

  MailAccountEntity({
    required this.address,
    required this.localpart,
    required this.domain,
    required this.status,
    this.clientSettings,
  });

  factory MailAccountEntity.fromJson(Map<String, dynamic> json) =>
      MailAccountEntity(
        address: json['address'] as String,
        localpart: json['localpart'] as String,
        domain: json['domain'] as String,
        status: json['status'] as String,
        clientSettings: json['clientSettings'] != null
            ? MailClientSettings.fromJson(
                Map<String, dynamic>.from(json['clientSettings'] as Map))
            : null,
      );
}

class MailClientSettings {
  final String host;
  final int imapPort;
  final int smtpPort;
  final String login;

  MailClientSettings({
    required this.host,
    required this.imapPort,
    required this.smtpPort,
    required this.login,
  });

  factory MailClientSettings.fromJson(Map<String, dynamic> json) =>
      MailClientSettings(
        host: json['host'] as String,
        imapPort: (json['imapPort'] as num).toInt(),
        smtpPort: (json['smtpPort'] as num).toInt(),
        login: json['login'] as String,
      );
}

class MailListItemEntity {
  final int uid;
  final String from;
  final String fromAddress;
  final String subject;
  final DateTime date;
  final bool seen;
  final String snippet;
  final bool hasAttachments;

  MailListItemEntity({
    required this.uid,
    required this.from,
    required this.fromAddress,
    required this.subject,
    required this.date,
    required this.seen,
    required this.snippet,
    required this.hasAttachments,
  });

  factory MailListItemEntity.fromJson(Map<String, dynamic> json) =>
      MailListItemEntity(
        uid: (json['uid'] as num).toInt(),
        from: json['from'] as String? ?? '',
        fromAddress: json['fromAddress'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        seen: json['seen'] as bool? ?? false,
        snippet: json['snippet'] as String? ?? '',
        hasAttachments: json['hasAttachments'] as bool? ?? false,
      );

  MailListItemEntity copyWith({bool? seen}) => MailListItemEntity(
        uid: uid,
        from: from,
        fromAddress: fromAddress,
        subject: subject,
        date: date,
        seen: seen ?? this.seen,
        snippet: snippet,
        hasAttachments: hasAttachments,
      );
}

class MailAttachmentEntity {
  final int index;
  final String filename;
  final String contentType;
  final int size;

  MailAttachmentEntity({
    required this.index,
    required this.filename,
    required this.contentType,
    required this.size,
  });

  factory MailAttachmentEntity.fromJson(Map<String, dynamic> json) =>
      MailAttachmentEntity(
        index: (json['index'] as num).toInt(),
        filename: json['filename'] as String? ?? 'attachment',
        contentType: json['contentType'] as String? ?? 'application/octet-stream',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

class MailMessageEntity {
  final int uid;
  final String from;
  final String to;
  final String subject;
  final DateTime date;
  final String? messageId;
  final String? html;
  final String text;
  final List<MailAttachmentEntity> attachments;

  MailMessageEntity({
    required this.uid,
    required this.from,
    required this.to,
    required this.subject,
    required this.date,
    this.messageId,
    this.html,
    required this.text,
    required this.attachments,
  });

  factory MailMessageEntity.fromJson(Map<String, dynamic> json) =>
      MailMessageEntity(
        uid: (json['uid'] as num).toInt(),
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        messageId: json['messageId'] as String?,
        html: json['html'] as String?,
        text: json['text'] as String? ?? '',
        attachments: (json['attachments'] as List? ?? [])
            .map((a) => MailAttachmentEntity.fromJson(
                Map<String, dynamic>.from(a as Map)))
            .toList(),
      );
}

class MailAppPasswordEntity {
  final String id;
  final String label;
  final DateTime? createdAt;
  final String? password; // только сразу после создания

  MailAppPasswordEntity({
    required this.id,
    required this.label,
    this.createdAt,
    this.password,
  });

  factory MailAppPasswordEntity.fromJson(Map<String, dynamic> json) =>
      MailAppPasswordEntity(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        password: json['password'] as String?,
      );
}

class MailAvailabilityEntity {
  final String localpart;
  final bool available;
  final String? reason; // INVALID | RESERVED | TAKEN

  MailAvailabilityEntity({
    required this.localpart,
    required this.available,
    this.reason,
  });

  factory MailAvailabilityEntity.fromJson(Map<String, dynamic> json) =>
      MailAvailabilityEntity(
        localpart: json['localpart'] as String? ?? '',
        available: json['available'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}
