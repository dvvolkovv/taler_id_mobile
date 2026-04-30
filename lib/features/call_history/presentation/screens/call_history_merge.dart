import 'dart:convert';

import '../../data/mesh_call_history_entry.dart';

/// View-model row used by the CallHistoryScreen list. Both server-fetched
/// and mesh-stored entries map onto this shape so the rendering code
/// doesn't branch on source.
class HistoryDisplayRow {
  final String id;
  final String otherPartyName;
  final String? otherPartyAvatar;
  final String? otherPartyId;
  final DateTime startedAt;
  final int? durationSec;
  final bool isOutgoing;
  final bool isMissed;
  final bool withAi;
  final String? conversationId;
  final bool isMesh;
  final String? meshEndReason;

  const HistoryDisplayRow({
    required this.id,
    required this.otherPartyName,
    required this.otherPartyAvatar,
    required this.otherPartyId,
    required this.startedAt,
    required this.durationSec,
    required this.isOutgoing,
    required this.isMissed,
    required this.withAi,
    required this.conversationId,
    required this.isMesh,
    required this.meshEndReason,
  });
}

/// Convert a [MeshCallHistoryEntry] to a [HistoryDisplayRow].
HistoryDisplayRow displayRowFromMesh(MeshCallHistoryEntry m) {
  String hexShort;
  try {
    final bytes = base64Decode(m.peerDevicePkBase64);
    final n = bytes.length < 4 ? bytes.length : 4;
    hexShort = bytes
        .take(n)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  } catch (_) {
    final l = m.peerDevicePkBase64.length;
    hexShort = m.peerDevicePkBase64.substring(0, l < 8 ? l : 8);
  }
  final name = (m.peerName != null && m.peerName!.isNotEmpty)
      ? m.peerName!
      : 'Mesh-устройство $hexShort';
  final isMissed = m.activatedAt == null &&
      (m.endReason == 'inviteTimeout' || m.endReason == 'rejectedByCallee');
  return HistoryDisplayRow(
    id: 'mesh-${m.callId.toRadixString(16)}',
    otherPartyName: name,
    otherPartyAvatar: null,
    otherPartyId: m.peerUserId,
    startedAt: m.startedAt,
    durationSec: m.durationSec,
    isOutgoing: m.isOutgoing,
    isMissed: isMissed,
    withAi: false,
    conversationId: null,
    isMesh: true,
    meshEndReason: m.endReason,
  );
}

/// Merge server-fetched display rows with mesh entries (converted on the fly),
/// sorted globally by startedAt desc.
List<HistoryDisplayRow> mergedHistoryEntries({
  required List<HistoryDisplayRow> serverEntries,
  required List<MeshCallHistoryEntry> meshEntries,
}) {
  final all = <HistoryDisplayRow>[
    ...serverEntries,
    ...meshEntries.map(displayRowFromMesh),
  ];
  all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return all;
}
