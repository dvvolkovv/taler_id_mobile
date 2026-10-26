/// Regression (PROD, 2026-10-26): a call rang in the system call UI while the
/// app sat in the background; the user opened the app — from the launcher,
/// not with the notification's Accept — and landed in the conversation:
/// without a tap the app joined the room and told the caller it had answered.
/// The dashboard's resume check took every call the plugin lists for one
/// answered behind a locked screen, and Android lists a call from the moment
/// it starts ringing.
///
/// Opening the app while a call rings must offer the in-app choice instead:
/// nothing joins, the caller hears no answer, Decline / Accept on the sheet
/// do what they say, and the sheet goes away when the caller gives up — on
/// PROD the caller had hung up a second before the app was opened.
///
/// One emulator. The test is the callee (integration_test_2) and plays the
/// caller (integration_test) itself, over HTTP and the messenger socket.
/// Going to the background and back is simulated on the lifecycle channel;
/// the ringing notification and what the plugin reports are the real ones.
///
/// flutter drive --profile --driver=test_driver/integration_test.dart \
///   --target=integration_test/call_open_while_ringing_test.dart \
///   --flavor dev --dart-define=FLAVOR=dev \
///   --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:taler_id_mobile/core/config/app_config.dart';
import 'package:taler_id_mobile/core/platform/call_kit.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';
import 'package:taler_id_mobile/features/voice/presentation/screens/voice_call_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/main.dart' as app;

const _calleeEmail = 'integration_test_2@taler-test.com';
const _callerEmail = 'integration_test@taler-test.com';
const _pass = 'IntegrationTest123!';

/// The two test accounts' conversation on DEV (see CLAUDE.md).
const _convId = '91f97844-307b-4a20-ad62-c1d2820e627f';

/// integration_test dialling integration_test_2 the way the app does: a room
/// first, then `call_invite` on the messenger socket. Remembers which rooms
/// the server reported answered or ended to the caller.
class _Caller {
  _Caller._(this._dio, this._socket);

  final Dio _dio;
  final io.Socket _socket;
  final answered = <String>{};
  final ended = <String>{};

  static Future<_Caller> connect() async {
    final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
    final login = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': _callerEmail, 'password': _pass},
    );
    final token = login.data!['accessToken'] as String;
    dio.options.headers['Authorization'] = 'Bearer $token';
    final socket = io.io(
      '${AppConfig.baseUrl}/messenger',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    final caller = _Caller._(dio, socket);
    socket.on('call_answered', (d) => caller.answered.add((d as Map)['roomName'] as String));
    socket.on('call_ended', (d) => caller.ended.add((d as Map)['roomName'] as String));
    final connected = Completer<void>();
    socket.onConnect((_) {
      if (!connected.isCompleted) connected.complete();
    });
    socket.connect();
    await connected.future.timeout(const Duration(seconds: 20));
    return caller;
  }

  Future<String> dial() async {
    final res = await _dio.post<Map<String, dynamic>>('/voice/rooms', data: {});
    final room = res.data!['roomName'] as String;
    _socket.emit('call_invite', {'conversationId': _convId, 'roomName': room});
    return room;
  }

  void hangUp(String room) =>
      _socket.emit('call_ended', {'conversationId': _convId, 'roomName': room});

  void dispose() => _socket.dispose();
}

/// What Android reports when the app goes to the background and when the user
/// brings it back. The binding fills in the states in between.
Future<void> _lifecycle(WidgetTester tester, AppLifecycleState state) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

Future<bool> _ringing(String room) async {
  final calls = await CallKitPlatform.instance.activeCalls();
  return calls.any((c) => c is Map && (c['extra'] as Map?)?['roomName'] == room);
}

