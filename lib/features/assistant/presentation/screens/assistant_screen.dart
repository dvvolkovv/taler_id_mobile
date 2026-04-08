import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_event.dart';
import '../../../messenger/presentation/bloc/messenger_state.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart';

enum _CallState { idle, connecting, connected, error }

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  _CallState _state = _CallState.idle;
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

  VideoPlayerController? _logoVideo;
  bool _logoVideoReady = false;
  bool? _logoVideoDark; // tracks which theme the current video was loaded for

  static const _audioChannel = MethodChannel('taler_id/audio');

  // Function call buffering
  String? _pendingCallId;
  String? _pendingCallName;
  final StringBuffer _pendingArgs = StringBuffer();

  // Incoming message listener
  StreamSubscription? _messageSub;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_logoVideoDark == isDark) return; // theme unchanged, skip
    _logoVideoDark = isDark;
    final asset = isDark ? 'assets/video.mp4' : 'assets/video_light.mp4';
    final oldVideo = _logoVideo;
    setState(() => _logoVideoReady = false);
    _logoVideo = VideoPlayerController.asset(asset)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _logoVideoReady = true);
          _logoVideo!.play();
        }
        oldVideo?.dispose();
      });
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
    _orbitCtrl.removeListener(_tickOrbit);
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _logoVideo?.dispose();
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
          if (mounted && _state == _CallState.connected && !_navigatingToCall) _endCall();
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
      setState(() => _state = _CallState.connected);
    } catch (e) {
      await _cleanup();
      setState(() {
        _state = _CallState.error;
        _errorMessage = e.toString();
      });
    }
  }

  static String _systemPrompt(String locale) {
    final tz = DateTime.now().timeZoneOffset;
    final tzStr = 'UTC${tz.isNegative ? "" : "+"}${tz.inHours}';
    final nowStr = DateTime.now().toIso8601String();

    if (locale == 'ru') {
      return 'ВСЕГДА отвечай ТОЛЬКО на русском языке, даже если тебе показалось, что пользователь сказал что-то на другом языке — это ошибка транскрипции, всё равно отвечай по-русски.\n\n'
          'Ты — голосовой ассистент Taler ID. Помогай пользователям с вопросами о цифровой идентификации, '
          'статусе KYC-верификации и данных профиля. Отвечай кратко и по делу. '
          'Не начинай разговор первым — жди когда пользователь заговорит. '
          'Отвечай кратко и по делу. '
          'При необходимости вызывай инструменты для чтения или обновления профиля. '
          'Ты также умеешь работать с разделами "О себе" — это личная информация пользователя: ценности, видение мира, '
          'навыки, интересы, желания, профиль, что нравится/не нравится. Ты можешь спрашивать пользователя о нём, '
          'задавать уточняющие вопросы, и сохранять ответы в соответствующие разделы. '
          'Перед сохранением обязательно вызови get_sections чтобы увидеть что уже заполнено, и дополняй, а не заменяй. '
          'Используй items для кратких тегов/ключевых слов, freeText для описания.\n\n'
          'Помимо основного режима работы с профилем, ты можешь работать в специальных режимах по запросу пользователя:\n\n'
          'РЕЖИМ "КОУЧ ICF":\n'
          'Активируется если пользователь говорит "давай коучинг", "коуч-сессия", "хочу поработать с коучем" и т.п.\n'
          '- Работай строго по стандартам ICF (PCC уровень)\n'
          '- НИКОГДА не давай советов и готовых решений\n'
          '- Задавай только открытые вопросы (что, как, какой, насколько)\n'
          '- Используй перефразирование и отражение чувств\n'
          '- Структура: контракт на сессию → исследование темы → осознание → конкретный шаг\n'
          '- В этом режиме НЕ вызывай инструменты профиля\n\n'
          'РЕЖИМ "ПСИХОЛОГ":\n'
          'Активируется если пользователь говорит "поговори как психолог", "нужна поддержка", "хочу поговорить" и т.п.\n'
          '- Эмпатическое слушание, рефлексивные вопросы\n'
          '- Валидация чувств и эмоциональная поддержка\n'
          '- Не давай медицинских рекомендаций\n'
          '- В этом режиме НЕ вызывай инструменты профиля\n\n'
          'РЕЖИМ "HR-КОНСУЛЬТАНТ":\n'
          'Активируется если пользователь говорит "HR консультация", "помоги с карьерой", "подготовка к собеседованию" и т.п.\n'
          '- Карьерные консультации, подготовка к собеседованиям, разрешение рабочих конфликтов, развитие карьеры\n'
          '- Можешь использовать get_profile и get_sections для понимания фона пользователя\n\n'
          'РЕЖИМ "СОБЕСЕДНИК":\n'
          'Активируется если пользователь говорит "поболтаем", "давай просто поговорим", "хочу поговорить о…", "обсудим" и т.п., либо задаёт вопрос на свободную тему, не связанную с Taler ID.\n'
          '- Это дружеский открытый разговор на любые темы: новости, идеи, хобби, философия, история, наука, искусство, спорт, путешествия и всё остальное\n'
          '- Говори живо, естественно, можно с юмором, как хороший собеседник за чашкой кофе\n'
          '- Можешь делиться фактами, мыслями, рассуждениями, предлагать свою точку зрения\n'
          '- Задавай встречные вопросы, поддерживай диалог, развивай тему\n'
          '- НЕ превращай каждую фразу в совет; просто разговаривай\n'
          '- В этом режиме НЕ вызывай инструменты профиля/KYC/контактов, если пользователь явно об этом не просит\n'
          '- Если пользователь переключается на тему продукта (профиль, звонки, заметки) — плавно выйди из режима и выполни запрос\n\n'
          'ПЕРЕКЛЮЧЕНИЕ РЕЖИМОВ:\n'
          '- При входе в режим — подтверди голосом какой режим активирован\n'
          '- "Сменить роль" / "выйди из роли" / "хватит" → вернись в обычный режим ассистента\n'
          '- Если пользователь просит что-то из основного режима (профиль, KYC) — спроси, хочет ли он выйти из текущего режима\n\n'
          'ЗВОНКИ КОНТАКТАМ:\n'
          'Если пользователь говорит "позвони [имя]" или "набери [имя]":\n'
          '1. ВСЕГДА сначала вызови get_conversations — там имена контактов с учётом кастомных имён (алиасов), заданных пользователем\n'
          '2. Найди диалог по otherUserName — сравнивай нечётко (частичное совпадение)\n'
          '3. Если нашёл — вызови start_call с conversationId и calleeName\n'
          '4. Если не нашёл в диалогах — вызови search_contacts\n'
          '5. Перед звонком скажи "Звоню [имя]"\n'
          'ВАЖНО: НЕ используй search_contacts до get_conversations — в search_contacts нет кастомных имён.\n\n'
          'АНАЛИЗ ПЕРЕПИСКИ:\n'
          'Если пользователь спрашивает "что мы обсуждали с [имя]", "на чём остановились с [имя]" и т.п.:\n'
          '1. Найди диалог через get_conversations\n'
          '2. Загрузи историю через get_messages\n'
          '3. Проанализируй и расскажи: ключевые темы, договорённости, на чём остановились\n\n'
          'ПРОВЕРКА НОВЫХ СООБЩЕНИЙ:\n'
          'Если пользователь говорит "проверь сообщения", "что нового", "есть непрочитанные?" и т.п.:\n'
          '1. Вызови get_conversations — в ответе будет unreadCount для каждого диалога\n'
          '2. Расскажи от кого есть непрочитанные сообщения\n'
          '3. Если пользователь хочет узнать подробнее — загрузи историю через get_messages\n'
          '4. Предложи ответить — если пользователь диктует ответ, отправь через send_message\n\n'
          'ОТВЕТ НА СООБЩЕНИЯ:\n'
          'Если пользователь говорит "ответь [имя] [текст]" или "напиши [имя] [текст]":\n'
          '1. Найди диалог через get_conversations\n'
          '2. Отправь сообщение через send_message\n'
          '3. Подтверди отправку голосом\n\n'
          'ЗАМЕТКИ:\n'
          'Если пользователь говорит "запиши", "сохрани мысль", "заметка", "запомни" и т.п.:\n'
          '1. Извлеки ключевую мысль и сформулируй краткий заголовок\n'
          '2. Сохрани через create_note\n'
          '3. Подтверди сохранение голосом\n'
          'Если пользователь спрашивает "какие у меня заметки" — вызови get_notes и перескажи\n'
          'Если просит резюме заметок — вызови get_notes, проанализируй и дай краткое резюме\n\n'
          'КАЛЕНДАРЬ И НАПОМИНАНИЯ:\n'
          'Сейчас: $nowStr.\n'
          'Передавай startAt и reminderAt в МЕСТНОМ времени формат YYYY-MM-DDTHH:MM:SS (БЕЗ Z, БЕЗ конвертации в UTC).\n'
          'Если говорит "встреча с [имя]" — ставь type="CALL", найди контакт через get_conversations (по otherUserName с учётом алиасов), передай contactIds.\n'
          'Типы: CALL=встреча со ссылкой, EVENT=событие, REMINDER=напоминание.\n'
          'Если спрашивает "что у меня запланировано", "встречи на сегодня", "что сегодня" — вызови get_events с from=начало сегодняшнего дня (YYYY-MM-DDT00:00:00) и to=конец дня (YYYY-MM-DDT23:59:59) и расскажи.\n'
          'Для запросов "на эту неделю" — from=сегодня, to=через 7 дней.';
    }

    return 'ALWAYS reply ONLY in English, even if you think the user said something in another language — that is a transcription error, reply in English anyway.\n\n'
        'You are a voice assistant for Taler ID. Help users with questions about digital identification, '
        'KYC verification status, and profile data. Be concise and to the point. '
        'Don\'t start the conversation — wait for the user to speak. '
        'When needed, call tools to read or update the profile. '
        'You can also work with "About me" sections — personal information: values, worldview, '
        'skills, interests, desires, profile, likes/dislikes. You can ask the user about themselves, '
        'ask clarifying questions, and save answers to corresponding sections. '
        'Before saving, always call get_sections to see what\'s already filled, and supplement rather than replace. '
        'Use items for brief tags/keywords, freeText for descriptions.\n\n'
        'In addition to the main profile mode, you can work in special modes on user request:\n\n'
        '"ICF COACH" MODE:\n'
        'Activated when the user says "let\'s do coaching", "coach session", "I want to work with a coach", etc.\n'
        '- Work strictly according to ICF standards (PCC level)\n'
        '- NEVER give advice or ready solutions\n'
        '- Ask only open questions (what, how, which, to what extent)\n'
        '- Use paraphrasing and reflection of feelings\n'
        '- Structure: session contract → topic exploration → awareness → concrete step\n'
        '- In this mode, do NOT call profile tools\n\n'
        '"PSYCHOLOGIST" MODE:\n'
        'Activated when the user says "talk as a psychologist", "need support", "want to talk", etc.\n'
        '- Empathic listening, reflective questions\n'
        '- Validation of feelings and emotional support\n'
        '- Don\'t give medical recommendations\n'
        '- In this mode, do NOT call profile tools\n\n'
        '"HR CONSULTANT" MODE:\n'
        'Activated when the user says "HR consultation", "help with career", "interview preparation", etc.\n'
        '- Career consultations, interview preparation, resolving work conflicts, career development\n'
        '- Can use get_profile and get_sections to understand user\'s background\n\n'
        '"CASUAL CHAT" MODE:\n'
        'Activated when the user says "let\'s chat", "just talk", "let\'s discuss…", "what do you think about…" or asks any free-form question unrelated to Taler ID.\n'
        '- This is a friendly open-ended conversation on any topic: news, ideas, hobbies, philosophy, history, science, art, sports, travel, anything.\n'
        '- Speak naturally, lively, with a touch of humour — like a good companion over coffee.\n'
        '- Feel free to share facts, thoughts, reasoning, offer your own opinion.\n'
        '- Ask follow-up questions, keep the dialogue going, develop the topic.\n'
        '- Don\'t turn every reply into advice; just talk.\n'
        '- In this mode, do NOT call profile/KYC/contact tools unless the user explicitly asks.\n'
        '- If the user switches to a product topic (profile, calls, notes) — smoothly exit the mode and handle the request.\n\n'
        'MODE SWITCHING:\n'
        '- When entering a mode — confirm by voice which mode is activated\n'
        '- "Switch role" / "exit role" / "enough" → return to normal assistant mode\n'
        '- If the user asks for something from the main mode (profile, KYC) — ask if they want to exit current mode\n\n'
        'CALLING CONTACTS:\n'
        'If user says "call [name]" or "dial [name]":\n'
        '1. ALWAYS call get_conversations FIRST — it returns contact names with custom aliases set by the user\n'
        '2. Find conversation by otherUserName — use fuzzy matching (partial match)\n'
        '3. If found — call start_call with conversationId and calleeName\n'
        '4. If not found in conversations — call search_contacts\n'
        '5. Before calling say "Calling [name]"\n'
        'IMPORTANT: Do NOT use search_contacts before get_conversations — search_contacts does not include custom names.\n\n'
        'CHAT ANALYSIS:\n'
        'If user asks "what did we discuss with [name]", "where did we stop with [name]", etc.:\n'
        '1. Find the conversation via get_conversations\n'
        '2. Load history via get_messages\n'
        '3. Analyze and tell: key topics, agreements, where you left off\n\n'
        'CHECKING NEW MESSAGES:\n'
        'If user says "check messages", "what\'s new", "any unread?", etc.:\n'
        '1. Call get_conversations — response will include unreadCount for each conversation\n'
        '2. Tell who has unread messages\n'
        '3. If user wants details — load history via get_messages\n'
        '4. Offer to reply — if user dictates a response, send via send_message\n\n'
        'REPLYING TO MESSAGES:\n'
        'If user says "reply to [name] [text]" or "write to [name] [text]":\n'
        '1. Find conversation via get_conversations\n'
        '2. Send message via send_message\n'
        '3. Confirm sending by voice\n\n'
        'NOTES:\n'
        'If user says "write down", "save a thought", "note", "remember", etc.:\n'
        '1. Extract the key idea and formulate a brief title\n'
        '2. Save via create_note\n'
        '3. Confirm saving by voice\n'
        'If user asks "what notes do I have" — call get_notes and summarize\n'
        'If asks for notes summary — call get_notes, analyze and give brief summary\n\n'
        'CALENDAR AND REMINDERS:\n'
        'Now: $nowStr.\n'
        'Pass startAt and reminderAt in LOCAL time format YYYY-MM-DDTHH:MM:SS (NO Z suffix, NO UTC conversion).\n'
        'If says "meeting with [name]" — set type="CALL", find contact via get_conversations (match by otherUserName which includes aliases), pass contactIds.\n'
        'Types: CALL=meeting with link, EVENT=event, REMINDER=reminder.\n'
        'If asks "what do I have planned", "meetings today", "what\'s today" — call get_events with from=start of today (YYYY-MM-DDT00:00:00) and to=end of day (YYYY-MM-DDT23:59:59) and tell them.\n'
        'For "this week" — from=today, to=7 days from now.\n\n'
        'CONTACTS MANAGEMENT:\n'
        'If user asks "who are my contacts", "show contacts" — call get_contacts.\n'
        'If user says "add [name] as contact", "send contact request to [name]":\n'
        '1. Find userId via search_contacts\n'
        '2. Send request via send_contact_request\n'
        'If user asks "any contact requests?", "incoming requests" — call get_contact_requests.\n'
        'If user says "accept request from [name]" or "reject request from [name]" — call respond_contact_request.\n'
        'If user says "remove [name] from contacts" — call delete_contact (get userId from get_contacts).\n'
        'If user says "block [name]" or "unblock [name]" — call block_contact.\n\n'
        'CALL HISTORY:\n'
        'If user asks "show call history", "recent calls", "missed calls" — call get_call_history.\n\n'
        'SESSIONS:\n'
        'If user asks "active sessions", "where am I logged in", "connected devices" — call get_sessions.\n'
        'If user says "log out from [device]", "terminate session" — call terminate_session with sessionId.\n\n'
        'GROUPS:\n'
        'If user says "create a group with [names]" — use search_contacts to find userIds, then call create_group.\n'
        'If user says "add [name] to group [groupName]" or "remove [name] from group" — call manage_group_members.\n\n'
        'ORGANIZATIONS:\n'
        'If user asks "my organizations", "which companies am I in" — call get_tenants.\n\n'
        'KYC:\n'
        'If user asks "my verification status", "is KYC complete", "identity verification" — call get_kyc_status.\n\n'
        'REACTIONS:\n'
        'If user says "react with [emoji] to [name]\'s message" — find conversation, get messageId from get_messages, then call react_to_message.\n\n'
        'FORWARDING:\n'
        'If user says "forward this message to [name]" — use forward_message with targetConversationId.\n\n'
        'SETTINGS:\n'
        'If user asks "what are my settings", "current settings" — call get_settings.\n'
        'THEME: If user says "switch to dark mode", "enable light theme", "use system theme" — call set_theme with light/dark/system.\n'
        'LANGUAGE: If user says "switch to English", "switch to Russian", "change language" — call set_language with en/ru.\n'
        'BIOMETRICS: If user says "disable fingerprint", "turn off Face ID", "disable biometrics" — call set_biometric with enabled=false. '
        'Enabling biometrics requires device authentication — tell the user to go to Settings.\n'
        'PIN: If user says "disable PIN", "turn off PIN code" — call disable_pin. '
        'Enabling PIN requires a setup screen — tell the user to go to Settings.\n'
        'After applying any setting change — confirm the action by voice.';
  }

  void _onChannelOpen() {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    final locale = Localizations.localeOf(context).languageCode;
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
          {
            'type': 'function',
            'name': 'get_sections',
            'description':
                'Get all profile sections of the current user. Returns array of sections with type, content (items + freeText), and visibility.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'upsert_section',
            'description':
                'Create or update a profile section. Merge new items with existing ones. '
                'Types: VALUES, WORLDVIEW, SKILLS, INTERESTS, DESIRES, BACKGROUND, LIKES, DISLIKES.',
            'parameters': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['VALUES', 'WORLDVIEW', 'SKILLS', 'INTERESTS', 'DESIRES', 'BACKGROUND', 'LIKES', 'DISLIKES'],
                },
                'items': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
                'freeText': {'type': 'string'},
                'visibility': {
                  'type': 'string',
                  'enum': ['PUBLIC', 'CONTACTS', 'PRIVATE'],
                },
              },
              'required': ['type'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_section',
            'description': 'Delete a profile section.',
            'parameters': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['VALUES', 'WORLDVIEW', 'SKILLS', 'INTERESTS', 'DESIRES', 'BACKGROUND', 'LIKES', 'DISLIKES'],
                },
              },
              'required': ['type'],
            },
          },
          {
            'type': 'function',
            'name': 'search_contacts',
            'description': 'Search for users/contacts by name, username, email or phone. Min 2 chars.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string', 'description': 'Search query (min 2 chars)'},
              },
              'required': ['query'],
            },
          },
          {
            'type': 'function',
            'name': 'get_conversations',
            'description': 'Get list of user conversations/chats with contact names, IDs, unreadCount and last message info.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'get_messages',
            'description': 'Get message history for a conversation. Use to analyze past discussions, meetings, agreements.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'limit': {'type': 'integer', 'description': 'Number of messages to fetch (default 50)'},
              },
              'required': ['conversationId'],
            },
          },
          {
            'type': 'function',
            'name': 'start_call',
            'description': 'Start a voice call to a contact. Creates a room, sends invite, and navigates to call screen.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'calleeName': {'type': 'string'},
              },
              'required': ['conversationId'],
            },
          },
          {
            'type': 'function',
            'name': 'send_message',
            'description': 'Send a text message to a conversation. Use to reply to messages.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'content': {'type': 'string', 'description': 'Message text to send'},
              },
              'required': ['conversationId', 'content'],
            },
          },
          {
            'type': 'function',
            'name': 'get_notes',
            'description': 'Get all user notes. Returns list with id, title, content, source, createdAt.',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {'type': 'integer', 'description': 'Max notes to return (default 20)'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'create_note',
            'description': 'Save a note/thought for the user. Use when user shares an idea or asks to save something.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Short title or main thought'},
                'content': {'type': 'string', 'description': 'Detailed content'},
              },
              'required': ['title', 'content'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_note',
            'description': 'Delete a note by ID.',
            'parameters': {
              'type': 'object',
              'properties': {
                'noteId': {'type': 'string'},
              },
              'required': ['noteId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_events',
            'description': 'Get calendar events for a date range. Returns events with id, title, type, startAt, reminderAt.',
            'parameters': {
              'type': 'object',
              'properties': {
                'from': {'type': 'string', 'description': 'Start date ISO string (default: today)'},
                'to': {'type': 'string', 'description': 'End date ISO string (default: 30 days from now)'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'create_event',
            'description': 'Create a calendar event, reminder, or scheduled call.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string'},
                'description': {'type': 'string'},
                'type': {'type': 'string', 'enum': ['CALL', 'EVENT', 'REMINDER']},
                'startAt': {'type': 'string', 'description': 'ISO datetime'},
                'endAt': {'type': 'string', 'description': 'ISO datetime (optional)'},
                'reminderAt': {'type': 'string', 'description': 'When to send push reminder (ISO datetime)'},
              },
              'required': ['title', 'type', 'startAt'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_event',
            'description': 'Delete a calendar event by ID.',
            'parameters': {
              'type': 'object',
              'properties': {
                'eventId': {'type': 'string'},
              },
              'required': ['eventId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_contacts',
            'description': 'Get list of accepted contacts (people the user has added). Returns name, userId, conversationId.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'send_contact_request',
            'description': 'Send a contact request to a user by userId (find userId via search_contacts first).',
            'parameters': {
              'type': 'object',
              'properties': {
                'userId': {'type': 'string', 'description': 'Target user ID'},
              },
              'required': ['userId'],
            },
          },
          {
            'type': 'function',
            'name': 'get_contact_requests',
            'description': 'Get incoming pending contact requests from other users.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'respond_contact_request',
            'description': 'Accept or reject an incoming contact request.',
            'parameters': {
              'type': 'object',
              'properties': {
                'requestId': {'type': 'string'},
                'action': {'type': 'string', 'enum': ['accept', 'reject']},
              },
              'required': ['requestId', 'action'],
            },
          },
          {
            'type': 'function',
            'name': 'delete_contact',
            'description': 'Remove a contact by userId.',
            'parameters': {
              'type': 'object',
              'properties': {
                'userId': {'type': 'string'},
              },
              'required': ['userId'],
            },
          },
          {
            'type': 'function',
            'name': 'block_contact',
            'description': 'Block or unblock a user by userId.',
            'parameters': {
              'type': 'object',
              'properties': {
                'userId': {'type': 'string'},
                'action': {'type': 'string', 'enum': ['block', 'unblock']},
              },
              'required': ['userId', 'action'],
            },
          },
          {
            'type': 'function',
            'name': 'get_call_history',
            'description': 'Get recent call history (incoming and outgoing calls) with duration, status, caller/callee names.',
            'parameters': {
              'type': 'object',
              'properties': {
                'limit': {'type': 'integer', 'description': 'Number of calls to return (default 20)'},
              },
            },
          },
          {
            'type': 'function',
            'name': 'get_sessions',
            'description': 'Get list of active user sessions (devices logged in). Returns device, IP, last activity.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'terminate_session',
            'description': 'Terminate (logout) a specific session by sessionId.',
            'parameters': {
              'type': 'object',
              'properties': {
                'sessionId': {'type': 'string'},
              },
              'required': ['sessionId'],
            },
          },
          {
            'type': 'function',
            'name': 'create_group',
            'description': 'Create a new group chat with specified members.',
            'parameters': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string', 'description': 'Group name'},
                'memberIds': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Array of userIds to add to the group',
                },
              },
              'required': ['name', 'memberIds'],
            },
          },
          {
            'type': 'function',
            'name': 'manage_group_members',
            'description': 'Add or remove a member from a group conversation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'userId': {'type': 'string'},
                'action': {'type': 'string', 'enum': ['add', 'remove']},
              },
              'required': ['conversationId', 'userId', 'action'],
            },
          },
          {
            'type': 'function',
            'name': 'get_tenants',
            'description': 'Get list of organizations/tenants the user belongs to.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'get_kyc_status',
            'description': 'Get current KYC (identity verification) status of the user.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'react_to_message',
            'description': 'Add an emoji reaction to a message in a conversation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'conversationId': {'type': 'string'},
                'messageId': {'type': 'string'},
                'emoji': {'type': 'string', 'description': 'Emoji character, e.g. 👍 ❤️ 😂'},
              },
              'required': ['conversationId', 'messageId', 'emoji'],
            },
          },
          {
            'type': 'function',
            'name': 'forward_message',
            'description': 'Forward a message content to another conversation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'targetConversationId': {'type': 'string', 'description': 'Destination conversation ID'},
                'content': {'type': 'string', 'description': 'Message text to forward'},
              },
              'required': ['targetConversationId', 'content'],
            },
          },
          {
            'type': 'function',
            'name': 'get_settings',
            'description': 'Get current app settings: theme (light/dark/system), language (ru/en), biometric enabled, PIN enabled.',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'set_theme',
            'description': 'Change the app theme.',
            'parameters': {
              'type': 'object',
              'properties': {
                'theme': {'type': 'string', 'enum': ['light', 'dark', 'system']},
              },
              'required': ['theme'],
            },
          },
          {
            'type': 'function',
            'name': 'set_language',
            'description': 'Change the app language.',
            'parameters': {
              'type': 'object',
              'properties': {
                'language': {'type': 'string', 'enum': ['ru', 'en']},
              },
              'required': ['language'],
            },
          },
          {
            'type': 'function',
            'name': 'set_biometric',
            'description': 'Enable or disable biometric authentication (fingerprint/Face ID). Disabling does not require authentication.',
            'parameters': {
              'type': 'object',
              'properties': {
                'enabled': {'type': 'boolean'},
              },
              'required': ['enabled'],
            },
          },
          {
            'type': 'function',
            'name': 'disable_pin',
            'description': 'Disable PIN code lock. To enable PIN a setup flow is required — tell the user to go to Settings.',
            'parameters': {'type': 'object', 'properties': {}},
          },
        ],
        'tool_choice': 'auto',
      },
    });

    // Auto-briefing on session start: check unread messages, missed calls, upcoming events
    final briefingPrompt = locale == 'ru'
        ? 'АВТОМАТИЧЕСКИЙ ЗАПУСК: Проверь незавершённые дела пользователя прямо сейчас:\n'
          '1. Вызови get_conversations — найди диалоги с unreadCount > 0 (непрочитанные сообщения)\n'
          '2. Вызови get_call_history — найди пропущенные звонки за последние 24 часа\n'
          '3. Вызови get_events — получи события на сегодня (от начала до конца дня)\n'
          '4. Вызови get_contact_requests — проверь входящие заявки в контакты\n'
          'На основе результатов дай краткую голосовую сводку: что нового, что требует внимания. '
          'Если всё чисто — скажи об этом коротко. Не задавай вопросов — просто озвучь сводку.'
        : 'AUTO-START: Check user\'s pending items right now:\n'
          '1. Call get_conversations — find chats with unreadCount > 0 (unread messages)\n'
          '2. Call get_call_history — find missed calls in the last 24 hours\n'
          '3. Call get_events — get today\'s events (from start to end of day)\n'
          '4. Call get_contact_requests — check incoming contact requests\n'
          'Based on the results, give a brief voice summary: what\'s new, what needs attention. '
          'If everything is clear — say so briefly. Don\'t ask questions — just deliver the briefing.';

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

  void _onIncomingMessage(dynamic msg) {
    if (_ws == null || _state != _CallState.connected) return;
    final senderName = msg.senderName ?? 'Unknown';
    final content = msg.content;
    final conversationId = msg.conversationId;
    if (content == null || content.isEmpty) return;
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
      } else if (name == 'get_sections') {
        final data = await client.get<List<dynamic>>(
          '/profile-sections',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'upsert_section') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.put<Map<String, dynamic>>(
          '/profile-sections',
          data: {
            'type': args['type'],
            'content': {
              'items': args['items'] ?? [],
              if (args['freeText'] != null) 'freeText': args['freeText'],
            },
            if (args['visibility'] != null) 'visibility': args['visibility'],
          },
          fromJson: (d) => d as Map<String, dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'delete_section') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/profile-sections/${args['type']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'search_contacts') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final query = args['query'] as String? ?? '';
        final data = await client.get<List<dynamic>>(
          '/messenger/users/search?q=${Uri.encodeComponent(query)}',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'get_conversations') {
        final data = await client.get<List<dynamic>>(
          '/messenger/conversations',
          fromJson: (d) => d as List<dynamic>,
        );
        // Return essential fields including unread info
        final slim = (data ?? []).map((c) {
          final m = c as Map<String, dynamic>;
          return {
            'id': m['id'],
            'otherUserName': m['otherUserName'],
            'otherUserId': m['otherUserId'],
            'type': m['type'],
            'unreadCount': m['unreadCount'] ?? 0,
            'lastMessageContent': m['lastMessageContent'],
            'lastMessageSenderName': m['lastMessageSenderName'],
          };
        }).toList();
        output = jsonEncode(slim);
      } else if (name == 'get_messages') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final convId = args['conversationId'] as String;
        final limit = args['limit'] as int? ?? 50;
        final data = await client.get<Map<String, dynamic>>(
          '/messenger/conversations/$convId/messages?limit=$limit',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'start_call') {
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
      } else if (name == 'send_message') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final convId = args['conversationId'] as String;
        final content = args['content'] as String;
        sl<MessengerRemoteDataSource>().sendMessage(convId, content);
        output = jsonEncode({'ok': true, 'message': 'sent'});
      } else if (name == 'get_notes') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final limit = args['limit'] as int? ?? 20;
        final data = await client.get<dynamic>('/notes?limit=$limit');
        output = jsonEncode(data);
      } else if (name == 'create_note') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.post('/notes', data: {
          'title': args['title'] as String,
          'content': args['content'] as String,
          'source': 'ASSISTANT',
        }, fromJson: (d) => d);
        output = jsonEncode(data);
      } else if (name == 'delete_note') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/notes/${args['noteId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'get_events') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        // Convert from/to to UTC for backend query
        String fromStr = args['from'] as String? ?? startOfDay.toUtc().toIso8601String();
        String toStr = args['to'] as String? ?? today.add(const Duration(days: 30)).toUtc().toIso8601String();
        if (!fromStr.endsWith('Z')) {
          final f = DateTime.tryParse(fromStr);
          if (f != null) fromStr = f.toUtc().toIso8601String();
        }
        if (!toStr.endsWith('Z')) {
          final t = DateTime.tryParse(toStr);
          if (t != null) toStr = t.toUtc().toIso8601String();
        }
        final data = await client.get<dynamic>('/calendar?from=$fromStr&to=$toStr');
        // Convert UTC times to local for the AI to read correct times
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final startUtc = DateTime.tryParse(item['startAt'] as String? ?? '');
              if (startUtc != null) item['startAt'] = startUtc.toLocal().toIso8601String();
              final endUtc = DateTime.tryParse(item['endAt'] as String? ?? '');
              if (endUtc != null) item['endAt'] = endUtc.toLocal().toIso8601String();
            }
          }
        }
        output = jsonEncode(data);
      } else if (name == 'create_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        // Convert local time to UTC for correct storage
        String startAtUtc = args['startAt'] as String? ?? '';
        String displayTime = startAtUtc; // keep original for push display
        if (startAtUtc.isNotEmpty && !startAtUtc.endsWith('Z')) {
          final local = DateTime.tryParse(startAtUtc);
          if (local != null) {
            displayTime = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
            startAtUtc = local.toUtc().toIso8601String();
          }
        }
        String? reminderUtc;
        if (args['reminderAt'] != null) {
          final r = DateTime.tryParse(args['reminderAt'] as String);
          if (r != null) reminderUtc = r.toUtc().toIso8601String();
        }
        String? endUtc;
        if (args['endAt'] != null) {
          final e = DateTime.tryParse(args['endAt'] as String);
          if (e != null) endUtc = e.toUtc().toIso8601String();
        }
        final data = await client.post('/calendar', data: {
          'title': args['title'],
          'description': args['description'],
          'type': args['type'],
          'startAt': startAtUtc,
          if (endUtc != null) 'endAt': endUtc,
          if (reminderUtc != null) 'reminderAt': reminderUtc,
          if (args['contactIds'] != null) 'contactIds': args['contactIds'],
          'displayTime': displayTime,
          'createdBy': 'ASSISTANT',
        }, fromJson: (d) => d);
        output = jsonEncode(data);
      } else if (name == 'delete_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/calendar/${args['eventId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'get_contacts') {
        final data = await client.get<List<dynamic>>(
          '/messenger/conversations',
          fromJson: (d) => d as List<dynamic>,
        );
        final contacts = (data ?? [])
            .where((c) => (c as Map<String, dynamic>)['type'] == 'DIRECT')
            .map((c) {
          final m = c as Map<String, dynamic>;
          return {
            'userId': m['otherUserId'],
            'name': m['otherUserName'],
            'conversationId': m['id'],
          };
        }).toList();
        output = jsonEncode(contacts);
      } else if (name == 'send_contact_request') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.post(
          '/messenger/contacts/request',
          data: {'receiverId': args['userId']},
          fromJson: (d) => d,
        );
        output = jsonEncode({'ok': true, 'data': data});
      } else if (name == 'get_contact_requests') {
        final data = await client.get<List<dynamic>>(
          '/messenger/contacts/requests',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'respond_contact_request') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final requestId = args['requestId'] as String;
        final action = args['action'] as String;
        await client.patch(
          '/messenger/contacts/requests/$requestId/$action',
          data: {},
          fromJson: (d) => d,
        );
        output = jsonEncode({'ok': true, 'action': action});
      } else if (name == 'delete_contact') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/messenger/contacts/${args['userId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'block_contact') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final userId = args['userId'] as String;
        final action = args['action'] as String;
        if (action == 'block') {
          await client.post('/messenger/contacts/$userId/block', data: {}, fromJson: (d) => d);
        } else {
          await client.delete('/messenger/contacts/$userId/block');
        }
        output = jsonEncode({'ok': true, 'action': action});
      } else if (name == 'get_call_history') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final limit = args['limit'] as int? ?? 20;
        final data = await client.get<dynamic>(
          '/voice/call-history?limit=$limit',
          fromJson: (d) => d,
        );
        output = jsonEncode(data);
      } else if (name == 'get_sessions') {
        final data = await client.get<List<dynamic>>(
          '/auth/sessions',
          fromJson: (d) => d as List<dynamic>,
        );
        output = jsonEncode(data);
      } else if (name == 'terminate_session') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/auth/sessions/${args['sessionId']}');
        output = jsonEncode({'ok': true});
      } else if (name == 'create_group') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.post(
          '/messenger/conversations/group',
          data: {
            'name': args['name'],
            'memberIds': args['memberIds'],
          },
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'manage_group_members') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final convId = args['conversationId'] as String;
        final userId = args['userId'] as String;
        final action = args['action'] as String;
        if (action == 'add') {
          await client.post(
            '/messenger/conversations/$convId/members',
            data: {'userId': userId},
            fromJson: (d) => d,
          );
        } else {
          await client.delete('/messenger/conversations/$convId/members/$userId');
        }
        output = jsonEncode({'ok': true, 'action': action});
      } else if (name == 'get_tenants') {
        final data = await client.get<List<dynamic>>(
          '/tenant',
          fromJson: (d) => d as List<dynamic>,
        );
        final slim = (data ?? []).map((t) {
          final m = t as Map<String, dynamic>;
          return {
            'id': m['id'],
            'name': m['name'],
            'role': m['role'],
            'membersCount': m['membersCount'],
          };
        }).toList();
        output = jsonEncode(slim);
      } else if (name == 'get_kyc_status') {
        final data = await client.get(
          '/kyc/status',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        output = jsonEncode(data);
      } else if (name == 'react_to_message') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        sl<MessengerRemoteDataSource>().reactToMessage(
          args['conversationId'] as String,
          args['messageId'] as String,
          args['emoji'] as String,
        );
        output = jsonEncode({'ok': true});
      } else if (name == 'forward_message') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        sl<MessengerRemoteDataSource>().sendMessage(
          args['targetConversationId'] as String,
          args['content'] as String,
        );
        output = jsonEncode({'ok': true, 'message': 'forwarded'});
      } else if (name == 'get_settings') {
        final storage = sl<SecureStorageService>();
        final theme = await storage.getThemeMode() ?? 'light';
        final lang = await storage.getLanguage() ?? 'ru';
        final biometric = await storage.isBiometricEnabled;
        final pin = await storage.isPinEnabled;
        output = jsonEncode({
          'theme': theme,
          'language': lang,
          'biometricEnabled': biometric,
          'pinEnabled': pin,
        });
      } else if (name == 'set_theme') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final theme = args['theme'] as String;
        final storage = sl<SecureStorageService>();
        await storage.saveThemeMode(theme);
        if (mounted) {
          final mode = switch (theme) {
            'dark' => ThemeMode.dark,
            'system' => ThemeMode.system,
            _ => ThemeMode.light,
          };
          TalerIdApp.setThemeMode(context, mode);
        }
        output = jsonEncode({'ok': true, 'theme': theme});
      } else if (name == 'set_language') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final lang = args['language'] as String;
        final storage = sl<SecureStorageService>();
        await storage.saveLanguage(lang);
        if (mounted) {
          TalerIdApp.setLocale(context, Locale(lang));
        }
        output = jsonEncode({'ok': true, 'language': lang});
      } else if (name == 'set_biometric') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final enabled = args['enabled'] as bool;
        if (enabled) {
          // Enabling requires device authentication — not safe to do from assistant
          output = jsonEncode({'ok': false, 'error': 'Enabling biometrics requires user authentication. Please go to Settings to enable it.'});
        } else {
          await sl<SecureStorageService>().setBiometricEnabled(false);
          output = jsonEncode({'ok': true, 'biometricEnabled': false});
        }
      } else if (name == 'disable_pin') {
        await sl<SecureStorageService>().clearPin();
        output = jsonEncode({'ok': true, 'pinEnabled': false});
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
    // Stop audio immediately so user doesn't hear lingering speech
    await _player.stop();
    _audioBuffer.clear();
    await _cleanup();
    await _setSpeaker(false);
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
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                          blurRadius: 60,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _logoVideoReady && _logoVideo != null
                          ? SizedBox(
                              width: 90,
                              height: 90,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _logoVideo!.value.size.width,
                                  height: _logoVideo!.value.size.height,
                                  child: VideoPlayer(_logoVideo!),
                                ),
                              ),
                            )
                          : Container(
                              width: 90,
                              height: 90,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding waveform rings when speaking
              AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (context, _) {
                  final t = (_orbitCtrl.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
                  return CustomPaint(
                    size: const Size(260, 260),
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
                  final scale =
                      speaking ? 1.0 + (_pulseAnim.value - 1.0) * 0.8 : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: speaking
                        ? const LinearGradient(
                            colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: speaking
                        ? null
                        : AppColors.of(context).card,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: speaking ? 0.3 : 0.1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (speaking ? const Color(0xFF22D3EE) : AppColors.of(context).primary)
                            .withValues(alpha: speaking ? 0.55 : 0.3),
                        blurRadius: speaking ? 40 : 24,
                        spreadRadius: speaking ? 8 : 4,
                      ),
                      if (speaking)
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                          blurRadius: 60,
                          spreadRadius: 12,
                        ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: _logoVideoReady && _logoVideo != null
                          ? SizedBox(
                              width: 90,
                              height: 90,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _logoVideo!.value.size.width,
                                  height: _logoVideo!.value.size.height,
                                  child: VideoPlayer(_logoVideo!),
                                ),
                              ),
                            )
                          : Container(
                              width: 90,
                              height: 90,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: speaking
              ? ShaderMask(
                  key: const ValueKey('speaking'),
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                  ).createShader(rect),
                  child: Text(
                    l10n.assistantAiSpeaking,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Text(
                  l10n.assistantAiListening,
                  key: const ValueKey('listening'),
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
