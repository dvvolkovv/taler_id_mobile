import 'package:equatable/equatable.dart';

import '../../room/interpreter_room_controller.dart' show RoomUpdate;

sealed class InterpreterEvent extends Equatable {
  const InterpreterEvent();
}

/// Opens the feature. [joinCode] is set when the screen was reached via a
/// scanned/deep-linked `talerid://interp/<code>` link, so it can be carried
/// through to a [JoinPressed] once a language is picked.
class Started extends InterpreterEvent {
  final String? joinCode;
  const Started({this.joinCode});
  @override
  List<Object?> get props => [joinCode];
}

class LanguageChosen extends InterpreterEvent {
  final String code;
  const LanguageChosen(this.code);
  @override
  List<Object?> get props => [code];
}

class HostPressed extends InterpreterEvent {
  const HostPressed();
  @override
  List<Object?> get props => const [];
}

/// Also used to resume a join after a scan or a deep link, once a language
/// has been picked and (if needed) a voice print has been recorded.
class JoinPressed extends InterpreterEvent {
  final String code;
  const JoinPressed(this.code);
  @override
  List<Object?> get props => [code];
}

/// Sent by the screen after the owner-enrollment sheet closes: `true` if a
/// usable voice print now exists, `false` on cancel.
class VoicePrintResult extends InterpreterEvent {
  final bool ok;
  const VoicePrintResult(this.ok);
  @override
  List<Object?> get props => [ok];
}

class NewCodePressed extends InterpreterEvent {
  const NewCodePressed();
  @override
  List<Object?> get props => const [];
}

class EndPressed extends InterpreterEvent {
  const EndPressed();
  @override
  List<Object?> get props => const [];
}

class MicToggled extends InterpreterEvent {
  final bool on;
  const MicToggled(this.on);
  @override
  List<Object?> get props => [on];
}

class RetryPressed extends InterpreterEvent {
  const RetryPressed();
  @override
  List<Object?> get props => const [];
}

class BackToStart extends InterpreterEvent {
  const BackToStart();
  @override
  List<Object?> get props => const [];
}

/// Internal: one update from [InterpreterRoomController.updates], funneled
/// through the bloc's own event queue like every other state change rather
/// than reacted to directly from the subscription callback.
class RoomUpdateArrived extends InterpreterEvent {
  final RoomUpdate update;
  const RoomUpdateArrived(this.update);
  @override
  List<Object?> get props => [update];
}

/// Internal: fired by the poll timer while [InterpreterActive].
class PollTicked extends InterpreterEvent {
  const PollTicked();
  @override
  List<Object?> get props => const [];
}
