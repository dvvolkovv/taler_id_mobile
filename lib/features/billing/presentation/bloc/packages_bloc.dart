import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import '../../domain/entities/billing_package_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import 'packages_event.dart';
import 'packages_state.dart';

class PackagesBloc extends Bloc<PackagesEvent, PackagesState> {
  final BillingRepository repo;

  /// Cached latest loaded list, used to re-emit [PackagesLoaded] after a
  /// successful (or failed) purchase so the UI returns to a stable state.
  List<BillingPackageEntity> _lastLoaded = const [];

  PackagesBloc({required this.repo}) : super(PackagesInitial()) {
    on<LoadPackages>(_onLoad);
    on<PurchasePackage>(_onPurchase);
  }

  Future<void> _onLoad(LoadPackages event, Emitter<PackagesState> emit) async {
    emit(PackagesLoading());
    try {
      final packages = await repo.getPackages();
      _lastLoaded = packages;
      emit(PackagesLoaded(packages));
    } on ApiException catch (e) {
      emit(PackagesError(e.message));
    } catch (_) {
      emit(PackagesError(ErrorKeys.failedToLoadPackages));
    }
  }

  Future<void> _onPurchase(
    PurchasePackage event,
    Emitter<PackagesState> emit,
  ) async {
    emit(PurchaseInProgress(event.packageId));
    try {
      final newBalance = await repo.purchase(event.packageId);
      emit(PurchaseSuccess(newBalance: newBalance));
      // Immediately return to a stable list state so the user can purchase
      // a second package without re-navigating.
      emit(PackagesLoaded(_lastLoaded));
    } on ApiException catch (e) {
      emit(PurchaseFailed(e.message));
      emit(PackagesLoaded(_lastLoaded));
    } catch (_) {
      emit(PurchaseFailed(ErrorKeys.failedToPurchasePackage));
      emit(PackagesLoaded(_lastLoaded));
    }
  }
}
