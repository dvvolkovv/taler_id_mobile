import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'noise_symmetric.dart';

const String _protocolName = 'Noise_IK_25519_ChaChaPoly_SHA256';

/// Noise IK handshake pattern (spec section 7.5):
///
///   IK:
///     <- s              // responder's static pk is pre-known to initiator
///     ...
///     -> e, es, s, ss
///     <- e, ee, se
///
/// After the handshake both sides call `finalize()` to obtain
/// `(k1, k2)` = two 32-byte transport keys.
///   - Initiator uses `k1` as send key, `k2` as recv key.
///   - Responder uses `k1` as recv key, `k2` as send key.
///   - The bytes of `k1` and `k2` are equal on both sides.
class NoiseIKHandshake {
  static final _x25519 = X25519();

  final NoiseSymmetricState _ss;
  final Uint8List _staticPriv;
  final Uint8List _staticPub;
  final bool _isInitiator;

  Uint8List? _remoteStaticPub;
  Uint8List? _ephemeralPriv;
  Uint8List? _ephemeralPub;
  Uint8List? _remoteEphemeralPub;

  NoiseIKHandshake._({
    required NoiseSymmetricState ss,
    required Uint8List staticPriv,
    required Uint8List staticPub,
    required bool isInitiator,
    Uint8List? remoteStaticPub,
  })  : _ss = ss,
        _staticPriv = staticPriv,
        _staticPub = staticPub,
        _isInitiator = isInitiator,
        _remoteStaticPub = remoteStaticPub;

  /// The remote peer's static public key — set after `readMessage1` on the
  /// responder side (i.e. the initiator's static pk learned during handshake).
  Uint8List? get remoteStaticPublicKey => _remoteStaticPub;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Initiator setup.  The initiator already knows the responder's static pk.
  static Future<NoiseIKHandshake> startInitiator({
    required Uint8List initiatorStaticPrivateKey,
    required Uint8List initiatorStaticPublicKey,
    required Uint8List responderStaticPublicKey,
    required Uint8List prologue,
  }) async {
    final ss = NoiseSymmetricState.initializeSymmetric(_protocolName);
    ss.mixHash(prologue);
    // Pre-message: <- s  (responder's static pk is pre-known)
    ss.mixHash(responderStaticPublicKey);
    return NoiseIKHandshake._(
      ss: ss,
      staticPriv: initiatorStaticPrivateKey,
      staticPub: initiatorStaticPublicKey,
      isInitiator: true,
      remoteStaticPub: responderStaticPublicKey,
    );
  }

