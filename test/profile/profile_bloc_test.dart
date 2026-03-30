import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/profile/domain/entities/user_entity.dart';
import 'package:taler_id_mobile/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:taler_id_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taler_id_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:taler_id_mobile/features/profile/presentation/bloc/profile_state.dart';

class MockProfileRepository extends Mock implements IProfileRepository {}

const _user = UserEntity(
  id: 'user-123',
  email: 'user@test.com',
  firstName: 'Ivan',
  lastName: 'Petrov',
  username: 'ivan_p',
  kycStatus: KycStatus.unverified,
);

const _updatedUser = UserEntity(
  id: 'user-123',
  email: 'user@test.com',
  firstName: 'Dmitry',
  lastName: 'Volkov',
  username: 'dmitry_v',
  kycStatus: KycStatus.unverified,
);

void main() {
  late MockProfileRepository repo;
  late ProfileBloc bloc;

  setUp(() {
    repo = MockProfileRepository();
    bloc = ProfileBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  // ── Load ─────────────────────────────────────────────────────────────────

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => repo.getProfile()).thenAnswer((_) async => _user);
        return bloc;
      },
      act: (b) => b.add(ProfileLoadRequested()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>()
            .having((s) => s.user.id, 'id', 'user-123')
            .having((s) => s.user.email, 'email', 'user@test.com')
            .having((s) => s.user.firstName, 'firstName', 'Ivan'),
      ],
      verify: (_) => verify(() => repo.getProfile()).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] on ApiException',
      build: () {
        when(() => repo.getProfile())
            .thenThrow(const ApiException(statusCode: 401, message: 'Unauthorized'));
        return bloc;
      },
      act: (b) => b.add(ProfileLoadRequested()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'message', 'Unauthorized'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] on unexpected exception',
      build: () {
        when(() => repo.getProfile()).thenThrow(Exception('No internet'));
        return bloc;
      },
      act: (b) => b.add(ProfileLoadRequested()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'message', 'Не удалось загрузить профиль'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'returns correct kycStatus from loaded user',
      build: () {
        when(() => repo.getProfile()).thenAnswer((_) async => _user.copyWith(
              kycStatus: KycStatus.verified,
            ));
        return bloc;
      },
      act: (b) => b.add(ProfileLoadRequested()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
          (s) => s.user.kycStatus,
          'kycStatus',
          KycStatus.verified,
        ),
      ],
    );
  });

  // ── Update ────────────────────────────────────────────────────────────────

  group('ProfileUpdateSubmitted', () {
    const updateData = {'firstName': 'Dmitry', 'lastName': 'Volkov', 'username': 'dmitry_v'};

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Loaded] with updated data on success',
      build: () {
        when(() => repo.updateProfile(updateData)).thenAnswer((_) async => _updatedUser);
        return bloc;
      },
      act: (b) => b.add(const ProfileUpdateSubmitted(updateData)),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>()
            .having((s) => s.user.firstName, 'firstName', 'Dmitry')
            .having((s) => s.user.lastName, 'lastName', 'Volkov'),
      ],
      verify: (_) => verify(() => repo.updateProfile(updateData)).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] when update fails with ApiException',
      build: () {
        when(() => repo.updateProfile(any()))
            .thenThrow(const ApiException(statusCode: 422, message: 'Username taken'));
        return bloc;
      },
      act: (b) => b.add(const ProfileUpdateSubmitted({'username': 'existing_user'})),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'message', 'Username taken'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] on network failure during update',
      build: () {
        when(() => repo.updateProfile(any())).thenThrow(Exception('timeout'));
        return bloc;
      },
      act: (b) => b.add(const ProfileUpdateSubmitted({'firstName': 'Test'})),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'message', contains('Не удалось обновить профиль')),
      ],
    );
  });

  // ── Sequential events ─────────────────────────────────────────────────────

  group('Sequential events', () {
    blocTest<ProfileBloc, ProfileState>(
      'load then update produces correct state sequence',
      build: () {
        when(() => repo.getProfile()).thenAnswer((_) async => _user);
        when(() => repo.updateProfile(any())).thenAnswer((_) async => _updatedUser);
        return bloc;
      },
      act: (b) async {
        b.add(ProfileLoadRequested());
        await Future.delayed(const Duration(milliseconds: 10));
        b.add(const ProfileUpdateSubmitted({'firstName': 'Dmitry'}));
      },
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having((s) => s.user.firstName, 'firstName', 'Ivan'),
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having((s) => s.user.firstName, 'firstName', 'Dmitry'),
      ],
    );
  });
}
