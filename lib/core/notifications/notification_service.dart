import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/dio_client.dart';
import '../di/service_locator.dart';
import '../platform/call_kit.dart';
import '../platform/fcm_messaging.dart';
import '../platform/secure_storage.dart';
import '../storage/secure_storage_service.dart';
import '../../features/messenger/data/datasources/messenger_remote_datasource.dart';
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
    lang = await SecureStorage.instance.read('app_language');
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
  // Conversation-keyed id/tag so a later `cancelForConversation` (triggered by
  // the server's silent `read_sync` push) can cancel this exact notification
  // by the same tag the server set on the FCM `notification.tag`.
  // `contact_request` reuses this helper with an empty conversationId — keep
  // the legacy hashCode id and no tag for that non-conversation case.
  final notifService = NotificationService();
  final id = conversationId.isNotEmpty
      ? notifService.notifIntIdFor(conversationId)
      : conversationId.hashCode;
  final tag = conversationId.isNotEmpty ? notifService.notifKeyFor(conversationId) : null;
  final androidDetails = AndroidNotificationDetails(
    'messages',
    s.channelMessages,
    channelDescription: s.channelMessagesDesc,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@drawable/ic_notification',
    largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
    tag: tag,
  );
  const iosDetails = DarwinNotificationDetails(sound: 'default');
  await _localNotifications.show(
    id,
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
    largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
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
  await CallKitPlatform.instance.showIncomingCall(
    uuid: toCallkitId(roomName),
    callerName: fromName,
    roomName: roomName,
    textAccept: s.accept,
    textDecline: s.decline,
    durationMs: 60000,
    androidIncomingChannelName: s.incomingCallChannel,
    androidMissedChannelName: s.missedCallChannel,
    extra: <String, dynamic>{
      'roomName': roomName,
      'conversationId': convId,
      if (fromName.isNotEmpty) 'callerName': fromName,
      if (fromAvatar != null && fromAvatar.isNotEmpty) 'callerAvatar': fromAvatar,
    },
  );
}

// Background message handler (top-level function required by FCM).
// Runs in a separate background isolate — do NOT call WidgetsFlutterBinding here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final type = message.data['type'] as String?;
  if (type == 'read_sync') {
    // Silent server push: another device/tab read this conversation.
    // Cancel this device's OS-displayed notification for it — never show
    // a banner for a read_sync push.
    final convId = message.data['conversationId'] as String?;
    if (convId != null) {
      await NotificationService().cancelForConversation(convId);
    }
    return;
  }
  if (type == 'call_invite') {
    await showCallkitIncoming(
      roomName: message.data['roomName'] ?? '',
      fromName: message.data['fromName'] ?? (await _notifStrings()).incomingCall,
      convId: message.data['conversationId'] ?? '',
      fromAvatar: message.data['fromAvatar'] as String?,
    );
  } else if (type == 'group_call_invite') {
    // Group call: display host name + group suffix ("Алиса + N").
    // APNs payload may pre-format `nameCaller` ("Алиса + 2 ещё");
    // FCM data-only payload sends raw `hostDisplayName` + `inviteeCount`.
    final hostDisplayName = (message.data['hostDisplayName'] as String?) ??
        (message.data['nameCaller'] as String?) ??
        (await _notifStrings()).incomingCall;
    final inviteeCount = int.tryParse(
          (message.data['inviteeCount'] ?? '1').toString(),
        ) ??
        1;
    final formattedCaller = inviteeCount > 1
        ? '$hostDisplayName + ${inviteeCount - 1}'
        : hostDisplayName;
    final groupCallId = message.data['groupCallId'] as String? ?? '';
    await showCallkitIncoming(
      // `group-<id>` prefix lets the CallKit accept handler in main.dart
      // discriminate group vs 1-on-1 routes.
      roomName: 'group-$groupCallId',
      fromName: formattedCaller,
      // Group calls are not tied to a Conversation row.
      convId: '',
      fromAvatar: message.data['hostAvatarUrl'] as String?,
    );
  } else if (type == 'call_cancelled') {
    // Caller hung up before answer OR the call was answered on another
    // device. Only dismiss RINGING calls — never an accepted one (the
    // answered-elsewhere cancel push also reaches the answering device).
    var hasAccepted = false;
    try {
      final active = await CallKitPlatform.instance.activeCalls();
      hasAccepted = active.any((c) =>
          c is Map && (c['isAccepted'] == true || c['accepted'] == true));
    } catch (_) {}
    if (!hasAccepted) {
      await CallKitPlatform.instance.endAllCalls();
    }
    final answeredElsewhere =
        message.data['fromName'] == 'answered_elsewhere';
    if (!hasAccepted && !answeredElsewhere) {
      await _initLocalNotifications();
      await _showMissedCallNotification(
        fromName: message.data['fromName'] ?? (await _notifStrings()).unknown,
      );
    }
  }
}

class NotificationService {
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
  static final StreamController<CallKitEvent?> _callEventController =
      StreamController<CallKitEvent?>.broadcast();
  static Stream<CallKitEvent?> get callEvents => _callEventController.stream;

