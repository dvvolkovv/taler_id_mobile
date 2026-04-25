import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/wallet_balance_entity.dart';
import 'package:taler_id_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_bloc.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_event.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_state.dart';

class MockBillingRepository extends Mock implements BillingRepository {}

const _balance = WalletBalanceEntity(
  balancePlanck: '1000000000000',
  balanceMicroTal: '1000000',
  custodialAddress: '5Abc...xyz',
);

const _balance2 = WalletBalanceEntity(
  balancePlanck: '2000000000000',
  balanceMicroTal: '2000000',
  custodialAddress: '5Abc...xyz',
);

void main() {
  late MockBillingRepository repo;
  late BalanceBloc bloc;

  setUp(() {
    repo = MockBillingRepository();
    bloc = BalanceBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  group('LoadBalance', () {
    blocTest<BalanceBloc, BalanceState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => repo.getBalance()).thenAnswer((_) async => _balance);
        return bloc;
      },
      act: (b) => b.add(LoadBalance()),
      expect: () => [
        isA<BalanceLoading>(),
        isA<BalanceLoaded>()
            .having((s) => s.balance.balancePlanck, 'planck', '1000000000000'),
      ],
      verify: (_) => verify(() => repo.getBalance()).called(1),
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits [Loading, Error] with server message on ApiException',
      build: () {
        when(() => repo.getBalance()).thenThrow(
          const ApiException(statusCode: 401, message: 'Unauthorized'),
        );
        return bloc;
      },
      act: (b) => b.add(LoadBalance()),
      expect: () => [
        isA<BalanceLoading>(),
        isA<BalanceError>().having((s) => s.message, 'message', 'Unauthorized'),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits [Loading, Error] with failedToLoadBalance key on unknown error',
      build: () {
        when(() => repo.getBalance()).thenThrow(Exception('boom'));
        return bloc;
      },
      act: (b) => b.add(LoadBalance()),
      expect: () => [
        isA<BalanceLoading>(),
        isA<BalanceError>().having(
          (s) => s.message,
          'message',
          'error.failedToLoadBalance',
        ),
      ],
    );
  });

  group('BalanceChangedExternally', () {
    blocTest<BalanceBloc, BalanceState>(
      'refetches and emits [Loaded] with the fresh balance',
      build: () {
        when(() => repo.getBalance()).thenAnswer((_) async => _balance2);
        return bloc;
      },
      seed: () => BalanceLoaded(_balance),
      act: (b) => b.add(BalanceChangedExternally('2000000000000')),
      expect: () => [
        isA<BalanceLoaded>()
            .having((s) => s.balance.balancePlanck, 'planck', '2000000000000'),
      ],
      verify: (_) => verify(() => repo.getBalance()).called(1),
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits [Error] when refetch fails',
      build: () {
        when(() => repo.getBalance()).thenThrow(
          const ApiException(statusCode: 500, message: 'Server error'),
        );
        return bloc;
      },
      seed: () => BalanceLoaded(_balance),
      act: (b) => b.add(BalanceChangedExternally('2000000000000')),
      expect: () => [
        isA<BalanceError>()
            .having((s) => s.message, 'message', 'Server error'),
      ],
    );
  });
}
