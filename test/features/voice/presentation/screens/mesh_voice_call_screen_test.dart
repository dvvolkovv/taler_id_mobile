import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/mesh/voice/mesh_voice_state.dart';
import 'package:taler_id_mobile/features/voice/presentation/screens/mesh_voice_call_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

PeerId _peer() =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + 100)));

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: child,
    );

void main() {
  group('MeshVoiceCallScreen', () {
    testWidgets('renders "Вызов…" status during InvitingState', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(_wrap(MeshVoiceCallScreen(
        stateStream: ctrl.stream,
        peer: _peer(),
        peerName: 'Alice',
        peerAvatarUrl: null,
        transportName: 'Bonjour',
        onMuteToggle: () async {},
        onHangup: () async {},
      )));
      ctrl.add(InvitingState(
          calleeDevicePk: _peer(), callId: 1, sentAt: DateTime.utc(2026)));
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Вызов…'), findsOneWidget);
      expect(find.textContaining('Mesh · Bonjour'), findsOneWidget);
    });

    testWidgets('renders timer during ActiveState', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(_wrap(MeshVoiceCallScreen(
        stateStream: ctrl.stream,
        peer: _peer(),
        peerName: 'Alice',
        peerAvatarUrl: null,
        transportName: 'BLE',
        onMuteToggle: () async {},
        onHangup: () async {},
      )));
      ctrl.add(ActiveState(
          peerDevicePk: _peer(),
          callId: 1,
          isCaller: true,
          startedAt: DateTime.now()));
      await tester.pump();
      expect(find.textContaining('0:0'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('0:0'), findsOneWidget);
    });

    testWidgets('hangup tap fires onHangup callback', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      var hung = 0;
      await tester.pumpWidget(_wrap(MeshVoiceCallScreen(
        stateStream: ctrl.stream,
        peer: _peer(),
        peerName: 'A',
        peerAvatarUrl: null,
        transportName: null,
        onMuteToggle: () async {},
        onHangup: () async => hung++,
      )));
      ctrl.add(ActiveState(
          peerDevicePk: _peer(),
          callId: 1,
          isCaller: false,
          startedAt: DateTime.now()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mesh-call-hangup')));
      await tester.pump();
      expect(hung, 1);
    });

    testWidgets('mute toggle fires onMuteToggle callback', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      var toggled = 0;
      await tester.pumpWidget(_wrap(MeshVoiceCallScreen(
        stateStream: ctrl.stream,
        peer: _peer(),
        peerName: 'A',
        peerAvatarUrl: null,
        transportName: null,
        onMuteToggle: () async => toggled++,
        onHangup: () async {},
      )));
      ctrl.add(ActiveState(
          peerDevicePk: _peer(),
          callId: 1,
          isCaller: true,
          startedAt: DateTime.now()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mesh-call-mute')));
      await tester.pump();
      expect(toggled, 1);
    });

    testWidgets('EndedState shows reason-specific status text', (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(_wrap(MeshVoiceCallScreen(
        stateStream: ctrl.stream,
        peer: _peer(),
        peerName: 'A',
        peerAvatarUrl: null,
        transportName: null,
        onMuteToggle: () async {},
        onHangup: () async {},
      )));
      ctrl.add(EndedState(callId: 1, reason: EndReason.noKeepalive));
      await tester.pump();
      expect(find.text('Соединение потеряно'), findsOneWidget);
    });

    testWidgets('auto-pops the route after EndedState (using shortened delay)',
        (tester) async {
      final ctrl = StreamController<CallState>.broadcast();
      addTearDown(ctrl.close);
      final navObserver = _PopObserver();
      await tester.pumpWidget(_wrap(Builder(
        builder: (ctx) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => MeshVoiceCallScreen(
                stateStream: ctrl.stream,
                peer: _peer(),
                peerName: 'A',
                peerAvatarUrl: null,
                transportName: null,
                onMuteToggle: () async {},
                onHangup: () async {},
                popDelay: const Duration(milliseconds: 50),
              ),
            )),
            child: const Text('go'),
          ),
        ),
      )));
      // Note: the navObserver is attached via the navigator inside MaterialApp,
      // but _wrap doesn't give us a way to attach navigatorObservers. Instead,
      // test that the screen pops by checking pumpAndSettle removes it.
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mesh-call-hangup')), findsOneWidget);
      ctrl.add(EndedState(callId: 1, reason: EndReason.userHangup));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mesh-call-hangup')), findsNothing);
    });
  });
}

class _PopObserver extends NavigatorObserver {
  bool popped = false;
  @override
  void didPop(Route route, Route? previousRoute) {
    popped = true;
    super.didPop(route, previousRoute);
  }
}
