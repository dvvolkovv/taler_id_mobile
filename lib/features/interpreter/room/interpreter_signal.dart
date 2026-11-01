import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A parsed message from the `interp` reliable data topic the agent
/// publishes. `parse` never throws — a room full of unrelated data packets
/// (or a future signal shape) should degrade to "ignored", not crash the
/// call.
sealed class InterpreterSignal extends Equatable {
  const InterpreterSignal();
}

/// Which side of the conversation a [CaptionSignal] reports: `source` is how
/// the speaker's own speech was recognised, `translation` is what the other
/// side hears.
enum CaptionRole { source, translation }

class CaptionSignal extends InterpreterSignal {
  final CaptionRole role;
  final String speaker;
  final String text;
  final bool isFinal;

  const CaptionSignal({
    required this.role,
    required this.speaker,
    required this.text,
    required this.isFinal,
  });

  @override
  List<Object?> get props => [role, speaker, text, isFinal];
}

class SpeakingSignal extends InterpreterSignal {
  final String speaker;
  final bool on;

  const SpeakingSignal({required this.speaker, required this.on});

  @override
  List<Object?> get props => [speaker, on];
}

enum StatusState { reconnecting, ok, failed }

class StatusSignal extends InterpreterSignal {
  final StatusState state;

  const StatusSignal(this.state);

  @override
  List<Object?> get props => [state];
}

CaptionRole? _roleFromJson(Object? raw) => switch (raw) {
      'source' => CaptionRole.source,
      'translation' => CaptionRole.translation,
      _ => null,
    };

StatusState? _stateFromJson(Object? raw) => switch (raw) {
      'reconnecting' => StatusState.reconnecting,
      'ok' => StatusState.ok,
      'failed' => StatusState.failed,
      _ => null,
    };

/// Parses one `interp`-topic data packet. Returns `null` on malformed UTF-8,
/// invalid JSON, an unknown `type`, or any field of the wrong shape —
/// callers treat all of those the same way: ignore the packet.
InterpreterSignal? parse(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) return null;

    switch (decoded['type']) {
      case 'caption':
        final role = _roleFromJson(decoded['role']);
        final speaker = decoded['speaker'];
        final text = decoded['text'];
        final isFinal = decoded['final'];
        if (role == null ||
            speaker is! String ||
            text is! String ||
            isFinal is! bool) {
          return null;
        }
        return CaptionSignal(
          role: role,
          speaker: speaker,
          text: text,
          isFinal: isFinal,
        );

      case 'speaking':
        final speaker = decoded['speaker'];
        final on = decoded['on'];
        if (speaker is! String || on is! bool) return null;
        return SpeakingSignal(speaker: speaker, on: on);

      case 'status':
        final state = _stateFromJson(decoded['state']);
        if (state == null) return null;
        return StatusSignal(state);

      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}
