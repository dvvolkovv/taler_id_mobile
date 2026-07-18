import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../../../main.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/domain/entities/message_entity.dart';
import '../../data/assistant_chat_api.dart';
import '../../data/assistant_draft_storage.dart';
import '../../domain/assistant_action.dart';
import '../../tools/assistant_system_prompt.dart';
import '../../tools/assistant_tools_executor.dart';
import '../../tools/assistant_tools_schema.dart';
import '../bloc/assistant_chat_bloc.dart';
import '../widgets/assistant_action_bubble.dart';
import '../widgets/assistant_chat_message_row.dart';
import '../widgets/assistant_nav_bar.dart';

/// Text chat with the assistant: persisted history, text turns with tool
/// calls, draft persistence, file attach and a mic shortcut into the voice
/// session screen.
class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  late final AssistantChatBloc _bloc;
  late final TextEditingController _ctrl;
  Timer? _draftTimer;
  bool _uploading = false;

  /// agent_task conversation continuity while this screen is alive
  /// (mirrors the voice session's per-session behavior).
  String? _agentConversationId;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: sl<AssistantDraftStorage>().read() ?? '');
    _bloc = AssistantChatBloc(
      api: sl<AssistantChatApi>(),
      executor: AssistantToolsExecutor(
        hooks: AssistantSessionHooks(
          // Text mode: no live voice session to end.
          endSession: () async => 'No active voice session.',
          // Executor already persists the name via PUT /profile; no screen
          // state to update in text mode.
          onPreferredNameChanged: (_) {},
          applyTheme: (theme) {
            if (!mounted) return;
            final mode = switch (theme) {
              'dark' => ThemeMode.dark,
              'system' => ThemeMode.system,
              _ => ThemeMode.light,
            };
            TalerIdApp.setThemeMode(context, mode);
          },
          applyLanguage: (lang) {
            if (mounted) TalerIdApp.setLocale(context, Locale(lang));
          },
          localeCode: () =>
              mounted ? Localizations.localeOf(context).languageCode : 'ru',
          getAgentConversationId: () => _agentConversationId,
          setAgentConversationId: (id) => _agentConversationId = id,
        ),
      ),
      messageStream: sl<MessengerRemoteDataSource>().messageStream,
      loadHistory: _loadHistory,
      instructions: () => assistantSystemPrompt(
        locale: mounted ? Localizations.localeOf(context).languageCode : 'ru',
        preferredName: null,
        nameFromProfile: false,
      ),
      toolSchemas: assistantToolSchemasForCompletions,
    )..add(const AssistantChatStarted());
  }

  /// Same response shape + mapping as MessengerBloc._onLoadMessages:
  /// `messages` list (newest first) → MessageEntity.fromJson → reversed
  /// to chronological (oldest first).
  Future<List<MessageEntity>> _loadHistory(String conversationId) async {
    final result =
        await sl<MessengerRemoteDataSource>().getMessages(conversationId);
    final raw = result['messages'] as List? ?? [];
    return raw
        .map((e) => MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
        .reversed
        .toList();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _ctrl.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onChanged(String text) {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500),
        () => sl<AssistantDraftStorage>().save(text));
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _bloc.state.status == AssistantChatStatus.sending) {
      return;
    }
    _bloc.add(AssistantChatTextSent(text));
    _ctrl.clear();
    _draftTimer?.cancel();
    sl<AssistantDraftStorage>().clear();
  }

  Future<void> _attachFile() async {
    final convId = _bloc.state.conversationId;
    if (convId == null || _uploading) return;
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.any);
    } catch (_) {
      // ignore picker errors (same as messenger)
    }
    final picked = result?.files.firstOrNull;
    if (picked == null || picked.path == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final formData = FormData.fromMap({
        'file':
            await MultipartFile.fromFile(picked.path!, filename: picked.name),
      });
      final res = await sl<DioClient>().uploadFile<Map<String, dynamic>>(
        '/messenger/files',
        formData: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final fileName = res['fileName'] as String? ?? picked.name;
      // Persisted message appears in the thread via the socket new_message.
      sl<MessengerRemoteDataSource>().sendMessage(
        convId,
        fileName,
        fileUrl: res['fileUrl'] as String?,
        fileName: fileName,
        fileSize: res['fileSize'] as int?,
        fileType: res['fileType'] as String?,
        s3Key: res['s3Key'] as String?,
        thumbnailSmallUrl: res['thumbnailSmallUrl'] as String?,
        thumbnailMediumUrl: res['thumbnailMediumUrl'] as String?,
        thumbnailLargeUrl: res['thumbnailLargeUrl'] as String?,
        fileRecordId: res['fileRecordId'] as String?,
      );
      _bloc.add(AssistantChatTextSent(
          'Я прикрепил файл «$fileName». Учти его в контексте диалога; '
          'если нужен анализ — передай аналитику.'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.assistantError)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _onActionTap(AssistantAction action) async {
    final ok = await navigateToAssistantAction(context, action);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.assistantActionUnavailable),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Compact section navigation (orbital nav port) — pinned above
              // the feed, does not scroll away with messages.
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: const AssistantNavBar(),
              ),
              Expanded(
                child: BlocConsumer<AssistantChatBloc, AssistantChatState>(
                  listenWhen: (prev, curr) =>
                      curr.status == AssistantChatStatus.error &&
                      prev.status != AssistantChatStatus.error,
                  listener: (context, state) {
                    final msg = state.error == 'tool_loop_limit'
                        ? l10n.assistantToolLoopError
                        : l10n.assistantError;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  },
                  builder: (context, state) {
                    if (state.status == AssistantChatStatus.initial ||
                        state.status == AssistantChatStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.messages.isEmpty &&
                        state.status == AssistantChatStatus.error) {
                      // History never loaded — offer retry instead of a blank list.
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.assistantError,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => context
                                  .read<AssistantChatBloc>()
                                  .add(const AssistantChatStarted()),
                              child: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.messages.isEmpty &&
                        state.status == AssistantChatStatus.ready) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.assistantEmptyHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }
                    final sending =
                        state.status == AssistantChatStatus.sending;
                    final messages = state.messages;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length + (sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (sending && index == 0) {
                          return _TypingRow(text: l10n.assistantTyping);
                        }
                        final i = index - (sending ? 1 : 0);
                        final message = messages[messages.length - 1 - i];
                        return AssistantChatMessageRow(
                          message: message,
                          onActionTap: _onActionTap,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _uploading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _attachFile,
                  icon: const Icon(Icons.attach_file),
                  tooltip: l10n.assistantAttachFile,
                ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.assistantChatHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push(RouteConstants.assistantSession),
            icon: const Icon(Icons.mic_none),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (context, value, _) =>
                BlocBuilder<AssistantChatBloc, AssistantChatState>(
              bloc: _bloc,
              builder: (context, state) {
                final enabled = value.text.trim().isNotEmpty &&
                    state.status != AssistantChatStatus.sending;
                return IconButton(
                  onPressed: enabled ? _send : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color: enabled
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
