import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/billing_transaction_entity.dart';
import 'package:taler_id_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/transactions_bloc.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/transactions_event.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/transactions_state.dart';

class MockBillingRepository extends Mock implements BillingRepository {}

const _txs = [
  BillingTransactionEntity(
    id: 'tx-1',
    type: 'TOPUP',
    amountPlanck: '5000000000000',
    createdAt: '2026-04-20T10:00:00Z',
    status: 'COMPLETED',
  ),
  BillingTransactionEntity(
    id: 'tx-2',
    type: 'CHARGE',
    amountPlanck: '-120000000',
    featureKey: 'ai.voice',
    sessionId: 'sess-xyz',
    createdAt: '2026-04-21T10:00:00Z',
    status: 'COMPLETED',
  ),
  BillingTransactionEntity(
    id: 'tx-3',
    type: 'CHARGE',
    amountPlanck: '-50000',
    featureKey: 'ai.web_search',
    createdAt: '2026-04-22T10:00:00Z',
    status: 'COMPLETED',
  ),
];

void main() {
  late MockBillingRepository repo;
  late TransactionsBloc bloc;

  setUp(() {
    repo = MockBillingRepository();
    bloc = TransactionsBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  group('LoadTransactions', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'emits [Loading, Loaded] with list of transactions',
      build: () {
        when(() => repo.getTransactions()).thenAnswer((_) async => _txs);
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsLoaded>()
            .having((s) => s.transactions.length, 'count', 3)
            .having((s) => s.transactions.first.id, 'first id', 'tx-1')
            .having(
              (s) => s.transactions[1].type,
              'charge type',
              'CHARGE',
            ),
      ],
      verify: (_) => verify(() => repo.getTransactions()).called(1),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'emits [Loading, Loaded] with empty list',
      build: () {
        when(() => repo.getTransactions()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsLoaded>()
            .having((s) => s.transactions, 'transactions', isEmpty),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'emits [Loading, Error] with server message on ApiException',
      build: () {
        when(() => repo.getTransactions()).thenThrow(
          const ApiException(statusCode: 401, message: 'Unauthorized'),
        );
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Unauthorized'),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'emits failedToLoadTransactions key on unknown error',
      build: () {
        when(() => repo.getTransactions()).thenThrow(Exception('net'));
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsError>().having(
          (s) => s.message,
          'message',
          'error.failedToLoadTransactions',
        ),
      ],
    );
  });
}
