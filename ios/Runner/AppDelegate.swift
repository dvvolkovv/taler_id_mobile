import Flutter
import UIKit
import AVFoundation
import PushKit
import Intents
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioChannel: FlutterMethodChannel?
  private var voipRegistry: PKPushRegistry?
  private var videoEffectsPlugin: VideoEffectsPlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins FIRST — ensures SwiftFlutterCallkitIncomingPlugin.sharedInstance
    // is non-nil before PushKit delegate fires (critical for killed-app VoIP push handling).
    // Also must happen before accessing binaryMessenger below.
    GeneratedPluginRegistrant.register(with: self)

    // Set up audio method channel (safe cast — nil-safe if window not ready on VoIP cold start)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "taler_id/audio",
        binaryMessenger: controller.binaryMessenger
      )
      audioChannel = channel
      channel.setMethodCallHandler { call, result in
        let session = AVAudioSession.sharedInstance()
        switch call.method {
        case "setSpeaker":
          let on = call.arguments as? Bool ?? false
          do {
            try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
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
          // Restore .voiceChat mode after playback ends
          do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
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

    // Register for VoIP push notifications via PushKit.
    // Store as instance property so the registry is not deallocated after this method returns.
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
      try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
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
      // Always derive UUID from roomName to match Flutter's _toCallkitId(roomName).
      // Server payload: { id: uuidv4(), extra: { roomName: "call-<uuid>", conversationId: "..." } }
      // Matching UUIDs lets CallKit deduplicate the VoIP-push call and the socket-triggered call,
      // preventing two simultaneous CallKit UIs and audio-session conflicts.
      let payloadExtra = args["extra"] as? [AnyHashable: Any]
      if let rn = payloadExtra?["roomName"] as? String {
        // Mirror Flutter's _toCallkitId: strip "call-" prefix, check UUID format.
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
