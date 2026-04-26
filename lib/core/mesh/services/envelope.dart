/// Phase 2 — wire-level envelope wrapping mesh-delivered messages.
///
/// Sent as JSON-encoded plaintext inside a Noise-encrypted data frame.
/// All fields are mandatory in v1; unknown fields are ignored on read for
/// forward compatibility with future envelope versions.
class Envelope {
  /// Envelope-format version (separate from the transport [Frame.version]).
  /// Bump when the field set changes incompatibly.
  final int version;

  /// Logical message type. Phase 2.0 supports only `'text'`. Future:
  /// `'system'` for membership change notices.
  final String type;

  /// Conversation id the message belongs to (server-side conversation UUID).
  /// On receive, used directly to route the message to the correct
  /// chat — bypasses Phase 1f's contact-userId resolveConversationId
  /// fallback (which is 1:1-only).
  final String convId;

  /// Sender-generated UUID v4. Same value passed to the server as
  /// `clientTempId` so receivers can dedup mesh-vs-server-echo (Phase 2.0
  /// uses heuristic dedup, not strict id-match — see spec §7).
  final String clientId;

  /// Message body (UTF-8).
  final String text;

  /// Send timestamp (UTC). Used for receiver-side ordering and the
  /// 10-second dedup window heuristic.
  final DateTime sentAt;

  Envelope({
    required this.version,
    required this.type,
    required this.convId,
    required this.clientId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'v': version,
        'type': type,
        'convId': convId,
        'clientId': clientId,
        'text': text,
        'sentAt': sentAt.toUtc().toIso8601String(),
      };

  factory Envelope.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    final type = json['type'];
    final convId = json['convId'];
    final clientId = json['clientId'];
    final text = json['text'];
    final sentAt = json['sentAt'];
    if (v is! int || type is! String || convId is! String ||
        clientId is! String || text is! String || sentAt is! String) {
      throw const FormatException('Envelope: missing or wrong-typed field');
    }
    final DateTime parsedAt;
    try {
      parsedAt = DateTime.parse(sentAt).toUtc();
    } on FormatException {
      throw const FormatException('Envelope: invalid sentAt timestamp');
    }
    return Envelope(
      version: v,
      type: type,
      convId: convId,
      clientId: clientId,
      text: text,
      sentAt: parsedAt,
    );
  }
}
