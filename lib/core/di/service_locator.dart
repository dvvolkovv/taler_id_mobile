import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';
import '../agent/agent_client.dart';
import '../../features/notifications/notification_permission_service.dart';
import '../../features/notifications/notification_platform.dart';
import '../../features/notifications/notification_store.dart';
import '../api/auth_interceptor.dart';
import '../api/dio_client.dart';
import '../api/endpoint_service.dart';
import '../audio/default_mesh_voice_audio_engine.dart';
import '../config/app_config.dart';
import '../mesh/voice/mesh_voice_service.dart';
import '../platform/secure_storage.dart';
import '../platform/platform_utils.dart';
import '../platform/mesh_transport_desktop_stub.dart';
import '../storage/secure_storage_service.dart';
import '../storage/cache_service.dart';
import '../services/update_check_service.dart';
import '../services/call_history_cache_service.dart';
import '../services/contacts_cache_service.dart';
import '../services/message_draft_service.dart';
import '../services/messenger_cache_service.dart';
import '../storage/sync_cursor_storage.dart';
import '../storage/saved_conversation_id_cache.dart';
import '../services/pending_message_service.dart';
import '../services/simple_list_cache.dart';
import '../services/video_effects_service.dart';
import '../services/wake_word_service.dart';
import '../voice/mesh_foreground_controller.dart';
import '../voice/mesh_peer_eligibility_watcher.dart';
import '../voice/mesh_prefs_service.dart';
import '../voice/mesh_voice_ui_coordinator.dart';
import '../../features/call_history/data/mesh_call_history_repository.dart';
import '../../features/messenger/services/hive_favorites_migration_service.dart';
import '../../main.dart' show globalNavigatorKey;

// Mesh Phase 1b/1c
import '../config/mesh_config.dart';
import '../mesh/crypto/keys/contact_key_store_hive.dart';
import '../mesh/crypto/keys/device_key.dart';
import '../mesh/crypto/keys/mesh_key_persistence.dart';
import '../mesh/crypto/keys/mesh_static_key.dart';
import '../mesh/crypto/keys/user_identity_key.dart';
import '../mesh/services/device_key_sync_service.dart';
import '../mesh/services/device_keys_api_client.dart';
// Mesh Phase 1d — transport composition
import '../mesh/transport/ble_transport.dart';
import '../mesh/transport/bonjour_transport.dart';
import '../mesh/transport/mesh_transport.dart';
import '../mesh/transport/multi_transport.dart';
import '../mesh/transport/transport_preference.dart';
// Mesh Phase 1e — messaging service + messenger wiring
import '../mesh/crypto/keys/contact_key_store.dart';
import '../mesh/mesh_bootstrap.dart';
import '../mesh/services/mesh_messaging_service.dart';
import '../mesh/transport/peer_id.dart';
import '../../features/mesh/presentation/bloc/mesh_status_bloc.dart';
import '../../features/messenger/data/services/mesh_messenger_adapter.dart';
import '../../features/messenger/data/services/pending_mesh_send_queue.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Profile
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/i_profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// KYC
import '../../features/kyc/data/datasources/kyc_remote_datasource.dart';
import '../../features/kyc/data/repositories/kyc_repository_impl.dart';
import '../../features/kyc/domain/repositories/i_kyc_repository.dart';
import '../../features/kyc/presentation/bloc/kyc_bloc.dart';

// Voice Enrollment (voice-gate owner)
import '../../features/voice_enrollment/data/datasources/voice_enrollment_remote.dart';
import '../../features/voice_enrollment/data/repositories/voice_enrollment_repository_impl.dart';
import '../../features/voice_enrollment/domain/repositories/voice_enrollment_repository.dart';
import '../../features/voice_enrollment/presentation/bloc/voice_enrollment_bloc.dart';

// Tenant
import '../../features/tenant/data/datasources/tenant_remote_datasource.dart';
import '../../features/tenant/data/repositories/tenant_repository_impl.dart';
import '../../features/tenant/domain/repositories/i_tenant_repository.dart';
import '../../features/tenant/presentation/bloc/tenant_bloc.dart';

// Sessions
import '../../features/sessions/data/datasources/sessions_remote_datasource.dart';
import '../../features/sessions/data/repositories/sessions_repository_impl.dart';
import '../../features/sessions/domain/repositories/i_session_repository.dart';
import '../../features/sessions/presentation/bloc/sessions_bloc.dart';

// OAuth (native mobile login)
import '../../features/oauth/data/datasources/oauth_remote_datasource.dart';
import '../../features/oauth/data/oauth_pending_request.dart';
import '../../features/oauth/data/repositories/oauth_repository_impl.dart';
import '../../features/oauth/domain/repositories/oauth_repository.dart';
import '../../features/oauth/presentation/bloc/oauth_authorize_bloc.dart';

