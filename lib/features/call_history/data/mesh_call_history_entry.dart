/// Local-only mesh call history record. Stored in Hive box `mesh_call_history`
/// as a JSON-encoded string (no type adapter — matches the rest of the
/// codebase's Hive-as-string-cache pattern, e.g. `messenger_cache_service`).
class MeshCallHistoryEntry {
  final int callId;
  final String peerDevicePkBase64;
  final String? peerUserId;
  final String? peerName;
  final bool isOutgoing;
  final DateTime startedAt;
  final DateTime? activatedAt;
  final DateTime endedAt;
  final int? durationSec;
  final String endReason;
  final String? transport;

  const MeshCallHistoryEntry({
    required this.callId,
    required this.peerDevicePkBase64,
    required this.peerUserId,
    required this.peerName,
    required this.isOutgoing,
    required this.startedAt,
    required this.activatedAt,
    required this.endedAt,
    required this.durationSec,
    required this.endReason,
    required this.transport,
  });

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'peerDevicePkBase64': peerDevicePkBase64,
        'peerUserId': peerUserId,
        'peerName': peerName,
        'isOutgoing': isOutgoing,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'activatedAt': activatedAt?.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
        'durationSec': durationSec,
        'endReason': endReason,
        'transport': transport,
      };

  factory MeshCallHistoryEntry.fromJson(Map<String, dynamic> j) =>
      MeshCallHistoryEntry(
        callId: j['callId'] as int,
        peerDevicePkBase64: j['peerDevicePkBase64'] as String,
        peerUserId: j['peerUserId'] as String?,
        peerName: j['peerName'] as String?,
        isOutgoing: j['isOutgoing'] as bool,
        startedAt: DateTime.parse(j['startedAt'] as String),
        activatedAt: j['activatedAt'] == null
            ? null
            : DateTime.parse(j['activatedAt'] as String),
        endedAt: DateTime.parse(j['endedAt'] as String),
        durationSec: j['durationSec'] as int?,
        endReason: j['endReason'] as String,
        transport: j['transport'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is MeshCallHistoryEntry &&
      other.callId == callId &&
      other.peerDevicePkBase64 == peerDevicePkBase64 &&
      other.peerUserId == peerUserId &&
      other.peerName == peerName &&
      other.isOutgoing == isOutgoing &&
      other.startedAt == startedAt &&
      other.activatedAt == activatedAt &&
      other.endedAt == endedAt &&
      other.durationSec == durationSec &&
      other.endReason == endReason &&
      other.transport == transport;

  @override
  int get hashCode => Object.hash(
      callId,
      peerDevicePkBase64,
      peerUserId,
      peerName,
      isOutgoing,
      startedAt,
      activatedAt,
      endedAt,
      durationSec,
      endReason,
      transport);
}
