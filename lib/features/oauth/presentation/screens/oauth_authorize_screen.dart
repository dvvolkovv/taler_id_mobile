import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/company_consent.dart';
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
            return _buildConsent(context, state.grantInfo, state.selection, busy: true);
          }
          if (state is OAuthConsentRequired) {
            return _buildConsent(context, state.grantInfo, state.selection, busy: false);
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

  Widget _buildConsent(
    BuildContext context,
    GrantInfo grantInfo,
    CompanySelection? selection, {
    required bool busy,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // С блоками выбора компаний содержимое не влезает в экран — оно
          // прокручивается, а кнопки остаются внизу, как раньше со Spacer.
          Expanded(
            child: ListView(
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
                if (selection != null && grantInfo.companies != null)
                  ..._buildCompanies(context, grantInfo.companies!, selection, busy: busy),
              ],
            ),
          ),
          const SizedBox(height: 16),
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

  // Выбор «войти как» и «что передать» (scope companies). Компания из
  // «войти как» передаётся всегда — её галочка отмечена и заблокирована.
  List<Widget> _buildCompanies(
    BuildContext context,
    CompanyConsent companies,
    CompanySelection selection, {
    required bool busy,
  }) {
    final bloc = context.read<OAuthAuthorizeBloc>();
    final title = Theme.of(context).textTheme.titleMedium;
    return [
      const SizedBox(height: 16),
      Text('Войти как', style: title),
      RadioGroup<String>(
        groupValue: selection.actAs,
        onChanged: (v) {
          if (!busy && v != null) bloc.add(ActAsChanged(v));
        },
        child: Column(
          children: [
            RadioListTile<String>(
              value: CompanySelection.person,
              enabled: !busy,
              title: Text(companies.personName.isEmpty ? 'Вы' : companies.personName),
              subtitle: const Text('Физлицо'),
              contentPadding: EdgeInsets.zero,
            ),
            ...companies.eligible.map((c) => RadioListTile<String>(
                  value: c.id,
                  enabled: !busy,
                  title: Text(c.displayName),
                  subtitle: const Text('KYB пройден'),
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('Передать данные компаний', style: title),
      ...companies.eligible.map((c) {
        final locked = selection.actAs == c.id;
        return CheckboxListTile(
          value: locked || selection.companyIds.contains(c.id),
          title: Text(c.displayName),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: busy || locked ? null : (v) => bloc.add(ShareToggled(c.id, v ?? false)),
        );
      }),
      if (companies.unverified.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Не прошли KYB: ${companies.unverified.map((c) => c.name).join(', ')}. '
            'Пройдите проверку компании в разделе «Организации» — тогда её можно будет выбрать.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ];
  }

  Widget _buildFailure(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // «Открыть в браузере» вела на /oauth/authorize, которого нет, а
          // правильный /oauth/auth приложение перехватило бы снова (App Links).
          ElevatedButton(
            onPressed: () => context
                .read<OAuthAuthorizeBloc>()
                .add(LoadGrantInfo(widget.params)),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