  /// Responder setup.  The responder does not yet know the initiator's static pk.
  static Future<NoiseIKHandshake> startResponder({
    required Uint8List responderStaticPrivateKey,
    required Uint8List responderStaticPublicKey,
    required Uint8List prologue,
  }) async {
    final ss = NoiseSymmetricState.initializeSymmetric(_protocolName);
    ss.mixHash(prologue);
    // Pre-message: <- s  (our own static pk)
    ss.mixHash(responderStaticPublicKey);
    return NoiseIKHandshake._(
      ss: ss,
      staticPriv: responderStaticPrivateKey,
      staticPub: responderStaticPublicKey,
      isInitiator: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Message 1 — initiator writes:  e, es, s, ss, payload
  // ---------------------------------------------------------------------------

  /// Initiator sends message 1.
  ///
  /// Wire layout:
  ///   [32B] ephemeral pk (plaintext)
  ///   [48B] encrypted initiator static pk  (32B pk + 16B Poly tag)
  ///   [len(payload)+16B] encrypted payload
  Future<Uint8List> writeMessage1({required Uint8List payload}) async {
    assert(_isInitiator, 'writeMessage1 called on non-initiator');

    final (ePriv, ePub) = await _newEphemeral();
    _ephemeralPriv = ePriv;
    _ephemeralPub = ePub;

    final buf = BytesBuilder();

    // → e
    buf.add(ePub);
    _ss.mixHash(ePub);

    // → es : DH(init_ephem_priv, resp_static_pub)
    final es = await _dh(myPriv: ePriv, remotePub: _remoteStaticPub!);
    _ss.mixKey(es);

    // → s  : encrypted initiator static pk
    final sEnc = await _ss.encryptAndHash(_staticPub);
    buf.add(sEnc);

    // → ss : DH(init_static_priv, resp_static_pub)
    final ss = await _dh(myPriv: _staticPriv, remotePub: _remoteStaticPub!);
    _ss.mixKey(ss);

    // → payload
    final plEnc = await _ss.encryptAndHash(payload);
    buf.add(plEnc);

    return buf.toBytes();
  }

  // ---------------------------------------------------------------------------
  // Message 1 — responder reads
  // ---------------------------------------------------------------------------

  /// Responder reads message 1.
  ///
  /// Returns `(decrypted_payload, _)`.
  /// After return, `remoteStaticPublicKey` is populated with the initiator's
  /// static pk.
  ///
  /// Throws [Exception] (AEAD auth failure) if the initiator used a wrong
  /// responder static key — the decryption of `s` or `payload` will fail.
  Future<(Uint8List, void)> readMessage1(Uint8List msg) async {
    assert(!_isInitiator, 'readMessage1 called on non-responder');

    // Minimum length: 32 (e) + 48 (s-enc = 32pk+16tag) + 16 (empty-payload tag)
    if (msg.length < 32 + 48 + 16) {
      throw FormatException(
        'IK msg1 too short: ${msg.length} < ${32 + 48 + 16}',
      );
    }

    // ← e
    final ePub = Uint8List.fromList(msg.sublist(0, 32));
    _remoteEphemeralPub = ePub;
    _ss.mixHash(ePub);

    // ← es : DH(resp_static_priv, init_ephem_pub) == same shared as DH(e, rs)
    final es = await _dh(myPriv: _staticPriv, remotePub: ePub);
    _ss.mixKey(es);

    // ← s  : decrypt initiator static pk
    final sBlock = Uint8List.fromList(msg.sublist(32, 32 + 48));
    final sPub = await _ss.decryptAndHash(sBlock); // throws on bad auth tag
    _remoteStaticPub = sPub;

    // ← ss : DH(resp_static_priv, init_static_pub)
    final ss = await _dh(myPriv: _staticPriv, remotePub: sPub);
    _ss.mixKey(ss);

    // ← payload
    final payloadEnc = Uint8List.fromList(msg.sublist(32 + 48));
    final payload = await _ss.decryptAndHash(payloadEnc);

    return (payload, null);
  }

  // ---------------------------------------------------------------------------
  // Message 2 — responder writes:  e, ee, se, payload
  // ---------------------------------------------------------------------------

  /// Responder sends message 2.
  ///
  /// Wire layout:
  ///   [32B] responder ephemeral pk (plaintext)
  ///   [len(payload)+16B] encrypted payload
  Future<Uint8List> writeMessage2({required Uint8List payload}) async {
    assert(!_isInitiator, 'writeMessage2 called on non-responder');

    final (ePriv, ePub) = await _newEphemeral();
    _ephemeralPriv = ePriv;
    _ephemeralPub = ePub;

    final buf = BytesBuilder();

    // ← e
    buf.add(ePub);
    _ss.mixHash(ePub);

    // ← ee : DH(resp_ephem_priv, init_ephem_pub)
    final ee = await _dh(myPriv: ePriv, remotePub: _remoteEphemeralPub!);
    _ss.mixKey(ee);

    // ← se : DH(resp_ephem_priv, init_static_pub)
    //   ("se" = resp-ephem × init-static; from spec: se means sender=initiator,
    //    responder performs DH(resp_ephem_priv, init_static_pub))
    final se = await _dh(myPriv: ePriv, remotePub: _remoteStaticPub!);
    _ss.mixKey(se);

    // ← payload
    final plEnc = await _ss.encryptAndHash(payload);
    buf.add(plEnc);

    return buf.toBytes();
  }

  // ---------------------------------------------------------------------------
  // Message 2 — initiator reads
  // ---------------------------------------------------------------------------

  /// Initiator reads message 2.  Returns decrypted payload.
  Future<Uint8List> readMessage2(Uint8List msg) async {
    assert(_isInitiator, 'readMessage2 called on non-initiator');

    // Minimum: 32 (e) + 16 (empty-payload tag)
    if (msg.length < 32 + 16) {
      throw FormatException(
        'IK msg2 too short: ${msg.length} < ${32 + 16}',
      );
    }

    // → e
    final ePub = Uint8List.fromList(msg.sublist(0, 32));
    _remoteEphemeralPub = ePub;
    _ss.mixHash(ePub);

    // → ee : DH(init_ephem_priv, resp_ephem_pub)
    final ee = await _dh(myPriv: _ephemeralPriv!, remotePub: ePub);
    _ss.mixKey(ee);

    // → se : DH(init_static_priv, resp_ephem_pub)
    //   ("se" from initiator side: DH(init_static_priv, resp_ephem_pub))
    final se = await _dh(myPriv: _staticPriv, remotePub: ePub);
    _ss.mixKey(se);

    // → payload
    final payloadEnc = Uint8List.fromList(msg.sublist(32));
    return _ss.decryptAndHash(payloadEnc);
  }

  // ---------------------------------------------------------------------------
  // Finalization
  // ---------------------------------------------------------------------------

  /// Returns `(k1, k2)` transport keys via `ck.split()`.
  ///
  /// Call only after the complete two-message handshake:
  ///   - Initiator: after `readMessage2`
  ///   - Responder: after `writeMessage2`
  ///
  /// Convention (mirrors Noise spec § 7.5):
  ///   - Initiator: k1 = send key, k2 = recv key
  ///   - Responder: k1 = recv key, k2 = send key
  (Uint8List, Uint8List) finalize() => _ss.split();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<(Uint8List, Uint8List)> _newEphemeral() async {
    final kp = await _x25519.newKeyPair();
    final priv = await kp.extractPrivateKeyBytes();
    final pub = await kp.extractPublicKey();
    return (Uint8List.fromList(priv), Uint8List.fromList(pub.bytes));
  }

  /// Performs X25519 DH with `myPriv` (private bytes) and `remotePub` (public
  /// bytes).  The local public key is derived from `myPriv` by the library
  /// internally, so we don't need to pass `myPub`.
  Future<Uint8List> _dh({
    required Uint8List myPriv,
    required Uint8List remotePub,
  }) async {
    // We need to supply the matching public key; derive it first.
    final tempKp = await _x25519.newKeyPairFromSeed(myPriv);
    final myPub = await tempKp.extractPublicKey();

    final kpData = SimpleKeyPairData(
      myPriv,
      publicKey: SimplePublicKey(myPub.bytes, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final shared = await _x25519.sharedSecretKey(
      keyPair: kpData,
      remotePublicKey: SimplePublicKey(remotePub, type: KeyPairType.x25519),
    );
    final bytes = await shared.extractBytes();
    return Uint8List.fromList(bytes);
  }
}
