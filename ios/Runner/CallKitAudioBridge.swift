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
  /// Managed calls CallKit has already ended (onEnd/onDecline/the call
  /// observer) that Dart has not dropped yet. When the system ends our call
  /// — the End button, "End & Accept", a held call hung up — WebRTC audio is
  /// already off (didDeactivate) by the time Dart hears about it and calls
  /// setManagedCalls; switching useManualAudio off right then gives WebRTC a
  /// canPlayOrRecord false→true edge, and it reinitialises its audio unit
  /// and activates the session on its own — exactly while a rival call
  /// (WhatsApp) may be setting up its own. Tracking "CallKit already killed
  /// this one" lets didDeactivate leave isAudioEnabled alone for it.
  private var endedHere = Set<UUID>()
  /// CallKit has our session activated right now.
  private var activatedSession: AVAudioSession?
  /// WebRTC was told the session is active (audioSessionDidActivate) and must
  /// hear about the deactivation too, managed or not by then — otherwise it
  /// believes the session is still live and never activates it again (the
  /// assistant after a call would go silent).
  private var webRTCKnowsActive = false

  private var managedCalls: Set<UUID> { registeredByDart.union(answeredHere) }

  /// A conversation is in CallKit: CallKit owns the audio session.
  var isManaging: Bool { !registeredByDart.isEmpty || !answeredHere.isEmpty }

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
          NSLog("[CallKitAudio] setManagedCalls: dropped %d malformed id(s)", ids.count - uuids.count)
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
    // A session is already active: "Hold & Accept" on a second incoming
    // call, or a Dart startOutgoing while one is live, must not reset the
    // live call's category/mode (e.g. drop a videoChat mode or a speaker
    // override) out from under it.
    guard activatedSession == nil else { return }
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
    } catch {
      NSLog("[CallKitAudio] prepareCallAudio failed: %@", "\(error)")
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
    // CallKit already tore this call's session handling down. If Dart still
    // has it registered (hasn't reacted to the socket's end yet), remember
    // that so a later didDeactivate does not treat it as still alive — see
    // endedHere.
    if registeredByDart.contains(uuid) { endedHere.insert(uuid) }
    guard answeredHere.contains(uuid) else { return }
    updateManaged { answeredHere.remove(uuid) }
  }

  /// providerDidReset (forwarded via the plugin's P13): CallKit wiped every
  /// call without a matching onEnd/onDecline for each. Give WebRTC back its
  /// own control and drop our own bookkeeping; Dart drops registeredByDart
  /// once it processes the plugin's own ENDED events for the reset (P9).
  func providerDidReset() {
    if webRTCKnowsActive {
      RTCAudioSession.sharedInstance().audioSessionDidDeactivate(activatedSession ?? AVAudioSession.sharedInstance())
      webRTCKnowsActive = false
    }
    activatedSession = nil
    updateManaged {
      answeredHere.removeAll()
      endedHere.removeAll()
    }
  }

  func didActivate(_ session: AVAudioSession) {
    activatedSession = session
    NSLog("[CallKitAudio] didActivate managing=%@", "\(isManaging)")
    // Relies on the plugin calling this BEFORE its own fake "interruption
    // ended" notification (PATCHES.md, "Оставлено как есть") — WebRTC must
    // already be enabled by the time that notification lands.
    if isManaging { enableWebRTCAudio(session) }
  }

  func didDeactivate(_ session: AVAudioSession) {
    activatedSession = nil
    NSLog("[CallKitAudio] didDeactivate managing=%@", "\(isManaging)")
    let rtc = RTCAudioSession.sharedInstance()
    if webRTCKnowsActive {
      rtc.audioSessionDidDeactivate(session)
      webRTCKnowsActive = false
    }
    // Only if a call CallKit hasn't already ended is still managed — this
    // deactivation may be for a call onEnd/onDecline/the observer already
    // settled (endedHere), and toggling isAudioEnabled off here for it would
    // toggle it back on once Dart's setManagedCalls catches up and
    // useManualAudio drops — the false→true edge endedHere exists to avoid.
    if !managedCalls.subtracting(endedHere).isEmpty { rtc.isAudioEnabled = false }
  }

  /// CXCallObserver hook while managing: tells Dart once no call other than
  /// our conversations remains (the WhatsApp call that held us is over).
  func callChanged(_ observer: CXCallObserver, _ call: CXCall) {
    guard isManaging, call.hasEnded else { return }
    let managed = managedCalls
    if managed.contains(call.uuid) {
      // One of ours ended — possibly without onEnd (a CallKit reset).
      callFinished(call.uuid)
      return
    }
    let othersLeft = observer.calls.contains { other in
      other.uuid != call.uuid && !other.hasEnded && !managed.contains(other.uuid)
    }
    NSLog("[CallKitAudio] other call ended, othersLeft=%@", "\(othersLeft)")
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
      // Forget calls Dart no longer registers — endedHere only needs to
      // outlive a call in registeredByDart, not survive past it.
      endedHere.formIntersection(registered)
    }
  }

  private func updateManaged(_ change: () -> Void) {
    let wasManaging = isManaging
    change()
    NSLog("[CallKitAudio] managed=%d sessionActive=%@", managedCalls.count, "\(activatedSession != nil)")
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
