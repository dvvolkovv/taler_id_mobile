import Flutter
import UIKit
import AVFoundation
import PushKit
import Intents
import CallKit
import flutter_callkit_incoming

// Phase 3 mesh voice: libopus is force-loaded into Runner via the local
// pod, but iOS strips the app's export trie so dlsym(RTLD_DEFAULT, "opus_*")
// returns NULL. We instead expose `taler_opus_*` Objective-C wrappers from
// OpusSymbolsKeeper.m with __attribute__((used,visibility("default"))) —
// those names DO end up in the export trie and Dart FFI looks them up.
// No code is needed in AppDelegate; the wrappers are referenced by their
// own attributes.

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioChannel: FlutterMethodChannel?
  private var orientationChannel: FlutterMethodChannel?
  private var voipRegistry: PKPushRegistry?
  private var videoEffectsPlugin: VideoEffectsPlugin?
  private var callObserver: CXCallObserver?
  // Native ringback player for outgoing calls. audioplayers deactivates the
  // whole AVAudioSession (setActive(false)) whenever its last player stops,
  // which kills WebRTC audio if the callee joins mid-ring — the "can't hear
  // the other party, works 1-in-5 calls" bug. AVAudioPlayer never touches
  // the session on stop.
  var ringbackPlayer: AVAudioPlayer?

  // Orientation lock toggle controlled from Flutter via the
  // `taler_id/orientation` MethodChannel. Defaults to portrait — only the
  // call screen flips it on so the device can rotate freely there.
  static var allowAllOrientations: Bool = false

  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return AppDelegate.allowAllOrientations ? [.portrait, .landscapeLeft, .landscapeRight] : .portrait
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins FIRST — ensures SwiftFlutterCallkitIncomingPlugin.sharedInstance
    // is non-nil before PushKit delegate fires (critical for killed-app VoIP push handling).
    // Also must happen before accessing binaryMessenger below.
    GeneratedPluginRegistrant.register(with: self)

    // Register mesh audio capture channel (VoiceProcessingIO capture for mesh voice calls)
    if let registrar = self.registrar(forPlugin: "AudioCaptureChannel") {
      AudioCaptureChannel.register(with: registrar)
    }

    // Register mesh audio playback channel (shares the same AudioIOSession as capture)
    if let registrar = self.registrar(forPlugin: "AudioPlaybackChannel") {
      AudioPlaybackChannel.register(with: registrar)
    }

    // CallKit → WebRTC bridge. Registered through a plugin registrar, not the
    // window's controller: on a VoIP cold start the window may not exist yet,
    // and that is exactly when the answered call needs the bridge.
    if let registrar = self.registrar(forPlugin: "CallKitAudioBridge") {
      CallKitAudioBridge.shared.register(messenger: registrar.messenger())
    }

    // Set up audio method channel (safe cast — nil-safe if window not ready on VoIP cold start)
    if let controller = window?.rootViewController as? FlutterViewController {
      // Orientation channel — Flutter toggles allowAllOrientations on entering
      // / leaving the call screen. We then nudge iOS to re-evaluate so the
      // window rotates to the device's current orientation immediately.
      let oc = FlutterMethodChannel(
        name: "taler_id/orientation",
        binaryMessenger: controller.binaryMessenger
      )
      orientationChannel = oc
      oc.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "setAllowAll":
          let allow = call.arguments as? Bool ?? false
          AppDelegate.allowAllOrientations = allow
          // Force iOS to query supportedInterfaceOrientations again so a
          // rotation that happened while the toggle was off can take effect.
          if #available(iOS 16.0, *) {
            self?.window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
          } else {
            UIViewController.attemptRotationToDeviceOrientation()
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let channel = FlutterMethodChannel(
        name: "taler_id/audio",
        binaryMessenger: controller.binaryMessenger
      )
      audioChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterMethodNotImplemented)
          return
        }
        self.handleAudioMethodCall(call, result: result)
      }
    }

    // Set up video effects method channel (background blur / virtual backgrounds)
    if let controller = window?.rootViewController as? FlutterViewController {
      let vfx = VideoEffectsPlugin()
      vfx.register(with: controller.binaryMessenger)
      videoEffectsPlugin = vfx
    }

    // Set up share suggestions channel (donate INSendMessageIntent for share sheet contacts)
    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(
        name: "taler_id/share_suggestions",
        binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "donateConversation":
          guard let args = call.arguments as? [String: Any],
                let conversationId = args["conversationId"] as? String,
                let displayName = args["displayName"] as? String else {
            result(nil)
            return
          }
          let avatarUrl = args["avatarUrl"] as? String

          if #available(iOS 15.0, *) {
            let handle = INPersonHandle(value: conversationId, type: .unknown)
            let person = INPerson(
              personHandle: handle,
              nameComponents: {
                var nc = PersonNameComponents()
                nc.givenName = displayName
                return nc
              }(),
              displayName: displayName,
              image: nil,
              contactIdentifier: nil,
              customIdentifier: conversationId
            )

            let intent = INSendMessageIntent(
              recipients: [person],
              outgoingMessageType: .outgoingMessageText,
              content: nil,
              speakableGroupName: INSpeakableString(spokenPhrase: displayName),
              conversationIdentifier: conversationId,
              serviceName: "Taler ID",
              sender: nil,
              attachments: nil
            )

            // Load avatar asynchronously
            if let urlStr = avatarUrl, let url = URL(string: urlStr) {
              DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                  let image = INImage(imageData: data)
                  intent.setImage(image, forParameterNamed: \.speakableGroupName)
                }
                let interaction = INInteraction(intent: intent, response: nil)
                interaction.direction = .outgoing
                interaction.donate { error in
                  if let error = error {
                    NSLog("[ShareSuggestions] Donate error: %@", error.localizedDescription)
                  } else {
                    NSLog("[ShareSuggestions] Donated: %@", displayName)
                  }
                }
              }
            } else {
              let interaction = INInteraction(intent: intent, response: nil)
              interaction.direction = .outgoing
              interaction.donate { error in
                if let error = error {
                  NSLog("[ShareSuggestions] Donate error: %@", error.localizedDescription)
                } else {
                  NSLog("[ShareSuggestions] Donated: %@", displayName)
                }
              }
            }
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Register for audio session interruptions (parallel calls from other apps/phone)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )

    // Register for audio route changes — more reliable than interruption.ended
    // for detecting when an external phone call ends and our audio can resume.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )

    // Observe system-wide CallKit call state (WhatsApp/Telegram/phone). iOS
    // sometimes never delivers interruption `.ended` after a rival VoIP call —
    // the observer's hasEnded is the reliable signal to restore our audio
    // session (2026-07-17: a parallel WhatsApp ring during a Taler ID call
    // left the conversation broken until manual recovery).
    let observer = CXCallObserver()
    observer.setDelegate(self, queue: .main)
    callObserver = observer

    // Register for VoIP push notifications via PushKit.
    // Store as instance property so the registry is not deallocated after this method returns.
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Extracted from the `taler_id/audio` MethodChannel closure: the giant
  // switch made the Swift type-checker time out ("unable to type-check this
  // expression in reasonable time") when compiled as one closure literal.
  private func handleAudioMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let session = AVAudioSession.sharedInstance()
        switch call.method {
        case "playRingback":
          // Ensure the call session is configured + active (idempotent), then
          // play the ringback asset natively. Deliberately NOT audioplayers —
          // see ringbackPlayer comment above.
          let volume = (call.arguments as? Double) ?? 0.6
          do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
          } catch {}
          let key = FlutterDartProject.lookupKey(forAsset: "assets/audio/ringback.wav")
          if let path = Bundle.main.path(forResource: key, ofType: nil) {
            self.ringbackPlayer?.stop()
            self.ringbackPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            self.ringbackPlayer?.volume = Float(volume)
            self.ringbackPlayer?.play()
          }
          result(nil)
        case "stopRingback":
          // Only stop the player — do NOT touch the AVAudioSession here, the
          // WebRTC call audio keeps using it.
          self.ringbackPlayer?.stop()
          self.ringbackPlayer = nil
          result(nil)
        case "setSpeaker":
          let on = call.arguments as? Bool ?? false
          do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            try session.overrideOutputAudioPort(on ? .speaker : .none)
            result(nil)
          } catch {
            result(FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil))
          }
        case "getAudioOutputs":
          var outputs: [[String: String]] = []
          let currentOutputs = session.currentRoute.outputs
          let hasWired = currentOutputs.contains {
            $0.portType == .headphones || $0.portType == .headsetMic
          }
          let btOutput = currentOutputs.first {
            $0.portType == .bluetoothHFP || $0.portType == .bluetoothA2DP || $0.portType == .bluetoothLE
          }
          outputs.append(["id": "earpiece", "name": "Телефон", "type": "earpiece"])
          outputs.append(["id": "speaker", "name": "Динамик", "type": "speaker"])
          if hasWired {
            outputs.append(["id": "headphones", "name": "Наушники", "type": "headphones"])
          }
          if let bt = btOutput {
            outputs.append(["id": "bluetooth", "name": bt.portName, "type": "bluetooth"])
          }
          result(outputs)
        case "setAudioOutput":
          let type = call.arguments as? String ?? "earpiece"
          do {
            switch type {
            case "speaker":
              try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
              try session.setActive(true)
              try session.overrideOutputAudioPort(.speaker)
            case "bluetooth":
              try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
              try session.setActive(true)
              try session.overrideOutputAudioPort(.none)
            default: // earpiece, headphones
              try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
              try session.setActive(true)
              try session.overrideOutputAudioPort(.none)
            }
            result(nil)
          } catch {
            result(FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil))
          }
        case "requestAudioFocus":
          do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            result(nil)
          } catch {
            result(nil) // Non-fatal
          }
        case "setAudioSessionForVideo":
          // Switch AVAudioSession to videoChat mode so camera capture works alongside audio
          do {
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            result(nil)
          } catch {
            result(nil) // Non-fatal
          }
        case "prepareForPlayback":
          // Switch audio session to .default mode so AudioPlayer can produce
          // sound at normal volume. The .voiceChat mode applies heavy AGC and
          // may suppress AudioPlayer output on some iOS versions.
          do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try session.setActive(true)
            result(nil)
          } catch {
            result(nil)
          }
        case "restoreVoiceChat":
          // Restore .voiceChat mode after playback ends. Keep .mixWithOthers —
          // this path runs mid-call, and dropping the mix flag re-opens the
          // rival-VoIP preemption window (see enableCallAudioMix).
          do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            result(nil)
          } catch {
            result(nil)
          }
        case "deactivateAudioSession":
          do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            result(nil)
          } catch {
            result(nil) // Non-fatal
          }
        case "getCurrentAudioRoute":
          // Actual hardware route right now — used on app resume to avoid
          // re-applying a stale UI selection over headphones/bluetooth.
          let out = session.currentRoute.outputs.first
          switch out?.portType {
          case .headphones, .headsetMic, .usbAudio:
            result("headphones")
          case .bluetoothHFP, .bluetoothA2DP, .bluetoothLE:
            result("bluetooth")
          case .builtInSpeaker:
            result("speaker")
          default:
            result("earpiece")
          }
        case "enableCallAudioMix":
          self.enableCallAudioMix()
          result(nil)
        case "disableCallAudioMix":
          self.disableCallAudioMix()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
  }

  /// Tracks whether we are currently interrupted by an external call.
  private var audioInterrupted = false

  @objc private func handleAudioInterruption(_ notification: Notification) {
    guard let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
    DispatchQueue.main.async {
      if type == .began {
        self.audioInterrupted = true
        self.audioChannel?.invokeMethod("audioInterrupted", arguments: nil)
      } else if type == .ended {
        self.audioInterrupted = false
        // Check shouldResume hint from iOS
        let shouldResume: Bool
        if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
          shouldResume = AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume)
        } else {
          shouldResume = true // Default to resuming if flag is absent
        }
        if shouldResume {
          self.restoreAudioSessionAfterInterruption()
        } else {
          NSLog("[Audio] iOS indicated shouldResume=false, attempting restore anyway")
          // Still try — our call is more important than the hint
          self.restoreAudioSessionAfterInterruption()
        }
      }
    }
  }

  @objc private func handleRouteChange(_ notification: Notification) {
    guard let info = notification.userInfo,
          let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
    // When an old device (phone call audio) is removed, restore our session
    if reason == .oldDeviceUnavailable && self.audioInterrupted {
      NSLog("[Audio] Route change: old device unavailable while interrupted — restoring")
      DispatchQueue.main.async {
        self.audioInterrupted = false
        self.restoreAudioSessionAfterInterruption()
      }
    }
  }

  /// Restores the audio session after an external interruption (phone call).
  /// Retries with increasing delays because iOS audio deactivation timing is unpredictable.
  private func restoreAudioSessionAfterInterruption() {
    let session = AVAudioSession.sharedInstance()
    // First attempt immediately
    self.doRestoreAudioSession(session)
    self.audioChannel?.invokeMethod("audioResumed", arguments: nil)
    // Retry after delays to handle iOS timing issues
    for delay in [300, 800, 1500] {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) { [weak self] in
        guard let self = self, !self.audioInterrupted else { return }
        self.doRestoreAudioSession(session)
      }
    }
  }

  private func doRestoreAudioSession(_ session: AVAudioSession) {
    do {
      // Restoration MUST mirror enableCallAudioMix exactly, otherwise iOS
      // re-interrupts immediately after recovery: when another VoIP app
      // (WhatsApp, Telegram) triggered the interruption, its CallKit state
      // may still be active for a brief window after the user declines, and
      // a session category without `.mixWithOthers` is treated as exclusive
      // → iOS prefers the other app's call and tears ours down again. This
      // was the 2026-06-16 incident where a declined WhatsApp ring killed
      // a Taler ID call with no recovery.
      try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [
          .mixWithOthers,
          .allowBluetooth,
          .allowBluetoothA2DP,
          .defaultToSpeaker,
        ]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      NSLog("[Audio] Failed to restore session: %@", error.localizedDescription)
    }
  }

  /// Configure AVAudioSession for active call: allow mixing with other apps' audio
  /// (WhatsApp/Telegram VoIP) so their incoming call doesn't preempt ours.
  private func enableCallAudioMix() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [
          .mixWithOthers,
          .allowBluetooth,
          .allowBluetoothA2DP,
          .defaultToSpeaker,
        ]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      NSLog("[CallAudioMix] enabled (mixWithOthers + voiceChat)")
    } catch {
      NSLog("[CallAudioMix] enable failed: \(error)")
    }
  }

  /// Revert AVAudioSession to default for non-call app behavior.
  private func disableCallAudioMix() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.soloAmbient)
      try session.setActive(false, options: .notifyOthersOnDeactivation)
      NSLog("[CallAudioMix] disabled (reverted to soloAmbient)")
    } catch {
      NSLog("[CallAudioMix] disable failed: \(error)")
    }
  }
}

