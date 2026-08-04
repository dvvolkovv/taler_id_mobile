import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../profile/data/datasources/profile_remote_datasource.dart';

/// Список доверенных устройств и тумблер подтверждения входа.
class TrustedDevicesScreen extends StatefulWidget {
  const TrustedDevicesScreen({super.key});

  @override
  State<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends State<TrustedDevicesScreen> {
  bool _loading = true;
  bool _approvalEnabled = false;
  bool _savingToggle = false;
  List<Map<String, dynamic>> _devices = const [];
  String? _error;

  AuthRemoteDataSource get _auth => sl<AuthRemoteDataSource>();
  ProfileRemoteDataSource get _profile => sl<ProfileRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await _auth.listTrustedDevices();
      final profile = await _profile.getProfile();
      if (!mounted) return;
      setState(() {
        _devices = devices
            .map((d) => Map<String, dynamic>.from(d as Map))
            .toList(growable: false);
        _approvalEnabled = profile['newDeviceApproval'] as bool? ?? false;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _setApproval(bool value) async {
    setState(() {
      _approvalEnabled = value;
      _savingToggle = true;
    });
    try {
      await _profile.updateProfile({'newDeviceApproval': value});
      if (mounted) setState(() => _savingToggle = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Возвращаем тумблер в прежнее положение: показывать «включено», когда
      // сервер этого не сохранил, — худший из возможных исходов для настройки
      // безопасности.
      setState(() {
        _approvalEnabled = !value;
        _savingToggle = false;
        _error = e.message;
      });
    }
  }

  Future<void> _revoke(Map<String, dynamic> device) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.trustedDevicesRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.trustedDevicesRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _auth.revokeTrustedDevice(device['id'] as String);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  String _formatWhen(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';
    final d = parsed.toLocal();
    final two = (int i) => i.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.trustedDevicesTitle)),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  SwitchListTile(
                    value: _approvalEnabled,
                    onChanged: _savingToggle ? null : _setApproval,
                    title: Text(
                      l10n.trustedDevicesToggle,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      l10n.trustedDevicesToggleHint,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.error, fontSize: 13),
                      ),
                    ),
                  const Divider(height: 1),
                  if (_devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l10n.trustedDevicesEmpty,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    ),
                  for (final d in _devices)
                    ListTile(
                      leading: Icon(
                        Icons.smartphone,
                        color: d['isCurrent'] == true
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      title: Text(
                        (d['label'] as String?)?.isNotEmpty == true
                            ? d['label'] as String
                            : (d['deviceInfo'] as String? ?? '—'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      subtitle: Text(
                        [
                          if (d['isCurrent'] == true)
                            l10n.trustedDevicesThisDevice,
                          if ((d['lastLocation'] as String?)?.isNotEmpty == true)
                            d['lastLocation'] as String,
                          if ((d['lastIp'] as String?)?.isNotEmpty == true)
                            d['lastIp'] as String,
                          l10n.trustedDevicesLastSeen(
                            _formatWhen(d['lastSeenAt'] as String?),
                          ),
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: d['isCurrent'] == true
                          ? null
                          : IconButton(
                              tooltip: l10n.trustedDevicesRevoke,
                              icon: Icon(Icons.logout, color: colors.error),
                              onPressed: () => _revoke(d),
                            ),
                    ),
                ],
              ),
            ),
    );
  }
}
