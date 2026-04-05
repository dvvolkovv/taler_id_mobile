import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/profile_section_entity.dart';
import '../../domain/repositories/i_profile_sections_repository.dart';
import '../bloc/profile_sections_bloc.dart';
import '../bloc/profile_sections_event.dart';
import '../bloc/profile_sections_state.dart';

class ProfileSectionsScreen extends StatelessWidget {
  const ProfileSectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileSectionsBloc(sl<IProfileSectionsRepository>())
        ..add(LoadMySections()),
      child: const _ProfileSectionsView(),
    );
  }
}

class _ProfileSectionsView extends StatelessWidget {
  const _ProfileSectionsView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.aboutMeTitle),
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<ProfileSectionsBloc, ProfileSectionsState>(
        builder: (context, state) {
          if (state is ProfileSectionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sections = state is ProfileSectionsLoaded ? state.sections : <ProfileSectionEntity>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: SectionType.values.map((type) {
              final existing = sections.where((s) => s.type == type).toList();
              final section = existing.isNotEmpty ? existing.first : null;
              return _SectionCard(type: type, section: section);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SectionType type;
  final ProfileSectionEntity? section;

  const _SectionCard({required this.type, this.section});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasContent = section != null && (section!.content.items.isNotEmpty || (section!.content.freeText?.isNotEmpty ?? false));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ProfileSectionsBloc>(),
                  child: _EditSectionScreen(type: type, section: section),
                ),
              ),
            );
            if (result == true && context.mounted) {
              context.read<ProfileSectionsBloc>().add(LoadMySections());
            }
          },
          child: Row(
            children: [
              () {
                final typeColor = colorForType(type);
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(typeColor, Colors.white, 0.15)!,
                        typeColor,
                        Color.lerp(typeColor, Colors.black, 0.25)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withOpacity(0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(iconForType(type), color: Colors.white, size: 22),
                );
              }(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titleForType(type, context),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (section != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            _visibilityIcon(section!.visibility),
                            size: 14,
                            color: colors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasContent
                          ? _previewText(section!)
                          : AppLocalizations.of(context)!.aboutMeClickToFill,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasContent ? colors.textSecondary : colors.textSecondary.withOpacity(0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText(ProfileSectionEntity s) {
    final parts = <String>[];
    if (s.content.items.isNotEmpty) {
      parts.add(s.content.items.take(3).join(', '));
      if (s.content.items.length > 3) parts.add('+${s.content.items.length - 3}');
    }
    if (s.content.freeText?.isNotEmpty ?? false) {
      parts.add(s.content.freeText!);
    }
    return parts.join(' · ');
  }

  static IconData iconForType(SectionType type) {
    switch (type) {
      case SectionType.coreValues: return Icons.diamond_rounded;
      case SectionType.worldview: return Icons.public_rounded;
      case SectionType.skills: return Icons.build_rounded;
      case SectionType.interests: return Icons.interests_rounded;
      case SectionType.desires: return Icons.star_rounded;
      case SectionType.background: return Icons.person_rounded;
      case SectionType.likes: return Icons.thumb_up_alt_rounded;
      case SectionType.dislikes: return Icons.thumb_down_alt_rounded;
    }
  }

  static Color colorForType(SectionType type) {
    switch (type) {
      case SectionType.coreValues: return const Color(0xFF22D3EE); // cyan (diamond)
      case SectionType.worldview: return const Color(0xFF3B82F6); // blue (globe)
      case SectionType.skills: return const Color(0xFFFBBF24); // amber (tools)
      case SectionType.interests: return const Color(0xFFA855F7); // violet
      case SectionType.desires: return const Color(0xFFF59E0B); // gold (star)
      case SectionType.background: return const Color(0xFF10B981); // emerald
      case SectionType.likes: return const Color(0xFF34D399); // green (thumbs up)
      case SectionType.dislikes: return const Color(0xFFFB7185); // rose (thumbs down)
    }
  }

  static String titleForType(SectionType type, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case SectionType.coreValues: return l10n.aboutMeCoreValues;
      case SectionType.worldview: return l10n.aboutMeWorldview;
      case SectionType.skills: return l10n.aboutMeSkills;
      case SectionType.interests: return l10n.aboutMeInterests;
      case SectionType.desires: return l10n.aboutMeDesires;
      case SectionType.background: return l10n.aboutMeBackground;
      case SectionType.likes: return l10n.aboutMeLikes;
      case SectionType.dislikes: return l10n.aboutMeDislikes;
    }
  }

  static IconData _visibilityIcon(SectionVisibility v) {
    switch (v) {
      case SectionVisibility.public_: return Icons.public;
      case SectionVisibility.contacts: return Icons.people_outline;
      case SectionVisibility.private_: return Icons.lock_outline;
    }
  }
}

// ────────────────────────────────────────────
// Edit Section Screen with auto-save + inline voice assistant
// ────────────────────────────────────────────

class _EditSectionScreen extends StatefulWidget {
  final SectionType type;
  final ProfileSectionEntity? section;

  const _EditSectionScreen({required this.type, this.section});

  @override
  State<_EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<_EditSectionScreen> {
  late final TextEditingController _freeTextCtrl;
  late final TextEditingController _tagCtrl;
  late List<String> _items;
  late SectionVisibility _visibility;
  bool _changed = false;
  Timer? _debounce;
  bool _saving = false;
  bool _saved = false;

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
  String? _pendingCallId;
  String? _pendingCallName;
  final StringBuffer _pendingArgs = StringBuffer();
  static const _audioChannel = MethodChannel('taler_id/audio');

  @override
  void initState() {
    super.initState();
    _freeTextCtrl = TextEditingController(text: widget.section?.content.freeText ?? '');
    _tagCtrl = TextEditingController();
    _items = List.from(widget.section?.content.items ?? []);
    _visibility = widget.section?.visibility ?? SectionVisibility.private_;
    _freeTextCtrl.addListener(_onTextChanged);
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
    _debounce?.cancel();
    if (_changed) _saveNow();
    _freeTextCtrl.dispose();
    _tagCtrl.dispose();
    _voiceCleanup();
    _player.dispose();
    super.dispose();
  }

  // ── Auto-save logic ──

  void _onTextChanged() {
    _changed = true;
    _debouncedSave();
  }

  void _debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), _saveNow);
  }

  void _saveImmediate() {
    _changed = true;
    _debounce?.cancel();
    _saveNow();
  }

  void _saveNow() {
    final content = SectionContent(
      items: _items,
      freeText: _freeTextCtrl.text.trim().isEmpty ? null : _freeTextCtrl.text.trim(),
    );
    if (_items.isEmpty && (content.freeText == null || content.freeText!.isEmpty)) {
      return;
    }
    context.read<ProfileSectionsBloc>().add(
      UpsertSection(type: widget.type, content: content, visibility: _visibility),
    );
    _changed = false;
    if (mounted) {
      setState(() { _saving = true; _saved = false; });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() { _saving = false; _saved = true; });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saved = false);
        });
      });
    }
  }

  void _addTag() {
    final text = _tagCtrl.text.trim();
    if (text.isNotEmpty && !_items.contains(text)) {
      setState(() { _items.add(text); _tagCtrl.clear(); });
      _saveImmediate();
    }
  }

  void _removeTag(String item) {
    setState(() => _items.remove(item));
    _saveImmediate();
  }

  void _changeVisibility(SectionVisibility v) {
    setState(() => _visibility = v);
    _saveImmediate();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aboutMeDeleteSection),
        content: Text(l10n.aboutMeDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _changed = false;
      context.read<ProfileSectionsBloc>().add(DeleteSection(widget.type));
      Navigator.of(context).pop(true);
    }
  }

  // ── Voice assistant logic ──

  String get _sectionTypeString {
    switch (widget.type) {
      case SectionType.coreValues: return 'VALUES';
      case SectionType.worldview: return 'WORLDVIEW';
      case SectionType.skills: return 'SKILLS';
      case SectionType.interests: return 'INTERESTS';
      case SectionType.desires: return 'DESIRES';
      case SectionType.background: return 'BACKGROUND';
      case SectionType.likes: return 'LIKES';
      case SectionType.dislikes: return 'DISLIKES';
    }
  }

  Future<void> _startVoice() async {
    setState(() => _voiceConnecting = true);
    try {
      final token = await sl<SecureStorageService>().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      final wsUrl = Uri(
        scheme: 'wss',
        host: Uri.parse(ApiConstants.baseUrl).host,
        path: '/voice/realtime-proxy',
        queryParameters: {'token': token},
      ).toString();
      _ws = await WebSocket.connect(wsUrl);

      _ws!.listen(
        (data) => _onVoiceMessage(data as String),
        onDone: () { if (mounted && _voiceActive) _stopVoice(); },
        onError: (_) { if (mounted) _stopVoice(); },
      );

      _sessionConfigured = false;
      _configureVoiceSession();

      try { await _audioChannel.invokeMethod('setSpeaker', true); } catch (_) {}

      const config = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 24000, numChannels: 1);
      final stream = await _recorder.startStream(config);
      _recordSub = stream.listen((chunk) {
        if (_ws == null) return;
        _ws!.add(jsonEncode({'type': 'input_audio_buffer.append', 'audio': base64Encode(chunk)}));
      });

      setState(() { _voiceActive = true; _voiceConnecting = false; });
    } catch (e) {
      await _voiceCleanup();
      setState(() => _voiceConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.aboutMeConnectionError(e.toString()))),
        );
      }
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

  void _configureVoiceSession() {
    if (_sessionConfigured) return;
    _sessionConfigured = true;

    final sectionTitle = _SectionCard.titleForType(widget.type, context);
    final currentItems = _items.join(', ');
    final currentText = _freeTextCtrl.text.trim();

    _ws!.add(jsonEncode({
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': Localizations.localeOf(context).languageCode == 'ru'
            ? 'Ты — голосовой ассистент Taler ID, помогающий заполнить раздел "$sectionTitle" в профиле пользователя. '
              'Говори только на русском языке. Будь кратким. '
              'Текущее содержимое раздела: теги: [$currentItems], описание: "${currentText.isEmpty ? "пусто" : currentText}". '
              'Начни разговор первым — поприветствуй и спроси о содержимом этого раздела, предложи помощь. '
              'Задавай пользователю уточняющие вопросы, чтобы лучше понять и заполнить этот раздел. '
              'Когда узнаешь что-то новое — сразу вызывай upsert_section чтобы сохранить. '
              'Объединяй новые теги с существующими, не заменяй.'
            : 'You are a Taler ID voice assistant helping fill the "$sectionTitle" section of the user\'s profile. '
              'Speak in the same language as the user. Be concise. '
              'Current section content: tags: [$currentItems], description: "${currentText.isEmpty ? "empty" : currentText}". '
              'Start the conversation — greet and ask about this section\'s content, offer help. '
              'Ask clarifying questions to better understand and fill this section. '
              'When you learn something new — immediately call upsert_section to save. '
              'Merge new tags with existing ones, don\'t replace.',
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
            'name': 'upsert_section',
            'description':
                'Save/update the current section "$sectionTitle" (type: $_sectionTypeString). '
                'Merge new items with existing, don\'t replace.',
            'parameters': {
              'type': 'object',
              'properties': {
                'items': {'type': 'array', 'items': {'type': 'string'}},
                'freeText': {'type': 'string'},
              },
            },
          },
        ],
        'tool_choice': 'auto',
      },
    }));

    // Make AI speak first — greet and start helping with this section
    _ws!.add(jsonEncode({'type': 'response.create'}));
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
        _playVoiceAudio();
      } else if (type == 'response.done') {
        if (_audioBuffer.isNotEmpty) _playVoiceAudio();
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
        _handleVoiceFunctionCall(callId, name, args);
      }
    } catch (_) {}
  }

  Future<void> _handleVoiceFunctionCall(String callId, String name, String argsJson) async {
    String output;
    try {
      if (name == 'upsert_section') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final newItems = (args['items'] as List<dynamic>?)?.cast<String>() ?? [];
        final newText = args['freeText'] as String?;

        // Merge items locally
        for (final item in newItems) {
          if (!_items.contains(item)) _items.add(item);
        }
        if (newText != null && newText.isNotEmpty) {
          final current = _freeTextCtrl.text.trim();
          if (current.isEmpty) {
            _freeTextCtrl.text = newText;
          } else if (!current.contains(newText)) {
            _freeTextCtrl.text = '$current\n$newText';
          }
        }

        // Save via API
        final client = sl<DioClient>();
        final data = await client.put<Map<String, dynamic>>(
          '/profile-sections',
          data: {
            'type': _sectionTypeString,
            'content': {
              'items': _items,
              if (_freeTextCtrl.text.trim().isNotEmpty) 'freeText': _freeTextCtrl.text.trim(),
            },
            'visibility': _visibilityToString(_visibility),
          },
          fromJson: (d) => d as Map<String, dynamic>,
        );
        output = jsonEncode(data);
        _changed = false;
        if (mounted) setState(() {});
      } else {
        output = jsonEncode({'error': 'unknown function $name'});
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

  String _visibilityToString(SectionVisibility v) {
    switch (v) {
      case SectionVisibility.public_: return 'PUBLIC';
      case SectionVisibility.contacts: return 'CONTACTS';
      case SectionVisibility.private_: return 'PRIVATE';
    }
  }

  Future<void> _playVoiceAudio() async {
    if (_audioBuffer.isEmpty) return;
    final pcm = Uint8List.fromList(_audioBuffer);
    _audioBuffer.clear();
    final wav = _buildWav(pcm, sampleRate: 24000, channels: 1);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/section_ai.wav');
      await file.writeAsBytes(wav);
      await _player.play(DeviceFileSource(file.path));
    } catch (_) {}
    if (mounted) setState(() => _aiSpeaking = true);
  }

  Uint8List _buildWav(Uint8List pcm, {required int sampleRate, required int channels}) {
    final dataSize = pcm.length;
    final buf = ByteData(44 + dataSize);
    final byteRate = sampleRate * channels * 2;
    buf.setUint32(0, 0x52494646, Endian.big);
    buf.setUint32(4, 36 + dataSize, Endian.little);
    buf.setUint32(8, 0x57415645, Endian.big);
    buf.setUint32(12, 0x666D7420, Endian.big);
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little);
    buf.setUint16(22, channels, Endian.little);
    buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, byteRate, Endian.little);
    buf.setUint16(32, channels * 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    buf.setUint32(36, 0x64617461, Endian.big);
    buf.setUint32(40, dataSize, Endian.little);
    final result = buf.buffer.asUint8List();
    result.setRange(44, 44 + dataSize, pcm);
    return result;
  }

  Future<void> _stopVoice() async {
    await _voiceCleanup();
    try { await _audioChannel.invokeMethod('setSpeaker', false); } catch (_) {}
    await _player.stop();
    if (mounted) {
      setState(() { _voiceActive = false; _aiSpeaking = false; _voiceConnecting = false; });
      // Reload sections to reflect AI changes
      context.read<ProfileSectionsBloc>().add(LoadMySections());
    }
  }

  Future<void> _voiceCleanup() async {
    _sessionConfigured = false;
    _audioBuffer.clear();
    await _recordSub?.cancel();
    _recordSub = null;
    try { await _recorder.stop(); } catch (_) {}
    await _ws?.close();
    _ws = null;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final sectionColor = _SectionCard.colorForType(widget.type);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (_voiceActive) _stopVoice();
          if (_changed) { _debounce?.cancel(); _saveNow(); }
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: [
                sectionColor,
                Color.lerp(sectionColor, Colors.white, 0.4)!,
              ],
            ).createShader(rect),
            child: Text(
              _SectionCard.titleForType(widget.type, context),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_saved)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.check, color: colors.primary, size: 20),
              ),
            if (widget.section != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _delete,
              ),
          ],
        ),
        floatingActionButton: _voiceConnecting
            ? FloatingActionButton(
                onPressed: null,
                backgroundColor: colors.card,
                child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : () {
                final sectionColor = _SectionCard.colorForType(widget.type);
                final gradient = _voiceActive
                    ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                    : [sectionColor, Color.lerp(sectionColor, Colors.black, 0.3)!];
                return GestureDetector(
                  onTap: _voiceActive ? _stopVoice : _startVoice,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _voiceActive ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                );
              }(),
        body: Column(
          children: [
            // Voice status bar
            if (_voiceActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      sectionColor.withOpacity(_aiSpeaking ? 0.25 : 0.08),
                      sectionColor.withOpacity(_aiSpeaking ? 0.08 : 0.02),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _aiSpeaking ? Icons.volume_up_rounded : Icons.hearing_rounded,
                      size: 18,
                      color: _aiSpeaking ? sectionColor : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _aiSpeaking ? 'Ассистент говорит...' : 'Слушаю...',
                      style: TextStyle(
                        fontSize: 13,
                        color: _aiSpeaking ? sectionColor : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Visibility selector
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.aboutMeVisibility, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        const SizedBox(height: 10),
                        Row(
                          children: SectionVisibility.values.map((v) {
                            final selected = v == _visibility;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: v != SectionVisibility.private_ ? 8 : 0),
                                child: GestureDetector(
                                  onTap: () => _changeVisibility(v),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: selected
                                          ? LinearGradient(
                                              colors: [
                                                sectionColor.withOpacity(0.25),
                                                sectionColor.withOpacity(0.08),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: selected ? null : colors.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected ? sectionColor : colors.textSecondary.withOpacity(0.2),
                                        width: selected ? 1.5 : 1,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: sectionColor.withOpacity(0.3),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          _SectionCard._visibilityIcon(v),
                                          size: 20,
                                          color: selected ? sectionColor : colors.textSecondary,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _visibilityLabel(v),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: selected ? sectionColor : colors.textSecondary,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tags
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.aboutMeTags, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._items.map((item) => Chip(
                              label: Text(
                                item,
                                style: TextStyle(fontSize: 13, color: sectionColor, fontWeight: FontWeight.w600),
                              ),
                              deleteIcon: Icon(Icons.close_rounded, size: 16, color: sectionColor.withOpacity(0.7)),
                              onDeleted: () => _removeTag(item),
                              backgroundColor: sectionColor.withOpacity(0.12),
                              side: BorderSide(color: sectionColor.withOpacity(0.35)),
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tagCtrl,
                                style: TextStyle(color: colors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.aboutMeAddTag,
                                  hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onSubmitted: (_) => _addTag(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _addTag,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      sectionColor,
                                      Color.lerp(sectionColor, Colors.black, 0.25)!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: sectionColor.withOpacity(0.45),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Free text
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.aboutMeDescription, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _freeTextCtrl,
                          style: TextStyle(color: colors.textPrimary),
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.aboutMeDescribeLong,
                            hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _visibilityLabel(SectionVisibility v) {
    final l10n = AppLocalizations.of(context)!;
    switch (v) {
      case SectionVisibility.public_: return l10n.aboutMeVisibilityEveryone;
      case SectionVisibility.contacts: return l10n.aboutMeVisibilityContacts;
      case SectionVisibility.private_: return l10n.aboutMeVisibilityOnlyMe;
    }
  }
}
