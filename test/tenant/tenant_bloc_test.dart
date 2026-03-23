import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/tenant/domain/entities/tenant_entity.dart';
import 'package:taler_id_mobile/features/tenant/domain/repositories/i_tenant_repository.dart';
import 'package:taler_id_mobile/features/tenant/presentation/bloc/tenant_bloc.dart';
import 'package:taler_id_mobile/features/tenant/presentation/bloc/tenant_event.dart';
import 'package:taler_id_mobile/features/tenant/presentation/bloc/tenant_state.dart';

class MockTenantRepository extends Mock implements ITenantRepository {}

const _tenant1 = TenantEntity(
  id: 'tenant-1',
  name: 'Taler GmbH',
  myRole: TenantRole.owner,
  kybStatus: KybStatus.verified,
);

const _tenant2 = TenantEntity(
  id: 'tenant-2',
  name: 'Partner AG',
  myRole: TenantRole.viewer,
);

void main() {
  late MockTenantRepository repo;
  late TenantBloc bloc;

  setUpAll(() {
    registerFallbackValue(TenantRole.viewer);
  });

  setUp(() {
    repo = MockTenantRepository();
    bloc = TenantBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  // ── Load tenants ──────────────────────────────────────────────────────────

  group('TenantsLoadRequested', () {
    blocTest<TenantBloc, TenantState>(
      'emits [Loading, TenantsLoaded] with list',
      build: () {
        when(() => repo.getMyTenants()).thenAnswer((_) async => [_tenant1, _tenant2]);
        return bloc;
      },
      act: (b) => b.add(TenantsLoadRequested()),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantsLoaded>()
            .having((s) => s.tenants.length, 'count', 2)
            .having((s) => s.tenants.first.name, 'first name', 'Taler GmbH'),
      ],
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Loading, TenantsLoaded] with empty list when no tenants',
      build: () {
        when(() => repo.getMyTenants()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(TenantsLoadRequested()),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantsLoaded>().having((s) => s.tenants, 'tenants', isEmpty),
      ],
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => repo.getMyTenants()).thenThrow(Exception('network error'));
        return bloc;
      },
      act: (b) => b.add(TenantsLoadRequested()),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantError>().having(
            (s) => s.message, 'message', 'Не удалось загрузить список организаций'),
      ],
    );
  });

  // ── Tenant detail ─────────────────────────────────────────────────────────

  group('TenantDetailRequested', () {
    blocTest<TenantBloc, TenantState>(
      'emits [Loading, DetailLoaded] with tenant data',
      build: () {
        when(() => repo.getTenant('tenant-1')).thenAnswer((_) async => _tenant1);
        return bloc;
      },
      act: (b) => b.add(TenantDetailRequested('tenant-1')),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantDetailLoaded>()
            .having((s) => s.tenant.id, 'id', 'tenant-1')
            .having((s) => s.tenant.myRole, 'role', TenantRole.owner)
            .having((s) => s.tenant.kybStatus, 'kybStatus', KybStatus.verified),
      ],
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Loading, Error] when tenant not found',
      build: () {
        when(() => repo.getTenant('bad-id'))
            .thenThrow(const ApiException(statusCode: 404, message: 'Not found'));
        return bloc;
      },
      act: (b) => b.add(TenantDetailRequested('bad-id')),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantError>().having((s) => s.message, 'message', 'Not found'),
      ],
    );
  });

  // ── Create tenant ─────────────────────────────────────────────────────────

  group('TenantCreateSubmitted', () {
    const createData = {'name': 'New Corp', 'description': 'Test company'};

    blocTest<TenantBloc, TenantState>(
      'emits [Loading, TenantsLoaded] with new tenant after create',
      build: () {
        when(() => repo.createTenant(createData)).thenAnswer((_) async {});
        when(() => repo.getMyTenants())
            .thenAnswer((_) async => [_tenant1, const TenantEntity(id: 'tenant-3', name: 'New Corp')]);
        return bloc;
      },
      act: (b) => b.add(TenantCreateSubmitted(createData)),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantsLoaded>().having((s) => s.tenants.length, 'count', 2),
      ],
      verify: (_) {
        verify(() => repo.createTenant(createData)).called(1);
        verify(() => repo.getMyTenants()).called(1);
      },
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Loading, Error] when create fails',
      build: () {
        when(() => repo.createTenant(any()))
            .thenThrow(const ApiException(statusCode: 422, message: 'Name too short'));
        return bloc;
      },
      act: (b) => b.add(TenantCreateSubmitted({'name': 'X'})),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantError>().having((s) => s.message, 'message', 'Name too short'),
      ],
    );
  });

  // ── Invite member ─────────────────────────────────────────────────────────

  group('TenantMemberInvited', () {
    blocTest<TenantBloc, TenantState>(
      'emits [ActionSuccess] and reloads detail on success',
      build: () {
        when(() => repo.inviteMember(
              tenantId: 'tenant-1',
              email: 'new@test.com',
              role: TenantRole.admin,
            )).thenAnswer((_) async {});
        when(() => repo.getTenant('tenant-1')).thenAnswer((_) async => _tenant1);
        return bloc;
      },
      act: (b) => b.add(TenantMemberInvited(
        tenantId: 'tenant-1',
        email: 'new@test.com',
        role: TenantRole.admin,
      )),
      expect: () => [
        isA<TenantActionSuccess>().having(
            (s) => s.message, 'message', contains('new@test.com')),
        isA<TenantLoading>(),
        isA<TenantDetailLoaded>(),
      ],
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Error] when email already member',
      build: () {
        when(() => repo.inviteMember(
              tenantId: any(named: 'tenantId'),
              email: any(named: 'email'),
              role: any(named: 'role'),
            )).thenThrow(const ApiException(statusCode: 409, message: 'Already a member'));
        return bloc;
      },
      act: (b) => b.add(TenantMemberInvited(
        tenantId: 'tenant-1',
        email: 'existing@test.com',
        role: TenantRole.viewer,
      )),
      expect: () => [
        isA<TenantError>().having((s) => s.message, 'message', 'Already a member'),
      ],
    );
  });

  // ── Accept invite ─────────────────────────────────────────────────────────

  group('TenantInviteAccepted', () {
    blocTest<TenantBloc, TenantState>(
      'emits [Loading, TenantsLoaded] after accepting invite',
      build: () {
        when(() => repo.acceptInvite('invite-token-abc')).thenAnswer((_) async {});
        when(() => repo.getMyTenants()).thenAnswer((_) async => [_tenant1, _tenant2]);
        return bloc;
      },
      act: (b) => b.add(TenantInviteAccepted('invite-token-abc')),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantsLoaded>().having((s) => s.tenants.length, 'count', 2),
      ],
      verify: (_) => verify(() => repo.acceptInvite('invite-token-abc')).called(1),
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Loading, Error] on expired or invalid invite token',
      build: () {
        when(() => repo.acceptInvite(any()))
            .thenThrow(const ApiException(statusCode: 410, message: 'Invite expired'));
        return bloc;
      },
      act: (b) => b.add(TenantInviteAccepted('expired-token')),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantError>().having((s) => s.message, 'message', 'Invite expired'),
      ],
    );
  });

  // ── Role change ───────────────────────────────────────────────────────────

  group('TenantMemberRoleChanged', () {
    blocTest<TenantBloc, TenantState>(
      'emits [ActionSuccess] and reloads detail',
      build: () {
        when(() => repo.updateMember(
              tenantId: 'tenant-1',
              memberId: 'member-1',
              role: TenantRole.admin,
            )).thenAnswer((_) async {});
        when(() => repo.getTenant('tenant-1')).thenAnswer((_) async => _tenant1);
        return bloc;
      },
      act: (b) => b.add(TenantMemberRoleChanged(
        tenantId: 'tenant-1',
        memberId: 'member-1',
        role: TenantRole.admin,
      )),
      expect: () => [
        isA<TenantActionSuccess>().having((s) => s.message, 'message', 'Роль изменена'),
        isA<TenantLoading>(),
        isA<TenantDetailLoaded>(),
      ],
    );
  });

  // ── Remove member ─────────────────────────────────────────────────────────

  group('TenantMemberRemoved', () {
    blocTest<TenantBloc, TenantState>(
      'emits [ActionSuccess] and reloads detail on success',
      build: () {
        when(() => repo.removeMember(tenantId: 'tenant-1', userId: 'user-5'))
            .thenAnswer((_) async {});
        when(() => repo.getTenant('tenant-1')).thenAnswer((_) async => _tenant1);
        return bloc;
      },
      act: (b) => b.add(TenantMemberRemoved(tenantId: 'tenant-1', userId: 'user-5')),
      expect: () => [
        isA<TenantActionSuccess>(),
        isA<TenantLoading>(),
        isA<TenantDetailLoaded>(),
      ],
    );

    blocTest<TenantBloc, TenantState>(
      'emits [Error] when trying to remove owner',
      build: () {
        when(() => repo.removeMember(tenantId: any(named: 'tenantId'), userId: any(named: 'userId')))
            .thenThrow(const ApiException(statusCode: 403, message: 'Cannot remove owner'));
        return bloc;
      },
      act: (b) => b.add(TenantMemberRemoved(tenantId: 'tenant-1', userId: 'owner-id')),
      expect: () => [
        isA<TenantError>().having((s) => s.message, 'message', 'Cannot remove owner'),
      ],
    );
  });

  // ── KYB ───────────────────────────────────────────────────────────────────

  group('TenantKybStartRequested', () {
    blocTest<TenantBloc, TenantState>(
      'emits [Loading, KybSdkReady] with SDK token',
      build: () {
        when(() => repo.startKyb('tenant-1')).thenAnswer((_) async => 'kyb-sdk-token');
        return bloc;
      },
      act: (b) => b.add(TenantKybStartRequested('tenant-1')),
      expect: () => [
        isA<TenantLoading>(),
        isA<TenantKybSdkReady>()
            .having((s) => s.sdkToken, 'sdkToken', 'kyb-sdk-token')
            .having((s) => s.tenantId, 'tenantId', 'tenant-1'),
      ],
    );
  });

  group('TenantKybSdkCompleted', () {
    blocTest<TenantBloc, TenantState>(
      'emits [KybDone] then reloads tenant detail',
      build: () {
        when(() => repo.getTenant('tenant-1')).thenAnswer((_) async => _tenant1);
        return bloc;
      },
      act: (b) => b.add(TenantKybSdkCompleted('tenant-1')),
      expect: () => [
        isA<TenantKybDone>(),
        isA<TenantLoading>(),
        isA<TenantDetailLoaded>(),
      ],
    );
  });
}
