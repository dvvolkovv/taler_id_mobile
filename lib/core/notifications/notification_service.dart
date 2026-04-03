import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/dio_client.dart';
import '../di/service_locator.dart';
import '../storage/secure_storage_service.dart';
import '../../firebase_options.dart';

/// Notification strings resolved by locale (no BuildContext needed).
class _NotifStrings {
  final String channelMessages;
  final String channelMessagesDesc;
  final String channelMissedCalls;
  final String channelMissedCallsDesc;
  final String missedCall;
  final String incomingCall;
  final String incomingCallChannel;
  final String missedCallChannel;
  final String unknown;
  final String accept;
  final String decline;

  const _NotifStrings({
    required this.channelMessages,
    required this.channelMessagesDesc,
    required this.channelMissedCalls,
    required this.channelMissedCallsDesc,
    required this.missedCall,
    required this.incomingCall,
    required this.incomingCallChannel,
    required this.missedCallChannel,
    required this.unknown,
    required this.accept,
    required this.decline,
  });
}

const _ruStrings = _NotifStrings(
  channelMessages: 'Сообщения',
  channelMessagesDesc: 'Уведомления о новых сообщениях',
  channelMissedCalls: 'Пропущенные звонки',
  channelMissedCallsDesc: 'Уведомления о пропущенных звонках',
  missedCall: 'Пропущенный звонок',
  incomingCall: 'Входящий звонок',
  incomingCallChannel: 'Входящий звонок',
  missedCallChannel: 'Пропущенный звонок',
  unknown: 'Неизвестный',
  accept: 'Принять',
  decline: 'Отклонить',
);

const _enStrings = _NotifStrings(
  channelMessages: 'Messages',
  channelMessagesDesc: 'New message notifications',
  channelMissedCalls: 'Missed calls',
  channelMissedCallsDesc: 'Missed call notifications',
  missedCall: 'Missed call',
  incomingCall: 'Incoming call',
  incomingCallChannel: 'Incoming call',
  missedCallChannel: 'Missed call',
  unknown: 'Unknown',
  accept: 'Accept',
  decline: 'Decline',
);

/// Detect locale from saved preference or platform, return notification strings.
Future<_NotifStrings> _notifStrings() async {
  String? lang;
  try {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    lang = await storage.read(key: 'app_language');
  } catch (_) {}
  lang ??= (!kIsWeb ? Platform.localeName : 'en').split('_').first;
  return lang == 'ru' ? _ruStrings : _enStrings;
}

final _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@drawable/ic_notification');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _localNotifications.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

Future<void> _showLocalNotification({
  required String title,
  required String body,
  required String conversationId,
}) async {
  final s = await _notifStrings();
  final androidDetails = AndroidNotificationDetails(
    'messages',
    s.channelMessages,
    channelDescription: s.channelMessagesDesc,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@drawable/ic_notification',
  );
  const iosDetails = DarwinNotificationDetails(sound: 'default');
  await _localNotifications.show(
    conversationId.hashCode,
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: conversationId,
  );
}

Future<void> _showMissedCallNotification({required String fromName}) async {
  final s = await _notifStrings();
  final androidDetails = AndroidNotificationDetails(
    'missed_calls',
    s.channelMissedCalls,
    channelDescription: s.channelMissedCallsDesc,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@drawable/ic_notification',
  );
  const iosDetails = DarwinNotificationDetails(sound: 'default');
  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    s.missedCall,
    fromName,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}

bool get _isIosSimulator =>
    !kIsWeb &&
    Platform.isIOS &&
    (Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['SIMULATOR_UDID'] != null);

/// Extract UUID part from roomName like "call-550e8400-e29b-41d4-a716-446655440000"
/// CallKit requires a valid RFC4122 UUID string as id.
String toCallkitId(String roomName) {
  // If roomName already looks like a UUID, use it directly
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  if (uuidRegex.hasMatch(roomName)) return roomName;
  // Strip prefix "call-" and take remaining UUID part
  final stripped = roomName.replaceFirst(RegExp(r'^call-'), '');
  if (uuidRegex.hasMatch(stripped)) return stripped;
  // Fallback: derive UUID from hash (must be a valid UUID)
  final hash = roomName.hashCode.abs();
  return '00000000-0000-4000-8000-${hash.toRadixString(16).padLeft(12, '0').substring(0, 12)}';
}

