import 'package:equatable/equatable.dart';

abstract class VoiceEnrollmentEvent extends Equatable {
  const VoiceEnrollmentEvent();
  @override
  List<Object?> get props => const [];
}

class Check extends VoiceEnrollmentEvent {
  const Check();
}

class StartRecording extends VoiceEnrollmentEvent {
  const StartRecording();
}

class Submit extends VoiceEnrollmentEvent {
  final String wavPath;
  const Submit(this.wavPath);
  @override
  List<Object?> get props => [wavPath];
}

class Reset extends VoiceEnrollmentEvent {
  const Reset();
}
