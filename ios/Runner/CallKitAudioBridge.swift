// ios/Runner/CallKitAudioBridge.swift
import AVFoundation
import CallKit
import Flutter
import WebRTC
import flutter_callkit_incoming

/// Single meeting point of CallKit and WebRTC for Taler ID conversations.
/// While a conversation is in CallKit, CallKit owns the audio session and
/// WebRTC runs in manual-audio mode, starting its audio unit exactly when
/// CallKit activates the session: call waiting, hold and resume become
/// deactivate/activate instead of interruptions we had to recover from.
/// See docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md.
final class CallKitAudioBridge: NSObject {
  static let shared = CallKitAudioBridge()

  private var channel: FlutterMethodChannel?
  /// Conversations Dart registered (SystemCallRegistry).
  private var registeredByDart = Set<UUID>()
  /// Incoming calls answered through CallKit, known here before Dart can
  /// register them. CallKit activates the session right after the answer —
  /// on a killed app long before Flutter runs — and the plugin's fake
  /// "interruption ended" on that activation must not reach the old recovery.
  private var answeredHere = Set<UUID>()
  /// CallKit has our session activated right now.
  private var activatedSession: AVAudioSession?
  /// WebRTC was told the session is active (audioSessionDidActivate) and must
  /// hear about the deactivation too, managed or not by then — otherwise it
  /// believes the session is still live and never activates it again (the
  /// assistant after a call would go silent).
  private var webRTCKnowsActive = false

  private var managedCalls: Set<UUID> { registeredByDart.union(answeredHere) }

  /// A conversation is in CallKit: CallKit owns the audio session.
  var isManaging: Bool { !managedCalls.isEmpty }

  func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "taler_id/callkit_audio", binaryMessenger: messenger)
    ch.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(nil); return }
      switch call.method {
      case "setManagedCalls":
        // A shape mismatch must not read as "manage nothing" — that would
        // switch manual audio off in the middle of a call.
        guard let ids = call.arguments as? [String] else {
          result(FlutterError(code: "bad_args", message: "setManagedCalls expects [String]", details: nil))
          return
        }
        let uuids = ids.compactMap { UUID(uuidString: $0) }
        if uuids.count != ids.count {
          NSLog("[CallKitAudio] setManagedCalls: dropped \(ids.count - uuids.count) malformed id(s)")
        }
        self.setManagedCalls(uuids)
        result(nil)
      case "prepareCallAudio":
        self.prepareCallAudio()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  /// The category CallKit activates the session with — set before the answer
  /// or start is fulfilled; no setActive here, that is CallKit's.
  func prepareCallAudio() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
    } catch {
      NSLog("[CallKitAudio] prepareCallAudio failed: \(error)")
    }
  }

  /// onAccept: a call-screen conversation (not a group or mesh call) is ours
  /// from the moment it is answered.
  func callAnswered(_ call: Call) {
    guard Self.isCallScreenConversation(call) else { return }
    updateManaged { answeredHere.insert(call.uuid) }
  }

  /// onDecline / onEnd / the call observer: the call is over.
  func callFinished(_ uuid: UUID) {
    guard answeredHere.contains(uuid) else { return }
    updateManaged { answeredHere.remove(uuid) }
  }

  func didActivate(_ session: AVAudioSession) {
    activatedSession = session
    NSLog("[CallKitAudio] didActivate managing=\(isManaging)")
    if isManaging { enableWebRTCAudio(session) }
  }

  func didDeactivate(_ session: AVAudioSession) {
    activatedSession = nil
    NSLog("[CallKitAudio] didDeactivate managing=\(isManaging)")
    let rtc = RTCAudioSession.sharedInstance()
    if webRTCKnowsActive {
      rtc.audioSessionDidDeactivate(session)
      webRTCKnowsActive = false
    }
    if isManaging { rtc.isAudioEnabled = false }
  }

  /// CXCallObserver hook while managing: tells Dart once no call other than
  /// our conversations remains (the WhatsApp call that held us is over).
  func callChanged(_ observer: CXCallObserver, _ call: CXCall) {
    guard isManaging, call.hasEnded else { return }
    if managedCalls.contains(call.uuid) {
      // One of ours ended — possibly without onEnd (a CallKit reset).
      callFinished(call.uuid)
      return
    }
    let othersLeft = observer.calls.contains { other in
      other.uuid != call.uuid && !other.hasEnded && !managedCalls.contains(other.uuid)
    }
    NSLog("[CallKitAudio] other call ended, othersLeft=\(othersLeft)")
    if !othersLeft {
      channel?.invokeMethod("otherCallsEnded", arguments: nil)
    }
  }

  private func setManagedCalls(_ ids: [UUID]) {
    let registered = Set(ids)
    updateManaged {
      // A call Dart dropped is over for us too — also after a CallKit reset,
      // which the plugin reports to Dart (P9) but which may reach neither
      // onEnd nor the call observer here.
      answeredHere.subtract(registeredByDart.subtracting(registered))
      registeredByDart = registered
    }
  }

  private func updateManaged(_ change: () -> Void) {
    let wasManaging = isManaging
    change()
    NSLog("[CallKitAudio] managed=\(managedCalls.count) sessionActive=\(activatedSession != nil)")
    if !wasManaging && isManaging, let session = activatedSession {
      // CallKit switched the session on before the call was known as ours.
      enableWebRTCAudio(session)
    } else if wasManaging && !isManaging {
      RTCAudioSession.sharedInstance().useManualAudio = false
    }
  }

  /// Group and mesh calls ring through CallKit too but run their own audio;
  /// the same filter as SystemCallRegistry._onAccepted.
  private static func isCallScreenConversation(_ call: Call) -> Bool {
    guard let extra = call.data.extra as? [String: Any],
          let room = extra["roomName"] as? String, !room.isEmpty else { return false }
    return !room.hasPrefix("group-") && (extra["kind"] as? String) != "mesh_gc"
  }

  private func enableWebRTCAudio(_ session: AVAudioSession) {
    let rtc = RTCAudioSession.sharedInstance()
    if !webRTCKnowsActive {
      rtc.audioSessionDidActivate(session)
      webRTCKnowsActive = true
    }
    // Allow audio first, then go manual: the other order would stop an audio
    // unit that is already running.
    rtc.isAudioEnabled = true
    rtc.useManualAudio = true
  }
}
