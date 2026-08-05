import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/wallet_balance_entity.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_bloc.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_event.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_state.dart';
import 'package:taler_id_mobile/features/billing/presentation/widgets/balance_chip.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';

class MockBalanceBloc extends MockBloc<BalanceEvent, BalanceState>
    implements BalanceBloc {}

const _balance = WalletBalanceEntity(
  balancePlanck: '430000000000',
  balanceMicroTal: '430.00',
  custodialAddress: '5Abc...xyz',
);

Widget _pumpChipWith(BalanceBloc bloc) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          appBar: AppBar(
            title: const Text('home'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: BalanceChip(),
              )
            ],
          ),
          body: const SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RouteConstants.wallet,
        builder: (_, __) => const Scaffold(body: Text('wallet screen')),
      ),
    ],
  );
  return BlocProvider<BalanceBloc>.value(
    value: bloc,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockBalanceBloc bloc;

  setUp(() {
    bloc = MockBalanceBloc();
  });

  tearDown(() => bloc.close());

  testWidgets('BalanceChip shows "X.XX μTAL" on BalanceLoaded', (tester) async {
    whenListen(
      bloc,
      Stream<BalanceState>.empty(),
      initialState: BalanceLoaded(_balance),
    );
    await tester.pumpWidget(_pumpChipWith(bloc));

    expect(find.text('430.00 μTAL'), findsOneWidget);
    expect(
      find.byIcon(Icons.account_balance_wallet_outlined),
      findsOneWidget,
    );
  });

  testWidgets('BalanceChip shows ellipsis on BalanceLoading', (tester) async {
    whenListen(
      bloc,
      Stream<BalanceState>.empty(),
      initialState: BalanceLoading(),
    );
    await tester.pumpWidget(_pumpChipWith(bloc));

    expect(find.text('…'), findsOneWidget);
  });

  testWidgets('BalanceChip shows em-dash on BalanceError / BalanceInitial',
      (tester) async {
    whenListen(
      bloc,
      Stream<BalanceState>.empty(),
      initialState: BalanceError('error.failedToLoadBalance'),
    );
    await tester.pumpWidget(_pumpChipWith(bloc));

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('Tap on BalanceChip navigates to wallet', (tester) async {
    whenListen(
      bloc,
      Stream<BalanceState>.empty(),
      initialState: BalanceLoaded(_balance),
    );
    await tester.pumpWidget(_pumpChipWith(bloc));

    await tester.tap(find.byType(BalanceChip));
    await tester.pumpAndSettle();

    expect(find.text('wallet screen'), findsOneWidget);
  });
}
