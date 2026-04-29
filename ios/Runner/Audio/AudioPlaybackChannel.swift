import Foundation
import Flutter

class AudioPlaybackChannel: NSObject {
  static let methodChannelName = "tirol.taler/mesh_audio_playback"

  // Strong reference so the instance survives after register() returns.
  // AudioIOSession keeps only a weak ref; the MethodChannel handler closure
  // also captured it weakly previously, which led to immediate dealloc and
  // hung MethodChannel calls on Dart side.
  private static var sharedInstance: AudioPlaybackChannel?

  private var pendingFrames: [Data] = []
  private let lock = NSLock()
  private var started = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AudioPlaybackChannel()
    sharedInstance = instance
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "start": instance.start(result: result)
      case "stop":  instance.stop(result: result)
      case "push":
        if let bytes = call.arguments as? FlutterStandardTypedData {
          instance.push(bytes.data); result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "expected typed bytes", details: nil))
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
    AudioIOSession.shared.attachPlayback(instance)
  }

  func push(_ data: Data) {
    lock.lock()
    defer { lock.unlock() }
    pendingFrames.append(data)
  }

  /// Called from the audio render thread by `AudioIOSession`. Must be fast and lock-free-ish.
  func pullNextSamples(into ptr: UnsafeMutablePointer<Int16>, count: Int) {
    lock.lock()
    defer { lock.unlock() }
    var written = 0
    while written < count, !pendingFrames.isEmpty {
      let frame = pendingFrames[0]
      let samplesAvailable = frame.count / 2
      let take = min(samplesAvailable, count - written)
      frame.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
        let src = raw.bindMemory(to: Int16.self).baseAddress!
        for i in 0..<take {
          ptr[written + i] = src[i]
        }
      }
      written += take
      if take == samplesAvailable {
        pendingFrames.removeFirst()
      } else {
        pendingFrames[0] = frame.subdata(in: (take * 2)..<frame.count)
      }
    }
    while written < count { ptr[written] = 0; written += 1 } // silence pad
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
    lock.lock(); pendingFrames.removeAll(); lock.unlock()
    result(nil)
  }
}
