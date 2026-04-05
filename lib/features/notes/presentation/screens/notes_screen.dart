import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/simple_list_cache.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart' show rainbowColorFor;
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/notes_remote_datasource.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _cache = sl<SimpleListCache>(instanceName: 'notes');
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  // Voice assistant state
  bool _voiceActive = false;
  bool _voiceConnecting = false;
  bool _aiSpeaking = false;
  WebSocket? _ws;
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;
  final _player = AudioPlayer();
  final List<int> _audioBuffer = [];
  bool _sessionConfigured = false;
  static const _audioChannel = MethodChannel('taler_id/audio');

  @override
  void initState() {
    super.initState();
    // Hydrate from cache instantly, then refresh.
    final cached = _cache.get();
    if (cached != null && cached.isNotEmpty) {
      _notes = cached;
      _loading = false;
    }
    _load();
    _player.onPlayerComplete.listen((_) async {
      if (mounted) setState(() => _aiSpeaking = false);
      if (_ws != null && _voiceActive) {
        await _recordSub?.cancel();
        _recordSub = null;
        try { await _recorder.stop(); } catch (_) {}
        await _restartRecording();
      }
    });
  }

  @override
  void dispose() {
    _voiceCleanup();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_notes.isEmpty) setState(() => _loading = true);
    try {
      final fresh = await NotesRemoteDataSource(sl<DioClient>()).getAll();
      _notes = fresh;
      _cache.save(fresh); // fire-and-forget persist
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteNote(String id) async {
    try {
      await NotesRemoteDataSource(sl<DioClient>()).delete(id);
      _notes.removeWhere((n) => n['id'] == id);
      _cache.remove(id);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _openEditor({Map<String, dynamic>? note}) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _NoteEditScreen(note: note)));
    if (result == true) _load();
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

      _sessionConfigured = false;
      _ws!.add(jsonEncode({
        'type': 'session.update',
        'session': {
          'modalities': ['text', 'audio'],
          'instructions': Localizations.localeOf(context).languageCode == 'ru'
              ? 'ВСЕГДА отвечай ТОЛЬКО на русском языке, даже если тебе показалось, что пользователь сказал что-то на другом языке — это ошибка транскрипции, всё равно отвечай по-русски.\n\n'
                'Ты — помощник для записи заметок и управления календарём. Пользователь будет диктовать мысли или ставить встречи. '
                'Для заметок: внимательно выслушай, сформулируй краткий заголовок (title) и подробное содержание (content), '
                'сохрани через create_note. Подтверди голосом что заметка сохранена. '
                'Если пользователь спрашивает "какие у меня заметки", "прочитай мои заметки", "что я записал" — вызови get_notes и перескажи. '
                'Если просит резюме или обзор заметок — вызови get_notes, проанализируй и дай краткое резюме. '
                'Для календаря: если пользователь говорит "напомни", "поставь встречу", "запланируй" — '
                'уточни дату/время и создай через create_event. '
                'Часовой пояс: ${DateTime.now().timeZoneName} (UTC${DateTime.now().timeZoneOffset.isNegative ? "" : "+"}${DateTime.now().timeZoneOffset.inHours}). '
                'Текущая дата: ${DateTime.now().toIso8601String()}. '
                'Начни с: "Слушаю, какую заметку хотите записать?"'
              : 'ALWAYS reply ONLY in English, even if you think the user said something in another language — that is a transcription error, reply in English anyway.\n\n'
                'You are an assistant for taking notes and managing the calendar. The user will dictate thoughts or schedule meetings. '
                'For notes: listen carefully, formulate a brief title and detailed content, save via create_note. Confirm by voice that the note is saved. '
                'If user asks "what notes do I have", "read my notes", "what did I write down" — call get_notes and summarize. '
                'If asks for notes overview or summary — call get_notes, analyze and give a brief summary. '
                'For calendar: if user says "remind me", "schedule a meeting", "plan" — clarify date/time and create via create_event. '
                'Timezone: ${DateTime.now().timeZoneName} (UTC${DateTime.now().timeZoneOffset.isNegative ? "" : "+"}${DateTime.now().timeZoneOffset.inHours}). '
                'Current date: ${DateTime.now().toIso8601String()}. '
                'Start with: "Listening, what note would you like to record?"',
          'voice': 'alloy',
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'input_audio_transcription': {'model': 'whisper-1', 'language': Localizations.localeOf(context).languageCode},
          'turn_detection': {'type': 'server_vad', 'threshold': 0.5, 'prefix_padding_ms': 300, 'silence_duration_ms': 700},
          'tools': [
            {
              'type': 'function',
              'name': 'create_note',
              'description': 'Save a note.',
              'parameters': {
                'type': 'object',
                'properties': {'title': {'type': 'string'}, 'content': {'type': 'string'}},
                'required': ['title', 'content'],
              },
            },
            {
              'type': 'function',
              'name': 'get_notes',
              'description': 'Read all notes the user has saved, with their title, content, and creation date. Use when the user asks what notes they have or wants a summary.',
              'parameters': {'type': 'object', 'properties': {}},
            },
            {
              'type': 'function',
              'name': 'create_event',
              'description': 'Create a calendar event, reminder, or meeting.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'title': {'type': 'string'},
                  'description': {'type': 'string'},
                  'type': {'type': 'string', 'enum': ['CALL', 'EVENT', 'REMINDER']},
                  'startAt': {'type': 'string', 'description': 'ISO datetime'},
                  'reminderAt': {'type': 'string', 'description': 'When to send push reminder (ISO datetime)'},
                },
                'required': ['title', 'type', 'startAt'],
              },
            },
            {
              'type': 'function',
              'name': 'get_events',
              'description': 'Get upcoming calendar events.',
              'parameters': {'type': 'object', 'properties': {}},
            },
          ],
          'tool_choice': 'auto',
        },
      }));
      _sessionConfigured = true;

      try { await _audioChannel.invokeMethod('setSpeaker', true); } catch (_) {}
      const config = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 24000, numChannels: 1);
      final stream = await _recorder.startStream(config);
      _recordSub = stream.listen((chunk) {
        if (_ws == null) return;
        _ws!.add(jsonEncode({'type': 'input_audio_buffer.append', 'audio': base64Encode(chunk)}));
      });

      setState(() { _voiceActive = true; _voiceConnecting = false; });
      // Trigger greeting
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
    _recordSub = stream.listen((chunk) {
      if (_ws == null) return;
      _ws!.add(jsonEncode({'type': 'input_audio_buffer.append', 'audio': base64Encode(chunk)}));
    });
  }

  Future<void> _stopVoice() async {
    await _player.stop(); // Stop audio immediately
    await _voiceCleanup();
    try { await _audioChannel.invokeMethod('setSpeaker', false); } catch (_) {}
    if (mounted) setState(() { _voiceActive = false; _aiSpeaking = false; });
    _load(); // Refresh notes after voice session
  }

  Future<void> _voiceCleanup() async {
    _sessionConfigured = false;
    _audioBuffer.clear();
    await _recordSub?.cancel();
    _recordSub = null;
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
        if (delta.isNotEmpty) {
          _audioBuffer.addAll(base64Decode(delta));
          if (mounted && !_aiSpeaking) setState(() => _aiSpeaking = true);
        }
      } else if (type == 'response.audio.done') {
        _playAudioBuffer();
      } else if (type == 'response.function_call_arguments.done') {
        final name = event['name'] as String? ?? '';
        final argsJson = event['arguments'] as String? ?? '{}';
        final callId = event['call_id'] as String? ?? '';
        _handleVoiceTool(name, argsJson, callId);
      }
    } catch (_) {}
  }

  Future<void> _playAudioBuffer() async {
    if (_audioBuffer.isEmpty) return;
    final header = _buildWavHeader(_audioBuffer.length, 24000, 1, 16);
    final wav = Uint8List.fromList([...header, ..._audioBuffer]);
    _audioBuffer.clear();
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notes_ai.wav');
      await file.writeAsBytes(wav);
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('[Notes] playback error: $e');
    }
    if (mounted) setState(() => _aiSpeaking = true);
  }

  Uint8List _buildWavHeader(int dataSize, int sampleRate, int channels, int bitsPerSample) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final buf = ByteData(44);
    void writeStr(int o, String s) { for (var i = 0; i < s.length; i++) buf.setUint8(o + i, s.codeUnitAt(i)); }
    writeStr(0, 'RIFF'); buf.setUint32(4, 36 + dataSize, Endian.little);
    writeStr(8, 'WAVE'); writeStr(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little); buf.setUint16(20, 1, Endian.little);
    buf.setUint16(22, channels, Endian.little); buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, byteRate, Endian.little); buf.setUint16(32, blockAlign, Endian.little);
    buf.setUint16(34, bitsPerSample, Endian.little); writeStr(36, 'data');
    buf.setUint32(40, dataSize, Endian.little);
    return buf.buffer.asUint8List();
  }

  Future<void> _handleVoiceTool(String name, String argsJson, String callId) async {
    String output;
    try {
      if (name == 'create_note') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        await sl<DioClient>().post('/notes', data: {'title': args['title'], 'content': args['content'], 'source': 'ASSISTANT'}, fromJson: (d) => d);
        _load(); // Refresh list immediately
        output = jsonEncode({'ok': true});
      } else if (name == 'get_notes') {
        final data = await sl<DioClient>().get<dynamic>('/notes');
        output = jsonEncode(data);
      } else if (name == 'create_event') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        String startUtc = args['startAt'] as String? ?? '';
        if (startUtc.isNotEmpty && !startUtc.endsWith('Z')) {
          final l = DateTime.tryParse(startUtc);
          if (l != null) startUtc = l.toUtc().toIso8601String();
        }
        String? remUtc;
        if (args['reminderAt'] != null) {
          final r = DateTime.tryParse(args['reminderAt'] as String);
          if (r != null) remUtc = r.toUtc().toIso8601String();
        }
        final data = await sl<DioClient>().post('/calendar', data: {
          'title': args['title'], 'description': args['description'], 'type': args['type'],
          'startAt': startUtc, if (remUtc != null) 'reminderAt': remUtc,
          'createdBy': 'ASSISTANT',
        }, fromJson: (d) => d);
        output = jsonEncode(data);
      } else if (name == 'get_events') {
        final data = await sl<DioClient>().get<dynamic>('/calendar?from=${DateTime.now().toIso8601String()}&to=${DateTime.now().add(const Duration(days: 30)).toIso8601String()}');
        output = jsonEncode(data);
      } else {
        output = jsonEncode({'error': 'unknown function'});
      }
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }
    _ws?.add(jsonEncode({
      'type': 'conversation.item.create',
      'item': {'type': 'function_call_output', 'call_id': callId, 'output': output},
    }));
    _ws?.add(jsonEncode({'type': 'response.create'}));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(centerTitle: true, title: Text(l10n.notesTitle)),
      floatingActionButton: _voiceConnecting
          ? FloatingActionButton(onPressed: null, backgroundColor: colors.card, child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GradientFab(
                  heroTag: 'voice',
                  onPressed: _voiceActive ? _stopVoice : _startVoice,
                  icon: _voiceActive ? Icons.stop_rounded : Icons.mic_rounded,
                  gradient: _voiceActive
                      ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                      : const [Color(0xFF22D3EE), Color(0xFFA855F7)],
                ),
                const SizedBox(height: 10),
                _GradientFab(
                  heroTag: 'add',
                  onPressed: () => _openEditor(),
                  icon: Icons.add_rounded,
                  gradient: const [Color(0xFFFB7185), Color(0xFFA855F7)],
                  small: true,
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
                  Text(_aiSpeaking ? l10n.notesAssistantSpeaking : l10n.notesListening, style: TextStyle(fontSize: 13, color: _aiSpeaking ? colors.primary : colors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                : _notes.isEmpty
                    ? EmptyStateView(
                        icon: Icons.sticky_note_2_rounded,
                        title: l10n.notesEmpty,
                        subtitle: l10n.notesEmptyHint,
                        gradient: const [Color(0xFFFB7185), Color(0xFFA855F7)],
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: colors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notes.length,
                          itemBuilder: (context, i) => _buildNoteCard(_notes[i], colors),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, AppColorsExtension colors) {
    final date = DateTime.tryParse(note['createdAt'] as String? ?? '');
    final dateStr = date != null ? DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal()) : '';
    final source = note['source'] as String? ?? 'MANUAL';
    final title = note['title'] as String? ?? '';
    final accentColor = rainbowColorFor(title.isNotEmpty ? title : (note['id'] as String? ?? 'note'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Color.lerp(colors.card, accentColor, 0.06)!,
            colors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openEditor(note: note),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (source == 'ASSISTANT')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22D3EE).withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.headset_mic_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    Expanded(child: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600), softWrap: true)),
                    IconButton(icon: Icon(Icons.delete_outline, size: 18, color: colors.textSecondary), onPressed: () => _confirmDelete(note['id'] as String), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
                const SizedBox(height: 6),
                Text(note['content'] as String? ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(dateStr, style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(l10n.notesDeleteConfirm, style: TextStyle(color: colors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary))),
          TextButton(onPressed: () { Navigator.pop(ctx); _deleteNote(id); }, child: Text(l10n.delete, style: TextStyle(color: colors.error))),
        ],
      ),
    );
  }
}

