import Foundation
import AVFoundation
import AudioToolbox

/// Shared AudioUnit lifecycle owner. Capture and playback both attach to the
/// same `VoiceProcessingIO` unit so AEC/AGC/NS work coherently.
class AudioIOSession {
  static let shared = AudioIOSession()

  private(set) var audioUnit: AudioUnit?
  private var refcount = 0

  weak var captureRef: AudioCaptureChannel?
  weak var playbackRef: AudioPlaybackChannel?

  private let sampleRate: Double = 16000

  func attachCapture(_ c: AudioCaptureChannel) { captureRef = c }
  func attachPlayback(_ p: AudioPlaybackChannel) { playbackRef = p }

  func acquire() throws {
    refcount += 1
    if refcount > 1 { return }
    try start()
  }

  func release() {
    refcount = max(0, refcount - 1)
    if refcount == 0 {
      stop()
    }
  }

  private func start() throws {
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
      throw NSError(domain: "AudioIOSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "VoiceProcessingIO not available"])
    }
    var unit: AudioUnit?
    let createStatus = AudioComponentInstanceNew(component, &unit)
    guard createStatus == noErr, let audioUnit = unit else {
      throw NSError(domain: "AudioIOSession", code: 2, userInfo: [NSLocalizedDescriptionKey: "AudioComponentInstanceNew failed: \(createStatus)"])
    }
    self.audioUnit = audioUnit

    // Enable input bus (1) and output bus (0) for capture+playback.
    var enableIO: UInt32 = 1
    AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, UInt32(MemoryLayout<UInt32>.size))
    AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &enableIO, UInt32(MemoryLayout<UInt32>.size))

    // Common 16 kHz mono S16LE format for both buses.
    var format = AudioStreamBasicDescription(
      mSampleRate: sampleRate,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
      mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2,
      mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))

    // Input callback (mic → us)
    var inputCb = AURenderCallbackStruct(
      inputProc: AudioIOSession.inputCallback,
      inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
    AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &inputCb, UInt32(MemoryLayout<AURenderCallbackStruct>.size))

    // Output (render) callback (us → speaker)
    var outputCb = AURenderCallbackStruct(
      inputProc: AudioIOSession.renderCallback,
      inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &outputCb, UInt32(MemoryLayout<AURenderCallbackStruct>.size))

    AudioUnitInitialize(audioUnit)
    AudioOutputUnitStart(audioUnit)
  }

  private func stop() {
    if let unit = audioUnit {
      AudioOutputUnitStop(unit)
      AudioUnitUninitialize(unit)
      AudioComponentInstanceDispose(unit)
      audioUnit = nil
    }
    try? AVAudioSession.sharedInstance().setActive(false)
  }

  // MARK: callbacks

  private static let inputCallback: AURenderCallback = { (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, _) -> OSStatus in
    let me = Unmanaged<AudioIOSession>.fromOpaque(inRefCon).takeUnretainedValue()
    guard let unit = me.audioUnit else { return noErr }

    let bufferPtr = UnsafeMutablePointer<Int16>.allocate(capacity: Int(inNumberFrames))
    defer { bufferPtr.deallocate() }
    var bufferList = AudioBufferList(
      mNumberBuffers: 1,
      mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: inNumberFrames * 2, mData: UnsafeMutableRawPointer(bufferPtr)))
    let status = AudioUnitRender(unit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList)
    if status != noErr { return status }
    me.captureRef?.deliverFrame(bufferPtr, count: Int(inNumberFrames))
    return noErr
  }

  private static let renderCallback: AURenderCallback = { (inRefCon, _, _, _, inNumberFrames, ioData) -> OSStatus in
    let me = Unmanaged<AudioIOSession>.fromOpaque(inRefCon).takeUnretainedValue()
    guard let ioData = ioData else { return noErr }
    let abl = UnsafeMutableAudioBufferListPointer(ioData)
    guard let buf = abl[0].mData?.assumingMemoryBound(to: Int16.self) else { return noErr }
    me.playbackRef?.pullNextSamples(into: buf, count: Int(inNumberFrames))
    return noErr
  }
}
