import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/kyc/data/datasources/kyc_remote_datasource.dart';
import 'package:taler_id_mobile/features/kyc/domain/entities/sumsub_applicant_entity.dart';
import 'package:taler_id_mobile/features/kyc/domain/repositories/i_kyc_repository.dart';
import 'package:taler_id_mobile/features/kyc/presentation/bloc/kyc_bloc.dart';
import 'package:taler_id_mobile/features/kyc/presentation/bloc/kyc_event.dart';
import 'package:taler_id_mobile/features/kyc/presentation/bloc/kyc_state.dart';

class MockKycRepository extends Mock implements IKycRepository {}

const _applicant = SumsubApplicantEntity(applicantId: 'app-123');

void main() {
  late MockKycRepository repo;
  late KycBloc bloc;

  setUp(() {
    repo = MockKycRepository();
    bloc = KycBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  // ── Status ────────────────────────────────────────────────────────────────

  group('KycStatusRequested', () {
    blocTest<KycBloc, KycState>(
      'emits [Loading, StatusLoaded(UNVERIFIED)] when not verified',
      build: () {
        when(() => repo.getKycStatus()).thenAnswer((_) async => {'status': 'UNVERIFIED'});
        return bloc;
      },
      act: (b) => b.add(KycStatusRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycStatusLoaded>().having((s) => s.status, 'status', 'UNVERIFIED'),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [Loading, StatusLoaded(PENDING)] for pending KYC',
      build: () {
        when(() => repo.getKycStatus()).thenAnswer((_) async => {'status': 'PENDING'});
        return bloc;
      },
      act: (b) => b.add(KycStatusRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycStatusLoaded>().having((s) => s.status, 'status', 'PENDING'),
      ],
    );

    blocTest<KycBloc, KycState>(
      'auto-fetches applicant data when status is VERIFIED',
      build: () {
        when(() => repo.getKycStatus()).thenAnswer((_) async => {
              'status': 'VERIFIED',
              'verifiedAt': '2024-01-15T10:00:00Z',
            });
        when(() => repo.getApplicantData()).thenAnswer((_) async => _applicant);
        return bloc;
      },
      act: (b) => b.add(KycStatusRequested()),
      expect: () => [
        isA<KycLoading>(),
        // StatusLoaded(VERIFIED) → triggers KycApplicantDataRequested
        isA<KycStatusLoaded>().having((s) => s.status, 'status', 'VERIFIED'),
        isA<KycApplicantDataLoading>(),
        isA<KycStatusLoaded>()
            .having((s) => s.applicantData?.applicantId, 'applicantId', 'app-123'),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [Loading, StatusLoaded] with rejectionReason when REJECTED',
      build: () {
        when(() => repo.getKycStatus()).thenAnswer((_) async => {
              'status': 'REJECTED',
              'rejectionReason': 'Document expired',
            });
        return bloc;
      },
      act: (b) => b.add(KycStatusRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycStatusLoaded>()
            .having((s) => s.status, 'status', 'REJECTED')
            .having((s) => s.rejectionReason, 'rejectionReason', 'Document expired'),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [Loading, Error] on ApiException',
      build: () {
        when(() => repo.getKycStatus())
            .thenThrow(const ApiException(statusCode: 500, message: 'Server error'));
        return bloc;
      },
      act: (b) => b.add(KycStatusRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycError>().having((s) => s.message, 'message', 'Server error'),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [Loading, Error] on unexpected exception',
      build: () {
        when(() => repo.getKycStatus()).thenThrow(Exception('timeout'));
        return bloc;
      },
      act: (b) => b.add(KycStatusRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycError>().having(
            (s) => s.message, 'message', 'error.failedToLoadKycStatus'),
      ],
    );
  });

  // ── Start KYC ─────────────────────────────────────────────────────────────

  group('KycStartRequested', () {
    blocTest<KycBloc, KycState>(
      'emits [Loading, SdkReady] with WebSDK url',
      build: () {
        when(() => repo.startKyc()).thenAnswer((_) async => const KycStartResponse(
              applicantId: 'app-123',
              webSdkUrl: 'https://mockss-test.up.railway.app/idensic/sdk/checkup?accessToken=tok',
              sdkBaseUrl: 'https://mockss-test.up.railway.app',
              status: 'PENDING',
            ));
        return bloc;
      },
      act: (b) => b.add(KycStartRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycSdkReady>().having(
          (s) => s.webSdkUrl,
          'webSdkUrl',
          contains('accessToken=tok'),
        ),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [Loading, Error] when KYC already started',
      build: () {
        when(() => repo.startKyc()).thenThrow(
            const ApiException(statusCode: 409, message: 'KYC already in progress'));
        return bloc;
      },
      act: (b) => b.add(KycStartRequested()),
      expect: () => [
        isA<KycLoading>(),
        isA<KycError>().having((s) => s.message, 'message', 'KYC already in progress'),
      ],
    );
  });

  // ── SDK callbacks ─────────────────────────────────────────────────────────

  group('KycSdkCompleted', () {
    blocTest<KycBloc, KycState>(
      'emits [SdkDone] when SDK finishes',
      build: () => bloc,
      act: (b) => b.add(KycSdkCompleted()),
      expect: () => [isA<KycSdkDone>()],
    );
  });

  group('KycSdkFailed', () {
    blocTest<KycBloc, KycState>(
      'emits [Error] with error code message',
      build: () => bloc,
      act: (b) => b.add(KycSdkFailed('1006')),
      expect: () => [
        isA<KycError>().having(
            (s) => s.message, 'message', contains('1006')),
      ],
    );
  });

  // ── Applicant data (manual) ────────────────────────────────────────────────

  group('KycApplicantDataRequested', () {
    blocTest<KycBloc, KycState>(
      'emits [ApplicantDataLoading, StatusLoaded] with applicant data',
      build: () {
        when(() => repo.getApplicantData()).thenAnswer((_) async => _applicant);
        return bloc;
      },
      act: (b) => b.add(KycApplicantDataRequested()),
      expect: () => [
        isA<KycApplicantDataLoading>(),
        isA<KycStatusLoaded>()
            .having((s) => s.applicantData?.applicantId, 'applicantId', 'app-123'),
      ],
    );

    blocTest<KycBloc, KycState>(
      'emits [ApplicantDataLoading, Error] when fetch fails',
      build: () {
        when(() => repo.getApplicantData()).thenThrow(Exception('fetch failed'));
        return bloc;
      },
      act: (b) => b.add(KycApplicantDataRequested()),
      expect: () => [
        isA<KycApplicantDataLoading>(),
        isA<KycError>().having(
            (s) => s.message, 'message', 'error.failedToLoadKycData'),
      ],
    );
  });
}
