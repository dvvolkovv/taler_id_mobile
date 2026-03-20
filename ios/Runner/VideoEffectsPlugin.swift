import Flutter
import Foundation
import WebRTC
import flutter_webrtc

/// Flutter method channel handler for video background effects.
/// Bridges between Flutter and the native VideoBackgroundProcessor.
class VideoEffectsPlugin {
  private var channel: FlutterMethodChannel?
  private var processor: Any? // VideoBackgroundProcessor (iOS 15+)
  private var isProcessing = false

  func register(with binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "taler_id/video_effects", binaryMessenger: binaryMessenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startProcessing":
      guard let args = call.arguments as? [String: Any],
            let effectType = args["effectType"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing effectType", details: nil))
        return
      }

      guard #available(iOS 15.0, *) else {
        result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required for background effects", details: nil))
        return
      }

      let bgProcessor: VideoBackgroundProcessor
      if let existing = processor as? VideoBackgroundProcessor {
        bgProcessor = existing
      } else {
        bgProcessor = VideoBackgroundProcessor()
        processor = bgProcessor
      }

      // Set effect type
      if effectType == "blur" {
        bgProcessor.effect = .blur
      } else if effectType == "background",
                let imageData = args["backgroundImageData"] as? FlutterStandardTypedData {
        if let ciImage = CIImage(data: imageData.data) {
          bgProcessor.effect = .background(ciImage)
        } else {
          result(FlutterError(code: "INVALID_IMAGE", message: "Cannot decode background image", details: nil))
          return
        }
      }

      // Add processor to active video track
      if !isProcessing {
        addProcessorToActiveTrack(bgProcessor)
        isProcessing = true
      }

      result(nil)

    case "setEffect":
      guard let args = call.arguments as? [String: Any],
            let effectType = args["effectType"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing effectType", details: nil))
        return
      }

      guard #available(iOS 15.0, *),
            let bgProcessor = processor as? VideoBackgroundProcessor else {
        result(nil)
        return
      }

      if effectType == "blur" {
        bgProcessor.effect = .blur
      } else if effectType == "background",
                let imageData = args["backgroundImageData"] as? FlutterStandardTypedData {
        if let ciImage = CIImage(data: imageData.data) {
          bgProcessor.effect = .background(ciImage)
        }
      }
      result(nil)

    case "stopProcessing":
      if #available(iOS 15.0, *), let bgProcessor = processor as? VideoBackgroundProcessor {
        removeProcessorFromAllTracks(bgProcessor)
        bgProcessor.cleanup()
      }
      isProcessing = false
      result(nil)

    case "reattach":
      // Called after camera re-enable or flip to re-add processor to new track
      if #available(iOS 15.0, *), isProcessing, let bgProcessor = processor as? VideoBackgroundProcessor {
        addProcessorToActiveTrack(bgProcessor)
      }
      result(nil)

    case "isSupported":
      if #available(iOS 15.0, *) {
        result(true)
      } else {
        result(false)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 15.0, *)
  private func addProcessorToActiveTrack(_ processor: VideoBackgroundProcessor) {
    guard let plugin = FlutterWebRTCPlugin.sharedSingleton(),
          let localTracks = plugin.localTracks else {
      print("[VideoEffects] FlutterWebRTCPlugin or localTracks not available")
      return
    }

    for (trackId, track) in localTracks {
      if let videoTrack = track as? LocalVideoTrack {
        print("[VideoEffects] Adding processor to track: \(trackId)")
        videoTrack.addProcessing(processor)
        return
      }
    }
    print("[VideoEffects] No active local video track found")
  }

  @available(iOS 15.0, *)
  private func removeProcessorFromAllTracks(_ processor: VideoBackgroundProcessor) {
    guard let plugin = FlutterWebRTCPlugin.sharedSingleton(),
          let localTracks = plugin.localTracks else { return }

    for (_, track) in localTracks {
      if let videoTrack = track as? LocalVideoTrack {
        videoTrack.removeProcessing(processor)
      }
    }
  }
}
