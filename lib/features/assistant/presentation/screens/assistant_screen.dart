import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:go_router/go_router.dart';

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

  // Orbit animation
  late AnimationController _orbitCtrl;
  int? _selectedOrbitIndex;

  VideoPlayerController? _logoVideo;
  bool _logoVideoReady = false;
  bool _logoVideoInitialized = false;

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
      duration: const Duration(seconds: 30),
    )..repeat();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logoVideoInitialized) {
      _logoVideoInitialized = true;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final asset = isDark ? 'assets/video.mp4' : 'assets/video_light.mp4';
      _logoVideo = VideoPlayerController.asset(asset)
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _logoVideoReady = true);
            _logoVideo!.play();
          }
        });
    }
  }

  @override
  void dispose() {
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
            'Говори на том же языке, на котором говорит пользователь. Не начинай разговор первым — жди когда пользователь заговорит. '
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
            'ПЕРЕКЛЮЧЕНИЕ РЕЖИМОВ:\n'
            '- При входе в режим — подтверди голосом какой режим активирован\n'
            '- "Сменить роль" / "выйди из роли" / "хватит" → вернись в обычный режим ассистента\n'
            '- Если пользователь просит что-то из основного режима (профиль, KYC) — спроси, хочет ли он выйти из текущего режима\n\n'
            'ЗВОНКИ КОНТАКТАМ:\n'
            'Если пользователь говорит "позвони [имя]" или "набери [имя]":\n'
            '1. Вызови get_conversations чтобы найти диалог с этим человеком по имени\n'
            '2. Если нашёл — вызови start_call с conversationId и calleeName\n'
            '3. Если не нашёл — вызови search_contacts и спроси уточнение\n'
            '4. Перед звонком скажи "Звоню [имя]"\n\n'
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
            'Часовой пояс: UTC${DateTime.now().timeZoneOffset.isNegative ? "" : "+"}${DateTime.now().timeZoneOffset.inHours}. '
            'Сейчас: ${DateTime.now().toIso8601String()}.\n'
            'Когда пользователь говорит время — это МЕСТНОЕ. Конвертируй в UTC для startAt.\n'
            'Если говорит "встреча с [имя]" — ставь type="CALL", найди контакт через get_conversations, передай contactIds.\n'
            'Типы: CALL=встреча со ссылкой, EVENT=событие, REMINDER=напоминание.\n'
            'Если спрашивает "что у меня запланировано" — вызови get_events и расскажи',
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
        final from = args['from'] as String? ?? DateTime.now().toIso8601String();
        final to = args['to'] as String? ?? DateTime.now().add(const Duration(days: 30)).toIso8601String();
        final data = await client.get<dynamic>('/calendar?from=$from&to=$to');
        output = jsonEncode(data);
      } else if (name == 'create_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.post('/calendar', data: {
          'title': args['title'],
          'description': args['description'],
          'type': args['type'],
          'startAt': args['startAt'],
          if (args['endAt'] != null) 'endAt': args['endAt'],
          if (args['reminderAt'] != null) 'reminderAt': args['reminderAt'],
          'createdBy': 'ASSISTANT',
        }, fromJson: (d) => d);
        output = jsonEncode(data);
      } else if (name == 'delete_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/calendar/${args['eventId']}');
        output = jsonEncode({'ok': true});
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
      appBar: AppBar(centerTitle: true, title: Text(l10n.tabAssistant)),
      body: switch (_state) {
        _CallState.idle => _buildIdle(l10n),
        _CallState.connecting => _buildConnecting(l10n),
        _CallState.connected => _buildConnected(l10n),
        _CallState.error => _buildError(l10n),
      },
    );
  }

  static const _capabilities = [
    _CapabilityData(
      icon: Icons.message_outlined,
      title: 'Сообщения',
      description: 'Проверь сообщения или напиши кому-нибудь. Например: "Напиши Виктору: буду через час"',
    ),
    _CapabilityData(
      icon: Icons.call_outlined,
      title: 'Звонки',
      description: 'Позвони любому контакту голосом. Например: "Позвони Виктору Викторову"',
    ),
    _CapabilityData(
      icon: Icons.history_outlined,
      title: 'Переписка',
      description: 'Проанализирую историю чата. Например: "Что мы обсуждали с Виктором?"',
    ),
    _CapabilityData(
      icon: Icons.person_outline,
      title: 'Профиль',
      description: 'Покажу или обновлю твой профиль. Например: "Покажи мой профиль"',
    ),
    _CapabilityData(
      icon: Icons.psychology_outlined,
      title: 'Коучинг',
      description: 'Режимы: коучинг ICF, психолог, HR-консультация. Скажи: "Давай коучинг"',
    ),
    _CapabilityData(
      icon: Icons.calendar_month_outlined,
      title: 'Календарь',
      description: 'Запланируй встречу или поставь напоминание. Например: "Поставь встречу с Виктором на завтра в 15:00"',
    ),
    _CapabilityData(
      icon: Icons.sticky_note_2_outlined,
      title: 'Заметки',
      description: 'Сохрани мысль или прочитай последние заметки. Например: "Запиши идею..." или "Прочитай последние заметки"',
    ),
  ];

  Widget _buildIdle(AppLocalizations l10n) {
    final colors = AppColors.of(context);
    final screenSize = MediaQuery.of(context).size;
    final orbitRadius = screenSize.width * 0.32;

    return Stack(
      children: [
        // Center assistant button (strictly centered)
        Center(
          child: GestureDetector(
            onTap: _connect,
            child: ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.card,
                  border: Border.all(color: colors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 6,
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

        // Orbiting icons (same center as logo)
        Center(
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (context, _) {
              return SizedBox(
                width: orbitRadius * 2 + 60,
                height: orbitRadius * 2 + 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(_capabilities.length, (i) {
                    final angle = (2 * math.pi * i / _capabilities.length) +
                        (_orbitCtrl.value * 2 * math.pi);
                    final x = orbitRadius * math.cos(angle);
                    final y = orbitRadius * math.sin(angle);
                    final cap = _capabilities[i];
                    final isSelected = _selectedOrbitIndex == i;

                    return Positioned(
                      left: orbitRadius + 30 + x - 24,
                      top: orbitRadius + 30 + y - 24,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOrbitIndex = isSelected ? null : i;
                          });
                        },
                        child: AnimatedScale(
                          scale: isSelected ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? colors.primary
                                  : colors.primary.withValues(alpha: 0.15),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: isSelected ? 1.0 : 0.4),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colors.primary.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              cap.icon,
                              size: 22,
                              color: isSelected ? Colors.white : colors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),

        // Selected capability description (bottom)
        if (_selectedOrbitIndex != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_selectedOrbitIndex),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _capabilities[_selectedOrbitIndex!].icon,
                          color: colors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _capabilities[_selectedOrbitIndex!].title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _capabilities[_selectedOrbitIndex!].description,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Text hint at the bottom
        if (_selectedOrbitIndex == null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              l10n.assistantTapToTalk,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
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

  Future<bool?> _showCallConfirmation(String calleeName) async {
    final colors = AppColors.of(context);
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
              'Позвонить?',
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
            child: Text('Отмена', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.call_rounded, size: 20),
            label: const Text('Позвонить', style: TextStyle(fontSize: 16)),
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

class _CapabilityData {
  final IconData icon;
  final String title;
  final String description;

  const _CapabilityData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
