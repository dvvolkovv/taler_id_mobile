import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/simple_list_cache.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../../messenger/presentation/bloc/messenger_event.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/datasources/calendar_remote_datasource.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _cache = sl<SimpleListCache>(instanceName: 'calendar');
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _invites = [];
  bool _loading = true;
  bool _calendarExpanded = true;

  // Voice assistant
  bool _voiceActive = false;
  bool _voiceConnecting = false;
  bool _aiSpeaking = false;
  WebSocket? _ws;
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;
  final _player = AudioPlayer();
  final List<int> _audioBuffer = [];
  static const _audioChannel = MethodChannel('taler_id/audio');

  String? _pendingEventId;

  @override
  void initState() {
    super.initState();
    // Hydrate from cache instantly, then refresh.
    final cached = _cache.get();
    if (cached != null && cached.isNotEmpty) {
      _events = cached;
      _loading = false;
    }
    _loadEvents();
    NotificationService.setCalendarUpdateCallback(_loadEvents);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final eventId = uri.queryParameters['eventId'];
      if (eventId != null && eventId.isNotEmpty) {
        _pendingEventId = eventId;
      }
    });
    _player.onPlayerComplete.listen((_) async {
      if (mounted) setState(() => _aiSpeaking = false);
      if (_ws != null && _voiceActive) {
        await _recordSub?.cancel();
        try { await _recorder.stop(); } catch (_) {}
        await _restartRecording();
      }
    });
  }

  @override
  void dispose() {
    NotificationService.setCalendarUpdateCallback(null);
    _voiceCleanup();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (_events.isEmpty) setState(() => _loading = true);
    try {
      final from = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      final to = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);
      final ds = CalendarRemoteDataSource(sl<DioClient>());
      _events = await ds.getEvents(from: from.toIso8601String(), to: to.toIso8601String());
      _invites = await ds.getMyInvites();
      _cache.save(_events); // fire-and-forget persist
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    // Open event detail if deep-linked from notification
    if (_pendingEventId != null && _events.isNotEmpty) {
      final eid = _pendingEventId;
      _pendingEventId = null;
      final event = _events.cast<Map<String, dynamic>?>().firstWhere(
        (e) => e?['id'] == eid, orElse: () => null,
      );
      if (event != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openEditor(event: event);
        });
      }
    }
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    return _events.where((e) {
      final start = DateTime.tryParse(e['startAt'] as String? ?? '');
      if (start == null) return false;
      return start.year == day.year && start.month == day.month && start.day == day.day;
    }).toList();
  }

  void _openEditor({Map<String, dynamic>? event}) async {
    // For new events, use today if selected date is in the past
    final date = event != null ? _selectedDate :
        (_selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) ? DateTime.now() : _selectedDate);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _EventEditScreen(event: event, selectedDate: date)),
    );
    if (result == true) _loadEvents();
  }

  void _refreshBadges() {
    try { context.read<MessengerBloc>().add(LoadBadgeCounts()); } catch (_) {}
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await CalendarRemoteDataSource(sl<DioClient>()).delete(id);
      _events.removeWhere((e) => e['id'] == id);
      _cache.remove(id);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ── Voice assistant ──
  Future<void> _startVoice() async {
    setState(() => _voiceConnecting = true);
    try {
      final token = await sl<SecureStorageService>().getAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final wsUrl = Uri(scheme: 'wss', host: Uri.parse(ApiConstants.baseUrl).host, path: '/voice/realtime-proxy', queryParameters: {'token': token}).toString();
      _ws = await WebSocket.connect(wsUrl);
      _ws!.listen((data) => _onVoiceMessage(data as String), onDone: () { if (mounted && _voiceActive) _stopVoice(); }, onError: (_) { if (mounted) _stopVoice(); });

      _ws!.add(jsonEncode({
        'type': 'session.update',
        'session': {
          'modalities': ['text', 'audio'],
          'instructions': Localizations.localeOf(context).languageCode == 'ru'
              ? 'Ты — помощник для управления календарём. '
                'Сейчас: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().day.toString().padLeft(2, "0")} ${DateTime.now().hour.toString().padLeft(2, "0")}:${DateTime.now().minute.toString().padLeft(2, "0")}. '
                'ВАЖНО: передавай startAt, endAt и reminderAt в МЕСТНОМ времени пользователя в формате YYYY-MM-DDTHH:MM:SS (БЕЗ Z на конце, БЕЗ конвертации в UTC). '
                'Например если пользователь сказал "18:00 сегодня" — передай "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().day.toString().padLeft(2, "0")}T18:00:00".\n\n'
                'СТРОГИЕ ПРАВИЛА:\n'
                '1. НИКОГДА не создавай create_event без предварительного вызова get_conversations. ВСЕГДА сначала get_conversations.\n'
                '2. НИКОГДА не вызывай create_event больше одного раза за запрос. Одна встреча = один вызов.\n'
                '3. Если пользователь упоминает имя человека — найди его userId через get_conversations и передай в contactIds.\n'
                '4. Если имя не упомянуто — спроси "С кем встреча?" перед созданием.\n'
                '5. Всегда ставь type="CALL" для встреч — ссылка на комнату создастся автоматически.\n'
                '6. Всегда ставь endAt = startAt + 1 час, если пользователь не указал длительность.\n\n'
                'ТИПЫ: CALL=встреча со ссылкой, EVENT=событие, REMINDER=напоминание.\n'
                'РЕДАКТИРОВАНИЕ: get_events → найди по названию → update_event с id. НЕ создавай дубликат!\n'
                'ДОБАВЛЕНИЕ УЧАСТНИКА: get_events → найди встречу → get_conversations → найди userId → update_event с contactIds.\n'
                'Начни с: "Слушаю, что хотите сделать в календаре?"'
              : 'You are an assistant for calendar management. '
                'Now: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().day.toString().padLeft(2, "0")} ${DateTime.now().hour.toString().padLeft(2, "0")}:${DateTime.now().minute.toString().padLeft(2, "0")}. '
                'IMPORTANT: pass startAt, endAt and reminderAt in USER LOCAL time format YYYY-MM-DDTHH:MM:SS (NO Z suffix, NO UTC conversion). '
                'For example if user says "6pm today" — pass "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().day.toString().padLeft(2, "0")}T18:00:00".\n\n'
                'STRICT RULES:\n'
                '1. NEVER call create_event without calling get_conversations first. ALWAYS get_conversations first.\n'
                '2. NEVER call create_event more than once per request. One meeting = one call.\n'
                '3. If user mentions a person name — find their userId via get_conversations and pass in contactIds.\n'
                '4. If no name mentioned — ask "Who is the meeting with?" before creating.\n'
                '5. Always use type="CALL" for meetings — room link is created automatically.\n'
                '6. Always set endAt = startAt + 1 hour unless user specifies duration.\n\n'
                'TYPES: CALL=meeting with link, EVENT=event, REMINDER=reminder.\n'
                'EDITING: get_events → find by name → update_event with id. Do NOT create duplicates!\n'
                'ADDING PARTICIPANT: get_events → find meeting → get_conversations → find userId → update_event with contactIds.\n'
                'Start with: "Listening, what would you like to do in the calendar?"',
          'voice': 'alloy',
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'input_audio_transcription': {'model': 'whisper-1'},
          'turn_detection': {'type': 'server_vad', 'threshold': 0.5, 'prefix_padding_ms': 300, 'silence_duration_ms': 700},
          'tools': [
            {
              'type': 'function', 'name': 'create_event',
              'description': 'Create a calendar event. For type CALL a meeting room link is auto-generated.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'title': {'type': 'string'},
                  'description': {'type': 'string'},
                  'type': {'type': 'string', 'enum': ['CALL', 'EVENT', 'REMINDER']},
                  'startAt': {'type': 'string', 'description': 'ISO datetime'},
                  'endAt': {'type': 'string', 'description': 'ISO datetime for end of event'},
                  'reminderAt': {'type': 'string', 'description': 'ISO datetime for push reminder'},
                  'contactIds': {'type': 'array', 'items': {'type': 'string'}, 'description': 'User IDs to invite'},
                },
                'required': ['title', 'type', 'startAt'],
              },
            },
            {
              'type': 'function', 'name': 'update_event',
              'description': 'Update an existing calendar event by ID. Only pass fields to change.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'eventId': {'type': 'string'},
                  'title': {'type': 'string'},
                  'description': {'type': 'string'},
                  'startAt': {'type': 'string'},
                  'endAt': {'type': 'string'},
                  'reminderAt': {'type': 'string'},
                  'contactIds': {'type': 'array', 'items': {'type': 'string'}},
                },
                'required': ['eventId'],
              },
            },
            {
              'type': 'function', 'name': 'delete_event',
              'description': 'Delete a calendar event by ID.',
              'parameters': {
                'type': 'object',
                'properties': {'eventId': {'type': 'string'}},
                'required': ['eventId'],
              },
            },
            {
              'type': 'function', 'name': 'get_events',
              'description': 'Get upcoming events with id, title, type, startAt, contactIds.',
              'parameters': {'type': 'object', 'properties': {}},
            },
            {
              'type': 'function', 'name': 'get_conversations',
              'description': 'Get user contacts/conversations to find contactIds for invites.',
              'parameters': {'type': 'object', 'properties': {}},
            },
          ],
          'tool_choice': 'auto',
        },
      }));

      try { await _audioChannel.invokeMethod('setSpeaker', true); } catch (_) {}
      const config = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 24000, numChannels: 1);
      final stream = await _recorder.startStream(config);
      _recordSub = stream.listen((chunk) { _ws?.add(jsonEncode({'type': 'input_audio_buffer.append', 'audio': base64Encode(chunk)})); });

      setState(() { _voiceActive = true; _voiceConnecting = false; });
      _ws!.add(jsonEncode({'type': 'response.create'}));
    } catch (e) {
      await _voiceCleanup();
      setState(() => _voiceConnecting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))));
    }
  }

  Future<void> _restartRecording() async {
    const config = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 24000, numChannels: 1);
    final stream = await _recorder.startStream(config);
    _recordSub = stream.listen((chunk) { _ws?.add(jsonEncode({'type': 'input_audio_buffer.append', 'audio': base64Encode(chunk)})); });
  }

  Future<void> _stopVoice() async {
    await _voiceCleanup();
    try { await _audioChannel.invokeMethod('setSpeaker', false); } catch (_) {}
    if (mounted) setState(() { _voiceActive = false; _aiSpeaking = false; });
    _loadEvents();
  }

  Future<void> _voiceCleanup() async {
    _audioBuffer.clear();
    await _recordSub?.cancel(); _recordSub = null;
    try { await _recorder.stop(); } catch (_) {}
    try { _ws?.close(); } catch (_) {}
    _ws = null;
  }

  void _onVoiceMessage(String data) {
    try {
      final event = jsonDecode(data) as Map<String, dynamic>;
      final type = event['type'] as String? ?? '';
      if (type == 'response.audio.delta') {
        final delta = event['delta'] as String? ?? '';
        if (delta.isNotEmpty) { _audioBuffer.addAll(base64Decode(delta)); if (mounted && !_aiSpeaking) setState(() => _aiSpeaking = true); }
      } else if (type == 'response.audio.done') {
        _playAudioBuffer();
      } else if (type == 'response.function_call_arguments.done') {
        _handleVoiceTool(event['name'] as String? ?? '', event['arguments'] as String? ?? '{}', event['call_id'] as String? ?? '');
      }
    } catch (_) {}
  }

  Future<void> _playAudioBuffer() async {
    if (_audioBuffer.isEmpty) return;
    final h = ByteData(44);
    void w(int o, String s) { for (var i = 0; i < s.length; i++) h.setUint8(o + i, s.codeUnitAt(i)); }
    w(0, 'RIFF'); h.setUint32(4, 36 + _audioBuffer.length, Endian.little);
    w(8, 'WAVE'); w(12, 'fmt '); h.setUint32(16, 16, Endian.little); h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 1, Endian.little); h.setUint32(24, 24000, Endian.little);
    h.setUint32(28, 48000, Endian.little); h.setUint16(32, 2, Endian.little); h.setUint16(34, 16, Endian.little);
    w(36, 'data'); h.setUint32(40, _audioBuffer.length, Endian.little);
    final wav = Uint8List.fromList([...h.buffer.asUint8List(), ..._audioBuffer]);
    _audioBuffer.clear();
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/calendar_ai.wav');
      await file.writeAsBytes(wav);
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('[Calendar] playback error: $e');
    }
    if (mounted) setState(() => _aiSpeaking = true);
  }

  Future<void> _handleVoiceTool(String name, String argsJson, String callId) async {
    final client = sl<DioClient>();
    String output;
    try {
      if (name == 'create_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        String? desc = args['description'] as String?;
        // Convert local time to UTC for correct storage
        String startAtUtc = args['startAt'] as String? ?? '';
        String displayTime = startAtUtc;
        if (startAtUtc.isNotEmpty && !startAtUtc.endsWith('Z')) {
          final local = DateTime.tryParse(startAtUtc);
          if (local != null) {
            displayTime = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
            startAtUtc = local.toUtc().toIso8601String();
          }
        }
        String? endAtUtc;
        if (args['endAt'] != null) {
          final e = DateTime.tryParse(args['endAt'] as String);
          if (e != null) endAtUtc = e.toUtc().toIso8601String();
        }
        String? reminderUtc;
        if (args['reminderAt'] != null) {
          final r = DateTime.tryParse(args['reminderAt'] as String);
          if (r != null) reminderUtc = r.toUtc().toIso8601String();
        }
        // For CALL type, create room and add link
        if (args['type'] == 'CALL') {
          try {
            final room = await client.post<Map<String, dynamic>>('/voice/rooms/public', data: {'title': args['title'] ?? 'Meeting'}, fromJson: (d) => Map<String, dynamic>.from(d as Map));
            final code = room?['code'] as String? ?? '';
            if (code.isNotEmpty) {
              final link = '${ApiConstants.baseUrl}/room/$code';
              desc = desc != null && desc.isNotEmpty ? '$desc\n$link' : link;
            }
          } catch (e) {
            debugPrint('[Calendar] Failed to create room: $e');
          }
        }
        final data = await client.post('/calendar', data: {
          'title': args['title'], 'description': desc, 'type': args['type'],
          'startAt': startAtUtc,
          if (endAtUtc != null) 'endAt': endAtUtc,
          if (reminderUtc != null) 'reminderAt': reminderUtc,
          if (args['contactIds'] != null) 'contactIds': args['contactIds'],
          'displayTime': displayTime,
          'createdBy': 'ASSISTANT',
        }, fromJson: (d) => d);
        _loadEvents();
        output = jsonEncode(data);
      } else if (name == 'update_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final eventId = args.remove('eventId') as String;
        final data = await client.patch('/calendar/$eventId', data: args, fromJson: (d) => d);
        _loadEvents();
        output = jsonEncode(data);
      } else if (name == 'delete_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await client.delete('/calendar/${args['eventId']}');
        _loadEvents();
        output = jsonEncode({'ok': true});
      } else if (name == 'get_events') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final now = DateTime.now();
        String fromStr = args['from'] as String? ?? DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
        String toStr = args['to'] as String? ?? now.add(const Duration(days: 30)).toUtc().toIso8601String();
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
      } else if (name == 'get_conversations') {
        final data = await client.get<dynamic>('/messenger/conversations');
        // Simplify for AI: extract contact name and userId
        final contacts = <Map<String, String>>[];
        if (data is List) {
          for (final conv in data) {
            if (conv is Map<String, dynamic> && conv['isGroup'] != true) {
              final name = conv['otherUserName'] as String? ?? '';
              final userId = conv['otherUserId'] as String? ?? '';
              if (name.isNotEmpty && userId.isNotEmpty) {
                contacts.add({'name': name, 'userId': userId, 'conversationId': conv['id'] as String? ?? ''});
              }
            }
          }
        }
        output = jsonEncode(contacts);
      } else {
        output = jsonEncode({'error': 'unknown'});
      }
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }
    _ws?.add(jsonEncode({'type': 'conversation.item.create', 'item': {'type': 'function_call_output', 'call_id': callId, 'output': output}}));
    _ws?.add(jsonEncode({'type': 'response.create'}));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dayEvents = List<Map<String, dynamic>>.from(_eventsForDay(_selectedDate));
    // Sort by time
    dayEvents.sort((a, b) {
      final ta = DateTime.tryParse(a['startAt'] as String? ?? '') ?? DateTime(2099);
      final tb = DateTime.tryParse(b['startAt'] as String? ?? '') ?? DateTime(2099);
      return ta.compareTo(tb);
    });

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.calendarTitle),
        actions: [
          if (_voiceConnecting)
            const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: GestureDetector(
                onTap: _voiceActive ? _stopVoice : _startVoice,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _voiceActive
                          ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                          : const [Color(0xFF22D3EE), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_voiceActive ? const Color(0xFFEF4444) : const Color(0xFF22D3EE))
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _voiceActive ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.add, color: colors.primary),
            onPressed: () => _openEditor(),
            tooltip: l10n.calendarNewEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_voiceActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _aiSpeaking ? colors.primary.withValues(alpha: 0.15) : colors.card,
              child: Row(
                children: [
                  Icon(_aiSpeaking ? Icons.volume_up : Icons.hearing, size: 18, color: _aiSpeaking ? colors.primary : colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(_aiSpeaking ? l10n.calendarAssistantSpeaking : l10n.calendarListening, style: TextStyle(fontSize: 13, color: _aiSpeaking ? colors.primary : colors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          // Pending invites banner — shown above calendar for visibility
          if (_invites.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colors.primary.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.calendarInvitations(_invites.length), style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ..._invites.map((inv) {
                    final event = inv['event'] as Map<String, dynamic>? ?? {};
                    final creator = event['user'] as Map<String, dynamic>? ?? {};
                    final profile = creator['profile'] as Map<String, dynamic>? ?? {};
                    final creatorName = [profile['firstName'], profile['lastName']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
                    final title = event['title'] as String? ?? '';
                    final start = DateTime.tryParse(event['startAt'] as String? ?? '')?.toLocal();
                    final timeStr = start != null ? DateFormat('dd.MM HH:mm').format(start) : '';
                    return Card(
                      color: colors.card,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('$creatorName · $timeStr', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close, color: colors.error, size: 20),
                              tooltip: l10n.reject,
                              onPressed: () async {
                                await CalendarRemoteDataSource(sl<DioClient>()).declineInvite(inv['id'] as String);
                                _loadEvents();
                                _refreshBadges();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.help_outline, color: colors.primary, size: 20),
                              tooltip: 'Maybe',
                              onPressed: () async {
                                await CalendarRemoteDataSource(sl<DioClient>()).maybeInvite(inv['id'] as String);
                                _loadEvents();
                                _refreshBadges();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green, size: 20),
                              tooltip: l10n.accept,
                              onPressed: () async {
                                await CalendarRemoteDataSource(sl<DioClient>()).acceptInvite(inv['id'] as String);
                                _loadEvents();
                                _refreshBadges();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          _buildMonthHeader(colors),
          if (_calendarExpanded) ...[
          _buildWeekDays(colors),
          _buildCalendarGrid(colors),
          ],
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                : dayEvents.isEmpty
                    ? Center(child: Text(l10n.calendarNoEvents, style: TextStyle(color: colors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: dayEvents.length,
                        itemBuilder: (_, i) => _buildEventCard(dayEvents[i], colors),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: colors.textPrimary),
            onPressed: () {
              setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
              _loadEvents();
            },
          ),
          GestureDetector(
            onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy', Localizations.localeOf(context).languageCode).format(_focusedMonth),
                  style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(_calendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: colors.textSecondary, size: 20),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: colors.textPrimary),
            onPressed: () {
              setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));
              _loadEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final days = [l10n.calendarDayMon, l10n.calendarDayTue, l10n.calendarDayWed, l10n.calendarDayThu, l10n.calendarDayFri, l10n.calendarDaySat, l10n.calendarDaySun];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: days.map((d) => Expanded(
          child: Center(child: Text(d, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500))),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(AppColorsExtension colors) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;
    final totalCells = startWeekday + lastDay.day;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final dayNum = idx - startWeekday + 1;
              if (dayNum < 1 || dayNum > lastDay.day) return const Expanded(child: SizedBox(height: 40));

              final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
              final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
              final hasEvents = _eventsForDay(date).isNotEmpty;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : null,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isSelected ? Colors.black : isToday ? colors.primary : colors.textPrimary,
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (hasEvents)
                          Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, AppColorsExtension colors) {
    final start = DateTime.tryParse(event['startAt'] as String? ?? '')?.toLocal();
    final end = DateTime.tryParse(event['endAt'] as String? ?? '')?.toLocal();
    final timeStr = start != null
        ? (end != null ? '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}' : DateFormat('HH:mm').format(start))
        : '';
    final type = event['type'] as String? ?? 'EVENT';

    IconData icon;
    List<Color> typeGradient;
    switch (type) {
      case 'CALL':
        icon = Icons.call_rounded;
        typeGradient = const [Color(0xFF3B82F6), Color(0xFFA855F7)]; // blue → purple
        break;
      case 'REMINDER':
        icon = Icons.notifications_active_rounded;
        typeGradient = const [Color(0xFFF59E0B), Color(0xFFEF4444)]; // amber → red
        break;
      default:
        icon = Icons.event_rounded;
        typeGradient = const [Color(0xFF10B981), Color(0xFF22D3EE)]; // emerald → cyan
    }
    final typeColor = typeGradient.first;

    final desc = event['description'] as String? ?? '';
    // Extract room link from description
    final linkMatch = RegExp(r'https://(?:staging\.)?id\.taler\.tirol/room/[\w-]+').firstMatch(desc);
    final roomLink = linkMatch?.group(0);
    final descClean = desc.replaceAll(RegExp(r'\n?https://(?:staging\.)?id\.taler\.tirol/room/[\w-]+'), '').replaceAll(RegExp(r'Место: '), '').trim();
    final invites = (event['invites'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final eventId = event['id'] as String;
    return Dismissible(
      key: Key(eventId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: colors.error, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        try {
          final ds = CalendarRemoteDataSource(sl<DioClient>());
          final currentUserId = context.read<MessengerBloc>().state.currentUserId;
          final eventUserId = event['userId'] as String?;
          final isOrganizer = currentUserId != null && eventUserId == currentUserId;

          if (isOrganizer) {
            // Organizer deletes the event for everyone
            await ds.delete(eventId);
          } else {
            // Participant declines their invite (removes from their calendar)
            final invites = (event['invites'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            final myInvite = invites.where((inv) {
              final u = inv['user'] as Map<String, dynamic>? ?? {};
              return u['id'] == currentUserId;
            }).firstOrNull;
            if (myInvite != null) {
              await ds.declineInvite(myInvite['id'] as String);
            } else {
              await ds.delete(eventId);
            }
          }
          return true;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.calendarDeleteError(e.toString())), backgroundColor: Colors.red),
            );
          }
          return false;
        }
      },
      onDismissed: (_) {
        _events.removeWhere((e) => e['id'] == eventId);
        if (mounted) setState(() {});
      },
      child: Card(
        color: colors.card,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openEditor(event: event),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                SizedBox(
                  width: 50,
                  child: Text(timeStr, style: TextStyle(color: typeColor, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Container(
                  width: 4, height: 44,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: typeGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: typeGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(event['title'] as String? ?? '', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (event['recurrence'] != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.repeat_rounded, size: 14, color: colors.textSecondary),
                          ],
                        ],
                      ),
                      if (descClean.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(descClean, style: TextStyle(color: colors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      if (roomLink != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final code = roomLink.split('/room/').last;
                            context.push('/dashboard/voice?publicCode=$code');
                          },
                          child: Row(
                            children: [
                              Icon(Icons.videocam_rounded, size: 14, color: colors.primary),
                              const SizedBox(width: 4),
                              Text(AppLocalizations.of(context)!.calendarEnterRoom, style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    if (invites.isNotEmpty || event['user'] != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: [
                          // Organizer chip
                          if (event['user'] != null) ...[
                            () {
                              final ou = event['user'] as Map<String, dynamic>;
                              final op = ou['profile'] as Map<String, dynamic>? ?? {};
                              final oName = [op['firstName'], op['lastName']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
                              return Chip(
                                avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
                                label: Text(oName.isNotEmpty ? oName : (ou['username'] as String? ?? '?'), style: TextStyle(fontSize: 11, color: colors.textPrimary)),
                                backgroundColor: colors.surface,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              );
                            }(),
                          ],
                          // Invited participants
                          ...invites.map<Widget>((inv) {
                          final u = inv['user'] as Map<String, dynamic>? ?? {};
                          final p = u['profile'] as Map<String, dynamic>? ?? {};
                          final name = [p['firstName'], p['lastName']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
                          final status = inv['status'] as String? ?? 'PENDING';
                          final Color sc;
                          final IconData si;
                          switch (status) {
                            case 'ACCEPTED': sc = Colors.green; si = Icons.check_circle; break;
                            case 'DECLINED': sc = colors.error; si = Icons.cancel; break;
                            case 'MAYBE': sc = Colors.orange; si = Icons.help_outline; break;
                            default: sc = colors.textSecondary; si = Icons.schedule; break;
                          }
                          return Chip(
                            avatar: Icon(si, size: 14, color: sc),
                            label: Text(name.isNotEmpty ? name : '?', style: TextStyle(fontSize: 11, color: colors.textPrimary)),
                            backgroundColor: colors.surface,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          );
                        }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _EventEditScreen extends StatefulWidget {
  final Map<String, dynamic>? event;
  final DateTime selectedDate;
  const _EventEditScreen({this.event, required this.selectedDate});

  @override
  State<_EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<_EventEditScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime; // null = no end time
  String _type = 'CALL';
  int _reminderMinutes = -1; // -1 = off, 15, 30, 60
  String _recurrenceFrequency = 'none';
  bool _saving = false;
  List<Map<String, dynamic>> _contacts = [];
  List<String> _selectedContactIds = [];
  Map<String, String> _invitesMap = {};
  String? _meetingLink;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?['title'] as String? ?? '');
    _type = e?['type'] as String? ?? 'CALL';

    // Parse description — extract meeting link if present
    final rawDesc = e?['description'] as String? ?? '';
    final linkMatch = RegExp(r'https://(?:staging\.)?id\.taler\.tirol/room/[\w-]+').firstMatch(rawDesc);
    _meetingLink = linkMatch?.group(0);
    final cleanDesc = rawDesc.replaceAll(RegExp(r'\n?https://(?:staging\.)?id\.taler\.tirol/room/[\w-]+'), '').trim();
    _descCtrl = TextEditingController(text: cleanDesc);
    _locationCtrl = TextEditingController(text: _meetingLink ?? '');
    _locationCtrl.addListener(() {
      // Rebuild so Copy/Join buttons appear/disappear as the link text changes.
      if (mounted) setState(() {});
    });

    if (e != null && e['startAt'] != null) {
      final dt = DateTime.parse(e['startAt'] as String).toLocal();
      _startDate = dt;
      _startTime = TimeOfDay.fromDateTime(dt);
    } else {
      _startDate = widget.selectedDate.isBefore(DateTime.now()) ? DateTime.now() : widget.selectedDate;
      // Round to next hour
      final now = TimeOfDay.now();
      _startTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    }

    if (e != null && e['endAt'] != null) {
      final endDt = DateTime.parse(e['endAt'] as String).toLocal();
      _endTime = TimeOfDay.fromDateTime(endDt);
    } else {
      // Default: 1 hour after start
      _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
    }

    if (e != null && e['reminderAt'] != null) {
      final reminderDt = DateTime.parse(e['reminderAt'] as String).toLocal();
      final startDt = e['startAt'] != null ? DateTime.parse(e['startAt'] as String).toLocal() : null;
      if (startDt != null) {
        final diff = startDt.difference(reminderDt).inMinutes;
        _reminderMinutes = [15, 30, 60].contains(diff) ? diff : 15;
      }
    }

    if (e != null && e['recurrence'] != null) {
      final rec = e['recurrence'] as Map<String, dynamic>;
      _recurrenceFrequency = rec['frequency'] as String? ?? 'none';
    }

    if (e != null && e['contactIds'] != null) {
      _selectedContactIds = List<String>.from(e['contactIds'] as List);
    }

    if (e != null) {
      final invites = (e['invites'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final inv in invites) {
        final u = inv['user'] as Map<String, dynamic>? ?? {};
        final userId = u['id'] as String?;
        if (userId != null) {
          _invitesMap[userId] = inv['status'] as String? ?? 'PENDING';
        }
      }
    }

    _loadContacts();
    // Auto-generate meeting link for new CALL events
    if (widget.event == null && _type == 'CALL') {
      _generateMeetingLink();
    }
  }

  bool _hasMeetingLink() {
    final text = _locationCtrl.text.trim();
    return RegExp(r'^https://(?:staging\.)?id\.taler\.tirol/room/[\w-]+').hasMatch(text);
  }

  Future<void> _copyMeetingLink() async {
    final text = _locationCtrl.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.callLinkCopied),
        backgroundColor: AppColors.of(context).primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _joinMeeting() {
    final text = _locationCtrl.text.trim();
    final match = RegExp(r'/room/([\w-]+)').firstMatch(text);
    final code = match?.group(1);
    if (code == null || code.isEmpty) return;
    context.push('/dashboard/voice?publicCode=$code');
  }

  Future<void> _generateMeetingLink() async {
    try {
      final room = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms/public',
        data: {'title': _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : AppLocalizations.of(context)!.calendarMeeting},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      // Prefer the full URL from the server (honours current flavor/host),
      // fall back to building it from the code.
      String? link = room?['link'] as String?;
      if (link == null || link.isEmpty) {
        final code = room?['code'] as String? ?? '';
        if (code.isNotEmpty) link = '${ApiConstants.baseUrl}/room/$code';
      }
      if (link != null && link.isNotEmpty && mounted) {
        setState(() {
          _meetingLink = link;
          _locationCtrl.text = link!;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadContacts() async {
    try {
      final data = await sl<DioClient>().get<dynamic>('/messenger/conversations');
      final list = (data as List?) ?? [];
      final contacts = <Map<String, dynamic>>[];
      for (final item in list) {
        final conv = Map<String, dynamic>.from(item as Map);
        if ((conv['type'] as String? ?? '').toUpperCase() != 'DIRECT') continue;
        contacts.add({
          'userId': conv['otherUserId'] as String? ?? '',
          'name': conv['otherUserName'] as String? ?? '',
          'avatar': conv['otherUserAvatar'] as String?,
          'conversationId': conv['id'] as String,
        });
      }
      if (mounted) setState(() => _contacts = contacts);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final startAt = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      // Build description with location/link
      String description = _descCtrl.text.trim();
      final loc = _locationCtrl.text.trim();
      if (loc.isNotEmpty && RegExp(r'^https://(?:staging\.)?id\.taler\.tirol/room/').hasMatch(loc)) {
        description = description.isNotEmpty ? '$description\n$loc' : loc;
      } else if (loc.isNotEmpty) {
        final locPrefix = AppLocalizations.of(context)!.calendarLocationPrefix(loc);
        description = description.isNotEmpty ? '$description\n$locPrefix' : locPrefix;
      }

      // Calculate reminderAt from minutes
      DateTime? reminderAt;
      if (_reminderMinutes > 0) {
        reminderAt = startAt.subtract(Duration(minutes: _reminderMinutes));
      }

      DateTime? endAt;
      if (_endTime != null) {
        endAt = DateTime(_startDate.year, _startDate.month, _startDate.day, _endTime!.hour, _endTime!.minute);
      }

      // Format display time in local timezone for push notifications
      final displayTime = '${startAt.day.toString().padLeft(2, '0')}.${startAt.month.toString().padLeft(2, '0')} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';

      final data = {
        'title': _titleCtrl.text.trim(),
        'description': description,
        'type': _type,
        'startAt': startAt.toUtc().toIso8601String(),
        if (endAt != null) 'endAt': endAt.toUtc().toIso8601String(),
        if (reminderAt != null) 'reminderAt': reminderAt.toUtc().toIso8601String(),
        if (_selectedContactIds.isNotEmpty) 'contactIds': _selectedContactIds,
        'displayTime': displayTime,
        'recurrence': _recurrenceFrequency != 'none' ? {'frequency': _recurrenceFrequency, 'interval': 1} : null,
      };
      final ds = CalendarRemoteDataSource(sl<DioClient>());
      if (widget.event != null) {
        await ds.update(widget.event!['id'] as String, data);
      } else {
        await ds.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showContactPicker() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ContactPickerSheet(
        contacts: _contacts,
        selectedIds: _selectedContactIds,
        onSelected: (id) {
          setState(() => _selectedContactIds.add(id));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildInviteStatus(String status, AppColorsExtension colors, AppLocalizations l10n) {
    final Color sc;
    final IconData si;
    final String label;
    switch (status) {
      case 'ACCEPTED': sc = Colors.green; si = Icons.check_circle_outline; label = l10n.calendarStatusAccepted; break;
      case 'DECLINED': sc = colors.error; si = Icons.cancel_outlined; label = l10n.calendarStatusDeclined; break;
      case 'MAYBE': sc = Colors.orange; si = Icons.help_outline; label = l10n.calendarStatusMaybe; break;
      default: sc = colors.textSecondary; si = Icons.schedule; label = l10n.calendarStatusPending; break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(si, size: 14, color: sc),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final today = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<MessengerBloc>().state.currentUserId;
    final eventUserId = widget.event?['userId'] as String?;
    final isOrganizer = widget.event == null || currentUserId == eventUserId;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.event == null ? l10n.calendarNewEvent : l10n.calendarEditEvent),
        actions: [
          if (isOrganizer) TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                : Text(l10n.save, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: l10n.calendarTitleHint, hintStyle: TextStyle(color: colors.textSecondary), border: InputBorder.none),
          ),
          TextField(
            controller: _descCtrl,
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.calendarDescriptionHint, hintStyle: TextStyle(color: colors.textSecondary), border: InputBorder.none),
          ),
          const Divider(),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: colors.card,
            style: TextStyle(color: colors.textPrimary),
            items: [
              DropdownMenuItem(value: 'EVENT', child: Text(l10n.calendarTypeEvent)),
              DropdownMenuItem(value: 'CALL', child: Text(l10n.calendarTypeMeeting)),
              DropdownMenuItem(value: 'REMINDER', child: Text(l10n.calendarTypeReminder)),
            ],
            onChanged: (v) {
              setState(() => _type = v!);
              if (v == 'CALL' && _meetingLink == null && widget.event == null) {
                _generateMeetingLink();
              }
            },
            decoration: InputDecoration(labelText: l10n.calendarTypeLabel, labelStyle: TextStyle(color: colors.textSecondary), border: InputBorder.none),
          ),
          // Location / Meeting link
          TextField(
            controller: _locationCtrl,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: _type == 'CALL' ? l10n.calendarMeetingLink : l10n.calendarLocationHint,
              hintStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(_type == 'CALL' ? Icons.link : Icons.place_outlined, color: colors.textSecondary, size: 20),
              border: InputBorder.none,
            ),
          ),
          if (_type == 'CALL' && _hasMeetingLink()) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyMeetingLink,
                    icon: Icon(Icons.copy_rounded, size: 18, color: colors.primary),
                    label: Text(l10n.chatCopy, style: TextStyle(color: colors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _joinMeeting,
                    icon: const Icon(Icons.videocam_rounded, size: 18, color: Colors.white),
                    label: Text(l10n.joinCall, style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarDateLabel, style: TextStyle(color: colors.textSecondary)),
            trailing: Text(DateFormat('dd.MM.yyyy').format(_startDate), style: TextStyle(color: colors.textPrimary)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: today, lastDate: DateTime(2030));
              if (d != null) setState(() => _startDate = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarTimeLabel, style: TextStyle(color: colors.textSecondary)),
            trailing: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: TextStyle(color: colors.textPrimary)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _startTime);
              if (t != null) {
                setState(() {
                  _startTime = t;
                  // Auto-adjust end time to stay 1h after start if end <= start
                  if (_endTime != null) {
                    final startMin = t.hour * 60 + t.minute;
                    final endMin = _endTime!.hour * 60 + _endTime!.minute;
                    if (endMin <= startMin) {
                      _endTime = TimeOfDay(hour: (t.hour + 1) % 24, minute: t.minute);
                    }
                  }
                });
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarEndTime, style: TextStyle(color: colors.textSecondary)),
            trailing: Text(
              _endTime != null ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}' : '—',
              style: TextStyle(color: colors.textPrimary),
            ),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute));
              if (t != null) setState(() => _endTime = t);
            },
          ),
          // Reminder selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarReminderLabel, style: TextStyle(color: colors.textPrimary)),
            trailing: DropdownButton<int>(
              value: _reminderMinutes,
              dropdownColor: colors.card,
              underline: const SizedBox(),
              style: TextStyle(color: colors.primary, fontSize: 14),
              items: [
                DropdownMenuItem(value: -1, child: Text(l10n.calendarReminderNone)),
                DropdownMenuItem(value: 15, child: Text(l10n.calendarReminder15min)),
                DropdownMenuItem(value: 30, child: Text(l10n.calendarReminder30min)),
                DropdownMenuItem(value: 60, child: Text(l10n.calendarReminder1hour)),
              ],
              onChanged: (v) => setState(() => _reminderMinutes = v ?? -1),
            ),
          ),
          // Recurrence selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarRepeatLabel, style: TextStyle(color: colors.textPrimary)),
            trailing: SizedBox(
              width: 160,
              child: DropdownButton<String>(
                value: _recurrenceFrequency,
                dropdownColor: colors.card,
                underline: const SizedBox(),
                isExpanded: true,
                style: TextStyle(color: colors.primary, fontSize: 14),
                items: [
                  DropdownMenuItem(value: 'none', child: Text(l10n.calendarRepeatNone, style: TextStyle(color: colors.primary))),
                  DropdownMenuItem(value: 'daily', child: Text(l10n.calendarRepeatDaily, style: TextStyle(color: colors.primary))),
                  DropdownMenuItem(value: 'weekly', child: Text(l10n.calendarRepeatWeekly, style: TextStyle(color: colors.primary))),
                  DropdownMenuItem(value: 'monthly', child: Text(l10n.calendarRepeatMonthly, style: TextStyle(color: colors.primary))),
                  DropdownMenuItem(value: 'yearly', child: Text(l10n.calendarRepeatYearly, style: TextStyle(color: colors.primary))),
                ],
                onChanged: isOrganizer ? (v) => setState(() => _recurrenceFrequency = v ?? 'none') : null,
              ),
            ),
          ),
          const Divider(),
          // Participants
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarParticipants, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            trailing: TextButton.icon(
              icon: Icon(Icons.person_add, size: 18, color: colors.primary),
              label: Text(l10n.calendarAddParticipant, style: TextStyle(color: colors.primary, fontSize: 13)),
              onPressed: _showContactPicker,
            ),
          ),
          // RSVP buttons for participant (not organizer)
          if (widget.event != null) ...[
            () {
              final currentUserId = context.read<MessengerBloc>().state.currentUserId;
              final eventUserId = widget.event!['userId'] as String?;
              if (currentUserId == null || currentUserId == eventUserId) return const SizedBox.shrink();
              final invites = (widget.event!['invites'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final myInvite = invites.where((inv) {
                final u = inv['user'] as Map<String, dynamic>? ?? {};
                return u['id'] == currentUserId;
              }).firstOrNull;
              if (myInvite == null) return const SizedBox.shrink();
              final myStatus = myInvite['status'] as String? ?? 'PENDING';
              final inviteId = myInvite['id'] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(l10n.calendarYourAnswer, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    const Spacer(),
                    _RsvpButton(label: l10n.calendarRsvpAccept, icon: Icons.check, color: Colors.green, active: myStatus == 'ACCEPTED', onTap: () async {
                      await CalendarRemoteDataSource(sl<DioClient>()).acceptInvite(inviteId);
                      if (mounted) Navigator.pop(context, true);
                    }),
                    const SizedBox(width: 8),
                    _RsvpButton(label: l10n.calendarRsvpMaybe, icon: Icons.help_outline, color: Colors.orange, active: myStatus == 'MAYBE', onTap: () async {
                      await CalendarRemoteDataSource(sl<DioClient>()).maybeInvite(inviteId);
                      if (mounted) Navigator.pop(context, true);
                    }),
                    const SizedBox(width: 8),
                    _RsvpButton(label: l10n.calendarRsvpDecline, icon: Icons.close, color: colors.error, active: myStatus == 'DECLINED', onTap: () async {
                      await CalendarRemoteDataSource(sl<DioClient>()).declineInvite(inviteId);
                      if (mounted) Navigator.pop(context, true);
                    }),
                  ],
                ),
              );
            }(),
          ],
          // Show organizer for existing events
          if (widget.event != null && widget.event!['user'] != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star, color: Colors.amber, size: 20),
              title: () {
                final ou = widget.event!['user'] as Map<String, dynamic>;
                final op = ou['profile'] as Map<String, dynamic>? ?? {};
                final name = [op['firstName'], op['lastName']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
                return Text(name.isNotEmpty ? name : (ou['username'] as String? ?? '?'),
                    style: TextStyle(color: colors.textPrimary));
              }(),
              subtitle: Text(l10n.calendarOrganizer, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ),
          ],
          if (_selectedContactIds.isNotEmpty)
            ..._selectedContactIds.map((id) {
              final c = _contacts.where((c) => c['userId'] == id).firstOrNull;
              if (c == null) return const SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                  backgroundImage: c['avatar'] != null && (c['avatar'] as String).isNotEmpty ? NetworkImage(c['avatar'] as String) : null,
                  child: c['avatar'] == null || (c['avatar'] as String).isEmpty
                      ? Text((c['name'] as String).isNotEmpty ? (c['name'] as String)[0].toUpperCase() : '?', style: TextStyle(color: colors.primary, fontSize: 14))
                      : null,
                ),
                title: Text(c['name'] as String, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_invitesMap.containsKey(id)) ...[
                      _buildInviteStatus(_invitesMap[id]!, colors, l10n),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                      onPressed: () => setState(() => _selectedContactIds.remove(id)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _RsvpButton({required this.label, required this.icon, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : AppColors.of(context).textSecondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? color : AppColors.of(context).textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? color : AppColors.of(context).textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;
  final List<String> selectedIds;
  final void Function(String) onSelected;
  const _ContactPickerSheet({required this.contacts, required this.selectedIds, required this.onSelected});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final available = widget.contacts
        .where((c) => !widget.selectedIds.contains(c['userId']))
        .where((c) => _query.isEmpty || (c['name'] as String).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.calendarSearchContacts,
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: available.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.calendarNoContacts, style: TextStyle(color: colors.textSecondary)))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: available.length,
                    itemBuilder: (_, i) {
                      final c = available[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.primary.withValues(alpha: 0.15),
                          backgroundImage: c['avatar'] != null && (c['avatar'] as String).isNotEmpty ? NetworkImage(c['avatar'] as String) : null,
                          child: c['avatar'] == null || (c['avatar'] as String).isEmpty
                              ? Text((c['name'] as String).isNotEmpty ? (c['name'] as String)[0].toUpperCase() : '?', style: TextStyle(color: colors.primary))
                              : null,
                        ),
                        title: Text(c['name'] as String, style: TextStyle(color: colors.textPrimary)),
                        onTap: () => widget.onSelected(c['userId'] as String),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
