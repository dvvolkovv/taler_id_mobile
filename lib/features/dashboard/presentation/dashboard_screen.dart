import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/outbox_replay_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/services/call_state_service.dart';
// Note: do NOT use FlutterCallkitIncoming.onEvent directly here — see _setupCallkitListener
// in main.dart. Use NotificationService.callEvents (the shared broadcast proxy) instead.
import '../../../core/notifications/notification_service.dart';
import '../../../core/platform/call_kit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../core/services/apk_installer_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/update_check_service.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/services/wake_word_service.dart';
import '../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../messenger/presentation/screens/share_target_screen.dart';
import '../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../messenger/presentation/bloc/messenger_event.dart';
import '../../messenger/presentation/bloc/messenger_state.dart';
import '../../assistant/presentation/screens/assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  static const _tabs = [
    RouteConstants.messenger,
    RouteConstants.callHistory,
    RouteConstants.assistant,
    RouteConstants.calendar,
    RouteConstants.settings,
  ];

  StreamSubscription? _disconnectSub;
  StreamSubscription? _callEndedSub;
  StreamSubscription? _callAnsweredSub;
  StreamSubscription? _gcEndedSub;
  StreamSubscription? _gcInviteSub;
  StreamSubscription? _callkitSub;
  StreamSubscription? _shareIntentSub;
  String? _showingCallDialogRoom;
  String? _pendingCallRoute; // queued when accept fires while phone is locked
  bool _waitingForCallAccept = false; // blocks in-app dialog after CallKit accept
  bool _acceptingInApp = false; // suppresses actionCallDecline after in-app accept
  bool _endingCallKitFromSocket = false; // suppresses actionCallDecline when CallKit ended by socket call_ended
  final Set<String> _answeredOnOtherDevice = {}; // rooms answered on another device
  Timer? _callAcceptTimer;
  UpdateInfo? _updateInfo;
  bool _updateDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Subscribe to the shared CallKit event proxy (broadcast stream).
    // Do NOT use FlutterCallkitIncoming.onEvent directly here — that creates a NEW
    // EventChannel listener each time, replacing (killing) the one in main.dart.
    // Navigation on accept is handled by _navigateWhenResumed in main.dart.
    _callkitSub = NotificationService.callEvents.listen((CallKitEvent? event) async {
      if (event == null) return;
      final extra = event.data?['extra'] as Map?;
      final roomName = extra?['roomName'] as String?;
      final convId = extra?['conversationId'] as String?;

      if (event.type == CallKitEvent.typeAccept) {
        // Navigation is handled by _navigateWhenResumed in main.dart.
        // Here we set the waiting flag to suppress in-app dialog and
        // dismiss any currently showing in-app call dialog for this room.
        _waitingForCallAccept = true;
        _callAcceptTimer?.cancel();
        _callAcceptTimer = Timer(const Duration(seconds: 15), () {
          _waitingForCallAccept = false;
        });
        // Dismiss in-app incoming call dialog if it's showing
        if (mounted && _showingCallDialogRoom != null &&
            (_showingCallDialogRoom == roomName || roomName == null)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } else if (event.type == CallKitEvent.typeDecline ||
                 event.type == CallKitEvent.typeTimeout) {
        // User declined from native CallKit UI — notify caller via socket.
        // Guard: skip if we're navigating to or already on the voice screen.
        // endAllCalls() in _connect() can trigger actionCallDecline for a still-ringing
        // duplicate CallKit call (VoIP-push UUID ≠ Flutter UUID), which must NOT
        // be treated as a real decline while we are accepting the call.
        if (roomName != null && convId != null) {
          try {
            bool skipNotify = _pendingCallRoute != null; // navigating to voice screen
            if (!skipNotify && _acceptingInApp) skipNotify = true; // in-app accept triggered endAllCalls
            if (!skipNotify && _waitingForCallAccept) skipNotify = true; // CallKit accept in progress
            if (!skipNotify && _endingCallKitFromSocket) skipNotify = true; // CallKit ended by socket call_ended event
            if (!skipNotify) {
              try {
                final loc = GoRouter.of(context)
                    .routerDelegate.currentConfiguration.uri.path;
                if (loc.startsWith('/dashboard/voice')) skipNotify = true;
              } catch (_) {}
            }
            if (!skipNotify) {
              sl<MessengerRemoteDataSource>().sendCallEnded(convId, roomName);
            }
          } catch (_) {}
        }
        // Close in-app dialog if it's showing for this room
        if (mounted && _showingCallDialogRoom != null &&
            (_showingCallDialogRoom == roomName || roomName == null)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        // End only this specific call, not all calls.
        // SKIP if we are accepting a call — VoiceCallScreen's endAllCalls()
        // triggers actionCallDecline for the same CallKit call; calling endCall
        // again here would deactivate the audio session AFTER VoiceCallScreen
        // re-activated it, killing LiveKit audio.
        if (!_waitingForCallAccept && !_acceptingInApp) {
          final callId = (event.data?['id'] ?? event.data?['uuid']) as String?;
          if (callId != null) {
            CallKitPlatform.instance.endCall(callId);
          } else {
            CallKitPlatform.instance.endAllCalls();
          }
        }
      } else if (event.type == CallKitEvent.typeEnded) {
        // User pressed "End" on CallKit native UI during an active call.
        // Only handle here if VoiceCallScreen is NOT showing — if it is,
        // VoiceCallScreen's own listener will call _hangUp().
        // Also skip during call accept flow — endAllCalls() in VoiceCallScreen
        // fires actionCallEnded before VoiceCallScreen route is committed,
        // which would kill the background-connected room.
        bool onVoiceScreen = false;
        try {
          final loc = GoRouter.of(context)
              .routerDelegate.currentConfiguration.uri.path;
          onVoiceScreen = loc.startsWith('/dashboard/voice');
        } catch (_) {}
        if (_waitingForCallAccept || _acceptingInApp) {
          debugPrint('[Dashboard] actionCallEnded SKIPPED (accepting call)');
        } else if (onVoiceScreen) {
          debugPrint('[Dashboard] actionCallEnded SKIPPED (VoiceCallScreen handles it)');
        } else if (CallStateService.instance.isInCall || CallStateService.instance.isBackgroundConnecting) {
          final rn = roomName ?? CallStateService.instance.roomName;
          final cId = convId ?? CallStateService.instance.conversationId;
          debugPrint('[Dashboard] actionCallEnded: roomName=$rn, convId=$cId');
          if (rn != null && cId != null) {
            try { sl<MessengerRemoteDataSource>().sendCallEnded(cId, rn); } catch (_) {}
            try {
              await sl<DioClient>().post(
                '/messenger/call-ended',
                data: {'conversationId': cId, 'roomName': rn},
                fromJson: (d) => d,
              );
            } catch (_) {}
          }
          await CallStateService.instance.endCall();
          try {
            const audioChannel = MethodChannel('taler_id/audio');
            await audioChannel.invokeMethod('deactivateAudioSession');
          } catch (_) {}
          debugPrint('[Dashboard] actionCallEnded cleanup done');
        } else {
          debugPrint('[Dashboard] actionCallEnded SKIPPED (not in call)');
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Handle CallKit accept that happened while app was cold-starting.
      // If lifecycle is not resumed yet (app still waking), defer navigation
      // to didChangeAppLifecycleState so the router is ready.
      final pendingRoute = NotificationService.consumePendingCallRoute();
      if (pendingRoute != null && mounted) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        if (lifecycle == AppLifecycleState.resumed) {
          context.push(pendingRoute);
        } else {
          _pendingCallRoute = pendingRoute; // defer to didChangeAppLifecycleState
        }
        return;
      }
      // Fallback: check CallKit active calls (EventChannel may have missed the event)
      if (await _checkActiveCallKitCalls()) return;
      // Handle FCM notification tap when app was terminated
      final initialMsg = await NotificationService.getInitialMessage();
      if (initialMsg != null) {
        final route = notificationToRoute(initialMsg);
        if (route != null && mounted) {
          context.go(route);
        }
      }
      // Re-register FCM token now that the user is authenticated.
      // NotificationService.init() runs before login so the initial save fails with 401.
      // force:true unconditionally re-uploads even if the device-local token
      // hasn't rotated — backend may have auto-purged a stale row, in which
      // case we must re-register or push silently stops working.
      NotificationService.refreshToken(force: true);
      NotificationService.setMissedCallCallback(() {
        if (mounted) context.read<MessengerBloc>().add(LoadBadgeCounts());
      });
      NotificationService.setCalendarInviteCallback(() {
        if (mounted) context.read<MessengerBloc>().add(LoadBadgeCounts());
      });
      _connectMessenger();
      _listenForDisconnect();
      _listenForCallEnded();
      _listenForCallAnswered();
      _listenForGroupCallEnded();
      _listenForGroupCallInvite();
      _listenForShareIntent();
      _checkForUpdate();
      _startWakeWord();
    });
  }

  void _listenForCallEnded() {
    _callEndedSub?.cancel();
    _callEndedSub = sl<MessengerRemoteDataSource>()
        .callEndedStream
        .listen((roomName) async {
      debugPrint('[Dashboard] callEndedStream fired: roomName=$roomName');
      // If an AI voice twin is currently handling this call, the server
      // broadcast of call_ended is stale — it was emitted by the original
      // human callee's device (their banner timed out / they swiped it)
      // and does NOT mean the live conversation in the room is over.
      // Suppress all Dashboard-side cleanup for this event so CallKit
      // stays out of the iOS audio session and the LiveKit room keeps
      // running. VoiceCallScreen's own listener also no-ops via the
      // _aiTwinActive gate in _hangUp().
      if (CallStateService.instance.isAiTwinRoom(roomName)) {
        debugPrint('[Dashboard] call_ended IGNORED — AI twin active in $roomName');
        return;
      }
      final wasInCallRoom = CallStateService.instance.roomName;
      final isOurCall = wasInCallRoom != null && wasInCallRoom == roomName;

      // Always dismiss a pending incoming call invite from the UI.
      debugPrint('[Dashboard] dismissing call invite, wasInCallRoom=$wasInCallRoom, isOurCall=$isOurCall, showingDialog=$_showingCallDialogRoom');
      if (mounted) {
        context.read<MessengerBloc>().add(DismissCallInvite());
        // Refresh badge counts after missed call
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.read<MessengerBloc>().add(LoadBadgeCounts());
        });
      }
      // Close the in-app incoming call modal dialog if it's showing
      if (mounted && _showingCallDialogRoom != null) {
        _showingCallDialogRoom = null;
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
      }
      // Set flag BEFORE ending CallKit so the resulting actionCallDecline
      // doesn't emit call_ended back to the server (causing double push).
      _endingCallKitFromSocket = true;
      // Dismiss CallKit ringing for this room.
      await _endCallKitCallForRoom(roomName, wasInCallRoom: wasInCallRoom);
      // Reset flag after a short delay (actionCallDecline fires asynchronously)
      Future.delayed(const Duration(seconds: 2), () => _endingCallKitFromSocket = false);

      if (!isOurCall) return;

      // If user is currently on the voice screen — do NOT auto-navigate away.
      // Each participant ends the call themselves by pressing the hang-up button.
      // The participant list will reflect the other party leaving.
      if (!mounted) return;
      final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
      if (location.startsWith('/dashboard/voice')) return;

      // User is NOT on the voice screen (banner mode) — end call state and hide banner.
      CallStateService.instance.endCall();
    });
  }

  /// Group-call analogue of [_listenForCallEnded]: when the server broadcasts
  /// `group_call_ended` (host_ended / all_left / timeout), every device of
  /// every participant gets the event. We must dismiss any still-ringing
  /// CallKit invite for this group call so Phone B doesn't keep ringing for
  /// the full 30 s timeout. The BLoC emits its own [Ended] state for the
  /// in-app screen; this listener handles only the OS-level CallKit cleanup.
  void _listenForGroupCallEnded() {
    _gcEndedSub?.cancel();
    _gcEndedSub = sl<MessengerRemoteDataSource>()
        .gcEndedStream
        .listen((payload) async {
      debugPrint('[Dashboard] gcEndedStream fired: $payload');
      try {
        await CallKitPlatform.instance.endAllCalls();
      } catch (_) {}
    });
  }

  /// Foreground-app analogue of the FCM background `group_call_invite`
  /// handler. The 1-on-1 path (see `_handleCallInvite`) shows CallKit even when
  /// the app is foregrounded so the OS rings; group calls were missing this
  /// hook, so an in-foreground invitee saw nothing.
  void _listenForGroupCallInvite() {
    _gcInviteSub?.cancel();
    _gcInviteSub = sl<MessengerRemoteDataSource>()
        .gcInviteStream
        .listen((payload) async {
      debugPrint('[Dashboard] gcInviteStream fired: $payload');
      final groupCallId = payload['groupCallId'] as String?;
      if (groupCallId == null || groupCallId.isEmpty) return;
      final host = payload['host'] as Map?;
      final hostName = (host?['displayName'] as String?) ?? 'Group Call';
      final hostAvatar = host?['avatarUrl'] as String?;
      final invitees = payload['invitees'] as List? ?? const [];
      final fromName = invitees.length > 1
          ? '$hostName + ${invitees.length - 1}'
          : hostName;
      try {
        await showCallkitIncoming(
          // `group-<id>` prefix lets main.dart's CallKit accept handler
          // discriminate group vs 1-on-1 routes (mirrors the FCM/APNs path).
          roomName: 'group-$groupCallId',
          fromName: fromName,
          convId: '',
          fromAvatar: hostAvatar,
        );
      } catch (e) {
        debugPrint('[Dashboard] gc CallKit show failed: $e');
      }
    });
  }

  void _listenForCallAnswered() {
    _callAnsweredSub?.cancel();
    _callAnsweredSub = sl<MessengerRemoteDataSource>()
        .callAnsweredStream
        .listen((roomName) async {
      // Ignore own broadcast — sendCallAnswered echoes back to the sender via
      // the server room broadcast. If we are already in this call, skip.
      if (CallStateService.instance.roomName == roomName) return;
      // Track so late VoIP pushes for this room are also suppressed
      _answeredOnOtherDevice.add(roomName);
      // Another device of the same user answered — dismiss this device's CallKit UI
      await _endCallKitCallForRoom(roomName, fallbackEndAll: true);
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
    });
  }

  /// Ends the CallKit call identified by [roomName] stored in its extra data.
  /// Falls back to endAllCalls() only when [wasInCallRoom] matches or [fallbackEndAll] is true.
  /// This prevents stale `call_ended` events from killing an unrelated incoming VoIP call.
  Future<void> _endCallKitCallForRoom(
    String roomName, {
    String? wasInCallRoom,
    bool fallbackEndAll = false,
  }) async {
    try {
      final calls = await CallKitPlatform.instance.activeCalls();
      for (final call in calls) {
        final callMap = call as Map;
        final extra = callMap['extra'] as Map?;
        final callRoom = extra?['roomName'] as String?;
        if (callRoom == roomName) {
          await CallKitPlatform.instance.endCall(callMap['id'] as String);
          return;
        }
      }
      // No matching call found by roomName
      if (fallbackEndAll || wasInCallRoom == roomName) {
        await CallKitPlatform.instance.endAllCalls();
      }
      // Otherwise: stale/unrelated event — leave other CallKit calls untouched
    } catch (_) {
      if (fallbackEndAll || wasInCallRoom == roomName) {
        CallKitPlatform.instance.endAllCalls();
      }
    }
  }

  void _listenForDisconnect() {
    _disconnectSub?.cancel();
    _disconnectSub = sl<MessengerRemoteDataSource>()
        .disconnectStream
        .listen((_) => _reconnectMessenger());
  }

  Future<void> _reconnectMessenger() async {
    if (!mounted) return;
    // Wait to see if socket.io auto-reconnects on its own
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    // Skip if socket already reconnected automatically
    if (sl<MessengerRemoteDataSource>().isSocketConnected) return;
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      if (token != null && mounted) {
        context.read<MessengerBloc>().add(ConnectMessenger(token, userId: userId));
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // _pendingCallRoute is set only from the cold-start initState postFrameCallback
      // (when lifecycle was not yet resumed at that point). Navigation for the
      // backgrounded-app accept path is handled by _navigateWhenResumed in main.dart.
      final route = _pendingCallRoute;
      if (route != null) {
        _pendingCallRoute = null;
        // Also consume the static latch so _navigateWhenResumed (main.dart) doesn't
        // double-navigate — it checks the latch after the 200ms delay.
        NotificationService.consumePendingCallRoute();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try { context.push(route); } catch (_) {}
          }
        });
        return;
      }
      // Fallback: if _navigateWhenResumed in main.dart timed out while the phone
      // was locked, the static pending route still exists. Pick it up now that
      // the app is resumed (user unlocked the device after accepting CallKit).
      final staticRoute = NotificationService.consumePendingCallRoute();
      if (staticRoute != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try { context.push(staticRoute); } catch (_) {}
          }
        });
        return;
      }
      // Final fallback: check if CallKit has an active accepted call that
      // the EventChannel missed (iOS may not deliver EventChannel events
      // to suspended Flutter engine on locked screen).
      _checkActiveCallKitCalls();
      // Refresh badge counts when app resumes
      try {
        context.read<MessengerBloc>().add(LoadBadgeCounts());
      } catch (_) {}
      // Drain any outbox ops that piled up while the device was offline
      // or that landed in the queue without a connectivity event to flush them.
      try {
        sl<OutboxReplayService>().drain();
      } catch (_) {}
      // Resume wake word when app comes back to foreground
      _resumeWakeWordIfNeeded();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      WakeWordService.instance.pause();
    }
  }

  /// Check for active CallKit calls that weren't captured via EventChannel.
  /// When the iPhone is locked and the user accepts via CallKit, iOS may not
  /// deliver the actionCallAccept event to Flutter's EventChannel because the
  /// engine was suspended. This method polls CallKit's native state directly
  /// to detect such orphaned accepts and navigate to the voice screen.
  Future<bool> _checkActiveCallKitCalls() async {
    if (_waitingForCallAccept) return false;
    if (CallStateService.instance.isInCall) return false;
    try {
      final loc = GoRouter.of(context)
          .routerDelegate.currentConfiguration.uri.path;
      if (loc.startsWith('/dashboard/voice')) return false;
    } catch (_) {}

    try {
      final calls = await CallKitPlatform.instance.activeCalls();
      if (calls.isEmpty) return false;
      for (final raw in calls) {
        final call = Map<String, dynamic>.from(raw as Map);
        final extra = call['extra'] as Map?;
        final roomName = extra?['roomName'] as String?;
        final convId = extra?['conversationId'] as String?;
        final e2eeKey = extra?['e2eeKey'] as String?;
        if (roomName == null || roomName.isEmpty) continue;
        debugPrint('[CallKit] _checkActiveCallKitCalls: found orphaned call, room=$roomName');
        _waitingForCallAccept = true;
        // Group call orphan: route to the group active screen, NOT the
        // 1-on-1 voice screen. The 1-on-1 path below would call
        // `connectInBackground` which hits `/voice/rooms/{room}/join` —
        // wrong endpoint for a group LiveKit room — and push
        // `/dashboard/voice`, which renders the 1-on-1 UI on top of a
        // group room. The group active screen owns its own LiveKit
        // connection via the BLoC.
        if (roomName.startsWith('group-')) {
          final groupCallId = roomName.substring('group-'.length);
          if (groupCallId.isEmpty) continue;
          if (mounted) {
            context.push('/group-call/$groupCallId');
          }
          return true;
        }
        // Connect to LiveKit immediately if not already connected (1-on-1)
        if (!CallStateService.instance.isInCall) {
          CallStateService.instance.connectInBackground(roomName, convId, e2eeKey: e2eeKey);
        }
        final callerName = extra?['callerName'] as String? ?? call['nameCaller'] as String? ?? '';
        final callerAvatar = extra?['callerAvatar'] as String? ?? '';
        final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
        final calleeParam = callerName.isNotEmpty ? '&callee=${Uri.encodeComponent(callerName)}' : '';
        final avatarParam = callerAvatar.isNotEmpty ? '&calleeAvatar=${Uri.encodeComponent(callerAvatar)}' : '';
        final voiceRoute =
            '/dashboard/voice?room=$roomName&convId=${convId ?? ''}&incoming=1$e2eeParam$calleeParam$avatarParam';
        if (mounted) {
          context.push(voiceRoute);
        }
        return true;
      }
    } catch (e) {
      debugPrint('[CallKit] _checkActiveCallKitCalls error: $e');
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectSub?.cancel();
    _callEndedSub?.cancel();
    _callAnsweredSub?.cancel();
    _gcEndedSub?.cancel();
    _gcInviteSub?.cancel();
    _callkitSub?.cancel();
    _callAcceptTimer?.cancel();
    _shareIntentSub?.cancel();
    WakeWordService.instance.stop();
    NotificationService.setMissedCallCallback(null);
    NotificationService.setCalendarInviteCallback(null);
    super.dispose();
  }

  void _listenForShareIntent() {
    _shareIntentSub?.cancel();
    _shareIntentSub = ShareIntentService.instance.pendingFilesStream.listen((files) {
      if (!mounted || files.isEmpty) return;
      debugPrint('[Dashboard] Received ${files.length} shared files');
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<MessengerBloc>(),
            child: ShareTargetScreen(sharedFiles: files),
          ),
        ),
      );
    });
    // Check for initial files (app was cold-started via share)
    // Multiple checks with delays since getInitialMedia() is async
    for (final delay in [500, 1500, 3000]) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        final initial = ShareIntentService.instance.initialFiles;
        if (initial != null && initial.isNotEmpty) {
          ShareIntentService.instance.clearFiles();
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MessengerBloc>(),
                child: ShareTargetScreen(sharedFiles: initial),
              ),
            ),
          );
        }
      });
    }
  }

  void _startWakeWord() {
    WakeWordService.instance.start(
      onWakeWord: () {
        if (!mounted) return;
        final loc = GoRouter.of(context)
            .routerDelegate.currentConfiguration.uri.path;
        // Don't trigger during a call
        if (loc.startsWith('/dashboard/voice')) return;
        debugPrint('[WakeWord] Navigating to assistant from $loc');
        if (loc.startsWith(RouteConstants.assistantSession)) {
          // Already on the voice session screen — trigger connect directly
          AssistantScreen.triggerConnect();
        } else {
          // Navigate to the voice session screen — it auto-connects via
          // the flag (the assistant tab root is now the text chat).
          AssistantScreen.autoConnect = true;
          context.go(RouteConstants.assistantSession);
        }
      },
    );
  }

  void _resumeWakeWordIfNeeded() {
    final loc = GoRouter.of(context)
        .routerDelegate.currentConfiguration.uri.path;
    // Don't listen during an active call
    if (loc.startsWith('/dashboard/voice')) return;
    WakeWordService.instance.resume();
  }

  Future<void> _checkForUpdate() async {
    final info = await sl<UpdateCheckService>().checkForUpdate();
    if (info != null && info.isAvailable && mounted) {
      setState(() {
        _updateInfo = info;
        _updateDismissed = false;
      });
    }
  }

  Future<void> _connectMessenger() async {
    if (!mounted) return;
    final bloc = context.read<MessengerBloc>();
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      // Compare against the currently-connected userId, not just `isConnected`.
      // After logout + re-login as a different account the bloc's state still
      // shows isConnected=true (DisconnectMessenger is async and the dashboard
      // may rebuild before its handler runs), so the previous user's socket
      // would have stayed authenticated. Force reconnect when the identity
      // differs so outbound events carry the right JWT.
      if (bloc.state.isConnected &&
          userId != null &&
          bloc.state.currentUserId == userId) {
        return;
      }
      if (token != null && mounted) {
        bloc.add(ConnectMessenger(token, userId: userId));
      }
    } catch (_) {}
  }

  int _currentIndex(String location) {
    // Contacts is accessed from Calls tab — highlight Calls when on contacts
    if (location.startsWith(RouteConstants.contacts)) return 1;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  void _showIncomingCall(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    final fromName = data['fromUserName'] as String? ?? l10n.dashboardUser;
    final fromAvatar = data['fromUserAvatar'] as String?;
    final fromUserId = data['fromUserId'] as String? ?? '';
    final roomName = data['roomName'] as String? ?? '';
    final convId = data['conversationId'] as String? ?? '';
    final e2eeKey = data['e2eeKey'] as String?;

    // Glare: we're already dialling this same person while they're dialling us.
    // Suppress the regular ringing UI (CallKit + dialog with ringtone would
    // collide with our own outgoing call's ringback) and present a silent
    // choice dialog: pick up theirs (drops ours), or stay on ours (drops theirs).
    final outgoingPeer = CallStateService.instance.outgoingPeerId;
    if (fromUserId.isNotEmpty && outgoingPeer == fromUserId) {
      _handleCallGlare(
        context,
        fromName: fromName,
        fromAvatar: fromAvatar,
        incomingRoom: roomName,
        incomingConv: convId,
        incomingE2eeKey: e2eeKey,
      );
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
      return;
    }

    // If at max call lines, silently dismiss incoming call invite
    if (!CallStateService.instance.canAddLine) {
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
      return;
    }

    // If this call was already answered on another device, suppress
    if (_answeredOnOtherDevice.contains(roomName)) {
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
      return;
    }

    // If the user already accepted via CallKit (locked screen / background), don't
    // show the in-app dialog — socket may deliver a delayed call_invite after
    // Face ID unlock / socket reconnect, which would overlay the voice screen.
    if (_waitingForCallAccept) {
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
      return;
    }

    // Check if app is in the foreground
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isForegrounded = lifecycle == AppLifecycleState.resumed;

    if (isForegrounded) {
      // App is visible: show native call UI with ringtone + in-app dialog
      showCallkitIncoming(
        fromName: fromName,
        roomName: roomName,
        convId: convId,
        fromAvatar: fromAvatar,
      );
      _showIncomingCallDialog(
        context,
        fromName: fromName,
        fromAvatar: fromAvatar,
        roomName: roomName,
        convId: convId,
        e2eeKey: e2eeKey,
      );
    } else {
      // App is backgrounded/paused: use native CallKit UI
      showCallkitIncoming(
        fromName: fromName,
        roomName: roomName,
        convId: convId,
        fromAvatar: fromAvatar,
      );
    }
    if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
  }

  void _showIncomingCallDialog(
    BuildContext context, {
    required String fromName,
    String? fromAvatar,
    required String roomName,
    required String convId,
    String? e2eeKey,
  }) {
    // Deduplicate: don't show a second dialog for the same room
    if (_showingCallDialogRoom == roomName) return;
    _showingCallDialogRoom = roomName;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.call_rounded,
                size: 48,
                color: AppColors.of(context).primary,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.dashboardIncomingCall,
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                fromName,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      // Dismiss native CallKit ringing
                      CallKitPlatform.instance.endAllCalls();
                      // Notify caller that the call was declined
                      if (convId.isNotEmpty && roomName.isNotEmpty) {
                        try {
                          sl<MessengerRemoteDataSource>().sendCallEnded(convId, roomName);
                        } catch (_) {}
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.of(context).error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.dashboardDecline,
                          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      Navigator.of(context, rootNavigator: true).pop();
                      _acceptingInApp = true;
                      try {
                        await CallKitPlatform.instance.endCall(toCallkitId(roomName));
                      } catch (_) {}
                      try {
                        await CallKitPlatform.instance.endAllCalls();
                      } catch (_) {}
                      for (final delay in [500, 1500, 3000]) {
                        Future.delayed(Duration(milliseconds: delay), () {
                          try { CallKitPlatform.instance.endAllCalls(); } catch (_) {}
                        });
                      }
                      Future.delayed(const Duration(seconds: 5), () => _acceptingInApp = false);
                      final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
                      final calleeParam = fromName.isNotEmpty ? '&callee=${Uri.encodeComponent(fromName)}' : '';
                      final avatarParam = fromAvatar != null && fromAvatar.isNotEmpty ? '&calleeAvatar=${Uri.encodeComponent(fromAvatar)}' : '';
                      final uri = '/dashboard/voice?room=$roomName'
                          '${convId.isNotEmpty ? '&convId=$convId' : ''}&incoming=1$e2eeParam$calleeParam$avatarParam';
                      context.push(uri);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.dashboardAccept,
                          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (_showingCallDialogRoom == roomName) _showingCallDialogRoom = null;
    });
  }

  /// Glare handler: peer dialled us while we were dialling them. Silent dialog
  /// (no CallKit, no ringtone) with two clear actions.
  ///
  /// NOTE on edge case: if BOTH sides press the same button, both calls drop —
  /// each end-tears down the other side's room. Acceptable trade-off for v1
  /// since it requires symmetric near-simultaneous choices; can be replaced
  /// with deterministic resolution (e.g. lower userId wins) later if needed.
  void _handleCallGlare(
    BuildContext context, {
    required String fromName,
    String? fromAvatar,
    required String incomingRoom,
    required String incomingConv,
    String? incomingE2eeKey,
  }) {
    if (_showingCallDialogRoom == incomingRoom) return;
    _showingCallDialogRoom = incomingRoom;
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_calls_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                l10n.callGlareTitle(fromName),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.callGlareBody,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.callGlareKeepOwn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.callGlareSwitch),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((switchToTheirs) async {
      if (_showingCallDialogRoom == incomingRoom) _showingCallDialogRoom = null;
      final ds = sl<MessengerRemoteDataSource>();
      final cs = CallStateService.instance;
      if (switchToTheirs == true) {
        // Drop our outgoing on both ends, then accept theirs and navigate.
        final outLine = cs.activeLine;
        if (outLine != null && outLine.conversationId != null) {
          try { ds.sendCallEnded(outLine.conversationId!, outLine.roomName); } catch (_) {}
          try { await cs.endLine(outLine.roomName); } catch (_) {}
        }
        cs.clearOutgoing();
        try { ds.sendCallAnswered(incomingConv, incomingRoom); } catch (_) {}
        if (!mounted) return;
        final e2eeParam = incomingE2eeKey != null
            ? '&e2ee=${Uri.encodeComponent(incomingE2eeKey)}'
            : '';
        final calleeParam = fromName.isNotEmpty
            ? '&callee=${Uri.encodeComponent(fromName)}'
            : '';
        final avatarParam = fromAvatar != null && fromAvatar.isNotEmpty
            ? '&calleeAvatar=${Uri.encodeComponent(fromAvatar)}'
            : '';
        // context.go fully replaces the route stack — our outgoing voice
        // screen is popped (its dispose clears the outgoing marker) and
        // the incoming voice screen takes its place.
        context.go(
          '/dashboard/voice?room=$incomingRoom'
          '${incomingConv.isNotEmpty ? '&convId=$incomingConv' : ''}'
          '&incoming=1$e2eeParam$calleeParam$avatarParam',
        );
      } else {
        // Decline theirs, keep our outgoing alive.
        if (incomingConv.isNotEmpty && incomingRoom.isNotEmpty) {
          try { ds.sendCallEnded(incomingConv, incomingRoom); } catch (_) {}
        }
      }
    });
  }

  void _showCallLinesSheet(BuildContext context, List<CallLine> lines) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ...lines.map((line) {
              final isActive = !line.isOnHold;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? colors.primary : colors.surface,
                  child: Icon(
                    isActive ? Icons.call_rounded : Icons.pause_rounded,
                    color: isActive ? Colors.black : colors.textSecondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  line.calleeName ?? line.roomName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  isActive ? AppLocalizations.of(context)!.voiceActiveCall : AppLocalizations.of(context)!.voiceOnHold,
                  style: TextStyle(color: isActive ? colors.primary : colors.textSecondary, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (line.isOnHold)
                      IconButton(
                        icon: Icon(Icons.swap_calls_rounded, color: colors.primary),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await CallStateService.instance.holdAndSwitch(line.roomName);
                          if (context.mounted) {
                            context.go(
                              '/dashboard/voice?room=${line.roomName}${line.conversationId != null ? '&convId=${line.conversationId}' : ''}',
                            );
                          }
                        },
                      ),
                    if (!line.isOnHold)
                      IconButton(
                        icon: Icon(Icons.open_in_new_rounded, color: colors.primary),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go(
                            '/dashboard/voice?room=${line.roomName}${line.conversationId != null ? '&convId=${line.conversationId}' : ''}',
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.call_end_rounded, color: colors.error),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await CallStateService.instance.endLine(line.roomName);
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    // Pause wake word during active calls (mic conflict)
    if (location.startsWith('/dashboard/voice')) {
      WakeWordService.instance.pause();
    }

    return BlocListener<MessengerBloc, MessengerState>(
      listenWhen: (prev, curr) =>
          curr.pendingCallInvite != null &&
          prev.pendingCallInvite != curr.pendingCallInvite,
      listener: (context, state) {
        if (state.pendingCallInvite != null) {
          _showIncomingCall(context, state.pendingCallInvite!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: Column(
          children: [
            // Active call banner — visible on all tabs
            StreamBuilder<bool>(
              stream: CallStateService.instance.stateStream,
              initialData: CallStateService.instance.isInCall,
              builder: (context, snapshot) {
                final inCall = snapshot.data ?? false;
                if (!inCall) return const SizedBox.shrink();
                final cs = CallStateService.instance;
                final lines = cs.allLines;
                final heldCount = lines.where((l) => l.isOnHold).length;
                return GestureDetector(
                  onTap: () {
                    if (lines.length > 1) {
                      _showCallLinesSheet(context, lines);
                    } else {
                      final room = cs.roomName;
                      final convId = cs.conversationId;
                      if (room != null) {
                        context.go(
                          '/dashboard/voice?room=$room${convId != null ? '&convId=$convId' : ''}',
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: AppColors.of(context).primary,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                heldCount > 0
                                    ? '${l10n.dashboardActiveCall} · $heldCount ${l10n.voiceOnHold.toLowerCase()}'
                                    : l10n.dashboardActiveCall,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lines.length > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${lines.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Update available banner
            if (_updateInfo != null && _updateInfo!.isAvailable && !_updateDismissed)
              _UpdateBanner(
                version: _updateInfo!.latestVersion,
                downloadUrl: _updateInfo!.downloadUrl,
                notes: _updateInfo!.latestNotes(
                  Localizations.localeOf(context).languageCode,
                ),
                onDismiss: () => setState(() => _updateDismissed = true),
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatefulWidget {
  final String version;
  final String downloadUrl;
  final String? notes;
  final VoidCallback onDismiss;

  const _UpdateBanner({
    required this.version,
    required this.downloadUrl,
    required this.notes,
    required this.onDismiss,
  });

  @override
  State<_UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<_UpdateBanner> {
  double? _progress; // null = idle, 0..1 = downloading
  bool _installing = false;

  void _showWhatsNew(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final notes = widget.notes ?? '';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n.dashboardWhatsNewTitle(widget.version),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollCtrl,
                      child: Text(
                        notes,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadAndInstall() async {
    if (_progress != null || _installing) return;

    if (!Platform.isAndroid) {
      final uri = Uri.parse(widget.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    setState(() => _progress = 0);
    final displayName = 'talerid-${widget.version}.apk';
    try {
      final dir = await getTemporaryDirectory();
      final apkPath = '${dir.path}/taler_id_update.apk';

      await dio_pkg.Dio().download(
        widget.downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() { _progress = null; _installing = true; });

      final res = await ApkInstallerService.install(
        filePath: apkPath,
        displayName: displayName,
      );
      if (mounted) {
        setState(() { _installing = false; });
        _handleInstallResult(res, displayName);
      }
    } catch (_) {
      if (mounted) setState(() { _progress = null; _installing = false; });
    }
  }

  void _handleInstallResult(ApkInstallResponse res, String displayName) {
    final l10n = AppLocalizations.of(context)!;
    switch (res.status) {
      case ApkInstallStatus.success:
      case ApkInstallStatus.aborted:
        return;
      case ApkInstallStatus.conflict:
        _showInstallDialog(
          l10n.updateInstallConflictTitle,
          l10n.updateInstallConflictBody(displayName),
        );
        return;
      case ApkInstallStatus.downloadFailed:
      case ApkInstallStatus.incompatible:
      case ApkInstallStatus.blocked:
      case ApkInstallStatus.storage:
      case ApkInstallStatus.invalid:
      case ApkInstallStatus.failureUnknown:
        final reason = res.message.isNotEmpty ? res.message : res.status.name;
        _showInstallDialog(
          l10n.updateInstallFailedTitle,
          l10n.updateInstallFailedBody(reason, displayName),
        );
        return;
    }
  }

  void _showInstallDialog(String title, String body) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.updateInstallOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDownloading = _progress != null;

    return Container(
      width: double.infinity,
      color: const Color(0xFF1565C0),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDownloading
                              ? '${((_progress ?? 0) * 100).toStringAsFixed(0)}%  ${l10n.dashboardUpdateAvailable(widget.version)}'
                              : _installing
                                  ? l10n.dashboardInstalling
                                  : l10n.dashboardUpdateAvailable(widget.version),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (!isDownloading && !_installing && (widget.notes?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _showWhatsNew(context),
                            child: Text(
                              l10n.dashboardWhatsNew,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isDownloading && !_installing) ...[
                    TextButton(
                      onPressed: _downloadAndInstall,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l10n.dashboardUpdate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ] else if (isDownloading)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (isDownloading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3,
              ),
          ],
        ),
      ),
    );
  }
}