/// Polls without pumping: in the background no frames are drawn, and a pump
/// would wait for one forever.
Future<bool> _eventually(FutureOr<bool> Function() check,
    {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (await check()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  return check();
}

extension on WidgetTester {
  Future<bool> waitFor(Finder f, {Duration timeout = const Duration(seconds: 15)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 300));
      if (f.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> pumpFor(Duration d) async {
    final steps = d.inMilliseconds ~/ 1000;
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await pump();
    }
    final remaining = d.inMilliseconds % 1000;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
      await pump();
    }
  }

  Future<bool> safeTap(Finder f) async {
    if (f.evaluate().isNotEmpty) {
      await tap(f.first, warnIfMissed: false);
      await pumpFor(const Duration(seconds: 2));
      return true;
    }
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opening the app while a call rings offers the choice and joins nothing',
      (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('google_fonts') || msg.contains('GoogleFonts') ||
          msg.contains('firebase') || msg.contains('FIS_AUTH') ||
          msg.contains('HandshakeException')) {
        return;
      }
      originalOnError?.call(details);
    };

    app.main();
    await tester.pumpFor(const Duration(seconds: 6));

    // Skip onboarding
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Next').evaluate().isNotEmpty) {
        for (var i = 0; i < 5; i++) {
          await tester.safeTap(find.text('Next'));
        }
        await tester.safeTap(find.text('Get Started'));
        await tester.safeTap(find.text('Skip'));
        break;
      }
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Skip'));
        break;
      }
      if (find.byType(TextFormField).evaluate().isNotEmpty) break;
    }

    // Login. Through the fields' controllers, not tester.enterText: that one
    // reaches the field only in a debug build (the text input accepts its
    // client id -1 inside an assert), and this test runs in profile — debug
    // eats the emulator's memory.
    if (await tester.waitFor(find.byType(TextFormField), timeout: const Duration(seconds: 10))) {
      final fields = find.byType(TextFormField);
      for (final (i, text) in [(0, _calleeEmail), (1, _pass)]) {
        tester
            .widget<EditableText>(
                find.descendant(of: fields.at(i), matching: find.byType(EditableText)))
            .controller
            .text = text;
      }
      await tester.pumpFor(const Duration(seconds: 1));
      final loginBtn = find.byType(ElevatedButton);
      await tester.ensureVisible(loginBtn.first);
      await tester.pumpFor(const Duration(milliseconds: 500));
      await tester.tap(loginBtn.first, warnIfMissed: false);
    }

    // Whatever a fresh install shows after login (as in app_test.dart):
    // onboarding, PIN setup, prompts to skip.
    await tester.pumpFor(const Duration(seconds: 3));
    var hasDash = false;
    final reachDeadline = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(reachDeadline)) {
      await tester.pump(const Duration(milliseconds: 400));
      if (find.byIcon(Icons.chat_bubble_outline_rounded).evaluate().isNotEmpty) {
        hasDash = true;
        break;
      }
      if (find.text('Next').evaluate().isNotEmpty) {
        await tester.safeTap(find.text('Next'));
        continue;
      }
      if (find.text('1').evaluate().isNotEmpty && find.text('5').evaluate().isNotEmpty) {
        for (var i = 0; i < 8; i++) {
          await tester.tap(find.text('1').first, warnIfMissed: false);
          await tester.pumpFor(const Duration(milliseconds: 400));
        }
        await tester.pumpFor(const Duration(seconds: 3));
        continue;
      }
      for (final label in const [
        'Get Started', 'Позже', 'Skip', 'Not now', 'Пропустить', 'Later',
        'ОК', 'OK', 'Понятно', 'Got it', 'Закрыть',
      ]) {
        if (await tester.safeTap(find.text(label))) break;
      }
    }
    expect(hasDash, isTrue, reason: 'Dashboard not found');
    // The messenger socket connects after the dashboard appears.
    await tester.pumpFor(const Duration(seconds: 5));

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
    Finder onSheet(String text) =>
        find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

    // Calls left ringing by an earlier run would be picked up first.
    await CallKitPlatform.instance.endAllCalls();
    final caller = await _Caller.connect();
    addTearDown(caller.dispose);

    // ── 1. A call rings while the app is in the background; it is opened ──
    await _lifecycle(tester, AppLifecycleState.paused);
    final declined = await caller.dial();
    addTearDown(() => caller.hangUp(declined));
    debugPrint('[OPEN-RINGING] dialled $declined');
    expect(await _eventually(() => _ringing(declined)), isTrue,
        reason: 'the call never rang on this device');
    await _lifecycle(tester, AppLifecycleState.resumed);

    // Long enough for the old behaviour to show: on PROD it joined the room
    // 2 s after the app was opened and told the caller 9 s after that.
    await tester.pumpFor(const Duration(seconds: 12));
    expect(caller.answered, isNot(contains(declined)),
        reason: 'the app told the caller it answered — nobody tapped Accept');
    expect(CallStateService.instance.isInCall || CallStateService.instance.isBackgroundConnecting,
        isFalse,
        reason: 'the app joined the room — nobody tapped Accept');
    expect(find.byType(VoiceCallScreen), findsNothing);
    expect(onSheet(l10n.dashboardIncomingCall), findsOneWidget,
        reason: 'no in-app choice to answer or decline');
    expect(await _ringing(declined), isTrue, reason: 'the system call stopped ringing');

    // ── 2. Decline on the sheet ──
    await tester.tap(onSheet(l10n.dashboardDecline));
    await tester.pumpFor(const Duration(seconds: 2));
    expect(await _eventually(() => caller.ended.contains(declined)), isTrue,
        reason: 'the caller was not told about the decline');
    expect(await _eventually(() async => !await _ringing(declined)), isTrue,
        reason: 'the system call kept ringing after Decline');
    expect(find.byType(BottomSheet), findsNothing);
    expect(caller.answered, isNot(contains(declined)));

    // ── 3. The caller gives up while the sheet is up ──
    await _lifecycle(tester, AppLifecycleState.paused);
    final abandoned = await caller.dial();
    addTearDown(() => caller.hangUp(abandoned));
    debugPrint('[OPEN-RINGING] dialled $abandoned');
    expect(await _eventually(() => _ringing(abandoned)), isTrue,
        reason: 'the second call never rang on this device');
    await _lifecycle(tester, AppLifecycleState.resumed);
    expect(await tester.waitFor(onSheet(l10n.dashboardIncomingCall)), isTrue,
        reason: 'no in-app choice for the second call');
    caller.hangUp(abandoned);
    var sheetGone = false;
    for (var i = 0; i < 20 && !sheetGone; i++) {
      await tester.pumpFor(const Duration(milliseconds: 500));
      sheetGone = find.byType(BottomSheet).evaluate().isEmpty;
    }
    expect(sheetGone, isTrue, reason: 'the sheet outlived the call');
    expect(await _eventually(() async => !await _ringing(abandoned)), isTrue,
        reason: 'the system call kept ringing after the caller hung up');
    expect(caller.answered, isNot(contains(abandoned)));

    // ── 4. Again, and Accept on the sheet ──
    await _lifecycle(tester, AppLifecycleState.paused);
    final accepted = await caller.dial();
    addTearDown(() => caller.hangUp(accepted));
    debugPrint('[OPEN-RINGING] dialled $accepted');
    expect(await _eventually(() => _ringing(accepted)), isTrue,
        reason: 'the third call never rang on this device');
    await _lifecycle(tester, AppLifecycleState.resumed);
    expect(await tester.waitFor(onSheet(l10n.dashboardAccept)), isTrue,
        reason: 'no in-app choice for the third call');
    // The sheet is in the tree while it still slides in from below the
    // screen, and a tap there misses.
    await tester.pumpFor(const Duration(seconds: 2));
    await tester.tap(onSheet(l10n.dashboardAccept));
    expect(await tester.waitFor(find.byType(VoiceCallScreen), timeout: const Duration(seconds: 10)),
        isTrue,
        reason: 'Accept did not open the call');
    expect(await _eventually(() => caller.answered.contains(accepted)), isTrue,
        reason: 'the caller was not told about the answer');

    caller.hangUp(accepted);
    await tester.pumpFor(const Duration(seconds: 3));
    FlutterError.onError = originalOnError;
  });
}
