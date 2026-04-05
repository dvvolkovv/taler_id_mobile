import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../api/auth_interceptor.dart';
import '../api/dio_client.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import '../storage/cache_service.dart';
import '../services/update_check_service.dart';
import '../services/call_history_cache_service.dart';
import '../services/contacts_cache_service.dart';
import '../services/message_draft_service.dart';
import '../services/messenger_cache_service.dart';
import '../services/pending_message_service.dart';
import '../services/simple_list_cache.dart';
import '../services/video_effects_service.dart';

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

// Chat
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/i_chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';

// Messenger
import '../../features/messenger/data/datasources/messenger_remote_datasource.dart';
import '../../features/messenger/data/repositories/messenger_repository_impl.dart';
import '../../features/messenger/domain/repositories/i_messenger_repository.dart';
import '../../features/messenger/presentation/bloc/messenger_bloc.dart';

// Profile Sections
import '../../features/profile_sections/data/datasources/profile_sections_remote_datasource.dart';
import '../../features/profile_sections/data/repositories/profile_sections_repository_impl.dart';
import '../../features/profile_sections/domain/repositories/i_profile_sections_repository.dart';


final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  final storage = SecureStorageService();
  sl.registerSingleton<SecureStorageService>(storage);

  // Cache
  await CacheService.init();
  sl.registerSingleton<CacheService>(CacheService());

  // Messenger cache (Hive)
  await MessengerCacheService.init();
  sl.registerSingleton<MessengerCacheService>(MessengerCacheService());

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

  // Dio (raw, for auth interceptor use)
  final rawDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final authInterceptor = AuthInterceptor(dio: rawDio, storage: storage);
  final dioClient = DioClient.create(authInterceptor: authInterceptor);
  sl.registerSingleton<DioClient>(dioClient);

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => KycRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => TenantRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton(() => SessionsRemoteDataSource(sl<DioClient>()));

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

  // Chat
  sl.registerLazySingleton(() => ChatRemoteDataSource());
  sl.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(
      remote: sl<ChatRemoteDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );

  // Messenger
  sl.registerLazySingleton(() => MessengerRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton<IMessengerRepository>(
    () => MessengerRepositoryImpl(sl<MessengerRemoteDataSource>()),
  );

  // Profile Sections
  sl.registerLazySingleton(() => ProfileSectionsRemoteDataSource(sl<DioClient>()));
  sl.registerLazySingleton<IProfileSectionsRepository>(
    () => ProfileSectionsRepositoryImpl(sl<ProfileSectionsRemoteDataSource>()),
  );

  // Update check
  sl.registerLazySingleton(() => UpdateCheckService());

  // Video effects (background blur / virtual backgrounds)
  sl.registerLazySingleton(() => VideoEffectsService());

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl<IAuthRepository>()));
  sl.registerFactory(() => ProfileBloc(repo: sl<IProfileRepository>()));
  sl.registerFactory(() => KycBloc(repo: sl<IKycRepository>()));
  sl.registerFactory(() => TenantBloc(repo: sl<ITenantRepository>()));
  sl.registerFactory(() => SessionsBloc(repo: sl<ISessionRepository>()));
  sl.registerFactory(() => ChatBloc(repo: sl<IChatRepository>()));
  sl.registerLazySingleton(() => MessengerBloc(repo: sl<IMessengerRepository>()));
}
