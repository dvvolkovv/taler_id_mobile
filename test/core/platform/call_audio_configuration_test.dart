// test/core/platform/call_audio_configuration_test.dart
// ignore_for_file: implementation_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/src/support/native_audio.dart';
import 'package:livekit_client/src/track/audio_management.dart';
import 'package:taler_id_mobile/core/platform/call_audio_configuration.dart';

void main() {
  tearDown(() => onConfigureNativeAudio = defaultNativeAudioConfigurationFunc);

  test('while CallKit owns a conversation every track state keeps the call category', () async {
    installCallAudioConfiguration(callKitOwnsAudio: () => true);
    for (final state in AudioTrackState.values) {
      final config = await onConfigureNativeAudio(state);
      expect(config.appleAudioCategory, AppleAudioCategory.playAndRecord, reason: '$state');
      expect(config.appleAudioMode, AppleAudioMode.voiceChat, reason: '$state');
      expect(config.appleAudioCategoryOptions,
          isNot(contains(AppleAudioCategoryOption.mixWithOthers)), reason: '$state');
    }
  });

  test('otherwise LiveKit decides as before', () async {
    installCallAudioConfiguration(callKitOwnsAudio: () => false);
    final config = await onConfigureNativeAudio(AudioTrackState.none);
    expect(config.appleAudioCategory, AppleAudioCategory.soloAmbient);
  });
}
