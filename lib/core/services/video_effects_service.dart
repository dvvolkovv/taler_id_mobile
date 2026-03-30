import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/services.dart';

enum VideoEffect { none, blur, bg1, bg2, bg3, bg4, bg5, bg6, custom }

class VideoEffectsService {
  static const _channel = MethodChannel('taler_id/video_effects');

  VideoEffect _current = VideoEffect.none;
  VideoEffect get current => _current;

  static const _assetPaths = {
    VideoEffect.bg1: 'assets/backgrounds/bg_1.jpg',
    VideoEffect.bg2: 'assets/backgrounds/bg_2.jpg',
    VideoEffect.bg3: 'assets/backgrounds/bg_3.jpg',
    VideoEffect.bg4: 'assets/backgrounds/bg_4.jpg',
    VideoEffect.bg5: 'assets/backgrounds/bg_5.jpg',
    VideoEffect.bg6: 'assets/backgrounds/bg_6.jpg',
  };

  static const _thumbPaths = {
    VideoEffect.bg1: 'assets/backgrounds/bg_1_thumb.jpg',
    VideoEffect.bg2: 'assets/backgrounds/bg_2_thumb.jpg',
    VideoEffect.bg3: 'assets/backgrounds/bg_3_thumb.jpg',
    VideoEffect.bg4: 'assets/backgrounds/bg_4_thumb.jpg',
    VideoEffect.bg5: 'assets/backgrounds/bg_5_thumb.jpg',
    VideoEffect.bg6: 'assets/backgrounds/bg_6_thumb.jpg',
  };

  static String labelKeyFor(VideoEffect effect) {
    switch (effect) {
      case VideoEffect.none: return 'effectNone';
      case VideoEffect.blur: return 'effectBlur';
      case VideoEffect.bg1: return 'effectOffice';
      case VideoEffect.bg2: return 'effectNature';
      case VideoEffect.bg3: return 'effectGradient';
      case VideoEffect.bg4: return 'effectLibrary';
      case VideoEffect.bg5: return 'effectCity';
      case VideoEffect.bg6: return 'effectMinimalism';
      case VideoEffect.custom: return 'effectCustom';
    }
  }
  String? thumbPathFor(VideoEffect effect) => _thumbPaths[effect];

  Future<bool> isSupported() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// [trackId] — native MediaStreamTrack ID (needed on Android to find the track).
  Future<void> applyEffect(VideoEffect effect, {String? trackId}) async {
    if (effect == VideoEffect.none) {
      await stopEffect();
      return;
    }

    try {
      if (effect == VideoEffect.blur) {
        if (_current == VideoEffect.none) {
          await _channel.invokeMethod('startProcessing', {
            'effectType': 'blur',
            if (trackId != null) 'trackId': trackId,
          });
        } else {
          await _channel.invokeMethod('setEffect', {
            'effectType': 'blur',
          });
        }
      } else {
        final assetPath = _assetPaths[effect];
        if (assetPath == null) return;
        final data = await rootBundle.load(assetPath);
        final imageBytes = data.buffer.asUint8List();

        if (_current == VideoEffect.none) {
          await _channel.invokeMethod('startProcessing', {
            'effectType': 'background',
            'backgroundImageData': imageBytes,
            if (trackId != null) 'trackId': trackId,
          });
        } else {
          await _channel.invokeMethod('setEffect', {
            'effectType': 'background',
            'backgroundImageData': imageBytes,
          });
        }
      }
      _current = effect;
    } catch (e) {
      _current = VideoEffect.none;
      rethrow;
    }
  }

  /// Apply a custom image from file path or network URL (cached locally).
  Future<void> applyCustomImage(Uint8List imageBytes, {String? trackId}) async {
    try {
      if (_current == VideoEffect.none) {
        await _channel.invokeMethod('startProcessing', {
          'effectType': 'background',
          'backgroundImageData': imageBytes,
          if (trackId != null) 'trackId': trackId,
        });
      } else {
        await _channel.invokeMethod('setEffect', {
          'effectType': 'background',
          'backgroundImageData': imageBytes,
        });
      }
      _current = VideoEffect.custom;
    } catch (e) {
      _current = VideoEffect.none;
      rethrow;
    }
  }

  Future<void> stopEffect() async {
    try {
      await _channel.invokeMethod('stopProcessing');
    } catch (_) {}
    _current = VideoEffect.none;
  }

  /// Re-attach processor after camera re-enable or flip.
  Future<void> reattach() async {
    if (_current == VideoEffect.none) return;
    try {
      await _channel.invokeMethod('reattach');
    } catch (_) {}
  }
}
