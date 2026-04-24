import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import '../../domain/repositories/billing_repository.dart';
import 'balance_event.dart';
import 'balance_state.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final BillingRepository repo;

  BalanceBloc({required this.repo}) : super(BalanceInitial()) {
    on<LoadBalance>(_onLoad);
    on<BalanceChangedExternally>(_onChangedExternally);
  }

  Future<void> _onLoad(LoadBalance event, Emitter<BalanceState> emit) async {
    emit(BalanceLoading());
    try {
      final balance = await repo.getBalance();
      emit(BalanceLoaded(balance));
    } on ApiException catch (e) {
      emit(BalanceError(e.message));
    } catch (_) {
      emit(BalanceError(ErrorKeys.failedToLoadBalance));
    }
  }

  /// On external push (socket), always re-fetch — backend is source of truth
  /// and may include updated `recentTx` deltas beyond just the new planck value.
  Future<void> _onChangedExternally(
    BalanceChangedExternally event,
    Emitter<BalanceState> emit,
  ) async {
    try {
      final balance = await repo.getBalance();
      emit(BalanceLoaded(balance));
    } on ApiException catch (e) {
      emit(BalanceError(e.message));
    } catch (_) {
      emit(BalanceError(ErrorKeys.failedToLoadBalance));
    }
  }
}
