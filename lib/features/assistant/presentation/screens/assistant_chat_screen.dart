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
import '../../domain/assistant_action.dart';
import '../../tools/assistant_system_prompt.dart';
import '../../tools/assistant_tools_executor.dart';
import '../../tools/assistant_tools_schema.dart';
import '../bloc/assistant_chat_bloc.dart';
import '../widgets/assistant_action_bubble.dart';
import '../widgets/assistant_chat_feed.dart';
import '../widgets/assistant_input_bar.dart';
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
  bool _uploading = false;

  /// agent_task conversation continuity while this screen is alive
  /// (mirrors the voice session's per-session behavior).
  String? _agentConversationId;

  @override
  void initState() {
    super.initState();
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
    _bloc.close();
    super.dispose();
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
                  builder: (context, state) => AssistantChatFeed(
                    messages: state.messages,
                    status: state.status,
                    error: state.error,
                    onActionTap: _onActionTap,
                    onRetry: () =>
                        _bloc.add(const AssistantChatStarted()),
                  ),
                ),
              ),
              BlocBuilder<AssistantChatBloc, AssistantChatState>(
                bloc: _bloc,
                buildWhen: (prev, curr) => prev.status != curr.status,
                builder: (context, state) => AssistantInputBar(
                  enabled: state.status != AssistantChatStatus.sending,
                  onSend: (text) => _bloc.add(AssistantChatTextSent(text)),
                  onAttach: _attachFile,
                  attaching: _uploading,
                  showMic: true,
                  onMic: () => context.push(RouteConstants.assistantSession),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