// Messenger
import '../../features/messenger/data/datasources/messenger_remote_datasource.dart';
import '../../features/messenger/data/repositories/messenger_repository_impl.dart';
import '../../features/messenger/domain/repositories/i_messenger_repository.dart';
import '../../features/messenger/presentation/bloc/messenger_bloc.dart';

// Profile Sections
import '../../features/profile_sections/data/datasources/profile_sections_remote_datasource.dart';
import '../../features/profile_sections/data/repositories/profile_sections_repository_impl.dart';
import '../../features/profile_sections/domain/repositories/i_profile_sections_repository.dart';

// Group Call (Phase 1) — voice multi-party rooms
import '../../features/voice/data/datasources/group_call_remote_datasource.dart';
import '../../features/voice/data/repositories/group_call_repository_impl.dart';
import '../../features/voice/domain/repositories/group_call_repository.dart';
import '../../features/voice/presentation/bloc/group_call_bloc.dart';

// Group Mesh Voice (Phase: group mesh voice room v1)
import '../audio/default_group_mesh_voice_audio_engine.dart';
import '../mesh/voice/group_mesh_call_service.dart';
import '../../features/voice/presentation/bloc/group_mesh_call_bloc.dart';

// Notes offline
import '../storage/outbox_queue.dart';
import '../services/outbox_replay_service.dart';
import '../services/connectivity_watcher.dart';
import '../../features/notes/data/datasources/notes_local_datasource.dart';
import '../../features/notes/data/datasources/notes_remote_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/data/services/notes_outbox_replay_handler.dart';
import '../../features/notes/domain/repositories/i_notes_repository.dart';
import '../../features/calendar/data/datasources/calendar_local_datasource.dart';
import '../../features/calendar/data/datasources/calendar_remote_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/data/services/calendar_outbox_replay_handler.dart';
import '../../features/calendar/domain/repositories/i_calendar_repository.dart';
import '../../features/contacts/data/datasources/contacts_local_datasource.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/data/services/contacts_outbox_replay_handler.dart';
import '../../features/contacts/domain/repositories/i_contacts_repository.dart';

// Billing
import '../../features/billing/data/datasources/billing_remote_datasource.dart';
import '../../features/billing/data/repositories/billing_repository_impl.dart';
import '../../features/billing/data/services/billing_event_bus.dart';
import '../../features/billing/data/services/billing_socket_listener.dart';
import '../../features/billing/data/services/voice_billing_bridge.dart';
import '../../features/billing/domain/repositories/billing_repository.dart';
import '../../features/billing/presentation/bloc/balance_bloc.dart';
import '../../features/billing/presentation/bloc/balance_event.dart';
import '../../features/billing/presentation/bloc/packages_bloc.dart';
import '../../features/billing/presentation/bloc/toggles_bloc.dart';
import '../../features/billing/presentation/bloc/transactions_bloc.dart';

// Assistant Chat
import '../../features/assistant/data/assistant_chat_api.dart';

