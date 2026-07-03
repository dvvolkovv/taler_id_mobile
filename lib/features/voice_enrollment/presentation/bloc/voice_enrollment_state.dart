import 'package:equatable/equatable.dart';

abstract class VoiceEnrollmentState extends Equatable {
  const VoiceEnrollmentState();
  @override
  List<Object?> get props => const [];
}

class Idle extends VoiceEnrollmentState {
  final bool busy;
  const Idle({this.busy = false});
  @override
  List<Object?> get props => [busy];
}

class NotEnrolled extends VoiceEnrollmentState {
  const NotEnrolled();
}

class Recording extends VoiceEnrollmentState {
  const Recording();
}

class Submitting extends VoiceEnrollmentState {
  const Submitting();
}

class Enrolled extends VoiceEnrollmentState {
  final String? speakerId;
  const Enrolled({this.speakerId});
  @override
  List<Object?> get props => [speakerId];
}

class Failed extends VoiceEnrollmentState {
  final String message;
  const Failed(this.message);
  @override
  List<Object?> get props => [message];
}
