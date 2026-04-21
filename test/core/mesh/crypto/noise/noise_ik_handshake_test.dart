import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/mesh/crypto/noise/noise_ik_handshake.dart';

Future<(Uint8List, Uint8List)> _x25519Keypair() async {
  final kp = await X25519().newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
}

void main() {
  group('NoiseIKHandshake', () {
    test('full handshake produces symmetric transport keys', () async {
      final (initStaticPriv, initStaticPub) = await _x25519Keypair();
      final (respStaticPriv, respStaticPub) = await _x25519Keypair();

      final initiator = await NoiseIKHandshake.startInitiator(
        initiatorStaticPrivateKey: initStaticPriv,
        initiatorStaticPublicKey: initStaticPub,
        responderStaticPublicKey: respStaticPub,
        prologue: Uint8List(0),
      );
      final msg1 = await initiator.writeMessage1(
        payload: Uint8List.fromList(utf8.encode('hi')),
      );
      expect(msg1.length, greaterThan(32)); // contains at least e + payload

      final responder = await NoiseIKHandshake.startResponder(
        responderStaticPrivateKey: respStaticPriv,
        responderStaticPublicKey: respStaticPub,
        prologue: Uint8List(0),
      );
      final (payloadFromInit, _) = await responder.readMessage1(msg1);
      expect(utf8.decode(payloadFromInit), equals('hi'));

      final msg2 = await responder.writeMessage2(
        payload: Uint8List.fromList(utf8.encode('ack')),
      );
      final responderKeys = responder.finalize();
      final payloadReceived = await initiator.readMessage2(msg2);
      expect(utf8.decode(payloadReceived), equals('ack'));
      final initiatorKeys = initiator.finalize();

      // Both parties derive identical (k1, k2) bytes.
      expect(initiatorKeys.$1, equals(responderKeys.$1));
      expect(initiatorKeys.$2, equals(responderKeys.$2));

      // Responder learned initiator's static pk during msg1.
      expect(responder.remoteStaticPublicKey, equals(initStaticPub));
    });

    test('handshake fails if initiator uses wrong responder static pk', () async {
      final (initStaticPriv, initStaticPub) = await _x25519Keypair();
      final (respStaticPriv, respStaticPub) = await _x25519Keypair();
      final (_, wrongRespPub) = await _x25519Keypair();

      final initiator = await NoiseIKHandshake.startInitiator(
        initiatorStaticPrivateKey: initStaticPriv,
        initiatorStaticPublicKey: initStaticPub,
        responderStaticPublicKey: wrongRespPub,
        prologue: Uint8List(0),
      );
      final msg1 = await initiator.writeMessage1(payload: Uint8List(0));

      final responder = await NoiseIKHandshake.startResponder(
        responderStaticPrivateKey: respStaticPriv,
        responderStaticPublicKey: respStaticPub,
        prologue: Uint8List(0),
      );
      await expectLater(responder.readMessage1(msg1), throwsA(isA<Exception>()));
    });
  });
}
