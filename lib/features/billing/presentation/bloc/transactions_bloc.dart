import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import '../../domain/repositories/billing_repository.dart';
import 'transactions_event.dart';
import 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final BillingRepository repo;

  TransactionsBloc({required this.repo}) : super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoad);
  }

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());
    try {
      final txs = await repo.getTransactions();
      emit(TransactionsLoaded(txs));
    } on ApiException catch (e) {
      emit(TransactionsError(e.message));
    } catch (_) {
      emit(TransactionsError(ErrorKeys.failedToLoadTransactions));
    }
  }
}
