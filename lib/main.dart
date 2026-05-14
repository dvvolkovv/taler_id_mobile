import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'dart:async';
import 'core/api/dio_client.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/call_state_service.dart';
import 'core/services/share_intent_service.dart';
import 'firebase_options.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/messenger/services/hive_favorites_migration_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/wallpaper_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/kyc/presentation/bloc/kyc_bloc.dart';
import 'features/tenant/presentation/bloc/tenant_bloc.dart';
import 'features/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:taler_id_mobile/core/mesh/voice/group_mesh_call_service.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_bloc.dart';
import 'package:taler_id_mobile/features/voice/presentation/bloc/group_mesh_call_event.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

/// Global navigator key used by:
/// - GoRouter (as `navigatorKey`)
/// - [BillingPaywallInterceptor] to reach a valid [BuildContext] from outside
///   the widget tree when centrally surfacing the insufficient-funds paywall.
/// Keep this as the single source of truth — do not introduce parallel keys.
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

/// Set up CallKit event listener as early as possible (before runApp) so that
/// accept events are not missed when the app is launched from a killed state.
///
/// This is the ONLY place that subscribes to [FlutterCallkitIncoming.onEvent].
/// [FlutterCallkitIncoming.onEvent] calls [EventChannel.receiveBroadcastStream()]
/// each time it is accessed, which replaces the previous native handler —
/// so a second subscription from DashboardScreen would silently kill this one.
/// All other code uses [NotificationService.callEvents] (a broadcast StreamController
/// fed from here) to safely receive CallKit events.
void _setupCallkitListener() {
  if (kIsWeb) return;
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    debugPrint('[CallKit] event: ${event?.event}');
    // Forward to all other subscribers (DashboardScreen etc.)
    NotificationService.addCallEvent(event);

    // === Mesh group call branch ===
    final extraMaybe = event?.body['extra'] as Map?;
    final kind = extraMaybe?['kind'] as String?;
    if (kind == 'mesh_gc') {
      _handleMeshGroupCallEvent(event!, extraMaybe!);
      return;
    }

    // === Existing 1-on-1 and LiveKit-group branches ===
    if (event?.event != Event.actionCallAccept) return;
    final extra = event!.body['extra'] as Map?;
    final roomName = extra?['roomName'] as String?;
    final convId = extra?['conversationId'] as String?;
    final e2eeKey = extra?['e2eeKey'] as String?;
    final callerName = event.body['nameCaller'] as String? ?? '';
    final callerAvatar = extra?['callerAvatar'] as String? ?? '';
    if (roomName == null || roomName.isEmpty) return;
    // Group call invites use a `group-<groupCallId>` roomName (set by the
    // background handler in notification_service.dart). Route to the group
    // active screen — it falls back to the lobby via BLoC state when needed.
    if (roomName.startsWith('group-')) {
      final groupCallId = roomName.substring('group-'.length);
      if (groupCallId.isEmpty) return;
      final route = '/group-call/$groupCallId';
      debugPrint('[CallKit] accept (group): groupCallId=$groupCallId, setting pending route');
      NotificationService.setPendingCallRoute(route);
      _navigateWhenResumed(route, 0);
      return;
    }
    final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
    final calleeParam = callerName.isNotEmpty ? '&callee=${Uri.encodeComponent(callerName)}' : '';
    final avatarParam = callerAvatar.isNotEmpty ? '&calleeAvatar=${Uri.encodeComponent(callerAvatar)}' : '';
    final route =
        '/dashboard/voice?room=$roomName&convId=${convId ?? ''}&incoming=1$e2eeParam$calleeParam$avatarParam';
    debugPrint('[CallKit] accept: roomName=$roomName, e2ee=${e2eeKey != null}, setting pending route');
    // Store for DashboardScreen's cold-start initState path.
    NotificationService.setPendingCallRoute(route);
    // Connect to LiveKit immediately in background so the caller sees
    // the callee join the room right away (even while CallKit UI is showing).
    _connectCallInBackground(roomName, convId, e2eeKey: e2eeKey);
    // Poll until the app is fully resumed, then navigate via the global router.
    // This is the primary navigation mechanism for incoming calls.
    _navigateWhenResumed(route, 0);
  });
}

/// Handle CallKit accept/decline for mesh group call invites.
///
/// The [extra] map contains: kind='mesh_gc', roomId, hostDevicePkHex,
/// participantDevicePks (List of String).
void _handleMeshGroupCallEvent(CallEvent event, Map extra) {
  final roomId = extra['roomId'] as String?;
  final hostHex = extra['hostDevicePkHex'] as String?;
  final participantsRaw = extra['participantDevicePks'];
  final participants = participantsRaw is List
      ? participantsRaw.whereType<String>().toList()
      : null;
  if (roomId == null || hostHex == null || participants == null) return;

  try {
    final bloc = sl<GroupMeshCallBloc>();
    if (event.event == Event.actionCallAccept) {
      bloc.add(GMCAcceptInvite(
        roomId: roomId,
        hostDevicePkHex: hostHex,
        participantDevicePks: participants,
      ));
      // acceptInvite emits GMCActive directly (no lobby), so navigate to the
      // active route. Going to /lobby caused a race where the BlocConsumer's
      // listener never fired (state was already GMCActive at screen mount,
      // no new emission) — UI stuck on the lobby-spinner while audio engine
      // happily ran in the background.
      final route = '/group-call/$roomId';
      NotificationService.setPendingCallRoute(route);
      _navigateWhenResumed(route, 0);
    } else if (event.event == Event.actionCallDecline) {
      bloc.add(GMCDeclineInvite(roomId: roomId, hostDevicePkHex: hostHex));
    }
  } catch (e) {
    debugPrint('[mesh-gc] CallKit handler: bloc unavailable ($e)');
  }
}

