// lib/core/platform/call_audio_configuration.dart
// LiveKit 2.4.1 does not export its audio-session hook; the implementation
// imports are the only way to it.
// ignore_for_file: implementation_imports
import 'package:livekit_client/livekit_client.dart' show Hardware;
import 'package:livekit_client/src/support/native_audio.dart';
import 'package:livekit_client/src/track/audio_management.dart';

/// LiveKit re-applies its own AVAudioSession preset whenever the set of audio
/// tracks changes, and some presets (`playback`, `soloAmbient`) can't record.
/// While CallKit owns a conversation the session keeps the call's category
/// and mode; the output route (speaker vs. earpiece) is left exactly as
/// LiveKit would otherwise set it — mirrored from [preferSpeakerOutput]
/// rather than pinned, since the call screen already keeps `Hardware` in
/// sync with the route it applies. Otherwise LiveKit's defaults apply as
/// before.
void installCallAudioConfiguration({
  required bool Function() callKitOwnsAudio,
  bool Function()? preferSpeakerOutput,
}) {
  onConfigureNativeAudio = (state) async {
    if (callKitOwnsAudio()) {
      final resolveSpeakerOutput = preferSpeakerOutput ?? _defaultPreferSpeakerOutput;
      return NativeAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
        },
        appleAudioMode: AppleAudioMode.voiceChat,
        // The route stays LiveKit's, as before; only the category is pinned.
        preferSpeakerOutput: resolveSpeakerOutput(),
      );
    }
    return defaultNativeAudioConfigurationFunc(state);
  };
}

/// LiveKit's own default source for the speaker/earpiece route. Touched
/// lazily — only from inside the hook, only while CallKit owns the call —
/// so that code which never lets that happen (e.g. unit tests) never
/// constructs `Hardware.instance`: its constructor talks to flutter_webrtc
/// (`enumerateDevices`, `ondevicechange`), which throws MissingPluginException
/// off a platform channel that isn't mocked in a plain unit test.
bool _defaultPreferSpeakerOutput() => Hardware.instance.preferSpeakerOutput;
