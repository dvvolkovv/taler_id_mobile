//
//  CallkitIncomingAppDelegate.swift
//  flutter_callkit_incoming
//
//  Created by Hien Nguyen on 05/01/2024.
//

import Foundation
import AVFAudio
import CallKit


@objc public protocol CallkitIncomingAppDelegate : NSObjectProtocol {

    func onAccept(_ call: Call, _ action: CXAnswerCallAction);

    func onDecline(_ call: Call, _ action: CXEndCallAction);

    func onEnd(_ call: Call, _ action: CXEndCallAction);

    func onTimeOut(_ call: Call);

    func didActivateAudioSession(_ audioSession: AVAudioSession)

    func didDeactivateAudioSession(_ audioSession: AVAudioSession)

    // PATCH P13 (Taler ID): optional so existing conformers keep compiling —
    // forwarded from providerDidReset (P9), after its own cleanup, so the
    // app can unwind CallKit-only state (e.g. our CallKit/WebRTC audio
    // bridge) that per-call ENDED events alone would not reach.
    @objc optional func providerDidReset()

}