/// Polls WidgetsBinding lifecycle every 300 ms (up to 30 s) until the app is
/// fully resumed, then pushes the voice route via the global [appRouter].
/// DashboardScreen may also navigate via [didChangeAppLifecycleState]; the
/// [NotificationService.consumePendingCallRoute] call acts as a one-shot latch
/// so only the first navigator wins.
///
/// On Android emulators the lifecycle sometimes oscillates `paused ↔ inactive`
/// after CallKit's UI overlays the app and never reaches `resumed`. To avoid
/// the user being stranded, after 30 attempts (10 s) we fall through and push
/// the route anyway — worst case the navigator queues it for the next frame.
void _navigateWhenResumed(String route, int attempt) {
  if (attempt > 100) {
    debugPrint('[CallKit] _navigateWhenResumed: gave up after 100 attempts');
    return;
  }
  if (attempt > 0 && attempt % 10 == 0) {
    debugPrint(
      '[CallKit] _navigateWhenResumed: still polling (attempt=$attempt, '
      'lifecycle=${WidgetsBinding.instance.lifecycleState})',
    );
  }
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  // Fallback: after 30 attempts (10 s) without seeing `resumed`, push anyway.
  // Covers Android-emulator lifecycle oscillation where `resumed` never fires.
  final shouldForcePush = attempt >= 30 && lifecycle != AppLifecycleState.resumed;
  if (lifecycle == AppLifecycleState.resumed || shouldForcePush) {
    if (shouldForcePush) {
      debugPrint(
        '[CallKit] _navigateWhenResumed: forcing push after $attempt attempts '
        '(lifecycle=$lifecycle, never reached resumed)',
      );
    }
    // Small delay so the router/navigator finishes initialising after resume.
    Future.delayed(const Duration(milliseconds: 200), () {
      // Only push if DashboardScreen hasn't already consumed the route.
      final pending = NotificationService.consumePendingCallRoute();
      if (pending != null) {
        debugPrint('[CallKit] _navigateWhenResumed: pushing $pending');
        try {
          appRouter.push(pending);
        } catch (e) {
          debugPrint('[CallKit] _navigateWhenResumed: push failed: $e');
        }
      } else {
        debugPrint('[CallKit] _navigateWhenResumed: route already consumed');
      }
    });
  } else {
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateWhenResumed(route, attempt + 1);
    });
  }
}

/// Subscribe to [GroupMeshCallService.incomingInviteStream] and surface the
/// native incoming UI via CallKit for mesh group call invites.
///
/// Must be called AFTER [setupDependencies()] so the DI graph is ready.
/// On iOS the CallKit sheet is shown; on Android the flutter_callkit_incoming
/// overlay (or foreground notification) is displayed.
void _setupMeshGroupCallIncoming() {
  if (kIsWeb) return;
  try {
    final svc = sl<GroupMeshCallService>();
    svc.incomingInviteStream.listen((evt) async {
      final extra = evt.envelope.extra;
      if (extra == null) return;
      final roomId = extra['roomId'] as String?;
      final hostHex = extra['hostDevicePk'] as String?;
      final participantsRaw = extra['participants'];
      final participants = participantsRaw is List
          ? participantsRaw.whereType<String>().toList()
          : null;
      if (roomId == null || hostHex == null || participants == null) return;

      // Surface native incoming UI. The accept/decline handler in
      // _setupCallkitListener and the dashboard route handle the rest.
      // NOTE: roomId is an 8-char hex (GroupMeshCallService._generateRoomId),
      // NOT a UUID. iOS CallKit's CXProvider requires a valid RFC 4122 UUID for
      // the call id — force-unwrapping nil in flutter_callkit_incoming crashed
      // the app on iPhone 2 during smoke. toCallkitId() maps the hex to a valid
      // UUID format; the original roomId stays in extra['roomId'] for routing.
      await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: toCallkitId(roomId),
        nameCaller: 'Group call',
        type: 0, // 0 = audio
        extra: <String, dynamic>{
          'kind': 'mesh_gc',
          'roomId': roomId,
          'hostDevicePkHex': hostHex,
          'participantDevicePks': participants,
        },
      ));
    });
  } catch (e) {
    debugPrint('[mesh-gc] _setupMeshGroupCallIncoming: DI not ready ($e)');
  }
}