// Presence (online/last-seen)
import '../../features/presence/data/datasources/presence_remote_datasource.dart';
import '../../features/presence/data/repositories/presence_repository_impl.dart';
import '../../features/presence/domain/repositories/i_presence_repository.dart';
import '../../features/presence/presentation/services/presence_heartbeat_service.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  final storage = SecureStorageService();
  sl.registerSingleton<SecureStorageService>(storage);

  // Cache
  await CacheService.init();
  sl.registerSingleton<CacheService>(CacheService());

  // Wake word settings (Hive)
  await WakeWordService.initBox();

  // Messenger cache (Hive)
  await MessengerCacheService.init();
  sl.registerSingleton<MessengerCacheService>(MessengerCacheService());

  // Sync cursor storage (Hive) — persists the last /messenger/sync cursor
  await Hive.openBox<String>(SyncCursorStorage.boxName);
  sl.registerLazySingleton<SyncCursorStorage>(() => SyncCursorStorage());

  // Notes offline: outbox queue + local note store (Hive)
  await Hive.openBox<String>(OutboxQueue.boxName);
  await Hive.openBox<String>(NotesLocalDataSource.boxName);
  await Hive.openBox<String>(NotesLocalDataSource.tombstoneBoxName);
  await Hive.openBox<String>(CalendarLocalDataSource.boxName);
  await Hive.openBox<String>(ContactsLocalDataSource.boxName);

  // Favorites offline: cached SAVED-conversation id (Hive)
  await Hive.openBox<String>(SavedConversationIdCache.boxName);
  sl.registerLazySingleton<SavedConversationIdCache>(
    () => SavedConversationIdCache(),
  );

  // Mesh call history (Hive) — local-only journal of mesh voice calls
  final meshCallHistory = HiveMeshCallHistoryRepository();
  await meshCallHistory.init();
  sl.registerSingleton<MeshCallHistoryRepository>(meshCallHistory);

  // Mesh prefs (Hive) — small flag store for mesh-related UI state
  final meshPrefs = MeshPrefsService();
  await meshPrefs.init();
  sl.registerSingleton<MeshPrefsService>(meshPrefs);

  // Message drafts (Hive) — persisted unsent text per conversation
  final drafts = MessageDraftService();
  await drafts.init();
  sl.registerSingleton<MessageDraftService>(drafts);

  // Pending message queue (Hive) — messages sent offline
  final pending = PendingMessageService();
  await pending.init();
  sl.registerSingleton<PendingMessageService>(pending);

  // Call history cache (Hive) — stale-while-revalidate for Calls screen
  final callCache = CallHistoryCacheService();
  await callCache.init();
  sl.registerSingleton<CallHistoryCacheService>(callCache);

  // Contacts cache (Hive) — stale-while-revalidate for Contacts screen
  final contactsCache = ContactsCacheService();
  await contactsCache.init();
  sl.registerSingleton<ContactsCacheService>(contactsCache);

  // Notes cache (Hive)
  final notesCache = SimpleListCache('notes_cache');
  await notesCache.init();
  sl.registerSingleton<SimpleListCache>(notesCache, instanceName: 'notes');

  // Calendar cache (Hive)
  final calendarCache = SimpleListCache('calendar_cache');
  await calendarCache.init();
  sl.registerSingleton<SimpleListCache>(calendarCache, instanceName: 'calendar');

  // Endpoint resolver (CIS failover). Loads the last-known-good base URL so a
  // blocked client starts on the RU edge it already discovered. Must run after
  // Hive init (CacheService.init above) since it persists to a Hive box.
  final endpoint = EndpointService();
  await endpoint.init();
  sl.registerSingleton<EndpointService>(endpoint);

  // Dio (raw, for auth interceptor use). baseUrl tracks the resolved endpoint so
  // token refresh follows the same failover as the main client.
  final rawDio = Dio(
    BaseOptions(
      baseUrl: endpoint.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  endpoint.activeUrl.addListener(() => rawDio.options.baseUrl = endpoint.baseUrl);

  final authInterceptor = AuthInterceptor(dio: rawDio, storage: storage);
  final dioClient = DioClient.create(
    authInterceptor: authInterceptor,
    endpoint: endpoint,
  );
  sl.registerSingleton<DioClient>(dioClient);

  // === Agent Shell (Phase 0) ===
  sl.registerLazySingleton<AgentClient>(
    () => AgentClient(sl<DioClient>().dio),
  );

  // === Agent Shell (Phase 1A) — on-device notification listener ===
  sl.registerLazySingleton<NotificationPlatform>(
    () => MethodChannelNotificationPlatform(),
  );
  sl.registerLazySingleton<NotificationStore>(
    () => NotificationStore(sl<NotificationPlatform>()),
  );
  sl.registerLazySingleton<NotificationPermissionService>(
    () => NotificationPermissionService(sl<NotificationPlatform>()),
  );

  // ---------------------------------------------------------------------------
  // Mesh Phase 1c — persistent identity + rotating device keys
  // ---------------------------------------------------------------------------
  //
  // Mobile only: mesh networking (Bonjour/BLE peer discovery + Noise handshake
  // encrypted channels) is not supported on desktop. On desktop we register a
  // no-op stub transport so the rest of the codebase compiles without
  // changes, and skip all mesh services so no advertising/discovery ever
  // starts. MeshMessagingService / MeshStatusBloc / MeshMessengerAdapter are
  // still registered (they work fine with empty stub streams) because the
  // messenger repository depends on them. The stub transport guarantees they
  // will never receive peers or route frames.
  if (PlatformUtils.instance.isMobile) {
    // UserIdentityKey is permanent per device (SecureStorage). DeviceKey
    // and MeshStaticKey are rotated every 30 days — the rotation check runs at
    // startup and triggers a fresh POST /profile/device-keys if any key was
    // regenerated. Phase 1e will wire _placeholderUserId() to the real JWT user
    // id; until then registerOwnDevice() is still dormant.
    final userIdentityKey = await UserIdentityKey.loadOrCreate(
      SecureStorage.instance,
    );
    sl.registerSingleton<UserIdentityKey>(userIdentityKey);

    final meshKeyPersistence = await MeshKeyPersistence.open(
      boxName: 'mesh_keys',
    );
    sl.registerSingleton<MeshKeyPersistence>(meshKeyPersistence);

    final (deviceKey, deviceKeyRotated) =
        await meshKeyPersistence.loadOrRotateDeviceKey();
    sl.registerSingleton<DeviceKey>(deviceKey);

    final (meshStaticKey, meshStaticRotated) =
        await meshKeyPersistence.loadOrRotateMeshStaticKey();
    sl.registerSingleton<MeshStaticKey>(meshStaticKey);

    // Hive-backed contact key store. Box name is stable across restarts.
    final contactKeyStore = await HiveContactKeyStore.open(
      boxName: 'mesh_contacts',
    );
    sl.registerSingleton<HiveContactKeyStore>(contactKeyStore);

    // Phase 1a in-memory ContactKeyStore — registered here (before
    // DeviceKeySyncService) so the lazy singleton is available when
    // DeviceKeySyncService is first instantiated (which may happen at
    // startup if keys were rotated, triggering registerOwnDevice).
    sl.registerLazySingleton<ContactKeyStore>(() => ContactKeyStore());

    // Phase 1g — populate the in-memory store from persistent Hive certs.
    // Without this, Noise IK handshakes would fail on startup until the user
    // opens a chat AND the backend fetchContactKeys call succeeds. After
    // the bridge, mesh works immediately for any contact whose cert was
    // previously synced.
    try {
      contactKeyStore.bridgeIntoInMemory(sl<ContactKeyStore>());
    } catch (e) {
      debugPrint('[mesh-di] bridgeIntoInMemory failed: $e');
    }

    sl.registerLazySingleton<DeviceKeysApiClient>(
      () => DeviceKeysApiClient(sl<DioClient>().dio),
    );

    sl.registerLazySingleton<DeviceKeySyncService>(
      () => DeviceKeySyncService(
        api: sl<DeviceKeysApiClient>(),
        store: sl<HiveContactKeyStore>(),
        inMemoryStore: sl<ContactKeyStore>(),
        userIdentityKey: sl<UserIdentityKey>(),
        meshStaticKey: sl<MeshStaticKey>(),
        myUserId: _placeholderUserId(),
      ),
    );

    // If any rotating key was regenerated, push a fresh cert. Best-effort: a
    // failure here must not block app startup. Wait for Phase 1e to wire the
    // real userId before this does anything useful — until then the POST goes
    // to the DEV server under the placeholder userId (dormant).
    if (deviceKeyRotated || meshStaticRotated) {
      // ignore: unawaited_futures
      sl<DeviceKeySyncService>().registerOwnDevice().catchError((e, st) {
        debugPrint('[mesh] registerOwnDevice failed: $e');
      });
    }

    // -------------------------------------------------------------------------
    // Mesh Phase 1d — transport composition (mobile only)
    // -------------------------------------------------------------------------
    //
    // Bonjour is always present (Phase 1a). BLE is added when the compile-time
    // flag MeshConfig.bleEnabled is true. MultiTransport picks the best path
    // per peer — Bonjour preferred for bandwidth, BLE fallback for offline.
    final bonjourTransport = BonjourTransport();
    // Register the concrete BonjourTransport separately so debug/diagnostic
    // tooling (Mesh Debug screen) can reach `discoveryReinitCount`. This is
    // the SAME instance that lives inside MultiTransport — registering it
    // twice via different types is fine for get_it.
    sl.registerSingleton<BonjourTransport>(bonjourTransport);

    final transports = <TransportId, MeshTransport>{
      TransportId.bonjour: bonjourTransport,
    };
    if (MeshConfig.bleEnabled) {
      transports[TransportId.ble] = BleTransport();
    }
    sl.registerSingleton<MeshTransport>(
      MultiTransport(children: transports),
    );

    // -------------------------------------------------------------------------
    // Mesh Phase 1e — messaging + voice services (mobile only)
    // -------------------------------------------------------------------------
    //
    // MeshMessagingService uses the Phase 1a in-memory ContactKeyStore
    // (registered above, before DeviceKeySyncService). Phase 1f bridges
    // verified certs from Hive into this store via DeviceKeySyncService.
    sl.registerLazySingleton<MeshMessagingService>(
      () => MeshMessagingService(
        transport: sl<MeshTransport>(),
        contactKeyStore: sl<ContactKeyStore>(),
        myDevicePrivateKey: sl<MeshStaticKey>().privateKeyBytes,
        myDevicePublicKey: sl<MeshStaticKey>().publicKey,
      ),
    );

    // MeshVoiceService — Phase 3c orchestrator. start() is called by
    // runMeshBootstrap after MeshMessagingService.start() succeeds.
    sl.registerLazySingleton<MeshVoiceService>(() {
      final messaging = sl<MeshMessagingService>();
      return MeshVoiceService(
        messaging: messaging,
        transport: sl<MeshTransport>(),
        audioEngineFactory: defaultMeshVoiceAudioEngine,
        // Lazy callback: evaluated at invite-arrival time, safe because
        // GroupMeshCallService is a lazy singleton registered below.
        isGroupCallBusy: () => sl<GroupMeshCallService>().isBusy,
      );
    });

    // GroupMeshCallService — Phase: group mesh voice room v1. Multi-peer
    // orchestrator (host + ≤4 invitees). One active call at a time.
    sl.registerLazySingleton<GroupMeshCallService>(() {
      return GroupMeshCallService(
        messaging: sl<MeshMessagingService>(),
        transport: sl<MeshTransport>(),
        myDevicePk: sl<MeshStaticKey>().publicKey,
        audioEngineFactory: defaultGroupMeshVoiceAudioEngine,
      );
    });

    // MeshVoiceUiCoordinator — singleton bridging MeshVoiceService state
    // transitions to UI (modal sheet, active-call screen, history writes).
    sl.registerLazySingleton<MeshVoiceUiCoordinator>(() {
      final voice = sl<MeshVoiceService>();
      final messaging = sl<MeshMessagingService>();
      final keyStore = sl<HiveContactKeyStore>();
      return MeshVoiceUiCoordinator(
        stateStream: voice.stateStream,
        invite: voice.invite,
        accept: voice.accept,
        reject: voice.reject,
        hangup: () => voice.hangup(),
        repo: sl<MeshCallHistoryRepository>(),
        navigator: _GlobalKeyMeshNavigator(),
        peerInfoLookup: (peer) async => _resolvePeerInfo(
          devicePk: peer,
          keyStore: keyStore,
        ),
        selfDevicePk: PeerId(messaging.myDevicePublicKey),
        transportLabelForPeer: (peer) {
          // Phase 3d.2 will surface this from MeshTransport.peerStatus +
          // discovery attributes. Phase 3d.1 returns null (badge says
          // just "📡 Mesh"). This is intentional — see spec Risks #4.
          return null;
        },
      );
    });

    sl.registerLazySingleton<MeshPeerEligibilityWatcher>(
      () => MeshPeerEligibilityWatcher(
        transport: sl<MeshTransport>(),
        contactKeyStore: sl<HiveContactKeyStore>(),
      ),
    );

    sl.registerLazySingleton<MeshForegroundController>(
      () => MeshForegroundController(
        watcher: sl<MeshPeerEligibilityWatcher>(),
      ),
    );

    // Phase 1e — mesh status cubit + messenger adapter + transport selector
    sl.registerLazySingleton<MeshStatusBloc>(
      () {
        final bloc = MeshStatusBloc(
          transport: sl<MeshTransport>(),
          lookupUserByDevice: (devicePk) =>
              sl<HiveContactKeyStore>().lookupUserByDevice(devicePk),
          contactUserIdForUserPk: _contactUserIdByUserPk,
        );
        bloc.start();
        return bloc;
      },
    );

    sl.registerLazySingleton<MeshMessengerAdapter>(() {
      final messaging = sl<MeshMessagingService>();
      return MeshMessengerAdapter(
        meshSendEnvelope: ({required toUserPk, required envelope}) =>
            messaging.sendEnvelope(toUserPk: toUserPk, envelope: envelope),
        meshInbound: messaging.inbound,
        meshDiscoveries: messaging.transport.discoveries,
        lookupUserByDevice: (devicePk) =>
            sl<HiveContactKeyStore>().lookupUserByDevice(devicePk),
        contactUserIdForUserPk: _contactUserIdByUserPk,
        currentUserIdProvider: () {
          try {
            return sl<MessengerBloc>().state.currentUserId;
          } catch (_) {
            return null;
          }
        },
        persistLocal: (entry) =>
            sl<MessengerCacheService>().appendMeshMessage(entry),
      );
    });
  } else {
    // -------------------------------------------------------------------------
    // Desktop: register no-op mesh stubs so dependent services compile/run.
    // -------------------------------------------------------------------------
    //
    // MeshTransportDesktopStub — empty streams, no-op methods. Never starts
    // any advertising or discovery. MeshMessagingService and MeshStatusBloc
    // are registered normally (they work fine with empty stub streams) because
    // IMessengerRepository is constructed with a MeshMessengerAdapter.
    // MeshVoiceService / GroupMeshCallService / MeshVoiceUiCoordinator /
    // MeshPeerEligibilityWatcher / MeshForegroundController are NOT registered
    // on desktop — callers in features guard with PlatformUtils.supportsMesh.
    sl.registerSingleton<MeshTransport>(const MeshTransportDesktopStub());

    // Stub HiveContactKeyStore: required by MessengerRepositoryImpl constructor
    // (hiveContactStore parameter). Open an empty box that never gets real certs.
    final contactKeyStore = await HiveContactKeyStore.open(
      boxName: 'mesh_contacts',
    );
    sl.registerSingleton<HiveContactKeyStore>(contactKeyStore);

    // Stub MeshMessagingService — uses stub transport (empty streams, no-ops).
    // Provide dummy key bytes so the constructor doesn't throw.
    sl.registerLazySingleton<MeshMessagingService>(
      () => MeshMessagingService(
        transport: sl<MeshTransport>(),
        contactKeyStore: ContactKeyStore(),
        myDevicePrivateKey: Uint8List(32),
        myDevicePublicKey: Uint8List(32),
      ),
    );

    // Stub MeshStatusBloc — subscribes to stub transport (no peers ever found).
    sl.registerLazySingleton<MeshStatusBloc>(
      () {
        final bloc = MeshStatusBloc(
          transport: sl<MeshTransport>(),
          lookupUserByDevice: (_) => null,
          contactUserIdForUserPk: (_) => null,
        );
        // Do not call bloc.start() — stub transport streams are const empty.
        return bloc;
      },
    );

    // Stub MeshMessengerAdapter — uses stub messaging service.
    sl.registerLazySingleton<MeshMessengerAdapter>(() {
      final messaging = sl<MeshMessagingService>();
      return MeshMessengerAdapter(
        meshSendEnvelope: ({required toUserPk, required envelope}) =>
            messaging.sendEnvelope(toUserPk: toUserPk, envelope: envelope),
        meshInbound: messaging.inbound,
        meshDiscoveries: messaging.transport.discoveries,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
        currentUserIdProvider: () {
          try {
            return sl<MessengerBloc>().state.currentUserId;
          } catch (_) {
            return null;
          }
        },
        persistLocal: (_) async {},
      );
    });
  }

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => KycRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => VoiceEnrollmentRemote(sl<DioClient>()));
  sl.registerLazySingleton(() => TenantRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => SessionsRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => OAuthRemoteDatasource(sl<DioClient>()));

  // Repositories
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(
      remote: sl<ProfileRemoteDataSource>(),
      cache: sl<CacheService>(),
    ),
  );
  sl.registerLazySingleton<IKycRepository>(
    () => KycRepositoryImpl(
      remote: sl<KycRemoteDataSource>(),
      cache: sl<CacheService>(),
    ),
  );
  sl.registerLazySingleton<VoiceEnrollmentRepository>(
    () => VoiceEnrollmentRepositoryImpl(sl<VoiceEnrollmentRemote>()),
  );
  sl.registerLazySingleton<ITenantRepository>(
    () => TenantRepositoryImpl(
      remote: sl<TenantRemoteDataSource>(),
      cache: sl<CacheService>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<ISessionRepository>(
    () => SessionsRepositoryImpl(sl<SessionsRemoteDataSource>()),
  );

  // OAuth (native mobile login)
  sl.registerLazySingleton<OAuthRepository>(
    () => OAuthRepositoryImpl(sl<OAuthRemoteDatasource>()),
  );
  sl.registerLazySingleton<OAuthPendingRequest>(
    () => OAuthPendingRequest(storage: SecureStorageOAuthPending()),
  );

  // Messenger
  sl.registerLazySingleton(
      () => MessengerRemoteDataSource(sl<DioClient>(), sl<EndpointService>()));
  sl.registerLazySingleton(() => PendingMeshSendQueue());
  sl.registerLazySingleton<IMessengerRepository>(
    () => MessengerRepositoryImpl(
      sl<MessengerRemoteDataSource>(),
      meshAdapter: sl<MeshMessengerAdapter>()..start(),
      pending: sl<PendingMessageService>(),
      cache: sl<MessengerCacheService>(),
      hiveContactStore: sl<HiveContactKeyStore>(),
      isPeerVisibleForContactUserId: (uid) {
        try {
          return sl<MeshStatusBloc>().state.visibilityByContactUserId[uid] ?? false;
        } catch (_) {
          return false;
        }
      },
      currentUserIdProvider: () {
        try {
          return sl<MessengerBloc>().state.currentUserId;
        } catch (_) {
          return null;
        }
      },
      pendingMeshQueue: sl<PendingMeshSendQueue>(),
    ),
  );
  sl.registerLazySingleton<HiveFavoritesMigrationService>(
    () => HiveFavoritesMigrationService(
      repo: sl<IMessengerRepository>(),
      storage: sl<SecureStorageService>(),
    ),
  );

  // Presence (online/last-seen) feature
  sl.registerLazySingleton<PresenceRemoteDataSource>(
    () => PresenceRemoteDataSource(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<IPresenceRepository>(
    () => PresenceRepositoryImpl(sl<PresenceRemoteDataSource>()),
  );
  sl.registerLazySingleton<PresenceHeartbeatService>(
    () => PresenceHeartbeatService(sl<IPresenceRepository>()),
  );

  // Profile Sections
  sl.registerLazySingleton(() => ProfileSectionsRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton<IProfileSectionsRepository>(
    () => ProfileSectionsRepositoryImpl(sl<ProfileSectionsRemoteDataSource>()),
  );

  // Group Call (Phase 1) — voice multi-party rooms.
  // BLoC is a factory: a fresh instance per screen so subscriptions don't
  // leak between calls. Repository + datasource are lazy singletons.
  sl.registerLazySingleton<GroupCallRemoteDatasource>(
    () => GroupCallRemoteDatasource(sl<DioClient>()),
  );
  sl.registerLazySingleton<GroupCallRepository>(
    () => GroupCallRepositoryImpl(sl<GroupCallRemoteDatasource>()),
  );
  // Singleton: GroupCallBloc state must persist across screen transitions
  // (picker → lobby → active). A factory registration would build a fresh
  // Idle-state BLoC for each `sl<GroupCallBloc>()` call, breaking the flow.
  sl.registerLazySingleton<GroupCallBloc>(
    () => GroupCallBloc(
      sl<GroupCallRepository>(),
      sl<MessengerRemoteDataSource>(),
    ),
  );

  // Singleton: GroupMeshCallBloc state must persist across screen transitions
  // (new-group-call picker → lobby → active). A factory would create a fresh
  // Idle-state BLoC for each sl<GroupMeshCallBloc>() call, breaking the flow.
  // Desktop: GroupMeshCallService is not registered, so skip this BLoC too.
  if (PlatformUtils.instance.isMobile) {
    sl.registerLazySingleton<GroupMeshCallBloc>(
      () => GroupMeshCallBloc(service: sl<GroupMeshCallService>()),
    );
  }

  // Billing
  sl.registerLazySingleton(() => BillingRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton<BillingRepository>(
    () => BillingRepositoryImpl(remote: sl<BillingRemoteDataSource>()),
  );
  // Real-time event hub (balance changed, session started/terminated, low balance).
  // Singleton: the messenger socket pushes into it; BLoCs and widgets listen.
  sl.registerLazySingleton<BillingEventBus>(() => BillingEventBus());
  sl.registerLazySingleton<BillingSocketListener>(
    () => BillingSocketListener(sl<BillingEventBus>()),
  );
  // Factory: a fresh bridge per voice/assistant session so each screen
  // owns its own heartbeat timer and terminated-event filter.
  sl.registerFactory<VoiceBillingBridge>(
    () => VoiceBillingBridge(
      dio: sl<DioClient>(),
      eventBus: sl<BillingEventBus>(),
    ),
  );

  // Outbox infrastructure
  sl.registerLazySingleton<OutboxQueue>(() => OutboxQueue());
  sl.registerLazySingleton<OutboxReplayService>(() => OutboxReplayService(queue: sl<OutboxQueue>()));
  sl.registerLazySingleton<ConnectivityWatcher>(() => ConnectivityWatcher(sl<OutboxReplayService>()));

  // Notes feature
  sl.registerLazySingleton<NotesLocalDataSource>(() => NotesLocalDataSource());
  sl.registerLazySingleton<NotesRemoteDataSource>(() => NotesRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton<INotesRepository>(() => NotesRepositoryImpl(
        local: sl<NotesLocalDataSource>(),
        remote: sl<NotesRemoteDataSource>(),
        outbox: sl<OutboxQueue>(),
      ));
  sl.registerLazySingleton<NotesOutboxReplayHandler>(() => NotesOutboxReplayHandler(
        remote: sl<NotesRemoteDataSource>(),
      ));

  // Calendar feature
  sl.registerLazySingleton<CalendarLocalDataSource>(() => CalendarLocalDataSource());
  if (!sl.isRegistered<CalendarRemoteDataSource>()) {
    sl.registerLazySingleton<CalendarRemoteDataSource>(() => CalendarRemoteDataSource(sl<DioClient>()));
  }
  sl.registerLazySingleton<ICalendarRepository>(() => CalendarRepositoryImpl(
        local: sl<CalendarLocalDataSource>(),
        remote: sl<CalendarRemoteDataSource>(),
        outbox: sl<OutboxQueue>(),
      ));
  sl.registerLazySingleton<CalendarOutboxReplayHandler>(() => CalendarOutboxReplayHandler(
        remote: sl<CalendarRemoteDataSource>(),
      ));

  // Contacts feature
  sl.registerLazySingleton<ContactsLocalDataSource>(() => ContactsLocalDataSource());
  sl.registerLazySingleton<IContactsRepository>(() => ContactsRepositoryImpl(
        local: sl<ContactsLocalDataSource>(),
        remote: sl<MessengerRemoteDataSource>(),
        outbox: sl<OutboxQueue>(),
        replay: sl<OutboxReplayService>(),
      ));
  sl.registerLazySingleton<ContactsOutboxReplayHandler>(() => ContactsOutboxReplayHandler(
        remote: sl<MessengerRemoteDataSource>(),
      ));

  // Update check
  sl.registerLazySingleton(() => UpdateCheckService());

  // Video effects (background blur / virtual backgrounds)
  sl.registerLazySingleton(() => VideoEffectsService());

  // Assistant Chat API
  sl.registerLazySingleton(() => AssistantChatApi(sl<DioClient>()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl<IAuthRepository>()));
  sl.registerFactory(() => ProfileBloc(repo: sl<IProfileRepository>()));
  sl.registerFactory(() => KycBloc(repo: sl<IKycRepository>()));
  sl.registerFactory(() => VoiceEnrollmentBloc(repo: sl<VoiceEnrollmentRepository>()));
  sl.registerFactory(() => TenantBloc(repo: sl<ITenantRepository>()));
  sl.registerFactory(() => SessionsBloc(repo: sl<ISessionRepository>()));
  sl.registerFactory(() => OAuthAuthorizeBloc(sl<OAuthRepository>()));
  sl.registerLazySingleton(() => MessengerBloc(repo: sl<IMessengerRepository>()));

  // Billing BLoCs (factory: new instance per screen).
  sl.registerFactory(() => BalanceBloc(
        repo: sl<BillingRepository>(),
        eventBus: sl<BillingEventBus>(),
      ));
  sl.registerFactory(() => PackagesBloc(repo: sl<BillingRepository>()));
  sl.registerFactory(() => TogglesBloc(repo: sl<BillingRepository>()));
  sl.registerFactory(() => TransactionsBloc(repo: sl<BillingRepository>()));

  // Global BalanceBloc for the dashboard AppBar chip (Task 9) — persists
  // across screens and subscribes to BillingEventBus so the chip always
  // reflects the current balance. Resolved via instanceName to coexist
  // with the per-screen factory above (used by wallet/purchase screens).
  sl.registerLazySingleton<BalanceBloc>(
    () => BalanceBloc(
      repo: sl<BillingRepository>(),
      eventBus: sl<BillingEventBus>(),
    )..add(LoadBalance()),
    instanceName: 'globalBalance',
  );

  // Boot outbox: reset any inflight ops, register handlers, start connectivity watch
  await sl<OutboxQueue>().onBoot();
  sl<OutboxReplayService>().registerHandler(sl<NotesOutboxReplayHandler>());
  sl<OutboxReplayService>().registerHandler(sl<CalendarOutboxReplayHandler>());
  sl<OutboxReplayService>().registerHandler(sl<ContactsOutboxReplayHandler>());
  sl<ConnectivityWatcher>().start();
  // First drain on app boot (in case we were offline last session)
  // ignore: discarded_futures
  sl<OutboxReplayService>().drain();

  // Phase 1g — if the user is already authenticated from a prior session
  // (JWT cached in SecureStorage), run the mesh bootstrap immediately so
  // Bonjour advertising + contact-key bridge are active without waiting
  // for a fresh LoginSubmitted event. On a clean install this is a no-op.
  // Desktop: mesh bootstrap is skipped entirely (no Bonjour, no device keys).
  if (PlatformUtils.instance.isMobile) {
    // ignore: unawaited_futures
    runMeshBootstrapIfAuthenticated();
  }
}

/// Placeholder until Phase 1e wires login → DeviceKeySyncService.registerOwnDevice.
/// Real userId is pulled from the JWT / SessionManager in a later phase.
/// Using a fixed sentinel means DeviceKeySyncService is retrievable but any
/// actual registerOwnDevice() call would POST with this userId — safe since
/// the backend device-keys endpoints are not yet deployed (Phase 1b deferred
/// deploy is explicit per project decision).
String _placeholderUserId() => 'phase1b-placeholder-user';

// ---------------------------------------------------------------------------
// Phase 1e helpers — contact resolution for mesh transport routing
// ---------------------------------------------------------------------------

String? _contactUserIdByUserPk(PeerId userPk) {
  try {
    // HiveContactKeyStore stores userId → userPk mappings, so we scan for
    // the reverse match. Phase 1e expects contact counts under 100 typically.
    final hex = userPk.toHex();
    for (final entry in sl<HiveContactKeyStore>().allUserIdMappings()) {
      if (entry.$2.toHex() == hex) return entry.$1;
    }
    return null;
  } catch (_) {
    return null;
  }
}

class _GlobalKeyMeshNavigator implements MeshNavigator {
  @override
  Future<T?> pushScreen<T>(Widget screen) async {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return null;
    return Navigator.of(ctx).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Future<void> showSheet(Widget sheet) async {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    // Sheet is itself an AlertDialog (see MeshIncomingCallSheet). showDialog
    // wraps it in a route that handles barrier + back-button dismissal.
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => sheet,
    );
  }

  @override
  void popSheet() {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    final nav = Navigator.of(ctx);
    if (nav.canPop()) nav.pop();
  }

  @override
  void popScreen() {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    final nav = Navigator.of(ctx);
    if (nav.canPop()) nav.pop();
  }

  @override
  void showSnackbar(String message) {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<MeshPeerInfo> _resolvePeerInfo({
  required PeerId devicePk,
  required HiveContactKeyStore keyStore,
}) async {
  // Phase 1a: userPk == devicePk. Resolve userId by scanning Hive
  // contactUserId mappings.
  String? userId;
  try {
    final hex = devicePk.toHex();
    for (final entry in keyStore.allUserIdMappings()) {
      if (entry.$2.toHex() == hex) {
        userId = entry.$1;
        break;
      }
    }
  } catch (_) {}
  if (userId == null) return const MeshPeerInfo();
  // Resolve name + avatar from MessengerBloc.state.conversations.
  String? name;
  String? avatar;
  try {
    final convs = sl<MessengerBloc>().state.conversations;
    for (final c in convs) {
      if (c.type == 'DIRECT' && c.otherUserId == userId) {
        name = c.otherUserName;
        avatar = c.otherUserAvatar;
        break;
      }
    }
  } catch (_) {}
  return MeshPeerInfo(userId: userId, name: name, avatarUrl: avatar);
}
