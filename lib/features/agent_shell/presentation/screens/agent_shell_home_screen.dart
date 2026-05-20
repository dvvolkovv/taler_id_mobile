import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/agent_shell_bloc.dart';
import '../../../../core/agent/agent_client.dart';
import '../../../notifications/notification_permission_service.dart';

class AgentShellHomeScreen extends StatelessWidget {
  const AgentShellHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgentShellBloc(client: GetIt.I<AgentClient>()),
      child: const _AgentShellScaffold(),
    );
  }
}

class _AgentShellScaffold extends StatefulWidget {
  const _AgentShellScaffold();
  @override
  State<_AgentShellScaffold> createState() => _AgentShellScaffoldState();
}

class _AgentShellScaffoldState extends State<_AgentShellScaffold>
    with WidgetsBindingObserver {
  final TextEditingController _input = TextEditingController();

  /// Looked up lazily — Task 6 registers this in the service locator. The
  /// scaffold tolerates a missing registration so the screen still mounts
  /// in tests or before Task 6 lands.
  NotificationPermissionService? _permissionService;

  /// `null` until the first poll completes; banner is hidden while unknown.
  bool? _accessGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolvePermissionService();
    _pollPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollPermission();
    }
  }

  void _resolvePermissionService() {
    final getIt = GetIt.I;
    if (getIt.isRegistered<NotificationPermissionService>()) {
      _permissionService = getIt<NotificationPermissionService>();
    }
  }

  Future<void> _pollPermission() async {
    final svc = _permissionService;
    if (svc == null) return;
    try {
      final granted = await svc.isGranted();
      if (!mounted) return;
      setState(() => _accessGranted = granted);
    } catch (_) {
      // Platform channel not wired yet (host shell without native side, or
      // tests without method-channel mocks) — leave the banner hidden.
    }
  }

  Future<void> _openNotificationSettings() async {
    final svc = _permissionService;
    if (svc == null) return;
    try {
      await svc.openSettings();
    } catch (_) {
      // Ignore — same rationale as _pollPermission.
    }
  }

  void _submit(BuildContext context) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<AgentShellBloc>().add(AgentShellSubmit(text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taler ID Agent (Phase 0 spike)')),
      body: SafeArea(
        child: Column(
          children: [
            if (_accessGranted == false) _buildPermissionBanner(context),
            Expanded(
              child: BlocBuilder<AgentShellBloc, AgentShellState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Скажи что-нибудь — попробует echo инструмент.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length + (state.busy ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Думаю…'),
                          ),
                        );
                      }
                      final msg = state.messages[i];
                      final isUser = msg.role == 'user';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(msg.text),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<AgentShellBloc, AgentShellState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !state.busy,
                        decoration: const InputDecoration(
                          hintText: 'Echo this...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: state.busy ? null : () => _submit(context),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AgentShellBloc, AgentShellState>(
              builder: (_, s) => s.error != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        s.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Card(
        elevation: 0,
        color: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: scheme.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Чтобы я мог читать сообщения из WhatsApp/Telegram '
                      'и отвечать за тебя — включи доступ к уведомлениям.',
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _openNotificationSettings,
                  child: const Text('Открыть настройки'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
