// lib/core/platform/call_audio_configuration.dart
// LiveKit 2.4.1 does not export its audio-session hook; the implementation
// imports are the only way to it.
// ignore_for_file: implementation_imports
import 'package:livekit_client/src/support/native_audio.dart';
import 'package:livekit_client/src/track/audio_management.dart';

/// LiveKit re-applies its own AVAudioSession preset whenever the set of audio
/// tracks changes, and some presets (`playback`, `soloAmbient`) can't record.
/// While CallKit owns a conversation the session keeps the call's category;
/// otherwise LiveKit's defaults apply as before.
void installCallAudioConfiguration({required bool Function() callKitOwnsAudio}) {
  onConfigureNativeAudio = (state) async {
    if (callKitOwnsAudio()) {
      return NativeAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
        },
        appleAudioMode: AppleAudioMode.voiceChat,
      );
    }
    return defaultNativeAudioConfigurationFunc(state);
  };
}