/// Shows native OS-level incoming call screen (Android full-screen / iOS CallKit).
/// Skipped on iOS Simulator where CallKit is not supported.
Future<void> showCallkitIncoming({
  required String roomName,
  required String fromName,
  required String convId,
  String? fromAvatar,
}) async {
  if (_isIosSimulator) return;
  final s = await _notifStrings();
  await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
    id: toCallkitId(roomName),
    nameCaller: fromName,
    appName: 'Taler ID',
    type: 0,
    textAccept: s.accept,
    textDecline: s.decline,
    duration: 60000,
    extra: <String, dynamic>{
      'roomName': roomName,
      'conversationId': convId,
      if (fromName.isNotEmpty) 'callerName': fromName,
      if (fromAvatar != null && fromAvatar.isNotEmpty) 'callerAvatar': fromAvatar,
    },
    android: AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      isShowFullLockedScreen: true,
      ringtonePath: 'bumer_ringtone',
      backgroundColor: '#0A1628',
      actionColor: '#167EF2',
      textColor: '#FFFFFF',
      incomingCallNotificationChannelName: s.incomingCallChannel,
      missedCallNotificationChannelName: s.missedCallChannel,
      isShowCallID: false,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      supportsVideo: false,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: false,
      supportsHolding: false,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'bumer_ringtone.caf',
    ),
  ));
}

// Background message handler (top-level function required by FCM).
// Runs in a separate background isolate — do NOT call WidgetsFlutterBinding here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final type = message.data['type'] as String?;
  if (type == 'call_invite') {
    await showCallkitIncoming(
      roomName: message.data['roomName'] ?? '',
      fromName: message.data['fromName'] ?? (await _notifStrings()).incomingCall,
      convId: message.data['conversationId'] ?? '',
      fromAvatar: message.data['fromAvatar'] as String?,
    );
  } else if (type == 'call_cancelled') {
    // Caller hung up before answer — dismiss CallKit UI
    await FlutterCallkitIncoming.endAllCalls();
    await _initLocalNotifications();
    await _showMissedCallNotification(
      fromName: message.data['fromName'] ?? (await _notifStrings()).unknown,
    );
  }
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static String? _currentToken;
  static VoidCallback? _onCalendarUpdated;
  static void setCalendarUpdateCallback(VoidCallback? cb) => _onCalendarUpdated = cb;
  static VoidCallback? _onCalendarInvite;
  static void setCalendarInviteCallback(VoidCallback? cb) => _onCalendarInvite = cb;
  static VoidCallback? _onMissedCall;
  static void setMissedCallCallback(VoidCallback? cb) => _onMissedCall = cb;

  // Pending voice call route to handle CallKit accept across all app states
  static String? _pendingCallRoute;
  static void setPendingCallRoute(String route) => _pendingCallRoute = route;
  static String? consumePendingCallRoute() {
    final route = _pendingCallRoute;
    _pendingCallRoute = null;
    return route;
  }

  static bool get hasPendingCallRoute => _pendingCallRoute != null;

  /// Single broadcast stream for CallKit events.
  /// Subscribe to this instead of [FlutterCallkitIncoming.onEvent] to avoid
  /// replacing the underlying EventChannel handler on each subscription.
  /// The raw EventChannel is subscribed ONCE in main.dart's _setupCallkitListener().
  static final StreamController<CallEvent?> _callEventController =
      StreamController<CallEvent?>.broadcast();
  static Stream<CallEvent?> get callEvents => _callEventController.stream;

  /// Forward a CallKit event to all subscribers. Called by main.dart only.
  static void addCallEvent(CallEvent? event) => _callEventController.add(event);

  static Future<void> init() async {
    // Register background handler — must be registered synchronously before any isolate runs.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize local notifications plugin (required for channel creation on Android).
    await _initLocalNotifications();

    // Set up token refresh listener.
    _fcm.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _saveTokenToBackend(token);
    });

    // Everything else (permission request, token fetch, VoIP token) is fire-and-forget
    // so we don't block runApp(). Tokens will be reliably saved in refreshToken() after login.
    _initPermissionsAndTokens();
  }

  /// Request notification permission explicitly (called from onboarding or init).
  static Future<void> requestPermission() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }
  }

  static Future<void> _initPermissionsAndTokens() async {
    try {
      // Request permission only if onboarding was already seen
      // (new users will get the prompt from the onboarding screen).
      // Existing users who update the app already have permission granted.
      final storage = sl<SecureStorageService>();
      final onboardingSeen = await storage.isOnboardingSeen;
      if (onboardingSeen) {
        await requestPermission();
      }
      final token = await _fcm.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }

    // Register VoIP push token for iOS (real device only, not simulator).
    if (!kIsWeb && Platform.isIOS && !_isIosSimulator) {
      try {
        final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        if (voipToken != null && voipToken.isNotEmpty) {
          final client = sl<DioClient>();
          await client.put('/profile', data: {'voipToken': voipToken}, fromJson: (d) => d);
          debugPrint('VoIP token saved to backend');
        }
      } catch (e) {
        debugPrint('Failed to save VoIP token: $e');
      }
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final client = sl<DioClient>();
      await client.put('/profile', data: {'fcmToken': token});
      debugPrint('FCM token saved to backend');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Call this after the user logs in to ensure FCM token is registered.
  /// Needed because init() runs before login and the PUT /profile call fails with 401.
  static Future<void> refreshToken() async {
    try {
      final token = _currentToken ?? await _fcm.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM getToken failed (simulator?): $e');
    }
    // Re-save VoIP token on iOS after login.
    // init() runs before authentication, so the initial save may fail with 401.
    // This call runs from DashboardScreen (post-login) to ensure the token is persisted.
    if (!kIsWeb && Platform.isIOS && !_isIosSimulator) {
      try {
        final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        if (voipToken != null && voipToken.isNotEmpty) {
          final client = sl<DioClient>();
          await client.put('/profile', data: {'voipToken': voipToken}, fromJson: (d) => d);
          debugPrint('VoIP token refreshed to backend');
        }
      } catch (e) {
        debugPrint('Failed to refresh VoIP token: $e');
      }
    }
    // Battery optimization exemption removed — no longer prompt user
  }

  /// Set up foreground notification tap handlers
  /// Call this after GoRouter is initialized
  static void setupForegroundHandlers({required Function(RemoteMessage) onTap}) {
    // Foreground FCM messages.
    // - call_invite: handled by WebSocket (in-app dialog) — skip to avoid double ringing.
    // - new_message: show local notification (Android won't auto-show FCM when app is open).
    FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['type'] as String?;
      if (type == 'new_message') {
        final convId = message.data['conversationId'] as String? ?? '';
        final title = message.notification?.title ?? '';
        final body = message.notification?.body ?? '';
        if (title.isNotEmpty && body.isNotEmpty) {
          _showLocalNotification(title: title, body: body, conversationId: convId);
        }
      }
      if (type == 'contact_request') {
        final title = message.notification?.title ?? 'Запрос на общение';
        final body = message.notification?.body ?? 'Новый запрос на добавление в контакты';
        _showLocalNotification(title: title, body: body, conversationId: '');
      }
      if (type == 'calendar_updated' || type == 'calendar_invite' || type == 'calendar_reminder') {
        _onCalendarUpdated?.call();
      }
      if (type == 'calendar_invite') {
        _onCalendarInvite?.call();
      }
      // call_invite is intentionally ignored here — socket handles it.
      if (type == 'call_cancelled') {
        FlutterCallkitIncoming.endAllCalls();
        _notifStrings().then((s) => _showMissedCallNotification(
          fromName: message.data['fromName'] ?? s.unknown,
        ));
        _onMissedCall?.call();
      }
    });

    // App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }

  /// Check if app was opened from a notification (terminated state)
  static Future<RemoteMessage?> getInitialMessage() =>
      _fcm.getInitialMessage();

  static String? get token => _currentToken;
}

