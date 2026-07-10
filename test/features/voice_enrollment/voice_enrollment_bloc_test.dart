import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/voice_enrollment/domain/entities/owner_voice_status.dart';
import 'package:taler_id_mobile/features/voice_enrollment/domain/repositories/voice_enrollment_repository.dart';
import 'package:taler_id_mobile/features/voice_enrollment/presentation/bloc/voice_enrollment_bloc.dart';
import 'package:taler_id_mobile/features/voice_enrollment/presentation/bloc/voice_enrollment_event.dart';
import 'package:taler_id_mobile/features/voice_enrollment/presentation/bloc/voice_enrollment_state.dart';

class _MockRepo extends Mock implements VoiceEnrollmentRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  blocTest<VoiceEnrollmentBloc, VoiceEnrollmentState>(
    'Check → emits Enrolled when status.enrolled=true',
    build: () {
      when(() => repo.getStatus()).thenAnswer(
        (_) async => const OwnerVoiceStatus(enrolled: true, speakerId: 'spk_x'),
      );
      return VoiceEnrollmentBloc(repo: repo);
    },
    act: (b) => b.add(const Check()),
    expect: () => [
      isA<Idle>().having((s) => s.busy, 'busy', true),
      isA<Enrolled>().having((s) => s.speakerId, 'speakerId', 'spk_x'),
    ],
  );

  blocTest<VoiceEnrollmentBloc, VoiceEnrollmentState>(
    'Check → emits NotEnrolled when status.enrolled=false',
    build: () {
      when(() => repo.getStatus()).thenAnswer(
        (_) async => const OwnerVoiceStatus(enrolled: false),
      );
      return VoiceEnrollmentBloc(repo: repo);
    },
    act: (b) => b.add(const Check()),
    expect: () => [
      isA<Idle>().having((s) => s.busy, 'busy', true),
      isA<NotEnrolled>(),
    ],
  );

  blocTest<VoiceEnrollmentBloc, VoiceEnrollmentState>(
    'Submit → emits Enrolled on success',
    build: () {
      when(() => repo.enroll(any())).thenAnswer(
        (_) async => const OwnerVoiceStatus(enrolled: true, speakerId: 'spk_y'),
      );
      return VoiceEnrollmentBloc(repo: repo);
    },
    act: (b) => b.add(const Submit('/tmp/x.wav')),
    expect: () => [
      isA<Submitting>(),
      isA<Enrolled>().having((s) => s.speakerId, 'speakerId', 'spk_y'),
    ],
  );

  blocTest<VoiceEnrollmentBloc, VoiceEnrollmentState>(
    'Submit → emits Failed on error',
    build: () {
      when(() => repo.enroll(any())).thenThrow(Exception('boom'));
      return VoiceEnrollmentBloc(repo: repo);
    },
    act: (b) => b.add(const Submit('/tmp/x.wav')),
    expect: () => [
      isA<Submitting>(),
      isA<Failed>(),
    ],
  );

  blocTest<VoiceEnrollmentBloc, VoiceEnrollmentState>(
    'Delete → emits NotEnrolled on success',
    build: () {
      when(() => repo.deleteOwner()).thenAnswer((_) async {});
      return VoiceEnrollmentBloc(repo: repo);
    },
    act: (b) => b.add(const Delete()),
    expect: () => [
      isA<Idle>().having((s) => s.busy, 'busy', true),
      isA<NotEnrolled>(),
    ],
  );

  blocTest<VoiceEnrollmentBloc, VoiceEnrollmentState>(
    'Delete → emits Failed on error',
    build: () {
      when(() => repo.deleteOwner()).thenThrow(Exception('boom'));
      return VoiceEnrollmentBloc(repo: repo);
    },
    act: (b) => b.add(const Delete()),
    expect: () => [
      isA<Idle>().having((s) => s.busy, 'busy', true),
      isA<Failed>(),
    ],
  );
}
