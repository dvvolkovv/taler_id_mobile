import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Listens for a wake phrase and triggers a callback.
///
/// Android: native SpeechRecognizer via MethodChannel (silent, mutes beep).
/// iOS: speech_to_text Flutter plugin (no beep on iOS).
///
/// Settings stored in Hive: enabled toggle + custom wake phrase.
class WakeWordService {
  WakeWordService._();
  static final instance = WakeWordService._();

  static const _wakeChannel = MethodChannel('taler_id/wake_word');
  static const _boxName = 'wake_word_settings';
  static const _keyEnabled = 'enabled';
  static const _keyPhrase = 'phrase';

  VoidCallback? _onWakeWord;
  bool _active = false;

  // Default phrases per language
  static const defaultPhraseRu = 'Привет, Талер';
  static const defaultPhraseEn = 'Hello Taler';

  // All recognized variations (lowercase)
  static List<String> _buildPhrases(String customPhrase) {
    final custom = customPhrase.toLowerCase().trim();
    final base = <String>{
      custom,
      // Russian variations
      'привет талер', 'привет taler', 'привет таллер',
      'привет тайлер', 'привет тэлер', 'привет тале',
      'привет аллер', 'привет алер', 'привет далер',
      'привет таллэр', 'приветствую талер',
      // English variations
      'hi taler', 'hey taler', 'hello taler',
    };
    return base.toList();
  }

  // ── Settings ──

  static Future<void> initBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static bool get isSettingEnabled {
    final box = Hive.box(_boxName);
    return box.get(_keyEnabled, defaultValue: false) as bool;
  }

  static set isSettingEnabled(bool v) {
    Hive.box(_boxName).put(_keyEnabled, v);
  }

  static String get settingPhrase {
    final box = Hive.box(_boxName);
    return box.get(_keyPhrase, defaultValue: '') as String;
  }

  static set settingPhrase(String v) {
    Hive.box(_boxName).put(_keyPhrase, v);
  }

  /// Returns the effective phrase based on settings and device locale.
  static String effectivePhrase(String locale) {
    final saved = settingPhrase;
    if (saved.isNotEmpty) return saved;
    return locale.startsWith('ru') ? defaultPhraseRu : defaultPhraseEn;
  }

  bool get isActive => _active;

  // ── Lifecycle ──

  Future<void> start({required VoidCallback onWakeWord}) async {
    _onWakeWord = onWakeWord;
    if (!isSettingEnabled) return;
    _active = true;

    if (Platform.isAndroid) {
      _wakeChannel.setMethodCallHandler((call) async {
        if (call.method == 'onWakeWord') {
          debugPrint('[WakeWord] DETECTED (native)!');
          _onWakeWord?.call();
        }
      });
      try {
        final phrase = effectivePhrase('ru').toLowerCase();
        await _wakeChannel.invokeMethod('start', {'customPhrase': phrase});
      } catch (e) {
        debugPrint('[WakeWord] Android start failed: $e');
      }
    } else if (Platform.isIOS) {
      _triggered = false;
      await _initSttIOS();
      _startSttIOS();
    }
  }

  void stop() {
    _active = false;
    // Keep _onWakeWord — resume() needs it
    if (Platform.isAndroid) {
      try { _wakeChannel.invokeMethod('stop'); } catch (_) {}
    } else {
      _restartTimer?.cancel();
      if (_sttListening) { _speech?.stop(); _sttListening = false; }
    }
  }

  void pause() {
    if (Platform.isAndroid) {
      try { _wakeChannel.invokeMethod('pause'); } catch (_) {}
    } else {
      _restartTimer?.cancel();
      if (_sttListening) { _speech?.stop(); _sttListening = false; }
    }
  }

  void resume() {
    if (!isSettingEnabled) return;
    _active = true;
    if (Platform.isAndroid) {
      debugPrint('[WakeWord] resume (native)');
      // Re-register handler in case it was lost
      _wakeChannel.setMethodCallHandler((call) async {
        if (call.method == 'onWakeWord') {
          debugPrint('[WakeWord] DETECTED (native)!');
          _onWakeWord?.call();
        }
      });
      try {
        final phrase = effectivePhrase('ru').toLowerCase();
        _wakeChannel.invokeMethod('resume', {'customPhrase': phrase});
      } catch (_) {}
    } else {
      debugPrint('[WakeWord] resume (iOS)');
      _triggered = false;
      if (!_sttListening) _scheduleRestartIOS();
    }
  }

  // ── iOS only: speech_to_text ──

  stt.SpeechToText? _speech;
  bool _sttInitialized = false;
  bool _sttListening = false;
  bool _triggered = false;
  Timer? _restartTimer;

  Future<void> _initSttIOS() async {
    if (_sttInitialized) return;
    _speech = stt.SpeechToText();
    try {
      _sttInitialized = await _speech!.initialize(
        onError: (e) {
          _sttListening = false;
          if (_active) _scheduleRestartIOS();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _sttListening = false;
            if (_active) _scheduleRestartIOS();
          }
        },
      );
      debugPrint('[WakeWord] iOS STT initialized: $_sttInitialized');
    } catch (e) {
      debugPrint('[WakeWord] iOS STT init failed: $e');
    }
  }

  void _startSttIOS() {
    if (!_active || !_sttInitialized || _sttListening) return;
    _sttListening = true;
    final phrases = _buildPhrases(effectivePhrase('en'));
    _speech!.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase().trim();
        if (text.isNotEmpty && !_triggered) {
          for (final phrase in phrases) {
            if (text.contains(phrase)) {
              debugPrint('[WakeWord] DETECTED (iOS)!');
              _triggered = true;
              _speech!.stop();
              _sttListening = false;
              _restartTimer?.cancel();
              _onWakeWord?.call();
              return;
            }
          }
        }
      },
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(hours: 1),
      listenFor: const Duration(hours: 1),
      // Use Russian locale — most users speak Russian to the assistant
      localeId: 'ru-RU',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        autoPunctuation: false,
        onDevice: true,
      ),
    );
  }

  void _scheduleRestartIOS() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 5), () {
      if (_active && !_sttListening) _startSttIOS();
    });
  }
}
