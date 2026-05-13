/// Phase 2 — wire-level envelope wrapping mesh-delivered messages.
///
/// Sent as JSON-encoded plaintext inside a Noise-encrypted data frame.
/// All fields are mandatory in v1; unknown fields are ignored on read for
/// forward compatibility with future envelope versions.
class Envelope {
  /// Envelope-format version (separate from the transport [Frame.version]).
  /// Bump when the field set changes incompatibly.
  final int version;

  /// Logical message type. Phase 2.0 supports only `'text'`. Phase 3c adds
  /// `'call_invite'`, `'call_accept'`, `'call_reject'`, `'call_end'`,
  /// `'call_keepalive'` for mesh voice signaling. Future: `'system'` for
  /// membership change notices.
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

  /// Message body (UTF-8). Empty string for non-text envelopes (call signaling).
  final String text;

  /// Send timestamp (UTC). Used for receiver-side ordering and the
  /// 10-second dedup window heuristic.
  final DateTime sentAt;

  /// Optional typed payload for non-text envelopes (e.g., call signaling).
  /// Null for legacy v1 text envelopes; populated for `call_*` types in
  /// Phase 3 mesh voice. Forward-compatible: legacy peers parse the
  /// envelope with `extra=null` and ignore the field.
  final Map<String, dynamic>? extra;

  Envelope({
    required this.version,
    required this.type,
    required this.convId,
    required this.clientId,
    required this.text,
    required this.sentAt,
    this.extra,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'v': version,
      'type': type,
      'convId': convId,
      'clientId': clientId,
      'text': text,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
    if (extra != null) {
      json['extra'] = extra;
    }
    return json;
  }

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
    final extraRaw = json['extra'];
    final Map<String, dynamic>? extra = extraRaw is Map<String, dynamic>
        ? extraRaw
        : (extraRaw is Map ? Map<String, dynamic>.from(extraRaw) : null);
    return Envelope(
      version: v,
      type: type,
      convId: convId,
      clientId: clientId,
      text: text,
      sentAt: parsedAt,
      extra: extra,
    );
  }
}

/// Group voice call envelope types (group mesh voice room v1).
///
/// Wire shape is identical to the existing v1 [Envelope]. Payload-specific
/// fields live in [Envelope.extra]. See spec at
/// docs/superpowers/specs/2026-05-13-group-mesh-voice-room-design.md.
class MeshGcEnvelopeType {
  static const invite = 'mesh_gc_invite';
  static const accept = 'mesh_gc_accept';
  static const decline = 'mesh_gc_decline';
  static const leave = 'mesh_gc_leave';
  static const keepalive = 'mesh_gc_keepalive';

  static const _all = {invite, accept, decline, leave, keepalive};

  static bool isMeshGc(String type) => _all.contains(type);
}