/// Map notification data to deep link route
String? notificationToRoute(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] as String?;

  switch (type) {
    case 'kyc_status':
      return '/dashboard/kyc';
    case 'kyb_status':
      return '/dashboard/organization';
    case 'new_session':
      return '/dashboard/sessions';
    case 'invite':
      final token = data['token'] as String?;
      return token != null ? '/invite?token=$token' : null;
    case 'call_invite':
      final roomName = data['roomName'] as String?;
      final convId = data['conversationId'] as String?;
      if (roomName != null && convId != null) {
        final e2eeKey = data['e2eeKey'] as String?;
        final fromName = data['fromName'] as String? ?? '';
        final fromAvatar = data['fromAvatar'] as String? ?? '';
        final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
        final calleeParam = fromName.isNotEmpty ? '&callee=${Uri.encodeComponent(fromName)}' : '';
        final avatarParam = fromAvatar.isNotEmpty ? '&calleeAvatar=${Uri.encodeComponent(fromAvatar)}' : '';
        return '/dashboard/voice?room=$roomName&convId=$convId&incoming=1$e2eeParam$calleeParam$avatarParam';
      }
      return null;
    case 'new_message':
      final convId = data['conversationId'] as String?;
      return convId != null
          ? '/dashboard/messenger/$convId'
          : '/dashboard/messenger';
    case 'contact_request':
      return '/dashboard/messenger/contacts?tab=incoming';
    case 'calendar_invite':
      final inviteEventId = data['eventId'] as String?;
      return inviteEventId != null
          ? '/dashboard/calendar?eventId=$inviteEventId'
          : '/dashboard/calendar?invites=1';
    case 'calendar_reminder':
      final eventId = data['eventId'] as String?;
      return eventId != null
          ? '/dashboard/calendar?eventId=$eventId'
          : '/dashboard/calendar';
    default:
      return null;
  }
}