/// Try to connect to LiveKit in the background right after CallKit accept.
/// DI may not be ready during killed-app cold start — silently skip in that case.
void _connectCallInBackground(String roomName, String? convId, {String? e2eeKey}) {
  try {
    if (!sl.isRegistered<DioClient>()) {
      debugPrint('[CallKit] DI not ready, skipping background connect');
      return;
    }
    CallStateService.instance.connectInBackground(roomName, convId, e2eeKey: e2eeKey);
  } catch (e) {
    debugPrint('[CallKit] _connectCallInBackground error: $e');
  }
}

/// Fallback for killed-app scenario: check if CallKit has an active call
/// that was accepted before the EventChannel listener was registered.
/// The native CallKit delegate processes the accept on the native side,
/// but the Flutter EventChannel may miss it during cold start.
Future<void> _checkInitialCallKitCall() async {
  try {
    final calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is! List || calls.isEmpty) return;
    for (final raw in calls) {
      final call = Map<String, dynamic>.from(raw as Map);
      final extra = call['extra'] as Map?;
      final roomName = extra?['roomName'] as String?;
      final convId = extra?['conversationId'] as String?;
      final e2eeKey = extra?['e2eeKey'] as String?;
      if (roomName == null || roomName.isEmpty) continue;
      // Only set if EventChannel hasn't already set it
      if (NotificationService.hasPendingCallRoute) return;
      // Group call cold-start: route directly to the group active screen.
      if (roomName.startsWith('group-')) {
        final groupCallId = roomName.substring('group-'.length);
        if (groupCallId.isEmpty) continue;
        final route = '/group-call/$groupCallId';
        debugPrint('[CallKit] _checkInitialCallKitCall: found active group call, route=$route');
        NotificationService.setPendingCallRoute(route);
        _navigateWhenResumed(route, 0);
        return;
      }
      final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
      final route =
          '/dashboard/voice?room=$roomName&convId=${convId ?? ''}&incoming=1$e2eeParam';
      debugPrint('[CallKit] _checkInitialCallKitCall: found active call, route=$route');
      NotificationService.setPendingCallRoute(route);
      _connectCallInBackground(roomName, convId, e2eeKey: e2eeKey);
      _navigateWhenResumed(route, 0);
      return;
    }
  } catch (e) {
    debugPrint('[CallKit] _checkInitialCallKitCall error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up CallKit listener early — before runApp — to catch accept events
  // that arrive while the app is cold-starting.
  _setupCallkitListener();

  // Fallback: check if CallKit already has an active accepted call
  // (event may have fired before the listener was registered on cold start).
  _checkInitialCallKitCall();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init web token storage (Hive-based, avoids flutter_secure_storage hang)
  await SecureStorageService.initWeb();

  // Setup DI first — must happen before NotificationService.init() so that
  // DioClient is registered when we try to save FCM/VoIP tokens.
  await setupDependencies();

  // Wire mesh group call incoming notifications (requires DI to be ready).
  _setupMeshGroupCallIncoming();

  // One-shot migration: move legacy Hive saved_messages → server SAVED conversation.
  unawaited(sl<HiveFavoritesMigrationService>().runOnce());

  // Initialize Firebase (mobile only) — after DI so DioClient is available
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Initialize FCM
      await NotificationService.init();
      // Handle FCM notification taps (app in background or foreground)
      NotificationService.setupForegroundHandlers(onTap: (msg) {
        final route = notificationToRoute(msg);
        if (route != null) {
          try {
            appRouter.go(route);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  // Load saved language & theme
  final storage = sl<SecureStorageService>();
  String? savedLang;
  ThemeMode themeMode = ThemeMode.light;
  try {
    savedLang = await storage.getLanguage();
    final savedTheme = await storage.getThemeMode();
    themeMode = switch (savedTheme) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  } catch (_) {
    // Corrupted storage — use defaults
  }

  // Load persisted wallpaper choice
  await WallpaperService.instance.loadFromStorage();

  // Initialize share intent listener (receive files from other apps)
  if (!kIsWeb) {
    ShareIntentService.instance.init();
  }

  runApp(TalerIdApp(initialLocale: savedLang, initialThemeMode: themeMode));
}

class TalerIdApp extends StatefulWidget {
  final String? initialLocale;
  final ThemeMode initialThemeMode;
  const TalerIdApp({super.key, this.initialLocale, this.initialThemeMode = ThemeMode.light});

  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_TalerIdAppState>();
    state?._setLocale(locale);
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    final state = context.findAncestorStateOfType<_TalerIdAppState>();
    state?._setThemeMode(mode);
  }

  @override
  State<TalerIdApp> createState() => _TalerIdAppState();
}

class _TalerIdAppState extends State<TalerIdApp> {
  Locale? _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocale != null) {
      _locale = Locale(widget.initialLocale!);
    }
    _themeMode = widget.initialThemeMode;
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
        BlocProvider(create: (_) => sl<KycBloc>()),
        BlocProvider(create: (_) => sl<TenantBloc>()),
        BlocProvider(create: (_) => sl<SessionsBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Taler ID',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru'),
          Locale('en'),
        ],
      ),
    );
  }
}
