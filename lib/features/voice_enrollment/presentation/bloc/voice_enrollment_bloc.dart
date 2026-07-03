import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/voice_enrollment_repository.dart';
import 'voice_enrollment_event.dart';
import 'voice_enrollment_state.dart';

class VoiceEnrollmentBloc
    extends Bloc<VoiceEnrollmentEvent, VoiceEnrollmentState> {
  final VoiceEnrollmentRepository repo;

  VoiceEnrollmentBloc({required this.repo}) : super(const Idle()) {
    on<Check>(_onCheck);
    on<StartRecording>((_, emit) => emit(const Recording()));
    on<Submit>(_onSubmit);
    on<Reset>((_, emit) => emit(const Idle()));
  }

  Future<void> _onCheck(Check _, Emitter<VoiceEnrollmentState> emit) async {
    emit(const Idle(busy: true));
    try {
      final status = await repo.getStatus();
      if (status.enrolled) {
        emit(Enrolled(speakerId: status.speakerId));
      } else {
        emit(const NotEnrolled());
      }
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> _onSubmit(Submit event, Emitter<VoiceEnrollmentState> emit) async {
    emit(const Submitting());
    try {
      final status = await repo.enroll(event.wavPath);
      emit(Enrolled(speakerId: status.speakerId));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }
}
