import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_keys.dart';
import '../../domain/entities/session_entity.dart';
import '../bloc/sessions_bloc.dart';
import '../bloc/sessions_event.dart';
import '../bloc/sessions_state.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SessionsBloc>().add(SessionsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.sessions)),
      body: BlocConsumer<SessionsBloc, SessionsState>(
        listener: (context, state) {
          if (state is SessionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: colors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is SessionsLoading) {
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }
          if (state is SessionsLoaded) {
            if (state.sessions.isEmpty) {
              return Center(child: Text(l10n.noSessions, style: TextStyle(color: colors.textSecondary)));
            }

            final current = state.sessions.where((s) => s.isCurrent).toList();
            final others = state.sessions.where((s) => !s.isCurrent).toList();

            return RefreshIndicator(
              color: colors.primary,
              onRefresh: () async => context.read<SessionsBloc>().add(SessionsLoadRequested()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Current session
                  if (current.isNotEmpty) ...[
                    _sectionLabel('Текущая сессия', colors),
                    const SizedBox(height: 8),
                    _buildSessionCard(context, current.first, l10n, colors),
                    const SizedBox(height: 20),
                  ],
                  // Other sessions
                  if (others.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(child: _sectionLabel('Другие устройства', colors)),
                        TextButton(
                          onPressed: () => _confirmTerminateAll(context, l10n, colors, others),
                          child: Text('Завершить все', style: TextStyle(color: colors.error, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...others.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildSessionCard(context, s, l10n, colors),
                        )),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _sectionLabel(String text, AppColorsExtension colors) => Text(
        text,
        style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      );

  Widget _buildSessionCard(BuildContext context, SessionEntity session, AppLocalizations l10n, AppColorsExtension colors) {
    final icon = _deviceIcon(session.device);
    final iconColor = session.isCurrent ? colors.primary : colors.textSecondary;
    final iconBg = session.isCurrent ? colors.primary.withValues(alpha: 0.12) : colors.surface;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isCurrent ? colors.primary.withValues(alpha: 0.3) : colors.border.withValues(alpha: 0.5),
          width: session.isCurrent ? 1.5 : 1,
        ),
        boxShadow: session.isCurrent
            ? [BoxShadow(color: colors.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 3))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Device icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.device ?? l10n.unknownDevice,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(l10n.currentSessionLabel, style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          [
                            if (session.ip != null) session.ip!,
                            if (session.location != null) session.location!,
                          ].join(' · ').isNotEmpty
                              ? [
                                  if (session.ip != null) session.ip!,
                                  if (session.location != null) session.location!,
                                ].join(' · ')
                              : l10n.ipUnknown,
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 3),
                      Text(_formatDate(session.createdAt, l10n), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (!session.isCurrent) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmTerminate(context, session, l10n, colors),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: colors.error, size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmTerminate(BuildContext context, SessionEntity session, AppLocalizations l10n, AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: colors.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.logout_rounded, color: colors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(l10n.deleteSessionConfirm, style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.deviceLoggedOut, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), side: BorderSide(color: colors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<SessionsBloc>().add(SessionDeleteRequested(session.id));
                    },
                    child: Text(l10n.endSessionAction, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTerminateAll(BuildContext context, AppLocalizations l10n, AppColorsExtension colors, List<SessionEntity> others) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: colors.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.devices_outlined, color: colors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Завершить все сессии', style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Все устройства (${others.length}) будут выйдены из аккаунта', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), side: BorderSide(color: colors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: () {
                      Navigator.pop(ctx);
                      for (final s in others) {
                        context.read<SessionsBloc>().add(SessionDeleteRequested(s.id));
                      }
                    },
                    child: const Text('Завершить все', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(String? device) {
    if (device == null) return Icons.devices_outlined;
    final d = device.toLowerCase();
    if (d.contains('iphone') || d.contains('android') || d.contains('mobile') || d.contains('pixel') || d.contains('samsung') || d.contains('xiaomi')) return Icons.smartphone_rounded;
    if (d.contains('ipad') || d.contains('tablet')) return Icons.tablet_rounded;
    if (d.contains('mac')) return Icons.laptop_mac_rounded;
    if (d.contains('windows')) return Icons.desktop_windows_rounded;
    if (d.contains('linux')) return Icons.computer_rounded;
    return Icons.devices_rounded;
  }

  String _formatDate(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