extension AppDelegate: PKPushRegistryDelegate {
  func pushRegistry(_ registry: PKPushRegistry,
                    didUpdate credentials: PKPushCredentials,
                    for type: PKPushType) {
    guard type == .voIP else { return }
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
    guard type == .voIP else { completion(); return }
    // iOS 13+ REQUIRES reporting the call to CallKit synchronously here.
    // If the plugin is ready, delegate to it; otherwise call completion immediately
    // to avoid iOS blacklisting the app for failing to report the call in time.
    if let instance = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
      // Build a mutable args dict — ensure 'id' is a valid UUID.
      // The plugin does uuid! (force-unwrap) at line 324, so it crashes if uuid is nil or invalid.
      var args = payload.dictionaryPayload as [AnyHashable: Any]
      let rawId = args["id"] as? String ?? ""
      NSLog("[VoIP] payload id=%@", rawId)
      // Always derive UUID from roomName to match `toCallkitId` in
      // lib/core/platform/callkit_support.dart.
      // Server payload: { id: uuidv4(), extra: { roomName: "call-<uuid>", conversationId: "..." } }
      // Matching UUIDs lets CallKit deduplicate the VoIP-push call and the socket-triggered call,
      // preventing two simultaneous CallKit UIs and audio-session conflicts.
      let payloadExtra = args["extra"] as? [AnyHashable: Any]
      if let rn = payloadExtra?["roomName"] as? String {
        // Mirror `toCallkitId` in lib/core/platform/callkit_support.dart:
        // strip "call-" prefix, check UUID format.
        let stripped = rn.hasPrefix("call-") ? String(rn.dropFirst(5)) : rn
        let uuidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        if let regex = try? NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive),
           regex.firstMatch(in: stripped, range: NSRange(stripped.startIndex..., in: stripped)) != nil {
          args["id"] = stripped
          NSLog("[VoIP] using roomName-derived UUID: %@", stripped)
        } else if UUID(uuidString: rawId) == nil {
          // roomName not UUID-shaped and server UUID invalid — generate fallback.
          args["id"] = UUID().uuidString
          NSLog("[VoIP] generated fallback UUID=%@", args["id"] as! String)
        }
        // else: roomName not UUID-shaped but server UUID is valid — keep server UUID.
      } else if UUID(uuidString: rawId) == nil {
        // No roomName in extra and server UUID invalid — generate fallback.
        args["id"] = UUID().uuidString
        NSLog("[VoIP] generated fallback UUID (no roomName)=%@", args["id"] as! String)
      }
      // args["extra"] already contains roomName/conversationId from the server payload —
      // no need to re-wrap; the plugin reads extra directly from args["extra"].
      let data = flutter_callkit_incoming.Data(args: args as NSDictionary)
      // Every conversation lives in CallKit now: the plugin must not configure
      // or activate the session itself, and the call must be holdable for
      // WhatsApp/cellular call waiting (same settings as CallKitMobile).
      data.configureAudioSession = false
      data.supportsHolding = true
      data.audioSessionMode = "voiceChat"
      // The push carries no `ios` dict, so besides the three fields above the
      // plugin's own Data() defaults would otherwise apply — mirror
      // CallKitMobile's _iosCallParams (lib/core/platform/call_kit_mobile.dart)
      // for everything that changes CallKit's own behaviour, so a VoIP-push
      // call looks the same to iOS as one reported while the app was
      // running. Only the four booleans below actually change anything: the
      // plugin defaults them to true with no `ios` dict. maximumCallGroups/
      // PerCallGroup and iconName already match the plugin's own no-`ios`-dict
      // defaults (2/1/"CallKitLogo") — set explicitly anyway, for parity with
      // _iosCallParams rather than because today's default is wrong.
      // ringtonePath is deliberately left at the plugin's default (the
      // system ringtone) — the socket path's own bumer_ringtone.caf is a UX
      // choice out of scope here, not a behaviour bug.
      data.supportsVideo = false
      data.supportsDTMF = false
      data.supportsGrouping = false
      data.supportsUngrouping = false
      data.maximumCallGroups = 2
      data.maximumCallsPerCallGroup = 1
      data.iconName = "CallKitLogo"
      // The push carries no duration: the plugin's 30 s default would ring
      // half as long as the same call arriving over the socket (60 s).
      data.duration = 60000
      instance.showCallkitIncoming(data, fromPushKit: true) {
        completion()
      }
    } else {
      // Plugin not initialized — should not happen since GeneratedPluginRegistrant
      // is now called before PushKit setup, but guard just in case.
      completion()
    }
  }
}

