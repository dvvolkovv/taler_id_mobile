import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/billing_package_entity.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/wallet_balance_entity.dart';
import 'package:taler_id_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/packages_bloc.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/packages_event.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/packages_state.dart';

class MockBillingRepository extends Mock implements BillingRepository {}

const _packages = [
  BillingPackageEntity(
    id: 'starter',
    amountPlanck: '1000000000000',
    priceEurCents: 199,
    label: {'en': 'Starter', 'ru': 'Старт'},
    highlights: {'en': ['~15 min talk']},
  ),
  BillingPackageEntity(
    id: 'standard',
    amountPlanck: '5000000000000',
    priceEurCents: 799,
    label: {'en': 'Standard', 'ru': 'Стандарт'},
    highlights: {'en': ['~80 min talk']},
  ),
  BillingPackageEntity(
    id: 'premium',
    amountPlanck: '15000000000000',
    priceEurCents: 1999,
    label: {'en': 'Premium', 'ru': 'Премиум'},
    highlights: {'en': ['~240 min talk']},
  ),
];

const _newBalance = WalletBalanceEntity(
  balancePlanck: '6000000000000',
  balanceMicroTal: '6000000',
);

void main() {
  late MockBillingRepository repo;
  late PackagesBloc bloc;

  setUp(() {
    repo = MockBillingRepository();
    bloc = PackagesBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  group('LoadPackages', () {
    blocTest<PackagesBloc, PackagesState>(
      'emits [Loading, Loaded] with 3 packages',
      build: () {
        when(() => repo.getPackages()).thenAnswer((_) async => _packages);
        return bloc;
      },
      act: (b) => b.add(LoadPackages()),
      expect: () => [
        isA<PackagesLoading>(),
        isA<PackagesLoaded>()
            .having((s) => s.packages.length, 'count', 3)
            .having((s) => s.packages.first.id, 'first id', 'starter'),
      ],
      verify: (_) => verify(() => repo.getPackages()).called(1),
    );

    blocTest<PackagesBloc, PackagesState>(
      'emits [Loading, Error] on ApiException',
      build: () {
        when(() => repo.getPackages()).thenThrow(
          const ApiException(statusCode: 500, message: 'oops'),
        );
        return bloc;
      },
      act: (b) => b.add(LoadPackages()),
      expect: () => [
        isA<PackagesLoading>(),
        isA<PackagesError>().having((s) => s.message, 'message', 'oops'),
      ],
    );

    blocTest<PackagesBloc, PackagesState>(
      'emits [Loading, Error] with failedToLoadPackages on unknown error',
      build: () {
        when(() => repo.getPackages()).thenThrow(Exception('timeout'));
        return bloc;
      },
      act: (b) => b.add(LoadPackages()),
      expect: () => [
        isA<PackagesLoading>(),
        isA<PackagesError>().having(
          (s) => s.message,
          'message',
          'error.failedToLoadPackages',
        ),
      ],
    );
  });

  group('PurchasePackage', () {
    blocTest<PackagesBloc, PackagesState>(
      'happy path: [InProgress, Success, Loaded]',
      build: () {
        when(() => repo.getPackages()).thenAnswer((_) async => _packages);
        when(() => repo.purchase('standard'))
            .thenAnswer((_) async => _newBalance);
        return bloc;
      },
      act: (b) async {
        b.add(LoadPackages());
        await Future.delayed(Duration.zero);
        b.add(PurchasePackage('standard'));
      },
      expect: () => [
        isA<PackagesLoading>(),
        isA<PackagesLoaded>().having((s) => s.packages.length, 'count', 3),
        isA<PurchaseInProgress>()
            .having((s) => s.packageId, 'packageId', 'standard'),
        isA<PurchaseSuccess>().having(
          (s) => s.newBalance.balancePlanck,
          'new planck',
          '6000000000000',
        ),
        // After success, BLoC re-emits Loaded so user can purchase again.
        isA<PackagesLoaded>().having((s) => s.packages.length, 'count', 3),
      ],
      verify: (_) => verify(() => repo.purchase('standard')).called(1),
    );

    blocTest<PackagesBloc, PackagesState>(
      'on failure: [InProgress, PurchaseFailed, Loaded] — list remains usable',
      build: () {
        when(() => repo.getPackages()).thenAnswer((_) async => _packages);
        when(() => repo.purchase('premium')).thenThrow(
          const ApiException(statusCode: 402, message: 'Payment required'),
        );
        return bloc;
      },
      act: (b) async {
        b.add(LoadPackages());
        await Future.delayed(Duration.zero);
        b.add(PurchasePackage('premium'));
      },
      expect: () => [
        isA<PackagesLoading>(),
        isA<PackagesLoaded>(),
        isA<PurchaseInProgress>(),
        isA<PurchaseFailed>()
            .having((s) => s.message, 'message', 'Payment required'),
        isA<PackagesLoaded>().having((s) => s.packages.length, 'count', 3),
      ],
    );

    blocTest<PackagesBloc, PackagesState>(
      'on unknown error: emits failedToPurchasePackage key',
      build: () {
        when(() => repo.getPackages()).thenAnswer((_) async => _packages);
        when(() => repo.purchase('starter')).thenThrow(Exception('network'));
        return bloc;
      },
      act: (b) async {
        b.add(LoadPackages());
        await Future.delayed(Duration.zero);
        b.add(PurchasePackage('starter'));
      },
      expect: () => [
        isA<PackagesLoading>(),
        isA<PackagesLoaded>(),
        isA<PurchaseInProgress>(),
        isA<PurchaseFailed>().having(
          (s) => s.message,
          'message',
          'error.failedToPurchasePackage',
        ),
        isA<PackagesLoaded>(),
      ],
    );
  });
}
