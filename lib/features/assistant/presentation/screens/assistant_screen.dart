import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/platform/platform_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import '../../../voice_enrollment/presentation/bloc/voice_enrollment_bloc.dart';
import '../../../voice_enrollment/presentation/bloc/voice_enrollment_event.dart';
import '../../../voice_enrollment/presentation/bloc/voice_enrollment_state.dart';
import '../../../voice_enrollment/presentation/widgets/owner_enrollment_sheet.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../audio/pcm_gain.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/linkified_text.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../../core/services/wake_word_service.dart';
import '../../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_event.dart';
import '../../../messenger/presentation/bloc/messenger_state.dart';
import '../../../billing/data/services/billing_event_bus.dart';
import '../../../billing/data/services/voice_billing_bridge.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart';
import '../../data/assistant_chat_api.dart';
import '../../data/assistant_chat_logger.dart';
import '../../domain/assistant_action.dart';
import '../../tools/assistant_system_prompt.dart';
import '../../tools/assistant_tools_executor.dart';
import '../../tools/assistant_tools_schema.dart';

enum _CallState { idle, connecting, connected, error }
enum _AssistantMode { normal, translator }

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  /// Set to true before navigating to auto-connect on open (wake word trigger).
  static bool autoConnect = false;

  /// Notifier for wake word when already on assistant screen.
  static final connectNotifier = ValueNotifier<int>(0);
  static void triggerConnect() => connectNotifier.value++;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  _CallState _state = _CallState.idle;
  _AssistantMode _mode = _AssistantMode.normal;
  String? _assistantName; // preferred form of address (Profile.assistantName / firstName)
  bool _assistantNameFromProfile = false; // true when explicitly set (vs firstName fallback)
  String? _langA;  // ISO code of first detected language in translator mode
  String? _langB;  // ISO code of second detected language (≠ _langA)
  bool _switchingMode = false;  // true during WebSocket reconnect for mode switch
  WebSocket? _ws;
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;
  final _player = AudioPlayer();

  bool _muted = false;
  bool _navigatingToCall = false;
  bool _speakerOn = false;
  bool _aiSpeaking = false;
  bool _sessionConfigured = false;
  String? _errorMessage;

  // PCM16 audio buffer for AI speech
  final List<int> _audioBuffer = [];

  // Live transcript: list of {role: 'user'|'assistant', text: String, itemId: String?}
  final List<_TranscriptMessage> _transcript = [];
  final ScrollController _transcriptCtrl = ScrollController();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _orbitCtrl;

  // Manual orbit drag + fling
  double _orbitAngle = 0; // current angle in radians
  double _orbitVelocity = 0.2; // radians per second (default slow spin)
  bool _isDragging = false;
  Duration _lastOrbitTick = Duration.zero;
  static const double _defaultOrbitSpeed = 0.07; // ~90s per revolution
  static const double _friction = 0.97; // velocity decay per tick

  static const _audioChannel = MethodChannel('taler_id/audio');

  // Function call buffering
  String? _pendingCallId;
  String? _pendingCallName;
  final StringBuffer _pendingArgs = StringBuffer();

  // Translator mode: pair user with assistant response
  String? _lastAssistantItemId;  // most recent assistant item id, used for translator-mode pairing

  // agent_task: conversation continuity across multiple agent_task calls within a voice session.
  // Reset on each new session via _connect().
  String? _agentConversationId;

  // Tool execution (former _handleFunctionCall switch). Session-bound
  // behaviors are wired back into this screen via AssistantSessionHooks.
  late final AssistantToolsExecutor _toolsExecutor;

  // Best-effort replication of the voice transcript (+ action bubbles) into
  // the persistent assistant chat thread on the backend.
  late final AssistantChatLogger _chatLogger;

  // Incoming message listener
  StreamSubscription? _messageSub;

  // Billing bridge: owns POST /voice/session, heartbeat, close.
  // Created per connect, disposed on cleanup.
  VoiceBillingBridge? _billing;
  StreamSubscription<AiSessionTerminatedEvent>? _terminatedSub;
  DateTime? _sessionStartedAt;

  @override
  void initState() {
    super.initState();
    _chatLogger = AssistantChatLogger(
      flush: (entries) => sl<AssistantChatApi>().logEntries(entries),
    );
    _toolsExecutor = AssistantToolsExecutor(
      onAction: (a) => _chatLogger.addAction(
        role: 'assistant',
        source: 'voice',
        text: a.title,
        action: a.toJson(),
      ),
      hooks: AssistantSessionHooks(
        endSession: () async {
          // Send output first so AI can say goodbye, then disconnect after 2s
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _endCall();
          });
          return jsonEncode({'status': 'ending'});
        },
        onPreferredNameChanged: (newName) {
          if (mounted) {
            setState(() {
              _assistantName = newName;
              _assistantNameFromProfile = true;
            });
          }
        },
        applyTheme: (theme) {
          if (mounted) {
            final mode = switch (theme) {
              'dark' => ThemeMode.dark,
              'system' => ThemeMode.system,
              _ => ThemeMode.light,
            };
            TalerIdApp.setThemeMode(context, mode);
          }
        },
        applyLanguage: (lang) {
          if (mounted) {
            TalerIdApp.setLocale(context, Locale(lang));
          }
        },
        localeCode: () =>
            mounted ? Localizations.localeOf(context).languageCode : 'ru',
        getAgentConversationId: () => _agentConversationId,
        setAgentConversationId: (id) => _agentConversationId = id,
      ),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _orbitCtrl.addListener(_tickOrbit);
    _lastOrbitTick = Duration.zero;
    _player.onPlayerComplete.listen((_) async {
      if (mounted) setState(() => _aiSpeaking = false);
      // Restart recording after playback completes.
      if (_ws != null && _state == _CallState.connected && !_muted) {
        await _recordSub?.cancel();
        _recordSub = null;
        try { await _recorder.stop(); } catch (_) {}
        await _startRecording();
      }
    });
    // Listen for wake word trigger while already on this screen
    AssistantScreen.connectNotifier.addListener(_onWakeWordTrigger);
    // Auto-connect if triggered by wake word
    if (AssistantScreen.autoConnect) {
      AssistantScreen.autoConnect = false;
      debugPrint('[WakeWord] Auto-connecting assistant...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == _CallState.idle) {
          debugPrint('[WakeWord] Calling _connect()');
          _connect();
        }
      });
    } else if (PlatformUtils.instance.isDesktop) {
      // Desktop: skip the idle "restart" screen on first entry — start the
      // voice session immediately. Mobile keeps the manual tap-to-start gesture.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == _CallState.idle) _connect();
      });
    }
  }

  void _tickOrbit() {
    if (!mounted) return;
    final now = _orbitCtrl.lastElapsedDuration ?? Duration.zero;
    final dt = _lastOrbitTick == Duration.zero
        ? 1 / 60
        : (now - _lastOrbitTick).inMicroseconds / 1e6;
    _lastOrbitTick = now;
    if (dt <= 0 || dt > 0.5) return; // skip glitches

    if (!_isDragging) {
      _orbitAngle += _orbitVelocity * dt;
      // Decay towards default speed
      if (_orbitVelocity.abs() > _defaultOrbitSpeed * 2) {
        _orbitVelocity *= _friction;
      } else {
        // Smoothly return to default
        _orbitVelocity += (_defaultOrbitSpeed - _orbitVelocity) * 0.02;
      }
    }
    setState(() {});
  }

  void _onOrbitPanStart(DragStartDetails details) {
    _isDragging = true;
    HapticFeedback.selectionClick();
  }

  void _onOrbitPanUpdate(DragUpdateDetails details, Offset center, double radius) {
    final pos = details.localPosition - center;
    final prev = pos - details.delta;
    // Compute angular change from cross product
    final cross = prev.dx * pos.dy - prev.dy * pos.dx;
    final dot = prev.dx * pos.dx + prev.dy * pos.dy;
    final dAngle = math.atan2(cross, dot);
    _orbitAngle += dAngle;
    // Store velocity for fling
    _orbitVelocity = dAngle / (1 / 60); // approximate: assume 60fps ticks
  }

  void _onOrbitPanEnd(DragEndDetails details) {
    _isDragging = false;
    // Amplify fling velocity for satisfying spin
    _orbitVelocity *= 1.5;
    if (_orbitVelocity.abs() > 0.5) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    unawaited(_chatLogger.flushNow());
    _chatLogger.dispose();
    AssistantScreen.connectNotifier.removeListener(_onWakeWordTrigger);
    _orbitCtrl.removeListener(_tickOrbit);
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _transcriptCtrl.dispose();
    _cleanup();
    _player.dispose();
    super.dispose();
  }

  Future<void> _cleanup() async {
    _sessionConfigured = false;
    _audioBuffer.clear();
    await _messageSub?.cancel();
    _messageSub = null;
    await _recordSub?.cancel();
    _recordSub = null;
    await _recorder.stop();
    // Finalize billing BEFORE closing the WS so the backend still has the
    // session active when it receives the close call. Best-effort — any
    // failure is swallowed by VoiceBillingBridge.stop().
    await _terminatedSub?.cancel();
    _terminatedSub = null;
    final bridge = _billing;
    if (bridge != null) {
      final secs = _sessionStartedAt == null
          ? 0
          : DateTime.now().difference(_sessionStartedAt!).inSeconds;
      await bridge.stop(durationSec: secs);
      await bridge.dispose();
    }
    _billing = null;
    _sessionStartedAt = null;
    await _ws?.close();
    _ws = null;
  }

  void _onWakeWordTrigger() {
    if (mounted && _state == _CallState.idle) {
      debugPrint('[WakeWord] connectNotifier triggered → _connect()');
      _connect();
    }
  }

  /// Voice owner gating bootstrap: check whether the user has enrolled
  /// their voice profile. If not, show a bottom sheet to record it. Cancel
  /// is non-fatal — the WS proxy on the backend fails open when no embedding
  /// is stored, so the assistant still works without gating.
  Future<bool> _ensureOwnerEnrolled() async {
    final bloc = sl<VoiceEnrollmentBloc>();
    bloc.add(const Check());
    final settled = await bloc.stream.firstWhere(
      (s) => s is Enrolled || s is NotEnrolled || s is Failed,
    );
    if (settled is Enrolled) return true;
    if (settled is Failed) return false; // be forgiving — let the session run
    if (!mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: const OwnerEnrollmentSheet(),
      ),
    );
    return result == true;
  }

  Future<void> _connect() async {
    setState(() {
      _state = _CallState.connecting;
      _errorMessage = null;
      _aiSpeaking = false;
    });
    // Reset agent_task conversation continuity for the new realtime session.
    _agentConversationId = null;
    try {
      // 1. Get JWT token (API key stays on server)
      final token = await sl<SecureStorageService>().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      // 1b. Load the preferred form of address for the system prompt:
      // explicit Profile.assistantName wins, firstName is the fallback,
      // empty means the assistant will ask and save via set_preferred_name.
      try {
        final prof = await sl<DioClient>().get<Map<String, dynamic>>(
          '/profile',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        final explicit = (prof['assistantName'] as String?)?.trim();
        final first = (prof['firstName'] as String?)?.trim();
        _assistantName = (explicit?.isNotEmpty ?? false)
            ? explicit
            : ((first?.isNotEmpty ?? false) ? first : null);
        _assistantNameFromProfile = explicit?.isNotEmpty ?? false;
      } catch (_) {
        // Non-fatal: prompt degrades to "ask the user".
      }

      // 1a. Open billing session. Pre-flight check for feature toggle +
      // minReserve balance happens server-side; 402 insufficient-funds
      // surfaces via the global Dio interceptor (InsufficientFundsSheet).
      // We keep the returned billingSessionId for heartbeat + close.
      _billing = sl<VoiceBillingBridge>();
      try {
        await _billing!.start();
        _sessionStartedAt = DateTime.now();
        _terminatedSub?.cancel();
        _terminatedSub = _billing!.onTerminated.listen(_onSessionTerminated);
      } catch (e) {
        // Insufficient funds or backend unavailable — abort before opening
        // the OpenAI socket so we don't consume bandwidth for nothing.
        _billing = null;
        rethrow;
      }

      // 1b. Voice owner gating (experimental). First-time users get a
      // bottom sheet asking them to record ~20 sec of their voice; that
      // profile lets the WS proxy retract OpenAI input when a non-owner
      // voice (TV, other person) leaks into the mic. If the user cancels
      // the sheet we still let the session run — the proxy fails open.
      await _ensureOwnerEnrolled();
      if (!mounted) return;

      // 2. Connect to backend WebSocket proxy
      // billingSessionId lets the proxy call gating.endSession when the WS
      // dies (app crash, network drop) — without it the cron keeps tickling
      // the wallet at /10s for a zombie session (incident 2026-05-26).
      final wsUrl = Uri(
        scheme: 'wss',
        host: Uri.parse(ApiConstants.baseUrl).host,
        path: '/voice/realtime-proxy',
        queryParameters: {
          'token': token,
          if (_billing?.sessionId?.isNotEmpty == true)
            'billingSessionId': _billing!.sessionId!,
        },
      ).toString();
      _ws = await WebSocket.connect(wsUrl);

      // 3. Listen for messages from OpenAI via proxy
      _ws!.listen(
        (data) => _onMessage(data as String),
        onDone: () {
          // During mode switch we intentionally close the old WebSocket — don't end the session.
          if (mounted && _state == _CallState.connected && !_navigatingToCall && !_switchingMode) _endCall();
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

      // Listen for incoming messages and notify AI
      _messageSub = sl<MessengerRemoteDataSource>().messageStream.listen(_onIncomingMessage);

      // No greeting — start listening immediately
      WakeWordService.instance.pause();
      setState(() => _state = _CallState.connected);
    } catch (e) {
      await _cleanup();
      setState(() {
        _state = _CallState.error;
        _errorMessage = e.toString();
      });
    }
  }

  String _systemPrompt(String locale) => assistantSystemPrompt(
        locale: locale,
        preferredName: _assistantName,
        nameFromProfile: _assistantNameFromProfile,
      );

  static String _translatorPrompt() {
    return 'YOU ARE A LIVE TRANSLATION MACHINE. NOT AN ASSISTANT. NOT A CHATBOT.\n\n'
        'Two people are speaking different languages. The phone is on the table '
        'between them. Your ONLY job: translate every utterance from one language '
        'into the other, in real time.\n\n'
        'RULES (violating these breaks the product — do NOT violate):\n\n'
        '1. Auto-detect the two languages from the first 1-2 utterances. Once '
        'detected, stick with them. Do not translate into a third language '
        'even if someone briefly uses it.\n\n'
        '2. Translate EVERY utterance. No exceptions. No commentary. No summary. '
        'No "the speaker said...". Just the translation, as if you were the '
        'speaker in the other language.\n\n'
        '3. You are INVISIBLE. You do NOT exist in this conversation. Do NOT:\n'
        '   - answer questions directed at you\n'
        '   - offer help, suggestions, opinions, explanations\n'
        '   - ask clarifying questions\n'
        '   - say "I am translating" or "got it" or any filler\n'
        '   - react to greetings, jokes, insults, compliments — translate them\n'
        '   - call any tool except exit_translator_mode\n\n'
        '4. If someone says "what do you think?", "can you translate?", '
        '"assistant, explain that" — these are NOT directed at you. They are '
        'part of the conversation. TRANSLATE THEM. Do not respond.\n\n'
        '5. If the audio is silence, background noise, or unintelligible — '
        'output NOTHING. Do not say "I didn\'t catch that". Just wait.\n\n'
        '6. ONE EXCEPTION — the owner\'s exit phrase. If and ONLY if you hear '
        'ANY of these exact phrases spoken clearly:\n'
        '   - "Ассистент, стоп"\n'
        '   - "выйди из роли"\n'
        '   - "хватит переводить"\n'
        '   - "stop translator"\n'
        '   - "exit translator"\n'
        '   → call exit_translator_mode(). Do not translate that phrase. Do not '
        'say anything. Just call the tool.\n\n'
        '7. Output language: translate A→B and B→A. Never output in the source '
        'language. Never output both languages at once.\n\n'
        '8. Tone: match the speaker. Formal → formal. Casual → casual. Rude → rude. '
        'Keep names, numbers, places exact.\n\n'
        'You have exactly one tool: exit_translator_mode. Use it ONLY on the '
        'exit phrases above. Never call it otherwise.\n\n'
        'Begin listening. Say nothing until someone speaks.';
  }

  Map<String, dynamic> _translatorSessionConfig() {
    return {
      'modalities': ['text', 'audio'],
      'instructions': _translatorPrompt(),
      'voice': 'alloy',
      'input_audio_format': 'pcm16',
      'output_audio_format': 'pcm16',
      // No language pin — we want Whisper to auto-detect each speaker.
      'input_audio_transcription': {'model': 'whisper-1'},
      'turn_detection': {
        'type': 'server_vad',
        'threshold': 0.6,
        'prefix_padding_ms': 300,
        'silence_duration_ms': 700,
        'create_response': true,
      },
      'tools': assistantToolSchemas(translatorMode: true),
      'tool_choice': 'auto',
    };
  }

  void _onChannelOpen() {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    final locale = Localizations.localeOf(context).languageCode;

    // Translator mode — send the minimal translator session and return.
    // No briefing prompt: translator must stay silent until someone speaks.
    if (_mode == _AssistantMode.translator) {
      _sendEvent({
        'type': 'session.update',
        'session': _translatorSessionConfig(),
      });
      return;
    }

    _sendEvent({
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': _systemPrompt(locale),
        'voice': 'alloy',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        // Pin Whisper to the app's locale so transcription doesn't drift into
        // Spanish/German when the first utterance is ambiguous.
        'input_audio_transcription': {'model': 'whisper-1', 'language': locale},
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 500,
          'create_response': true,
        },
        'tools': assistantToolSchemas(translatorMode: false),
        'tool_choice': 'auto',
      },
    });

    // Auto-briefing on session start: greet briefly, then check for unread/missed
    final briefingPrompt = locale == 'ru'
        ? 'АВТОМАТИЧЕСКИЙ ЗАПУСК: Сначала скажи "Слушаю вас" (коротко, одна фраза). '
          'Затем тихо проверь:\n'
          '1. get_conversations — диалоги с unreadCount > 0 (непрочитанные сообщения)\n'
          '2. get_contact_requests — входящие заявки в контакты\n'
          '3. get_call_history — пропущенные звонки за последние 24 часа\n'
          '4. get_events — события и приглашения на сегодня\n'
          'Если есть что-то новое — кратко сообщи после приветствия: '
          '"У вас N непрочитанных сообщений / N пропущенных звонков / событие на сегодня". '
          'Предложи обработать голосом. '
          'Если всё чисто — жди запроса пользователя, больше ничего не говори.'
        : 'AUTO-START: First say "I\'m listening" (brief, one phrase). '
          'Then silently check:\n'
          '1. get_conversations — unread messages (unreadCount > 0)\n'
          '2. get_contact_requests — pending contact requests\n'
          '3. get_call_history — missed calls in last 24 hours\n'
          '4. get_events — today\'s events and invitations\n'
          'If there is something new — briefly mention after greeting: '
          '"You have N unread messages / N missed calls / event today". '
          'Offer to handle by voice. '
          'If all clear — wait for user, say nothing else.';

    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': briefingPrompt},
        ],
      },
    });
    _sendEvent({'type': 'response.create'});
  }

  Future<void> _switchMode(
    _AssistantMode target, {
    String? langA,
    String? langB,
  }) async {
    if (!mounted) return;
    if (_switchingMode) return; // guard against double triggers
    debugPrint('[Assistant] switchMode $_mode → $target langA=$langA langB=$langB');

    setState(() {
      _switchingMode = true;
      _aiSpeaking = false;
      _mode = target;
      if (target == _AssistantMode.translator) {
        // Explicit pair from the tool call wins; nulls fall back to
        // per-utterance auto-detection.
        _langA = langA;
        _langB = langB;
      }
    });

    // Stop audio and recording cleanly
    await _player.stop();
    _audioBuffer.clear();
    await _recordSub?.cancel();
    _recordSub = null;
    try { await _recorder.stop(); } catch (_) {}

    // Close current WebSocket
    await _ws?.close();
    _ws = null;
    _sessionConfigured = false;

    // Reopen new WebSocket + configure for target mode
    try {
      final token = await sl<SecureStorageService>().getAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final wsUrl = Uri(
        scheme: 'wss',
        host: Uri.parse(ApiConstants.baseUrl).host,
        path: '/voice/realtime-proxy',
        queryParameters: {
          'token': token,
          if (_billing?.sessionId?.isNotEmpty == true)
            'billingSessionId': _billing!.sessionId!,
        },
      ).toString();
      _ws = await WebSocket.connect(wsUrl);
      _ws!.listen(
        (data) => _onMessage(data as String),
        onDone: () {
          // Same guard as in _connect — ignore close events triggered by mode switch.
          if (mounted && _state == _CallState.connected && !_navigatingToCall && !_switchingMode) _endCall();
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
      _onChannelOpen(); // uses _mode internally
      await _startRecording();
    } catch (e) {
      debugPrint('[Assistant] switchMode failed: $e');
      if (mounted) {
        setState(() {
          _state = _CallState.error;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _switchingMode = false);
    }
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
      // Half-duplex: не шлём микрофон пока AI говорит — иначе его голос ловится
      // через динамик обратно в мик и whisper транскрибирует эхо как реплику юзера.
      if (_aiSpeaking) return;
      _sendEvent({
        'type': 'input_audio_buffer.append',
        'audio': base64Encode(chunk),
      });
    });
  }

  void _sendEvent(Map<String, dynamic> event) {
    _ws?.add(jsonEncode(event));
  }

  /// Append text delta to an existing transcript message (by itemId) or create new
  void _appendTranscript(String role, String delta, String itemId) {
    if (!mounted) return;
    setState(() {
      final idx = _transcript.indexWhere((m) => m.itemId == itemId && m.role == role);
      if (idx >= 0) {
        _transcript[idx] = _transcript[idx].copyWith(text: _transcript[idx].text + delta);
      } else {
        _transcript.add(_TranscriptMessage(role: role, text: delta, itemId: itemId));
      }
    });
    _scrollTranscriptToBottom();
  }

  /// Replace full transcript for an item (used on .done events with final text)
  void _replaceTranscript(String role, String text, String itemId, {String? originalLang}) {
    if (!mounted) return;
    setState(() {
      final idx = _transcript.indexWhere((m) => m.itemId == itemId && m.role == role);
      if (idx >= 0) {
        _transcript[idx] = _transcript[idx].copyWith(text: text, originalLang: originalLang);
      } else {
        _transcript.add(_TranscriptMessage(
          role: role,
          text: text,
          itemId: itemId,
          originalLang: originalLang,
        ));
      }
    });
    _scrollTranscriptToBottom();
  }

  void _updateLanguagePair(String? lang) {
    if (lang == null || lang.isEmpty) return;
    // 'en' from script detection is unreliable: any latin noise in a Whisper
    // transcript maps to 'en' and used to lock RU+EN before the real second
    // language was ever spoken. Only accept 'en' as _langB when _langA is
    // already a non-latin-script language and the pair came from detection.
    if (_langA == null) {
      setState(() => _langA = lang);
      return;
    }
    if (_langB == null && lang != _langA) {
      setState(() => _langB = lang);
    }
  }

  void _pairLastUserWithAssistant(String assistantItemId) {
    if (!mounted) return;
    setState(() {
      // Find the most recent user message without a pair, walking backwards.
      for (int i = _transcript.length - 1; i >= 0; i--) {
        final m = _transcript[i];
        if (m.role == 'user' && m.pairedItemId == null) {
          _transcript[i] = m.copyWith(pairedItemId: assistantItemId);
          break;
        }
      }
    });
  }

  void _scrollTranscriptToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptCtrl.hasClients) {
        _transcriptCtrl.animateTo(
          _transcriptCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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
      } else if (type == 'response.audio_transcript.delta') {
        // AI speech transcript (live) — item_id is the assistant response item
        final delta = event['delta'] as String? ?? '';
        final itemId = event['item_id'] as String? ?? '';
        debugPrint('[Assistant] ai.delta item=$itemId');
        if (delta.isNotEmpty) _appendTranscript('assistant', delta, 'ai:$itemId');
      } else if (type == 'response.audio_transcript.done') {
        final transcript = event['transcript'] as String? ?? '';
        final itemId = event['item_id'] as String? ?? '';
        debugPrint('[Assistant] ai.done item=$itemId text=$transcript');
        if (transcript.isNotEmpty) {
          _replaceTranscript('assistant', transcript, 'ai:$itemId');
          // Finalized assistant replica — replicate to the chat thread.
          // Translator mode is a pass-through of other people's speech —
          // never persist it.
          if (_mode != _AssistantMode.translator) {
            _chatLogger.addAssistant(transcript, source: 'voice');
          }
        }
        if (itemId.isNotEmpty) _lastAssistantItemId = 'ai:$itemId';
      } else if (type == 'conversation.item.created') {
        // User voice items are created in true conversation order, while the
        // input transcription completes only AFTER the assistant already
        // started answering — appending on transcription made the user's
        // message land below the answer. Insert a placeholder now; the
        // transcription event replaces its text in place.
        final item = event['item'] as Map<String, dynamic>?;
        final role = item?['role'] as String? ?? '';
        final createdId = item?['id'] as String? ?? '';
        if (role == 'user' && createdId.isNotEmpty) {
          final exists = _transcript.any((m) => m.itemId == 'user:$createdId');
          if (!exists) _appendTranscript('user', '…', 'user:$createdId');
        }
      } else if (type == 'conversation.item.deleted') {
        // Voice-gate retracts foreign turns (YouTube, other people) with
        // conversation.item.delete — drop them from the visible transcript.
        final deletedId = event['item_id'] as String? ?? '';
        if (deletedId.isNotEmpty) {
          // Retracted foreign speech must not be persisted to the chat thread.
          _chatLogger.dropByItemId(deletedId);
          if (mounted) {
            setState(() =>
                _transcript.removeWhere((m) => m.itemId == 'user:$deletedId'));
          }
        }
      } else if (type == 'conversation.item.input_audio_transcription.completed') {
        // User speech transcript (after whisper finishes)
        final transcript = event['transcript'] as String? ?? '';
        final itemId = event['item_id'] as String? ?? '';
        // Whisper's transcription.completed event doesn't actually include a
        // language field in the current Realtime API — fall back to script-based
        // detection from the transcript text.
        final lang = (event['language'] as String?) ?? _detectLanguageFromText(transcript);
        debugPrint('[Assistant] user.done item=$itemId lang=$lang text=$transcript');
        if (transcript.isNotEmpty) {
          _replaceTranscript('user', transcript, 'user:$itemId', originalLang: lang);
          if (_mode == _AssistantMode.translator) _updateLanguagePair(lang);
          // Whisper delivers the whole user turn at once — this is the final
          // user replica for the item, replicate to the chat thread. Tag with
          // the item id so a later voice-gate retraction can drop it before
          // flush. Translator mode: never persist (foreign speech).
          if (_mode != _AssistantMode.translator) {
            _chatLogger.addUser(transcript, source: 'voice', itemId: itemId);
          }
        }
      } else if (type == 'response.audio.done') {
        _playBufferedAudio();
      } else if (type == 'response.done') {
        if (_audioBuffer.isNotEmpty) _playBufferedAudio();
        if (_mode == _AssistantMode.translator && _lastAssistantItemId != null) {
          _pairLastUserWithAssistant(_lastAssistantItemId!);
        }
        _lastAssistantItemId = null;
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

  // OpenAI Realtime PCM is quiet on the in-call audio session; boost like
  // the backend does for translator TTS (TRANSLATOR_GAIN).
  static const double _playbackGain = 1.8;

  Future<void> _playBufferedAudio() async {
    if (_audioBuffer.isEmpty) return;
    final pcm = amplifyPcm16(Uint8List.fromList(_audioBuffer), _playbackGain);
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

  void _onIncomingMessage(dynamic msg) {
    if (_ws == null || _state != _CallState.connected) return;
    final senderName = msg.senderName ?? 'Unknown';
    final content = msg.content;
    final conversationId = msg.conversationId;
    if (content == null || content.isEmpty) return;

    // AI Analyst bot responses: proactively tell the user what the
    // analyst said, instead of waiting for them to ask.
    if (msg.isSystem && senderName == 'AI Аналитик') {
      final summary = content.length > 600
          ? '${content.substring(0, 600)}...'
          : content;
      _sendEvent({
        'type': 'conversation.item.create',
        'item': {
          'type': 'message',
          'role': 'user',
          'content': [
            {
              'type': 'input_text',
              'text': '[СИСТЕМНОЕ УВЕДОМЛЕНИЕ] AI Аналитик завершил анализ и прислал ответ:\n\n$summary\n\n'
                  'Кратко сообщи пользователю, что аналитик ответил, и перескажи суть ответа в 2-3 предложениях.',
            },
          ],
        },
      });
      _sendEvent({'type': 'response.create'});
      return;
    }

    // Ignore other system messages (missed-call labels, etc.)
    if (msg.isSystem) return;

    // Inject as a user-context message with conversationId so AI can load history and recommend a reply
    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': '[СИСТЕМНОЕ УВЕДОМЛЕНИЕ] Новое входящее сообщение от "$senderName" (conversationId: $conversationId): "$content". '
                'Загрузи последние сообщения этого диалога через get_messages(conversationId: "$conversationId", limit: 10), '
                'проанализируй контекст переписки и сообщи пользователю: кто написал, что написал, '
                'и предложи взвешенный вариант ответа с учётом контекста. '
                'Если пользователь одобрит — отправь через send_message.',
          },
        ],
      },
    });
    _sendEvent({'type': 'response.create'});
  }

  Future<void> _handleFunctionCall(
      String callId, String name, String argsJson) async {
    String output;
    try {
      // Translator mode switches — handled specially.
      // We do NOT send function_call_output because we're about to drop the WebSocket;
      // the call id becomes moot in the new session.
      if (name == 'enter_translator_mode') {
        debugPrint('[Assistant] tool enter_translator_mode (callId=$callId) args=$argsJson');
        // If the user named the languages, lock the pair from the tool args —
        // script-based auto-detection kept locking RU+EN from the trigger
        // phrase itself before the second language was ever spoken.
        String? a;
        String? b;
        try {
          final args = jsonDecode(argsJson) as Map<String, dynamic>;
          a = (args['lang_a'] as String?)?.toLowerCase();
          b = (args['lang_b'] as String?)?.toLowerCase();
        } catch (_) {}
        // Fire-and-forget: schedule the switch without awaiting inside the handler.
        Future.microtask(() => _switchMode(_AssistantMode.translator, langA: a, langB: b));
        return;
      }
      if (name == 'exit_translator_mode') {
        debugPrint('[Assistant] tool exit_translator_mode (callId=$callId)');
        Future.microtask(() => _switchMode(_AssistantMode.normal));
        return;
      }
      if (name == 'start_call') {
        final client = sl<DioClient>();
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final convId = args['conversationId'] as String;
        final calleeName = args['calleeName'] as String? ?? '';

        // Show confirmation dialog instead of calling immediately
        output = jsonEncode({'ok': true, 'waiting_confirmation': true});
        _sendEvent({
          'type': 'conversation.item.create',
          'item': {
            'type': 'function_call_output',
            'call_id': callId,
            'output': output,
          },
        });

        // Stop assistant audio/recording while showing dialog
        await _recorder.stop();
        await _recordSub?.cancel();

        if (mounted) {
          final confirmed = await _showCallConfirmation(calleeName);
          if (confirmed == true && mounted) {
            // Proceed with call
            try {
              final room = await client.post<Map<String, dynamic>>(
                '/voice/rooms',
                data: {'conversationId': convId, 'withAi': false},
                fromJson: (d) => Map<String, dynamic>.from(d as Map),
              );
              final roomName = room?['roomName'] as String? ?? '';
              sl<MessengerRemoteDataSource>().sendCallInvite(convId, roomName);

              // Call actually started — record the action bubble.
              final callAction = AssistantAction(
                type: AssistantActionType.callMade,
                entityId: convId,
                conversationId: convId,
                title: calleeName.isNotEmpty ? 'Звонок: $calleeName' : 'Звонок',
              );
              _chatLogger.addAction(
                role: 'assistant',
                source: 'voice',
                text: callAction.title,
                action: callAction.toJson(),
              );
              // We're about to tear the session down for navigation — flush now.
              unawaited(_chatLogger.flushNow());

              // Navigate FIRST, then cleanup — prevents mounted becoming false
              _navigatingToCall = true;
              final calleeEncoded = Uri.encodeComponent(calleeName);
              final route = '/dashboard/voice?room=$roomName&convId=$convId&callee=$calleeEncoded';
              debugPrint('[Assistant] Navigating to voice: $route');

              setState(() {
                _state = _CallState.idle;
                _muted = false;
                _aiSpeaking = false;
              });

              // Navigate before cleanup
              if (mounted) {
                context.push(route);
              }

              // Cleanup after navigation
              await _cleanup();
            } catch (e) {
              debugPrint('[Assistant] Call failed: $e');
            }
          } else {
            // Cancelled — resume assistant
            if (_ws != null && mounted) {
              await _startRecording();
            }
          }
        }
        return; // Skip the default sendEvent below — already sent
      }
      final args = argsJson.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(argsJson) as Map<String, dynamic>;
      output = await _toolsExecutor.execute(name, args);
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

  static const Map<String, String> _langFlagMap = {
    'ru': '🇷🇺',
    'en': '🇬🇧',
    'de': '🇩🇪',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'zh': '🇨🇳',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'ar': '🇸🇦',
    'tr': '🇹🇷',
    'uk': '🇺🇦',
    'pl': '🇵🇱',
  };

  String _langDisplay(String? code) {
    if (code == null || code.isEmpty) return '';
    return _langFlagMap[code] ?? code.toUpperCase();
  }

  String? _otherLang(String? currentLang) {
    if (currentLang == null) return null;
    if (currentLang == _langA) return _langB;
    if (currentLang == _langB) return _langA;
    // Third language fallback — if user briefly speaks a language outside the detected
    // pair, show the translation's flag as _langA (our "default" direction).
    return _langA;
  }

  /// Best-effort language detection by Unicode script — fallback when the
  /// Realtime API's `conversation.item.input_audio_transcription.completed`
  /// event does not carry a `language` field (currently it never does).
  /// Distinguishes broad scripts: Cyrillic → ru, CJK → zh, Arabic → ar,
  /// Korean → ko, Latin → en. Cannot tell en/de/es/fr apart — good enough
  /// for badge display in the most common ru↔en pair.
  static String? _detectLanguageFromText(String text) {
    if (text.isEmpty) return null;
    var cyrillic = 0, latin = 0, cjk = 0, arabic = 0, korean = 0;
    for (final rune in text.runes) {
      if (rune >= 0x0400 && rune <= 0x04FF) {
        cyrillic++;
      } else if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
        latin++;
      } else if (rune >= 0x4E00 && rune <= 0x9FFF) {
        cjk++;
      } else if (rune >= 0x0600 && rune <= 0x06FF) {
        arabic++;
      } else if (rune >= 0xAC00 && rune <= 0xD7AF) {
        korean++;
      }
    }
    final counts = {'ru': cyrillic, 'en': latin, 'zh': cjk, 'ar': arabic, 'ko': korean};
    String? best;
    var bestCount = 0;
    counts.forEach((code, count) {
      if (count > bestCount) {
        bestCount = count;
        best = code;
      }
    });
    return best;
  }

  Widget _buildTranslatorBadge(BuildContext context) {
    final colors = AppColors.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'ru' ? 'Переводчик' : 'Translator';
    final detecting = locale == 'ru' ? 'определяю языки…' : 'detecting languages…';

    final hasPair = _langA != null && _langB != null;
    final right = hasPair
        ? '${_langDisplay(_langA)} ⇄ ${_langDisplay(_langB)}'
        : detecting;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text('·', style: TextStyle(color: colors.primary)),
          const SizedBox(width: 6),
          Text(
            right,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall() async {
    // Push any queued transcript replicas before the session tears down.
    unawaited(_chatLogger.flushNow());
    // Stop audio immediately so user doesn't hear lingering speech
    await _player.stop();
    _audioBuffer.clear();
    // Note: transcript is NOT cleared — it persists across sessions
    await _cleanup();
    await _setSpeaker(false);
    // Resume wake word listening after session ends
    WakeWordService.instance.resume();
    if (mounted) {
      setState(() {
        _state = _CallState.idle;
        _muted = false;
        _aiSpeaking = false;
      });
    }
  }

  /// Backend pushed `ai_session_terminated` for *our* session (the bridge
  /// already filtered by sessionId). Show a short message to the user and
  /// tear the call down — `no_funds` is the common case (cron-driven
  /// balance exhaustion), `failed` is a backend/internal error.
  void _onSessionTerminated(AiSessionTerminatedEvent e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = e.reason == 'no_funds'
        ? l10n.billingSessionTerminatedNoFunds
        : l10n.billingSessionTerminatedGeneric;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
    _endCall();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: switch (_state) {
        _CallState.idle => _buildIdle(l10n),
        _CallState.connecting => _buildConnecting(l10n),
        _CallState.connected => _buildConnected(l10n),
        _CallState.error => _buildError(l10n),
      },
    );
  }

  Widget _buildIdle(AppLocalizations l10n) {
    final colors = AppColors.of(context);
    if (PlatformUtils.instance.isDesktop) {
      return _buildIdleDesktop(l10n, colors);
    }
    final screenSize = MediaQuery.of(context).size;
    final shortSide = screenSize.width < screenSize.height ? screenSize.width : screenSize.height;
    final orbitRadius = (shortSide * 0.30).clamp(100.0, 220.0);

    return BlocBuilder<MessengerBloc, MessengerState>(
      builder: (context, msState) {
        final unreadMessages = msState.conversations.fold<int>(0, (s, c) => s + c.unreadCount);
        final missedCalls = msState.missedCallsCount;
        final pendingCalendar = msState.pendingCalendarInvites;
        final pendingContacts = msState.pendingContactRequests;

        final navCircles = [
          _NavCircle(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.tabMessenger,
            route: RouteConstants.messenger,
            // Include incoming contact requests — they now live inline in
            // the chats list, so the Messenger badge should count them too.
            badge: unreadMessages + pendingContacts,
            color: const Color(0xFF22D3EE), // cyan
          ),
          _NavCircle(
            icon: Icons.call_outlined,
            label: l10n.tabCalls,
            route: RouteConstants.callHistory,
            badge: missedCalls,
            color: const Color(0xFF34D399), // emerald
            onTap: () => context.read<MessengerBloc>().add(const UpdateBadgeCounts(missedCallsCount: 0)),
          ),
          _NavCircle(
            icon: Icons.calendar_month_outlined,
            label: l10n.tabCalendar,
            route: RouteConstants.calendar,
            badge: pendingCalendar,
            color: const Color(0xFFA78BFA), // violet
            onTap: () => context.read<MessengerBloc>().add(const UpdateBadgeCounts(pendingCalendarInvites: 0)),
          ),
          _NavCircle(
            icon: Icons.sticky_note_2_outlined,
            label: l10n.notesTitle,
            route: RouteConstants.notes,
            badge: 0,
            color: const Color(0xFFFB7185), // rose
          ),
          _NavCircle(
            icon: Icons.people_outline,
            label: l10n.contacts,
            route: RouteConstants.contacts,
            badge: pendingContacts,
            color: const Color(0xFF38BDF8), // sky
          ),
          _NavCircle(
            icon: Icons.person_outline,
            label: l10n.tabProfile,
            route: RouteConstants.profile,
            badge: 0,
            color: const Color(0xFFFBBF24), // amber
          ),
          _NavCircle(
            icon: Icons.settings_outlined,
            label: l10n.tabSettings,
            route: RouteConstants.settings,
            badge: 0,
            color: const Color(0xFF818CF8), // indigo-lavender
          ),
        ];

        return Stack(
          children: [
            // Ambient floating color blobs (animated background)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _orbitCtrl,
                  builder: (context, _) {
                    final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
                    return CustomPaint(
                      painter: _AmbientBlobsPainter(time: t, colors: navCircles.map((n) => n.color).toList()),
                    );
                  },
                ),
              ),
            ),

            // Orbital trajectory ring (subtle dotted path)
            Center(
              child: AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (context, _) {
                  final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
                  return CustomPaint(
                    size: Size.square(orbitRadius * 2 + 80),
                    painter: _OrbitRingPainter(
                      radius: orbitRadius,
                      time: t,
                      baseColor: colors.primary,
                    ),
                  );
                },
              ),
            ),

            // Multi-color aura blobs rotating around the center button
            Center(
              child: AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (context, _) {
                  final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
                  return CustomPaint(
                    size: const Size(240, 240),
                    painter: _CenterAuraPainter(
                      time: t,
                      colors: const [
                        Color(0xFF22D3EE),
                        Color(0xFFA78BFA),
                        Color(0xFFFBBF24),
                        Color(0xFFFB7185),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Center assistant button
            Center(
              child: GestureDetector(
                onTap: _connect,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: orbitRadius < 150 ? 90 : 120,
                    height: orbitRadius < 150 ? 90 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.card,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 90,
                        height: 90,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/app_icon_dark.png'
                                : 'assets/app_icon_light.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Orbiting nav circles (interactive drag + fling + slow auto-spin)
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final areaSize = orbitRadius * 2 + 80;
                  final areaCenter = Offset(areaSize / 2, areaSize / 2);
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: _onOrbitPanStart,
                    onPanUpdate: (d) => _onOrbitPanUpdate(d, areaCenter, orbitRadius),
                    onPanEnd: _onOrbitPanEnd,
                    child: SizedBox(
                      width: areaSize,
                      height: areaSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(navCircles.length, (i) {
                          final baseAngle = 2 * math.pi * i / navCircles.length;
                          final angle = baseAngle + _orbitAngle;
                          final x = orbitRadius * math.cos(angle);
                          final y = orbitRadius * math.sin(angle);
                          final nav = navCircles[i];
                          return Positioned(
                            left: orbitRadius + 40 + x - 30,
                            top: orbitRadius + 40 + y - 30,
                            child: _buildNavCircle(nav, colors, i),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),

          ],
        );
      },
    );
  }

  Widget _buildIdleDesktop(AppLocalizations l10n, AppColorsExtension colors) {
    return Center(
      child: GestureDetector(
        onTap: _connect,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.card,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/app_icon_dark.png'
                          : 'assets/app_icon_light.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.assistantTapToStart,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCircle(_NavCircle nav, AppColorsExtension colors, int index) {
    // Individual breathing phase based on index so each circle pulses
    // independently (creates a "living cluster" feel).
    return AnimatedBuilder(
      animation: _orbitCtrl,
      builder: (context, _) {
        final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
        final phase = t * 1.6 + index * 0.9;
        final breath = 1.0 + 0.06 * math.sin(phase);
        final glow = 0.55 + 0.3 * (0.5 + 0.5 * math.sin(phase * 0.7));

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            nav.onTap?.call();
            context.push(nav.route);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: breath,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Outer colored glow aura
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            nav.color.withValues(alpha: glow * 0.45),
                            nav.color.withValues(alpha: 0.0),
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                    // Main circle body with radial gradient
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.4),
                          radius: 1.1,
                          colors: [
                            Color.lerp(nav.color, Colors.white, 0.35)!,
                            nav.color,
                            Color.lerp(nav.color, Colors.black, 0.35)!,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          // Strong colored glow
                          BoxShadow(
                            color: nav.color.withValues(alpha: glow * 0.55),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                          // Depth shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        nav.icon,
                        size: 24,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    // Badge
                    if (nav.badge > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.error,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: colors.error.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            nav.badge > 99 ? '99+' : '${nav.badge}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nav.label,
                style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnecting(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (context, _) {
                final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
                return Transform.rotate(
                  angle: t * 2 * math.pi * 0.7,
                  child: CustomPaint(
                    painter: _ConnectingRingPainter(
                      colors: const [
                        Color(0xFF22D3EE),
                        Color(0xFFA855F7),
                        Color(0xFFFBBF24),
                        Color(0xFF22D3EE),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.assistantConnectingToAssistant,
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConnected(AppLocalizations l10n) {
    final speaking = _aiSpeaking;
    final colors = AppColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Full-screen transcript
        Expanded(
          child: _transcript.isEmpty
              ? Center(
                  child: Text(
                    speaking ? l10n.assistantAiSpeaking : l10n.assistantAiListening,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final isTranslator = _mode == _AssistantMode.translator;
                    // In translator mode, we show one card per user item (with its paired translation).
                    // Skip assistant items that are already paired — they get rendered inside their user card.
                    final pairedAssistantIds = isTranslator
                        ? _transcript
                            .where((m) => m.role == 'user' && m.pairedItemId != null)
                            .map((m) => m.pairedItemId!)
                            .toSet()
                        : const <String>{};
                    final renderItems = isTranslator
                        ? _transcript
                            .where((m) =>
                                m.role == 'user' ||
                                (m.role == 'assistant' &&
                                    m.itemId != null &&
                                    !pairedAssistantIds.contains(m.itemId)))
                            .toList()
                        : _transcript;

                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border.withValues(alpha: 0.2)),
                      ),
                      child: ListView.builder(
                        controller: _transcriptCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: renderItems.length,
                        itemBuilder: (_, i) {
                          final m = renderItems[i];
                          final isUser = m.role == 'user';

                          if (isTranslator && isUser) {
                            // Paired card: user original + translation below.
                            final paired = m.pairedItemId != null
                                ? _transcript.firstWhere(
                                    (x) => x.itemId == m.pairedItemId,
                                    orElse: () => const _TranscriptMessage(role: 'assistant', text: ''),
                                  )
                                : const _TranscriptMessage(role: 'assistant', text: '');
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.card.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          _langDisplay(m.originalLang),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      Expanded(
                                        child: LinkifiedText(
                                          text: m.text,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (paired.text.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: Text(
                                            // The translation's language is "the other one".
                                            _langDisplay(_otherLang(m.originalLang)),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Expanded(
                                          child: LinkifiedText(
                                            text: paired.text,
                                            style: TextStyle(
                                              color: colors.textPrimary.withValues(alpha: 0.85),
                                              fontSize: 14,
                                              height: 1.4,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          // Normal-mode card (or orphan assistant card in translator mode).
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isUser ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: LinkifiedText(
                                text: m.text,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        if (_mode == _AssistantMode.translator)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Align(
              alignment: Alignment.center,
              child: _buildTranslatorBadge(context),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CallButton(
                icon: _speakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: _speakerOn ? l10n.assistantSpeakerOn : l10n.assistantSpeaker,
                color: _speakerOn
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.card,
                iconColor:
                    _speakerOn ? colors.primary : colors.textSecondary,
                onTap: _toggleSpeaker,
              ),
              // Animated logo — tap to end session
              GestureDetector(
                onTap: _endCall,
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding waveform rings when speaking
                      AnimatedBuilder(
                        animation: _orbitCtrl,
                        builder: (context, _) {
                          final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
                          return CustomPaint(
                            size: const Size(88, 88),
                            painter: _AssistantWavePainter(
                              time: t,
                              active: speaking,
                              colors: const [
                                Color(0xFF22D3EE),
                                Color(0xFFA855F7),
                                Color(0xFFFBBF24),
                              ],
                            ),
                          );
                        },
                      ),
                      // Breathing central container with video logo
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) {
                          final scale = speaking ? 1.0 + (_pulseAnim.value - 1.0) * 0.5 : 1.0;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: speaking
                                ? const LinearGradient(
                                    colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: speaking ? null : colors.card,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: speaking ? 0.3 : 0.1),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (speaking ? const Color(0xFF22D3EE) : colors.primary)
                                    .withValues(alpha: speaking ? 0.5 : 0.25),
                                blurRadius: speaking ? 20 : 12,
                                spreadRadius: speaking ? 4 : 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: ClipOval(
                              child: Container(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? 'assets/app_icon_dark.png'
                                      : 'assets/app_icon_light.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CallButton(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _muted ? l10n.assistantUnmute : l10n.assistantMicrophone,
                color: _muted
                    ? colors.error.withValues(alpha: 0.2)
                    : colors.card,
                iconColor: _muted ? colors.error : colors.textSecondary,
                onTap: _toggleMute,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool?> _showCallConfirmation(String calleeName) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.call_rounded, size: 36, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.assistantCallConfirm,
              style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              calleeName,
              style: TextStyle(color: colors.primary, fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.call_rounded, size: 20),
            label: Text(l10n.chatCall, style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
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
    final appColors = AppColors.of(context);
    final isNeutral = color.value == appColors.card.value ||
        color.opacity < 0.9;
    final isColoredAction = !isNeutral;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: isColoredAction
                  ? RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      radius: 1.1,
                      colors: [
                        Color.lerp(color, Colors.white, 0.18)!,
                        color,
                        Color.lerp(color, Colors.black, 0.3)!,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    )
                  : null,
              color: isColoredAction ? null : color,
              shape: BoxShape.circle,
              border: isNeutral
                  ? Border.all(
                      color: appColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
              boxShadow: isColoredAction
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: size >= 72 ? 22 : 14,
                        spreadRadius: size >= 72 ? 2 : 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: appColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
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

/// Rotating conic-gradient ring shown while the assistant is connecting.
class _ConnectingRingPainter extends CustomPainter {
  final List<Color> colors;
  _ConnectingRingPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: colors).createShader(rect);
    canvas.drawArc(rect, 0, math.pi * 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ConnectingRingPainter old) => false;
}

/// Expanding colored rings emanating from the center while the
/// assistant is speaking. Goes quiet (just a soft breathing aura) when
/// it's listening.
class _AssistantWavePainter extends CustomPainter {
  final double time;
  final bool active;
  final List<Color> colors;
  _AssistantWavePainter({
    required this.time,
    required this.active,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    if (active) {
      // Three outward-expanding rings, phase-offset
      for (var i = 0; i < 3; i++) {
        final phase = ((time * 0.9) + i * 0.33) % 1.0;
        final r = 60 + phase * (maxRadius - 60);
        final alpha = (1.0 - phase) * 0.45;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = colors[i % colors.length].withValues(alpha: alpha);
        canvas.drawCircle(center, r, paint);
      }
    } else {
      // Idle: soft breathing halo
      final breath = 0.5 + 0.5 * math.sin(time * 1.2);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[0].withValues(alpha: 0.12 + 0.08 * breath),
            colors[0].withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 90));
      canvas.drawCircle(center, 90, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AssistantWavePainter old) =>
      old.time != time || old.active != active;
}

class _NavCircle {
  final IconData icon;
  final String label;
  final String route;
  final int badge;
  final Color color;
  final VoidCallback? onTap;

  const _NavCircle({
    required this.icon,
    required this.label,
    required this.route,
    required this.badge,
    required this.color,
    this.onTap,
  });
}

/// Animated ambient background — soft floating color blobs that slowly
/// drift, giving the idle screen a "living" feel.
class _AmbientBlobsPainter extends CustomPainter {
  final double time;
  final List<Color> colors;
  _AmbientBlobsPainter({required this.time, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Use a subset of palette colors to avoid chaos
    final palette = [
      colors.isNotEmpty ? colors[0] : const Color(0xFF22D3EE),
      colors.length > 2 ? colors[2] : const Color(0xFFA78BFA),
      colors.length > 5 ? colors[5] : const Color(0xFFFBBF24),
      colors.length > 3 ? colors[3] : const Color(0xFFFB7185),
    ];
    // 4 blobs moving on independent Lissajous paths
    for (var i = 0; i < palette.length; i++) {
      final phaseX = time * 0.08 + i * 1.7;
      final phaseY = time * 0.11 + i * 2.3;
      final cx = w * (0.5 + 0.35 * math.sin(phaseX));
      final cy = h * (0.5 + 0.28 * math.cos(phaseY));
      final radius = w * 0.55;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            palette[i].withValues(alpha: 0.14),
            palette[i].withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBlobsPainter old) =>
      old.time != time;
}

/// Subtle dotted ring showing the orbital trajectory. The dots slowly
/// rotate in the opposite direction for parallax life.
class _OrbitRingPainter extends CustomPainter {
  final double radius;
  final double time;
  final Color baseColor;
  _OrbitRingPainter({
    required this.radius,
    required this.time,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Base translucent ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = baseColor.withValues(alpha: 0.10);
    canvas.drawCircle(center, radius, ringPaint);

    // Tiny orbiting dots (counter-rotating, slow)
    const dotCount = 36;
    final rotation = -time * 0.15;
    for (var i = 0; i < dotCount; i++) {
      final angle = rotation + (i / dotCount) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final alpha = 0.12 + 0.18 * (0.5 + 0.5 * math.sin(time * 1.2 + i * 0.4));
      final dotPaint = Paint()
        ..color = baseColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) =>
      old.time != time || old.radius != radius;
}

/// Multi-color aura of 4 soft colored blobs slowly rotating around the
/// center button, layered behind it for a "halo of planets" effect.
class _CenterAuraPainter extends CustomPainter {
  final double time;
  final List<Color> colors;
  _CenterAuraPainter({required this.time, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbitR = size.width * 0.28;
    final blobR = size.width * 0.32;
    for (var i = 0; i < colors.length; i++) {
      final angle = time * 0.35 + (i / colors.length) * 2 * math.pi;
      final cx = center.dx + orbitR * math.cos(angle);
      final cy = center.dy + orbitR * math.sin(angle);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: 0.38),
            colors[i].withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: blobR));
      canvas.drawCircle(Offset(cx, cy), blobR, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CenterAuraPainter old) => old.time != time;
}


class _TranscriptMessage {
  final String role;          // 'user' or 'assistant'
  final String text;
  final String? itemId;
  final String? originalLang; // ISO code, set for user items in translator mode
  final String? pairedItemId; // itemId of assistant translation that pairs with this user item
  const _TranscriptMessage({
    required this.role,
    required this.text,
    this.itemId,
    this.originalLang,
    this.pairedItemId,
  });
  _TranscriptMessage copyWith({
    String? text,
    String? originalLang,
    String? pairedItemId,
  }) =>
      _TranscriptMessage(
        role: role,
        text: text ?? this.text,
        itemId: itemId,
        originalLang: originalLang ?? this.originalLang,
        pairedItemId: pairedItemId ?? this.pairedItemId,
      );
}
