import Foundation
import Flutter
import AVFoundation
import AudioToolbox

class AudioCaptureChannel: NSObject, FlutterStreamHandler {
  static let methodChannelName = "tirol.taler/mesh_audio_capture"
  static let eventChannelName  = "tirol.taler/mesh_audio_capture/frames"

  private var audioUnit: AudioUnit?
  private var eventSink: FlutterEventSink?
  private let sampleRate: Double = 16000

  private var micEnabled = true

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
  }

  // MARK: FlutterStreamHandler
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
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
      try session.setPreferredSampleRate(sampleRate)
      try session.setPreferredIOBufferDuration(0.02)
      try session.setActive(true)

      var desc = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_VoiceProcessingIO,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0, componentFlagsMask: 0)
      guard let component = AudioComponentFindNext(nil, &desc) else {
        result(FlutterError(code: "no_component", message: "VoiceProcessingIO not available", details: nil))
        return
      }
      var unit: AudioUnit?
      let createStatus = AudioComponentInstanceNew(component, &unit)
      guard createStatus == noErr, let audioUnit = unit else {
        result(FlutterError(code: "instance_failed", message: "AudioComponentInstanceNew failed: \(createStatus)", details: nil))
        return
      }
      self.audioUnit = audioUnit

      var enableIO: UInt32 = 1
      AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, UInt32(MemoryLayout<UInt32>.size))

      var format = AudioStreamBasicDescription(
        mSampleRate: sampleRate,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
        mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2,
        mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
      AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))

      var callback = AURenderCallbackStruct(inputProc: AudioCaptureChannel.inputCallback, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
      AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &callback, UInt32(MemoryLayout<AURenderCallbackStruct>.size))

      AudioUnitInitialize(audioUnit)
      AudioOutputUnitStart(audioUnit)
      result(nil)
    } catch {
      result(FlutterError(code: "audio_session_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func stop(result: @escaping FlutterResult) {
    if let unit = audioUnit {
      AudioOutputUnitStop(unit)
      AudioUnitUninitialize(unit)
      AudioComponentInstanceDispose(unit)
      audioUnit = nil
    }
    try? AVAudioSession.sharedInstance().setActive(false)
    result(nil)
  }

  private static let inputCallback: AURenderCallback = { (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
    let me = Unmanaged<AudioCaptureChannel>.fromOpaque(inRefCon).takeUnretainedValue()
    guard let unit = me.audioUnit else { return noErr }

    let bufferPtr = UnsafeMutablePointer<Int16>.allocate(capacity: Int(inNumberFrames))
    defer { bufferPtr.deallocate() }
    var bufferList = AudioBufferList(
      mNumberBuffers: 1,
      mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: inNumberFrames * 2, mData: UnsafeMutableRawPointer(bufferPtr)))
    let status = AudioUnitRender(unit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList)
    if status != noErr { return status }
    if me.micEnabled, let sink = me.eventSink {
      let data = Data(bytes: bufferPtr, count: Int(inNumberFrames) * 2)
      DispatchQueue.main.async { sink(FlutterStandardTypedData(bytes: data)) }
    }
    return noErr
  }
}
