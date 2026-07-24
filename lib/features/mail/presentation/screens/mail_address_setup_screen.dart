import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/platform_utils.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/repositories/i_mail_repository.dart';

class MailAddressSetupScreen extends StatefulWidget {
  const MailAddressSetupScreen({super.key});

  @override
  State<MailAddressSetupScreen> createState() => _MailAddressSetupScreenState();
}

class _MailAddressSetupScreenState extends State<MailAddressSetupScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String? _statusKey; // available | taken | invalid | reserved
  bool _checking = false;
  bool _creating = false;
  String _checkedLocalpart = '';

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _statusKey = null);
    final lp = value.trim().toLowerCase();
    if (lp.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _checking = true);
      try {
        final res = await sl<IMailRepository>().checkAvailability(lp);
        if (!mounted) return;
        setState(() {
          _checkedLocalpart = res.localpart;
          _statusKey = res.available
              ? 'available'
              : (res.reason ?? 'INVALID').toLowerCase();
          _checking = false;
        });
      } catch (_) {
        if (mounted) setState(() => _checking = false);
      }
    });
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      await sl<IMailRepository>().createAccount(_checkedLocalpart);
      await sl<SecureStorageService>().setMailSetupConfirmed();
      if (!mounted) return;
      _goNext();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _statusKey = 'taken';
      });
    }
  }

  Future<void> _later() async {
    await sl<SecureStorageService>().setMailSetupDismissed();
    if (mounted) _goNext();
  }

  void _goNext() {
    context.go(PlatformUtils.instance.isDesktop
        ? RouteConstants.messenger
        : RouteConstants.assistant);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusText = switch (_statusKey) {
      'available' => l10n.mailAddressAvailable,
      'taken' => l10n.mailAddressTaken,
      'reserved' => l10n.mailAddressReserved,
      'invalid' => l10n.mailAddressInvalid,
      _ => null,
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.alternate_email,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(l10n.mailNoAccountTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.mailNoAccountBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: l10n.mailAddressHint,
                  suffixText: '@talerid.io',
                  helperText: statusText,
                  helperStyle: TextStyle(
                    color: _statusKey == 'available'
                        ? Colors.greenAccent
                        : Theme.of(context).colorScheme.error,
                  ),
                  suffixIcon: _checking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    _statusKey == 'available' && !_creating ? _create : null,
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.mailCreateAddress),
              ),
              TextButton(
                  onPressed: _later, child: Text(l10n.mailSetupLater)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
