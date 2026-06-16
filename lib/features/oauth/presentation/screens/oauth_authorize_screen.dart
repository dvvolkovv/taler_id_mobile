import 'package:flutter/material.dart';
import 'package:taler_id_mobile/core/config/app_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/grant_info.dart';
import '../../domain/entities/oauth_authorize_params.dart';
import '../bloc/oauth_authorize_bloc.dart';
import '../bloc/oauth_authorize_event.dart';
import '../bloc/oauth_authorize_state.dart';

typedef LaunchUrlFn = Future<void> Function(String url);

Future<void> _defaultLaunch(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class OAuthAuthorizeScreen extends StatefulWidget {
  final OAuthAuthorizeParams params;
  final LaunchUrlFn? onLaunchUrl;

  const OAuthAuthorizeScreen({
    super.key,
    required this.params,
    this.onLaunchUrl,
  });

  @override
  State<OAuthAuthorizeScreen> createState() => _OAuthAuthorizeScreenState();
}

class _OAuthAuthorizeScreenState extends State<OAuthAuthorizeScreen> {
  bool _loadDispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loadDispatched) {
        _loadDispatched = true;
        context.read<OAuthAuthorizeBloc>().add(LoadGrantInfo(widget.params));
      }
    });
  }

  Future<void> _handleLaunch(String url) async {
    final fn = widget.onLaunchUrl ?? _defaultLaunch;
    await fn(url);
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход через Taler ID')),
      body: BlocConsumer<OAuthAuthorizeBloc, OAuthAuthorizeState>(
        listener: (context, state) async {
          if (state is OAuthSuccess) {
            await _handleLaunch(state.redirectUri);
          } else if (state is OAuthCancelled) {
            await _handleLaunch(state.redirectUri);
          }
        },
        builder: (context, state) {
          if (state is OAuthLoading || state is OAuthInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OAuthAutoApproving) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OAuthApproving) {
            return _buildConsent(context, state.grantInfo, busy: true);
          }
          if (state is OAuthConsentRequired) {
            return _buildConsent(context, state.grantInfo, busy: false);
          }
          if (state is OAuthFailure) {
            return _buildFailure(context, state.message);
          }
          if (state is OAuthSuccess || state is OAuthCancelled) {
            return const Center(child: CircularProgressIndicator());
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildConsent(BuildContext context, GrantInfo grantInfo, {required bool busy}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (grantInfo.clientLogo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Image.network(
                grantInfo.clientLogo!,
                height: 64,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Text(
            '${grantInfo.clientName} запрашивает доступ',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...grantInfo.scopes.map<Widget>((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(s.label),
                  subtitle: Text(s.description),
                  contentPadding: EdgeInsets.zero,
                ),
              )),
          const Spacer(),
          ElevatedButton(
            onPressed: busy
                ? null
                : () => context.read<OAuthAuthorizeBloc>().add(const ApprovePressed()),
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Разрешить'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy
                ? null
                : () => context.read<OAuthAuthorizeBloc>().add(const CancelPressed()),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailure(BuildContext context, String message) {
    final fallback = Uri.parse('${AppConfig.webUrl}/oauth/authorize').replace(
      queryParameters: widget.params.toQueryParameters(),
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context
                .read<OAuthAuthorizeBloc>()
                .add(LoadGrantInfo(widget.params)),
            child: const Text('Повторить'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _handleLaunch(fallback.toString()),
            child: const Text('Открыть в браузере'),
          ),
        ],
      ),
    );
  }
}
