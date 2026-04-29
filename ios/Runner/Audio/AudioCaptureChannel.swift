import Foundation
import Flutter
import AVFoundation
import AudioToolbox

class AudioCaptureChannel: NSObject, FlutterStreamHandler {
  static let methodChannelName = "tirol.taler/mesh_audio_capture"
  static let eventChannelName  = "tirol.taler/mesh_audio_capture/frames"

  private var eventSink: FlutterEventSink?
  private var micEnabled = true
  private var started = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AudioCaptureChannel()
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { [weak instance] call, result in
      switch call.method {
      case "start": instance?.start(result: result)
      case "stop":  instance?.stop(result: result)
      case "setMicEnabled":
        if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
          instance?.micEnabled = enabled
        }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
    AudioIOSession.shared.attachCapture(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  private func start(result: @escaping FlutterResult) {
    do {
      try AudioIOSession.shared.acquire()
      started = true
      result(nil)
    } catch {
      result(FlutterError(code: "audio_session_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func stop(result: @escaping FlutterResult) {
    if started {
      AudioIOSession.shared.release()
      started = false
    }
    result(nil)
  }

  func deliverFrame(_ ptr: UnsafePointer<Int16>, count: Int) {
    if !micEnabled { return }
    guard let sink = eventSink else { return }
    let data = Data(bytes: ptr, count: count * 2)
    DispatchQueue.main.async { sink(FlutterStandardTypedData(bytes: data)) }
  }
}
