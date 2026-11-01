import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:wakelock_plus/wakelock_plus.dart';

/// Owns the device-level side effects of an interpreter conversation:
/// earpiece output, the wakelock that keeps the screen alive while the phone
/// isn't at the ear, (Android only) the foreground service that keeps the
/// microphone running while the app is backgrounded, and — separately, via
/// [setNearEarScreenOff] — the proximity-triggered screen-off.
///
/// Proximity is deliberately not part of [enterConversation]: that runs
/// before the host's QR code is even shown, and the proximity sensor would
/// blank the screen while the user is still holding the phone up for the
/// partner to scan. Callers turn it on only once two people are actually
/// talking (host: after the partner joins; guest: after joining).
///
/// Every platform call is best-effort: a conversation must not crash because
/// a channel call failed or a plugin is missing (e.g. in tests), so failures
/// are logged via [debugPrint] and swallowed, mirroring how the rest of the
/// codebase treats these channels.
class InterpreterDevice {
  static const _channelName = 'taler_id/interpreter_device';

  InterpreterDevice({
    MethodChannel? channel,
    bool? isAndroid,
    bool Function()? getPreferSpeakerOutput,
    Future<void> Function(bool on)? setSpeakerphoneOn,
    Future<void> Function()? wakelockEnable,
    Future<void> Function()? wakelockDisable,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _isAndroid =
            isAndroid ?? (defaultTargetPlatform == TargetPlatform.android),
        _getPreferSpeakerOutput = getPreferSpeakerOutput ??
            (() => lk.Hardware.instance.preferSpeakerOutput),
        _setSpeakerphoneOn = setSpeakerphoneOn ??
            ((on) => lk.Hardware.instance.setSpeakerphoneOn(on)),
        _wakelockEnable = wakelockEnable ?? WakelockPlus.enable,
        _wakelockDisable = wakelockDisable ?? WakelockPlus.disable;

  final MethodChannel _channel;
  final bool _isAndroid;
  final bool Function() _getPreferSpeakerOutput;
  final Future<void> Function(bool on) _setSpeakerphoneOn;
  final Future<void> Function() _wakelockEnable;
  final Future<void> Function() _wakelockDisable;

  bool _active = false;
  bool? _rememberedSpeakerPref;

  /// Switches the device into "interpreter conversation" mode. Idempotent —
  /// calling it again while already active does nothing. Does not touch the
  /// proximity sensor — see [setNearEarScreenOff].
  Future<void> enterConversation() async {
    if (_active) return;
    _active = true;
    _rememberedSpeakerPref = _getPreferSpeakerOutput();
    // Earpiece by default; a connected headset still wins over this.
    await _guard(() => _setSpeakerphoneOn(false));
    await _guard(_wakelockEnable);
    if (_isAndroid) {
      await _guard(() => _channel.invokeMethod<void>('startForeground'));
    }
  }

  /// Reverses [enterConversation] and, idempotently, also turns the
  /// proximity sensor off regardless of whether [setNearEarScreenOff] was
  /// ever called — a conversation must never leave the screen locked off.
  /// Never throws.
  Future<void> leaveConversation() async {
    if (!_active) return;
    _active = false;
    if (_isAndroid) {
      await _guard(() => _channel.invokeMethod<void>('stopForeground'));
    }
    await _guard(() => _channel.invokeMethod<void>('setProximity', false));
    await _guard(_wakelockDisable);
    final pref = _rememberedSpeakerPref;
    _rememberedSpeakerPref = null;
    if (pref != null) await _guard(() => _setSpeakerphoneOn(pref));
  }

  /// Turns the proximity-triggered screen-off on or off. Independent of
  /// [enterConversation]/[leaveConversation] — called once two people are
  /// actually in the conversation, not while a QR/code is still on screen.
  /// Best-effort: never throws.
  Future<void> setNearEarScreenOff(bool on) =>
      _guard(() => _channel.invokeMethod<void>('setProximity', on));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[InterpreterDevice] platform call failed: $e');
    }
  }
}
