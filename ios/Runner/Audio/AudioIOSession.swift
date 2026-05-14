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
    do {
      try start()
    } catch {
      // Tear down any partial AudioUnit/session state that start() may have
      // left around — otherwise subsequent acquire() leaks the old unit (it
      // overwrites self.audioUnit blindly) and AVAudioSession stays half-
      // active so the OS rejects the next setActive(true) again.
      stop()
      // Roll back the refcount so a subsequent release() doesn't see a
      // phantom owner and skip teardown — and so the next acquire() actually
      // attempts start() again instead of short-circuiting on refcount > 1.
      refcount = max(0, refcount - 1)
      throw error
    }
  }

  func release() {
    refcount = max(0, refcount - 1)
    if refcount == 0 {
      stop()
    }
  }

  private func start() throws {
    let session = AVAudioSession.sharedInstance()
    // Forcibly deactivate any half-active session left over from a previous
    // CallKit cycle BEFORE setting category. Rapid start/end cycles let iOS
    // hold the previous voiceChat session in a "blacklisted" state where
    // setActive(true) below fails with OSStatus 560557684 (audio_session_
    // failed) and the AudioUnit then produces no input frames. Doing this
    // pre-deactivate ourselves (rather than relying on the previous release()
    // to have done it) gives the OS audio graph a clean slate.
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
    // Forcibly deactivate any stale session first. Rapid CallKit cycling can
    // leave the previous voiceChat session in a half-released state, and the
    // subsequent setActive(true) then succeeds but never produces input
    // callbacks (the "iOS VoIP blacklist" symptom — peers see no audio out
    // from this device). notifyOthersOnDeactivation tells the system audio
    // routing graph to fully tear down before we re-arm.
    // setCategory must succeed — it tells iOS what we'll do (playAndRecord
    // + voiceChat enables AEC/AGC). Failure here means the audio subsystem
    // is in an unrecoverable state and we WANT to surface it.
    try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
    try? session.setPreferredSampleRate(sampleRate)
    try? session.setPreferredIOBufferDuration(0.02)
    // setActive(true) is best-effort: CallKit owns the audio session when
    // an incoming call accept routed us here, and any setActive call we make
    // before the CallKit `provider:didActivate` delegate runs is rejected
    // with OSStatus 561017449 (session activation failed). When that happens
    // CallKit has already activated the session on our behalf, so we just
    // log and continue — the VoiceProcessingIO AudioUnit below still works.
    do {
      try session.setActive(true)
      NSLog("[AudioIOSession] AVAudioSession active sampleRate=\(session.sampleRate) bufferDuration=\(session.ioBufferDuration)")
    } catch {
      NSLog("[AudioIOSession] setActive(true) declined (CallKit owns session?): \(error) — proceeding with AudioUnit anyway")
    }

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

    func check(_ status: OSStatus, _ op: String) throws {
      if status != noErr {
        throw NSError(domain: "AudioIOSession", code: Int(status),
                      userInfo: [NSLocalizedDescriptionKey: "\(op) failed: OSStatus=\(status)"])
      }
    }

    // Enable input bus (1) and output bus (0) for capture+playback.
    var enableIO: UInt32 = 1
    try check(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, UInt32(MemoryLayout<UInt32>.size)),
              "EnableIO input")
    try check(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &enableIO, UInt32(MemoryLayout<UInt32>.size)),
              "EnableIO output")

    // Common 16 kHz mono S16LE format for both buses.
    var format = AudioStreamBasicDescription(
      mSampleRate: sampleRate,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
      mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2,
      mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
    try check(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.size)),
              "StreamFormat input-scope-output")
    try check(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, UInt32(MemoryLayout<AudioStreamBasicDescription>.size)),
              "StreamFormat output-scope-input")

    // Input callback (mic → us)
    var inputCb = AURenderCallbackStruct(
      inputProc: AudioIOSession.inputCallback,
      inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
    try check(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &inputCb, UInt32(MemoryLayout<AURenderCallbackStruct>.size)),
              "SetInputCallback")

    // Output (render) callback (us → speaker)
    var outputCb = AURenderCallbackStruct(
      inputProc: AudioIOSession.renderCallback,
      inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
    try check(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &outputCb, UInt32(MemoryLayout<AURenderCallbackStruct>.size)),
              "SetRenderCallback")

    try check(AudioUnitInitialize(audioUnit), "AudioUnitInitialize")
    try check(AudioOutputUnitStart(audioUnit), "AudioOutputUnitStart")
    NSLog("[AudioIOSession] AudioUnit started — VoiceProcessingIO ready")
  }

  private func stop() {
    if let unit = audioUnit {
      let stopStatus = AudioOutputUnitStop(unit)
      let uninitStatus = AudioUnitUninitialize(unit)
      let disposeStatus = AudioComponentInstanceDispose(unit)
      NSLog("[AudioIOSession] AudioUnit teardown stop=\(stopStatus) uninit=\(uninitStatus) dispose=\(disposeStatus)")
      audioUnit = nil
    }
    // notifyOthersOnDeactivation: lets the OS audio graph fully release the
    // voiceChat session so the NEXT acquire() can re-activate cleanly. Without
    // this, rapid mesh-gc start/stop cycles leave the session "half-active"
    // and the next setActive(true) silently fails to enable mic capture.
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      NSLog("[AudioIOSession] AVAudioSession deactivated cleanly")
    } catch {
      NSLog("[AudioIOSession] AVAudioSession deactivation failed: \(error)")
    }
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
