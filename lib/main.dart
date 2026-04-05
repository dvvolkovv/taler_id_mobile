import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'core/api/dio_client.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/call_state_service.dart';
import 'core/services/share_intent_service.dart';
import 'firebase_options.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/wallpaper_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/kyc/presentation/bloc/kyc_bloc.dart';
import 'features/tenant/presentation/bloc/tenant_bloc.dart';
import 'features/sessions/presentation/bloc/sessions_bloc.dart';

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

    if (event?.event != Event.actionCallAccept) return;
    final extra = event!.body['extra'] as Map?;
    final roomName = extra?['roomName'] as String?;
    final convId = extra?['conversationId'] as String?;
    final e2eeKey = extra?['e2eeKey'] as String?;
    final callerName = event.body['nameCaller'] as String? ?? '';
    final callerAvatar = extra?['callerAvatar'] as String? ?? '';
    if (roomName == null || roomName.isEmpty) return;
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

/// Polls WidgetsBinding lifecycle every 300 ms (up to 3 s) until the app is
/// fully resumed, then pushes the voice route via the global [appRouter].
/// DashboardScreen may also navigate via [didChangeAppLifecycleState]; the
/// [NotificationService.consumePendingCallRoute] call acts as a one-shot latch
/// so only the first navigator wins.
void _navigateWhenResumed(String route, int attempt) {
  if (attempt > 100) {
    debugPrint('[CallKit] _navigateWhenResumed: gave up after 100 attempts');
    return;
  }
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  if (lifecycle == AppLifecycleState.resumed) {
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
