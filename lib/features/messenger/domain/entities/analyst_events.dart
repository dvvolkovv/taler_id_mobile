class SeamStep {
  final String kind;   // 'search' | 'file' | 'cmd' | 'image' | 'other'
  final int count;
  const SeamStep({required this.kind, required this.count});

  factory SeamStep.fromJson(Map<String, dynamic> json) => SeamStep(
        kind: json['kind'] as String,
        count: (json['count'] as num).toInt(),
      );
}

class AnalystSeam {
  final String conversationId;
  final String messageId;
  final List<SeamStep> steps;
  final int durationMs;

  const AnalystSeam({
    required this.conversationId,
    required this.messageId,
    required this.steps,
    required this.durationMs,
  });

  factory AnalystSeam.fromJson(Map<String, dynamic> json) => AnalystSeam(
        conversationId: json['conversationId'] as String,
        messageId: json['messageId'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => SeamStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMs: (json['durationMs'] as num).toInt(),
      );

  /// Build a seam from an already-persisted message's metadata.
  static AnalystSeam? fromMetadata({
    required String conversationId,
    required String messageId,
    required Map<String, dynamic>? metadata,
  }) {
    if (metadata == null) return null;
    final stepsRaw = metadata['steps'];
    if (stepsRaw is! List || stepsRaw.isEmpty) return null;
    final steps = stepsRaw
        .map((e) => SeamStep.fromJson(e as Map<String, dynamic>))
        .toList();
    final durationMs = (metadata['durationMs'] as num?)?.toInt() ?? 0;
    return AnalystSeam(
      conversationId: conversationId,
      messageId: messageId,
      steps: steps,
      durationMs: durationMs,
    );
  }
}

class AnalystChunk {
  final String conversationId;
  final String text;
  const AnalystChunk({required this.conversationId, required this.text});

  factory AnalystChunk.fromJson(Map<String, dynamic> json) => AnalystChunk(
        conversationId: json['conversationId'] as String,
        text: json['text'] as String,
      );
}