class _NoteEditScreen extends StatefulWidget {
  final Map<String, dynamic>? note;
  const _NoteEditScreen({this.note});
  @override
  State<_NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<_NoteEditScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?['title'] as String? ?? '');
    _contentCtrl = TextEditingController(text: widget.note?['content'] as String? ?? '');
  }

  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final ds = NotesRemoteDataSource(sl<DioClient>());
      if (widget.note != null) {
        await ds.update(widget.note!['id'] as String, title: _titleCtrl.text.trim(), content: _contentCtrl.text.trim());
      } else {
        await ds.create(title: _titleCtrl.text.trim(), content: _contentCtrl.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    final accent = rainbowColorFor(
      title.isNotEmpty
          ? title
          : (widget.note?['id'] as String? ?? 'note-new'),
    );
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.note == null ? l10n.notesNew : l10n.notesEdit),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
                : Text(l10n.save, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top accent strip — color encodes the note's identity
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  Color.lerp(accent, Colors.white, 0.3)!,
                  accent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(hintText: l10n.notesTitleHint, hintStyle: TextStyle(color: colors.textSecondary), border: InputBorder.none),
            ),
            const SizedBox(height: 6),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.0),
                    accent.withValues(alpha: 0.45),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                style: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(hintText: l10n.notesContentHint, hintStyle: TextStyle(color: colors.textSecondary), border: InputBorder.none),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FloatingActionButton with a gradient fill and matching colored glow.
class _GradientFab extends StatelessWidget {
  final Object heroTag;
  final VoidCallback onPressed;
  final IconData icon;
  final List<Color> gradient;
  final bool small;

  const _GradientFab({
    required this.heroTag,
    required this.onPressed,
    required this.icon,
    required this.gradient,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 44.0 : 56.0;
    return GestureDetector(
      onTap: onPressed,
      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.5),
                  blurRadius: small ? 12 : 18,
                  spreadRadius: small ? 0 : 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: small ? 20 : 26),
          ),
        ),
      ),
    );
  }
}
