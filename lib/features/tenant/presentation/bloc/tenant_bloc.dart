import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import 'tenant_event.dart';
import 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final ITenantRepository repo;

  TenantBloc({required this.repo}) : super(TenantInitial()) {
    on<TenantsLoadRequested>(_onLoad);
    on<TenantDetailRequested>(_onDetail);
    on<TenantCreateSubmitted>(_onCreate);
    on<TenantUpdateSubmitted>(_onUpdate);
    on<TenantMemberInvited>(_onInvite);
    on<TenantMemberRoleChanged>(_onRoleChange);
    on<TenantMemberRemoved>(_onRemoveMember);
    on<TenantInviteAccepted>(_onAcceptInvite);
    on<TenantKybStartRequested>(_onKybStart);
    on<TenantKybSdkCompleted>(_onKybComplete);
  }

  Future<void> _onLoad(TenantsLoadRequested event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final tenants = await repo.getMyTenants();
      emit(TenantsLoaded(tenants));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToLoadOrgs));
    }
  }

  Future<void> _onDetail(TenantDetailRequested event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final tenant = await repo.getTenant(event.tenantId);
      emit(TenantDetailLoaded(tenant));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToLoadOrg));
    }
  }

  Future<void> _onCreate(TenantCreateSubmitted event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      await repo.createTenant(event.data);
      final tenants = await repo.getMyTenants();
      emit(TenantsLoaded(tenants));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToCreateOrg));
    }
  }

  Future<void> _onUpdate(TenantUpdateSubmitted event, Emitter<TenantState> emit) async {
    try {
      await repo.updateTenant(event.tenantId, event.data);
      emit(TenantActionSuccess(ErrorKeys.orgUpdated));
      add(TenantDetailRequested(event.tenantId));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToUpdateOrg));
    }
  }

  Future<void> _onInvite(TenantMemberInvited event, Emitter<TenantState> emit) async {
    try {
      await repo.inviteMember(
        tenantId: event.tenantId,
        email: event.email,
        role: event.role,
      );
      emit(TenantActionSuccess('inviteSent:${event.email}'));
      add(TenantDetailRequested(event.tenantId));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToInvite));
    }
  }

  Future<void> _onRoleChange(TenantMemberRoleChanged event, Emitter<TenantState> emit) async {
    try {
      await repo.updateMember(
        tenantId: event.tenantId,
        memberId: event.memberId,
        role: event.role,
      );
      emit(TenantActionSuccess(ErrorKeys.roleChanged));
      add(TenantDetailRequested(event.tenantId));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToChangeRole));
    }
  }

  Future<void> _onRemoveMember(TenantMemberRemoved event, Emitter<TenantState> emit) async {
    try {
      await repo.removeMember(tenantId: event.tenantId, userId: event.userId);
      emit(TenantActionSuccess(ErrorKeys.memberRemoved));
      add(TenantDetailRequested(event.tenantId));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToRemoveMember));
    }
  }

  Future<void> _onAcceptInvite(TenantInviteAccepted event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      await repo.acceptInvite(event.token);
      final tenants = await repo.getMyTenants();
      emit(TenantsLoaded(tenants));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToAcceptInvite));
    }
  }

  Future<void> _onKybStart(TenantKybStartRequested event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final token = await repo.startKyb(event.tenantId);
      emit(TenantKybSdkReady(sdkToken: token, tenantId: event.tenantId));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError(ErrorKeys.failedToStartKyb));
    }
  }

  Future<void> _onKybComplete(TenantKybSdkCompleted event, Emitter<TenantState> emit) async {
    emit(TenantKybDone());
    add(TenantDetailRequested(event.tenantId));
  }
}
