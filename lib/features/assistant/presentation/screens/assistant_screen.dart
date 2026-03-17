import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';

enum _CallState { idle, connecting, connected, error }

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  _CallState _state = _CallState.idle;
  WebSocket? _ws;
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;
  final _player = AudioPlayer();

  bool _muted = false;
  bool _speakerOn = false;
  bool _aiSpeaking = false;
  bool _sessionConfigured = false;
  String? _errorMessage;

  // PCM16 audio buffer for AI speech
  final List<int> _audioBuffer = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late VideoPlayerController _logoVideo;
  bool _logoVideoReady = false;

  static const _audioChannel = MethodChannel('taler_id/audio');

  // Function call buffering
  String? _pendingCallId;
  String? _pendingCallName;
  final StringBuffer _pendingArgs = StringBuffer();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _logoVideo = VideoPlayerController.asset('assets/video.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _logoVideoReady = true);
          _logoVideo.play();
        }
      });
    _player.onPlayerComplete.listen((_) async {
      if (mounted) setState(() => _aiSpeaking = false);
      // On Android, audioplayers takes audio focus and stops the recorder.
      // Restart recording after playback completes.
      if (_ws != null && _state == _CallState.connected && !_muted) {
        await _recordSub?.cancel();
        _recordSub = null;
        await _recorder.stop();
        await _startRecording();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _logoVideo.dispose();
    _cleanup();
    _player.dispose();
    super.dispose();
  }

  Future<void> _cleanup() async {
    _sessionConfigured = false;
    _audioBuffer.clear();
    await _recordSub?.cancel();
    _recordSub = null;
    await _recorder.stop();
    await _ws?.close();
    _ws = null;
  }

  Future<void> _connect() async {
    setState(() {
      _state = _CallState.connecting;
      _errorMessage = null;
      _aiSpeaking = false;
    });
    try {
      // 1. Get JWT token (API key stays on server)
      final token = await sl<SecureStorageService>().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      // 2. Connect to backend WebSocket proxy
      final wsUrl = Uri(
        scheme: 'wss',
        host: Uri.parse(ApiConstants.baseUrl).host,
        path: '/voice/realtime-proxy',
        queryParameters: {'token': token},
      ).toString();
      _ws = await WebSocket.connect(wsUrl);

      // 3. Listen for messages from OpenAI via proxy
      _ws!.listen(
        (data) => _onMessage(data as String),
        onDone: () {
          if (mounted && _state == _CallState.connected) _endCall();
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _state = _CallState.error;
              _errorMessage = e.toString();
            });
          }
        },
      );

      // 4. Configure session
      _onChannelOpen();

      // 5. Enable speaker BEFORE recording so AudioSession is stable
      await _setSpeaker(true);

      // 6. Start recording microphone and streaming to OpenAI
      await _startRecording();

      setState(() => _state = _CallState.connected);
    } catch (e) {
      await _cleanup();
      setState(() {
        _state = _CallState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _onChannelOpen() {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    _sendEvent({
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions':
            'Ты — голосовой ассистент Taler ID. Помогай пользователям с вопросами о цифровой идентификации, '
            'статусе KYC-верификации и данных профиля. Отвечай кратко и по делу. '
            'Говори исключительно на русском языке. При необходимости вызывай инструменты для чтения или обновления профиля.',
        'voice': 'alloy',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {'model': 'whisper-1'},
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 500,
          'create_response': true,
        },
        'tools': [
          {
            'type': 'function',
            'name': 'get_profile',
            'description':
                'Get current user profile: firstName, lastName, email, username, phone',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'update_profile',
            'description': 'Update user profile fields (firstName, lastName, phone)',
            'parameters': {
              'type': 'object',
              'properties': {
                'firstName': {'type': 'string'},
                'lastName': {'type': 'string'},
                'phone': {'type': 'string'},
              },
            },
          },
        ],
        'tool_choice': 'auto',
      },
    });
  }

  Future<void> _startRecording() async {
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 24000,
      numChannels: 1,
    );
    final stream = await _recorder.startStream(config);
    _recordSub = stream.listen((chunk) {
      if (_muted || _ws == null) return;
      _sendEvent({
        'type': 'input_audio_buffer.append',
        'audio': base64Encode(chunk),
      });
    });
  }

  void _sendEvent(Map<String, dynamic> event) {
    _ws?.add(jsonEncode(event));
  }

  void _onMessage(String data) {
    try {
      final event = jsonDecode(data) as Map<String, dynamic>;
      final type = event['type'] as String? ?? '';

      if (type == 'response.audio.delta') {
        final delta = event['delta'] as String? ?? '';
        if (delta.isNotEmpty) {
          _audioBuffer.addAll(base64Decode(delta));
          if (mounted && !_aiSpeaking) setState(() => _aiSpeaking = true);
        }
      } else if (type == 'response.audio.done') {
        _playBufferedAudio();
      } else if (type == 'response.done') {
        if (_audioBuffer.isNotEmpty) _playBufferedAudio();
      } else if (type == 'response.function_call_arguments.delta') {
        _pendingCallId ??= event['call_id'] as String?;
        _pendingCallName ??= event['name'] as String?;
        _pendingArgs.write(event['delta'] as String? ?? '');
      } else if (type == 'response.function_call_arguments.done') {
        final callId = event['call_id'] as String? ?? _pendingCallId ?? '';
        final name = event['name'] as String? ?? _pendingCallName ?? '';
        final args = event['arguments'] as String? ?? _pendingArgs.toString();
        _pendingCallId = null;
        _pendingCallName = null;
        _pendingArgs.clear();
        _handleFunctionCall(callId, name, args);
      }
    } catch (_) {}
  }

  Future<void> _playBufferedAudio() async {
    if (_audioBuffer.isEmpty) return;
    final pcm = Uint8List.fromList(_audioBuffer);
    _audioBuffer.clear();
    final wav = _buildWav(pcm, sampleRate: 24000, channels: 1);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ai_response.wav');
      await file.writeAsBytes(wav);
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('[Assistant] playback error: $e');
    }
    if (mounted) setState(() => _aiSpeaking = true);
  }

  // Build a WAV file from raw PCM16 little-endian data
  Uint8List _buildWav(Uint8List pcm, {required int sampleRate, required int channels}) {
    final dataSize = pcm.length;
    final buf = ByteData(44 + dataSize);
    final byteRate = sampleRate * channels * 2;
    // RIFF
    buf.setUint32(0, 0x52494646, Endian.big);
    buf.setUint32(4, 36 + dataSize, Endian.little);
    buf.setUint32(8, 0x57415645, Endian.big);
    // fmt
    buf.setUint32(12, 0x666D7420, Endian.big);
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little);
    buf.setUint16(22, channels, Endian.little);
    buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, byteRate, Endian.little);
    buf.setUint16(32, channels * 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    // data
    buf.setUint32(36, 0x64617461, Endian.big);
    buf.setUint32(40, dataSize, Endian.little);
    final result = buf.buffer.asUint8List();
    result.setRange(44, 44 + dataSize, pcm);
    return result;
  }

  Future<void> _handleFunctionCall(
      String callId, String name, String argsJson) async {
    final client = sl<DioClient>();
    String output;
    try {
      if (name == 'get_profile') {
        final data = await client.get(
          '/profile',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'update_profile') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.put(
          '/profile',
          data: args,
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else {
        output = jsonEncode({'error': 'unknown function $name'});
      }
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }
    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': output,
      },
    });
    _sendEvent({'type': 'response.create'});
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    if (_muted) {
      _sendEvent({'type': 'input_audio_buffer.clear'});
    }
  }

  Future<void> _setSpeaker(bool on) async {
    try {
      await _audioChannel.invokeMethod('setSpeaker', on);
    } catch (_) {}
    setState(() => _speakerOn = on);
  }

  Future<void> _toggleSpeaker() => _setSpeaker(!_speakerOn);

  Future<void> _endCall() async {
    await _cleanup();
    await _setSpeaker(false);
    await _player.stop();
    if (mounted) {
      setState(() {
        _state = _CallState.idle;
        _muted = false;
        _aiSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(l10n.tabAssistant)),
      body: switch (_state) {
        _CallState.idle => _buildIdle(l10n),
        _CallState.connecting => _buildConnecting(l10n),
        _CallState.connected => _buildConnected(l10n),
        _CallState.error => _buildError(l10n),
      },
    );
  }

  Widget _buildIdle(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _connect,
            child: ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.of(context).card,
                  border: Border.all(color: AppColors.of(context).primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.of(context).primary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _logoVideoReady
                      ? SizedBox(
                          width: 120,
                          height: 120,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _logoVideo.value.size.width,
                              height: _logoVideo.value.size.height,
                              child: VideoPlayer(_logoVideo),
                            ),
                          ),
                        )
                      : Image.asset('app_icon_1024.png',
                          width: 120, height: 120, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.assistantTapToTalk,
            style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.assistantRealtimeDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.of(context).primary),
          const SizedBox(height: 24),
          Text(l10n.assistantConnectingToAssistant,
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildConnected(AppLocalizations l10n) {
    final speaking = _aiSpeaking;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final scale =
                speaking ? 1.0 + (_pulseAnim.value - 1.0) * 0.8 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.of(context).primary.withValues(alpha: 0.15),
              border: Border.all(
                color: speaking ? AppColors.of(context).primary : AppColors.of(context).border,
                width: speaking ? 2 : 1,
              ),
              boxShadow: speaking
                  ? [
                      BoxShadow(
                        color: AppColors.of(context).primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      )
                    ]
                  : null,
            ),
            child: ClipOval(
              child: _logoVideoReady
                  ? SizedBox(
                      width: 90,
                      height: 90,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _logoVideo.value.size.width,
                          height: _logoVideo.value.size.height,
                          child: VideoPlayer(_logoVideo),
                        ),
                      ),
                    )
                  : Image.asset('app_icon_1024.png',
                      width: 90, height: 90, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          speaking ? l10n.assistantAiSpeaking : l10n.assistantAiListening,
          style: TextStyle(
            color: speaking ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallButton(
                icon: _speakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: _speakerOn ? l10n.assistantSpeakerOn : l10n.assistantSpeaker,
                color: _speakerOn
                    ? AppColors.of(context).primary.withValues(alpha: 0.2)
                    : AppColors.of(context).card,
                iconColor:
                    _speakerOn ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
                onTap: _toggleSpeaker,
              ),
              _CallButton(
                icon: Icons.call_end_rounded,
                label: l10n.assistantEnd,
                color: AppColors.of(context).error,
                iconColor: Colors.white,
                onTap: _endCall,
                size: 72,
              ),
              _CallButton(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _muted ? l10n.assistantUnmute : l10n.assistantMicrophone,
                color: _muted
                    ? AppColors.of(context).error.withValues(alpha: 0.2)
                    : AppColors.of(context).card,
                iconColor: _muted ? AppColors.of(context).error : AppColors.of(context).textSecondary,
                onTap: _toggleMute,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.of(context).error),
            const SizedBox(height: 16),
            Text(l10n.assistantConnectionError,
                style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style:
                  TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.of(context).primary,
                  foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: AppColors.of(context).textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
