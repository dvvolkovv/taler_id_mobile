import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/voice/presentation/widgets/mesh_incoming_call_sheet.dart';

PeerId _peer() =>
    PeerId(Uint8List.fromList(List<int>.generate(32, (i) => i + 100)));

void main() {
  group('MeshIncomingCallSheet', () {
    testWidgets('renders peer name and avatar URL when provided',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'Alice',
            peerAvatarUrl: 'https://example.com/a.png',
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('📡 Входящий mesh-звонок'), findsOneWidget);
    });

    testWidgets('falls back to "Mesh-устройство <hex>" when peerName is null',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: null,
            peerAvatarUrl: null,
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ));
      expect(find.textContaining('Mesh-устройство'), findsOneWidget);
    });

    testWidgets('Accept button fires onAccept', (tester) async {
      var accepted = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'A',
            peerAvatarUrl: null,
            onAccept: () => accepted++,
            onDecline: () {},
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('mesh-incoming-accept')));
      await tester.pumpAndSettle();
      expect(accepted, 1);
    });

    testWidgets('Decline button fires onDecline', (tester) async {
      var declined = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'A',
            peerAvatarUrl: null,
            onAccept: () {},
            onDecline: () => declined++,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('mesh-incoming-decline')));
      await tester.pumpAndSettle();
      expect(declined, 1);
    });

    testWidgets('30s auto-decline calls onDecline (using shortened timer)',
        (tester) async {
      var declined = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MeshIncomingCallSheet(
            peer: _peer(),
            peerName: 'A',
            peerAvatarUrl: null,
            onAccept: () {},
            onDecline: () => declined++,
            autoDeclineAfter: const Duration(milliseconds: 50),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(declined, 1);
    });
  });
}