extension AppDelegate: CXCallObserverDelegate {
  /// Fires for every CallKit-visible call system-wide (ours and rival apps').
  /// Scope: only act when a call ENDS while our session is marked interrupted
  /// — that combination means a rival app's call (WhatsApp/Telegram/phone)
  /// took the audio session and iOS may never send interruption `.ended`
  /// (long-standing iOS bug). Our own calls never set audioInterrupted, so
  /// this can't misfire on Taler ID call teardown.
  func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    guard call.hasEnded, audioInterrupted else { return }
    NSLog("[Audio] CXCallObserver: rival call ended — forcing session restore")
    audioInterrupted = false
    restoreAudioSessionAfterInterruption()
  }
}

extension AppDelegate: CallkitIncomingAppDelegate {
  // Conforming hands fulfilment of these actions to us — the plugin no
  // longer fulfils them itself. Every path must fulfil or fail. (Answering an
  // outgoing call is refused inside the plugin, PATCH P11.)

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    CallKitAudioBridge.shared.callAnswered(call)
    CallKitAudioBridge.shared.prepareCallAudio()
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    CallKitAudioBridge.shared.callFinished(call.uuid)
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    CallKitAudioBridge.shared.callFinished(call.uuid)
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    CallKitAudioBridge.shared.didActivate(audioSession)
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    CallKitAudioBridge.shared.didDeactivate(audioSession)
  }

  // PATCH P13 (Taler ID) forwards this from the plugin's providerDidReset.
  func providerDidReset() {
    CallKitAudioBridge.shared.providerDidReset()
  }
}
