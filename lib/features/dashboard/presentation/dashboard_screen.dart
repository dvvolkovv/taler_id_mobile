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
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/services/call_state_service.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// Note: do NOT use FlutterCallkitIncoming.onEvent directly here — see _setupCallkitListener
// in main.dart. Use NotificationService.callEvents (the shared broadcast proxy) instead.
import '../../../core/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/update_check_service.dart';
import '../../../core/services/share_intent_service.dart';
import '../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../messenger/presentation/screens/share_target_screen.dart';
import '../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../messenger/presentation/bloc/messenger_event.dart';
import '../../messenger/presentation/bloc/messenger_state.dart';

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
  StreamSubscription? _callkitSub;
  StreamSubscription? _shareIntentSub;
  String? _showingCallDialogRoom;
  String? _pendingCallRoute; // queued when accept fires while phone is locked
  bool _waitingForCallAccept = false; // blocks in-app dialog after CallKit accept
  bool _acceptingInApp = false; // suppresses actionCallDecline after in-app accept
  bool _endingCallKitFromSocket = false; // suppresses actionCallDecline when CallKit ended by socket call_ended
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
    _callkitSub = NotificationService.callEvents.listen((CallEvent? event) async {
      if (event == null) return;
      final extra = event.body['extra'] as Map?;
      final roomName = extra?['roomName'] as String?;
      final convId = extra?['conversationId'] as String?;

      if (event.event == Event.actionCallAccept) {
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
      } else if (event.event == Event.actionCallDecline ||
                 event.event == Event.actionCallTimeout) {
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
          final callId = (event.body['id'] ?? event.body['uuid']) as String?;
          if (callId != null) {
            FlutterCallkitIncoming.endCall(callId);
          } else {
            FlutterCallkitIncoming.endAllCalls();
          }
        }
      } else if (event.event == Event.actionCallEnded) {
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
      NotificationService.refreshToken();
      _connectMessenger();
      _listenForDisconnect();
      _listenForCallEnded();
      _listenForCallAnswered();
      _listenForShareIntent();
      _checkForUpdate();
    });
  }

  void _listenForCallEnded() {
    _callEndedSub?.cancel();
    _callEndedSub = sl<MessengerRemoteDataSource>()
        .callEndedStream
        .listen((roomName) async {
      debugPrint('[Dashboard] callEndedStream fired: roomName=$roomName');
      final wasInCallRoom = CallStateService.instance.roomName;
      final isOurCall = wasInCallRoom != null && wasInCallRoom == roomName;

      // Always dismiss a pending incoming call invite from the UI.
      debugPrint('[Dashboard] dismissing call invite, wasInCallRoom=$wasInCallRoom, isOurCall=$isOurCall, showingDialog=$_showingCallDialogRoom');
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
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

  void _listenForCallAnswered() {
    _callAnsweredSub?.cancel();
    _callAnsweredSub = sl<MessengerRemoteDataSource>()
        .callAnsweredStream
        .listen((roomName) async {
      // Ignore own broadcast — sendCallAnswered echoes back to the sender via
      // the server room broadcast. If we are already in this call, skip.
      if (CallStateService.instance.roomName == roomName) return;
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
      final calls = await FlutterCallkitIncoming.activeCalls() as List;
      for (final call in calls) {
        final callMap = call as Map;
        final extra = callMap['extra'] as Map?;
        final callRoom = extra?['roomName'] as String?;
        if (callRoom == roomName) {
          await FlutterCallkitIncoming.endCall(callMap['id'] as String);
          return;
        }
      }
      // No matching call found by roomName
      if (fallbackEndAll || wasInCallRoom == roomName) {
        await FlutterCallkitIncoming.endAllCalls();
      }
      // Otherwise: stale/unrelated event — leave other CallKit calls untouched
    } catch (_) {
      if (fallbackEndAll || wasInCallRoom == roomName) {
        FlutterCallkitIncoming.endAllCalls();
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
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List || calls.isEmpty) return false;
      for (final raw in calls) {
        final call = Map<String, dynamic>.from(raw as Map);
        final extra = call['extra'] as Map?;
        final roomName = extra?['roomName'] as String?;
        final convId = extra?['conversationId'] as String?;
        final e2eeKey = extra?['e2eeKey'] as String?;
        if (roomName == null || roomName.isEmpty) continue;
        debugPrint('[CallKit] _checkActiveCallKitCalls: found orphaned call, room=$roomName');
        _waitingForCallAccept = true;
        // Connect to LiveKit immediately if not already connected
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
    _callkitSub?.cancel();
    _callAcceptTimer?.cancel();
    _shareIntentSub?.cancel();
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
    final initial = ShareIntentService.instance.initialFiles;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<MessengerBloc>(),
              child: ShareTargetScreen(sharedFiles: initial),
            ),
          ),
        );
      });
    }
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
    if (bloc.state.isConnected) return;
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
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
    final roomName = data['roomName'] as String? ?? '';
    final convId = data['conversationId'] as String? ?? '';
    final e2eeKey = data['e2eeKey'] as String?;

    // If already in a call, silently dismiss incoming call invite
    if (CallStateService.instance.isInCall) {
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
                      FlutterCallkitIncoming.endAllCalls();
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
                        await FlutterCallkitIncoming.endCall(toCallkitId(roomName));
                      } catch (_) {}
                      try {
                        await FlutterCallkitIncoming.endAllCalls();
                      } catch (_) {}
                      for (final delay in [500, 1500, 3000]) {
                        Future.delayed(Duration(milliseconds: delay), () {
                          try { FlutterCallkitIncoming.endAllCalls(); } catch (_) {}
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
                  isActive ? 'Active' : 'On hold',
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
                            context.push(
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
                          context.push(
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
    final currentIndex = _currentIndex(location);

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
                        context.push(
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
                                    ? '${l10n.dashboardActiveCall} · $heldCount on hold'
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
                onDismiss: () => setState(() => _updateDismissed = true),
              ),
            Expanded(child: widget.child),
          ],
        ),
        floatingActionButton: null,
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).surface.withOpacity(0.60),
                border: Border(
                  top: BorderSide(
                    color: AppColors.of(context).glassColor.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (i) => context.go(_tabs[i]),
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.of(context).accent,
                unselectedItemColor: AppColors.of(context).textSecondary,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                iconSize: 28,
                selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: BlocBuilder<MessengerBloc, MessengerState>(
                      buildWhen: (p, c) =>
                          p.conversations.fold<int>(0, (s, e) => s + e.unreadCount) !=
                          c.conversations.fold<int>(0, (s, e) => s + e.unreadCount),
                      builder: (ctx, state) {
                        final total =
                            state.conversations.fold<int>(0, (s, c) => s + c.unreadCount);
                        if (total == 0) {
                          return const Icon(Icons.chat_bubble_outline_rounded);
                        }
                        return Badge(
                          label: Text('$total'),
                          backgroundColor: AppColors.of(context).error,
                          child: const Icon(Icons.chat_bubble_outline_rounded),
                        );
                      },
                    ),
                    activeIcon: const Icon(Icons.chat_bubble_rounded),
                    label: l10n.tabMessenger,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.call_outlined),
                    activeIcon: const Icon(Icons.call),
                    label: l10n.tabCalls,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.headset_mic_outlined),
                    activeIcon: const Icon(Icons.headset_mic),
                    label: l10n.tabAssistant,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_month_outlined),
                    activeIcon: const Icon(Icons.calendar_month),
                    label: l10n.tabCalendar,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined),
                    activeIcon: const Icon(Icons.settings),
                    label: l10n.tabSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final String version;
  final String downloadUrl;
  final VoidCallback onDismiss;

  const _UpdateBanner({
    required this.version,
    required this.downloadUrl,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE65100),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.dashboardUpdateAvailable(version),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(AppLocalizations.of(context)!.dashboardUpdate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