  /// Forward a CallKit event to all subscribers. Called by main.dart only.
  static void addCallEvent(CallKitEvent? event) => _callEventController.add(event);

  static Future<void> init() async {
    // Register background handler — must be registered synchronously before any isolate runs.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize local notifications plugin (required for channel creation on Android).
    await _initLocalNotifications();

    // Set up token refresh listener.
    FcmMessagingPlatform.instance.onTokenRefresh.listen((token) async {
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
      await FcmMessagingPlatform.instance.requestPermissions();
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
      final token = await FcmMessagingPlatform.instance.getToken();
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
        final voipToken = await CallKitPlatform.instance.getDevicePushTokenVoIP();
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

  /// Persist [token] to the backend via PUT /profile.
  ///
  /// [force] is reserved for future symmetry: today we always PUT, but the
  /// flag documents intent so a future cache-skip optimisation cannot
  /// accidentally short-circuit the post-login re-registration. Backend may
  /// auto-purge stale FCM tokens (NotRegistered/InvalidRegistration), so a
  /// fresh login MUST re-upload even when the device-local token is unchanged.
  static Future<void> _saveTokenToBackend(String token, {bool force = false}) async {
    try {
      final client = sl<DioClient>();
      await client.put('/profile', data: {'fcmToken': token});
      debugPrint('FCM token saved to backend (force=$force)');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Call this after the user logs in to ensure FCM/VoIP tokens are registered.
  /// Needed because init() runs before login and the PUT /profile call fails with 401.
  ///
  /// Pass [force]=true on every successful login to bypass any caching and
  /// guarantee the backend has a current token row. This is required because
  /// the backend may have auto-purged the row after a stale-token push error;
  /// without a forced re-register the device thinks it's still registered while
  /// the server has forgotten it, and push silently stops working.
  ///
  /// [onTokenRefresh] (FCM rotation) and other passive paths can keep calling
  /// this with the default [force]=false.
  static Future<void> refreshToken({bool force = false}) async {
    try {
      // When forced, always re-fetch from FCM SDK to avoid relying on a stale
      // in-memory cache. Otherwise reuse cached value to skip the SDK round-trip.
      final token = force
          ? (await FcmMessagingPlatform.instance.getToken() ?? _currentToken)
          : (_currentToken ?? await FcmMessagingPlatform.instance.getToken());
      if (token != null) {
        _currentToken = token;
        await _saveTokenToBackend(token, force: force);
      }
    } catch (e) {
      debugPrint('FCM getToken failed (simulator?): $e');
    }
    // Re-save VoIP token on iOS after login.
    // init() runs before authentication, so the initial save may fail with 401.
    // This call runs from DashboardScreen (post-login) to ensure the token is persisted.
    if (!kIsWeb && Platform.isIOS && !_isIosSimulator) {
      try {
        final voipToken = await CallKitPlatform.instance.getDevicePushTokenVoIP();
        if (voipToken != null && voipToken.isNotEmpty) {
          final client = sl<DioClient>();
          await client.put('/profile', data: {'voipToken': voipToken}, fromJson: (d) => d);
          debugPrint('VoIP token refreshed to backend (force=$force)');
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
    FirebaseMessaging.onMessage.listen((message) async {
      final type = message.data['type'] as String?;
      if (type == 'read_sync') {
        // Silent server push: another device/tab read this conversation.
        // Cancel this device's OS-displayed notification for it — never show
        // a banner for a read_sync push.
        final convId = message.data['conversationId'] as String?;
        if (convId != null) {
          NotificationService().cancelForConversation(convId);
        }
        return;
      }
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
        // Mirror the background handler's guards: the answered-elsewhere
        // cancel push fans out to EVERY device of the answerer — including
        // the one that just picked up. Without these guards the answering
        // device killed its own accepted call via endAllCalls() and showed
        // a bogus "missed call from answered_elsewhere" notification.
        var hasAccepted = false;
        try {
          final active = await CallKitPlatform.instance.activeCalls();
          hasAccepted = active.any((c) =>
              c is Map && (c['isAccepted'] == true || c['accepted'] == true));
        } catch (_) {}
        if (!hasAccepted) {
          await CallKitPlatform.instance.endAllCalls();
        }
        final answeredElsewhere =
            message.data['fromName'] == 'answered_elsewhere';
        if (!hasAccepted && !answeredElsewhere) {
          _notifStrings().then((s) => _showMissedCallNotification(
            fromName: message.data['fromName'] ?? s.unknown,
          ));
          _onMissedCall?.call();
        }
      }
    });

    // App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }

  /// Check if app was opened from a notification (terminated state)
  static Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();

  static String? get token => _currentToken;

  /// The stable per-conversation notification key.
  ///
  /// MUST equal the server's `fcm.service.notificationIdFor` scheme byte-for-byte:
  /// `'conv-' + sha1(utf8(conversationId)).hex.substring(0, 16)`.
  /// This string is what the server sets as the Android FCM `notification.tag`
  /// and the iOS `apns-collapse-id`, so client and server MUST derive it
  /// identically or cancellation silently fails.
  String notifKeyFor(String conversationId) =>
      'conv-${sha1.convert(utf8.encode(conversationId)).toString().substring(0, 16)}';

  /// Stable non-negative int id derived from [notifKeyFor], for use as the
  /// flutter_local_notifications numeric id when the app renders a message
  /// notification itself (foreground/Android data path).
  int notifIntIdFor(String conversationId) => notifKeyFor(conversationId).hashCode & 0x7fffffff;

  /// Cancel any OS-displayed notification for [conversationId] (e.g. after the
  /// user reads the conversation, triggered by the server's silent
  /// `read_sync` push) and recompute the app badge.
  Future<void> cancelForConversation(String conversationId) async {
    final tag = notifKeyFor(conversationId);
    // Android background/killed: the FCM SDK auto-displays the message push
    // ITSELF (we never render it), keyed by the `notification.tag` the server
    // set (== [tag]) but with a notification id we do NOT control — the SDK
    // picks its own, which is NOT [notifIntIdFor]. Android's NotificationManager
    // cancels only when BOTH id and tag match, so a fixed-id cancel silently
    // misses the OS-shown banner (the case that matters most for clear-on-read).
    // Fix: enumerate the active notifications and cancel every one whose tag
    // matches — robust regardless of the id the SDK assigned.
    try {
      // getActiveNotifications() is only implemented on Android/iOS — and only
      // there do FCM-auto-displayed banners exist. On desktop (Linux/Windows/
      // macOS) it throws UnimplementedError, so skip it entirely to avoid log
      // spam on every reconcile; the direct cancel below still runs.
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final active = await _localNotifications.getActiveNotifications();
          for (final n in active) {
            if (n.tag == tag && n.id != null) {
              await _localNotifications.cancel(n.id!, tag: n.tag);
            }
          }
        } catch (e) {
          // Unsupported on some OS levels — fall through to the direct cancel.
          debugPrint('cancelForConversation: getActiveNotifications failed: $e');
        }
      }
      // Belt-and-suspenders: also cancel our own foreground-rendered id directly,
      // in case the active-notifications query is unsupported or raced the OS.
      await _localNotifications.cancel(notifIntIdFor(conversationId), tag: tag);
    } catch (e) {
      debugPrint('cancelForConversation: cancel failed for $conversationId: $e');
    }
    // NOTE(ios-clear): flutter_local_notifications ^18 can't remove an iOS
    // DELIVERED notification whose identifier is the server's apns-collapse-id
    // (a non-numeric string) — getActiveNotifications returns it with a null id
    // and cancel(id) can't target it. Android now clears reliably (above); iOS
    // FCM-shown banners still need a native
    // UNUserNotificationCenter.removeDeliveredNotifications(withIdentifiers:)
    // channel (follow-up). The foreground reconcile (read-state fetch) is the
    // interim iOS safety net.
  }

  /// Internal id for the badge-only "ghost" notification used to refresh the
  /// iOS app icon badge without showing a banner/sound. flutter_local_notifications
  /// has no standalone "set badge count" API on iOS — updating the badge via a
  /// silent (`presentAlert: false, presentSound: false`) notification is the
  /// standard idiom for this plugin.
  static const int _badgeGhostNotificationId = 0x7ffffffe;

  /// Refresh the app icon badge to reflect [totalUnread] (clamped to >= 0).
  Future<void> setBadgeFromUnread(int totalUnread) async {
    final count = totalUnread < 0 ? 0 : totalUnread;
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _localNotifications.show(
          _badgeGhostNotificationId,
          null,
          null,
          NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentSound: false,
              presentBadge: true,
              badgeNumber: count,
            ),
          ),
        );
      } catch (e) {
        debugPrint('setBadgeFromUnread: iOS badge update failed: $e');
      }
    }
    // Android: flutter_local_notifications has no dedicated launcher-badge
    // API; most launchers derive the badge count from the number of active
    // notifications, which cancelForConversation already keeps accurate.
  }

  /// Foreground reconcile: fetch the authoritative read-state from the
  /// backend, cancel any stale OS notification for conversations that are
  /// now fully read (`unread == 0`), and refresh the app badge to the true
  /// total unread count. This is the safety net for read_sync pushes that
  /// never arrived (app was killed/backgrounded past FCM delivery limits)
  /// and for iOS, where a delivered banner can't be pulled by
  /// [cancelForConversation] alone (see NOTE(ios-clear) above).
  ///
  /// Call on app resume and on messenger socket (re)connect.
  Future<void> reconcile() async {
    try {
      final datasource = sl<MessengerRemoteDataSource>();
      final states = await datasource.fetchReadState();
      var total = 0;
      for (final s in states) {
        if (s.unread == 0) {
          await cancelForConversation(s.conversationId);
        }
        total += s.unread;
      }
      await setBadgeFromUnread(total);
    } catch (e) {
      debugPrint('NotificationService.reconcile failed: $e');
    }
  }
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
    case 'group_call_invite':
      final groupCallId = data['groupCallId'] as String?;
      if (groupCallId != null && groupCallId.isNotEmpty) {
        // Active screen handles lobby fallback via BLoC state.
        return '/group-call/$groupCallId';
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
