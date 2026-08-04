import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:taler_id_mobile/features/auth/domain/entities/auth_entities.dart';
import 'package:taler_id_mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:taler_id_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taler_id_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:taler_id_mobile/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

const _tokens = AuthTokens(
  accessToken: 'test.access.token',
  refreshToken: 'test.refresh.token',
);

void main() {
  late MockAuthRepository repo;
  late AuthBloc bloc;

  setUp(() {
    repo = MockAuthRepository();
    bloc = AuthBloc(authRepository: repo);
  });

  tearDown(() => bloc.close());

  // ── Login ────────────────────────────────────────────────────────────────

  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful login',
      build: () {
        when(() => repo.login(email: 'user@test.com', password: 'pass123'))
            .thenAnswer((_) async => _tokens);
        return bloc;
      },
      act: (b) => b.add(LoginSubmitted(email: 'user@test.com', password: 'pass123')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.accessToken, 'accessToken', 'test.access.token'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Requires2FA] when server demands 2FA',
      build: () {
        when(() => repo.login(email: 'user@test.com', password: 'pass123'))
            .thenThrow(TwoFARequiredException(
          email: 'user@test.com',
          challengeToken: 'chal-token-123',
        ));
        return bloc;
      },
      act: (b) => b.add(LoginSubmitted(email: 'user@test.com', password: 'pass123')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRequires2FA>()
            .having((s) => s.email, 'email', 'user@test.com')
            .having((s) => s.challengeToken, 'challengeToken', 'chal-token-123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on wrong credentials',
      build: () {
        when(() => repo.login(email: 'user@test.com', password: 'wrong'))
            .thenThrow(const ApiException(statusCode: 401, message: 'Invalid credentials'));
        return bloc;
      },
      act: (b) => b.add(LoginSubmitted(email: 'user@test.com', password: 'wrong')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on network error',
      build: () {
        when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(Exception('Network unreachable'));
        return bloc;
      },
      act: (b) => b.add(LoginSubmitted(email: 'user@test.com', password: 'pass123')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>(),
      ],
    );
  });

  // ── Register ─────────────────────────────────────────────────────────────

  group('RegisterSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful registration',
      build: () {
        when(() => repo.register(
              email: 'new@test.com',
              password: 'pass123',
              firstName: 'Ivan',
              lastName: 'Petrov',
              username: 'ivan_p',
            )).thenAnswer((_) async => _tokens);
        return bloc;
      },
      act: (b) => b.add(RegisterSubmitted(
        email: 'new@test.com',
        password: 'pass123',
        firstName: 'Ivan',
        lastName: 'Petrov',
        username: 'ivan_p',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when email already taken',
      build: () {
        when(() => repo.register(
              email: any(named: 'email'),
              password: any(named: 'password'),
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              username: any(named: 'username'),
            )).thenThrow(const ApiException(statusCode: 409, message: 'Email already exists'));
        return bloc;
      },
      act: (b) => b.add(RegisterSubmitted(email: 'taken@test.com', password: 'pass123')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Email already exists'),
      ],
    );
  });

  // ── 2FA ──────────────────────────────────────────────────────────────────

  group('TwoFASubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on correct 2FA code',
      build: () {
        when(() => repo.verify2FA(
              code: '123456',
              challengeToken: 'chal-token',
            )).thenAnswer((_) async => _tokens);
        return bloc;
      },
      act: (b) => b.add(TwoFASubmitted(
        code: '123456',
        challengeToken: 'chal-token',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on wrong 2FA code',
      build: () {
        when(() => repo.verify2FA(
              code: any(named: 'code'),
              challengeToken: any(named: 'challengeToken'),
            )).thenThrow(const ApiException(statusCode: 400, message: 'Invalid code'));
        return bloc;
      },
      act: (b) => b.add(TwoFASubmitted(
        code: '000000',
        challengeToken: 'chal-token',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    // Пройденный TOTP не отменяет проверку устройства.
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, RequiresDeviceApproval] when the device is unknown',
      build: () {
        when(() => repo.verify2FA(
              code: any(named: 'code'),
              challengeToken: any(named: 'challengeToken'),
            )).thenThrow(const DeviceApprovalRequiredException(
          approvalToken: 'appr-1',
          approverCount: 2,
          emailAvailable: true,
          expiresIn: 600,
        ));
        return bloc;
      },
      act: (b) => b.add(TwoFASubmitted(
        code: '123456',
        challengeToken: 'chal-token',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRequiresDeviceApproval>()
            .having((s) => s.approvalToken, 'approvalToken', 'appr-1')
            .having((s) => s.approverCount, 'approverCount', 2),
      ],
    );
  });

  // ── Logout ───────────────────────────────────────────────────────────────

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [LoggedOut] after logout',
      build: () {
        when(() => repo.logout()).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(LogoutRequested()),
      expect: () => [isA<AuthLoggedOut>()],
      verify: (_) => verify(() => repo.logout()).called(1),
    );
  });

  // ── Forgot password ───────────────────────────────────────────────────────

  group('ForgotPassword', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, PasswordResetCodeSent] when email is valid',
      build: () {
        when(() => repo.requestPasswordReset('user@test.com'))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(ForgotPasswordRequested(email: 'user@test.com')),
      expect: () => [
        isA<AuthLoading>(),
        isA<PasswordResetCodeSent>().having((s) => s.email, 'email', 'user@test.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, PasswordResetCodeVerified] on correct code',
      build: () {
        when(() => repo.verifyPasswordResetCode(
              email: 'user@test.com',
              code: '654321',
            )).thenAnswer((_) async => 'reset-token-abc');
        return bloc;
      },
      act: (b) => b.add(ForgotPasswordCodeVerified(email: 'user@test.com', code: '654321')),
      expect: () => [
        isA<AuthLoading>(),
        isA<PasswordResetCodeVerified>()
            .having((s) => s.resetToken, 'resetToken', 'reset-token-abc'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, PasswordResetSuccess] on new password set',
      build: () {
        when(() => repo.resetPassword(
              resetToken: 'reset-token-abc',
              newPassword: 'newPass123',
            )).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(ForgotPasswordNewPassword(
        resetToken: 'reset-token-abc',
        newPassword: 'newPass123',
      )),
      expect: () => [isA<AuthLoading>(), isA<PasswordResetSuccess>()],
    );
  });
}
