import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
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
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(l10n.sessions)),
      body: BlocConsumer<SessionsBloc, SessionsState>(
        listener: (context, state) {
          if (state is SessionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: AppColors.of(context).error),
            );
          }
        },
        builder: (context, state) {
          if (state is SessionsLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.of(context).primary));
          }

          if (state is SessionsLoaded) {
            if (state.sessions.isEmpty) {
              return Center(
                child: Text(l10n.noSessions, style: TextStyle(color: AppColors.of(context).textSecondary)),
              );
            }
            return RefreshIndicator(
              color: AppColors.of(context).primary,
              onRefresh: () async => context.read<SessionsBloc>().add(SessionsLoadRequested()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _buildSessionCard(context, state.sessions[i]),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionEntity session) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.logout, color: AppColors.of(context).error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.of(context).card,
            title: Text(l10n.deleteSessionConfirm, style: TextStyle(color: AppColors.of(context).textPrimary)),
            content: Text(l10n.deviceLoggedOut, style: TextStyle(color: AppColors.of(context).textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel, style: TextStyle(color: AppColors.of(context).textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.endSessionAction, style: TextStyle(color: AppColors.of(context).error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => context.read<SessionsBloc>().add(SessionDeleteRequested(session.id)),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: session.isCurrent
                    ? AppColors.of(context).primary.withOpacity(0.15)
                    : AppColors.of(context).border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _deviceIcon(session.device),
                color: session.isCurrent ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.device ?? l10n.unknownDevice,
                        style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (session.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.of(context).primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(l10n.currentSessionLabel, style: TextStyle(color: AppColors.of(context).primary, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.ip ?? l10n.ipUnknown} · ${_formatDate(session.createdAt, l10n)}',
                    style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                  ),
                  if (session.location != null)
                    Text(session.location!, style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (!session.isCurrent)
              IconButton(
                icon: Icon(Icons.close, color: AppColors.of(context).error, size: 18),
                onPressed: () => context.read<SessionsBloc>().add(SessionDeleteRequested(session.id)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(String? device) {
    if (device == null) return Icons.devices_outlined;
    final lower = device.toLowerCase();
    if (lower.contains('iphone') || lower.contains('android')) return Icons.smartphone_outlined;
    if (lower.contains('ipad') || lower.contains('tablet')) return Icons.tablet_outlined;
    if (lower.contains('mac') || lower.contains('windows') || lower.contains('linux')) return Icons.computer_outlined;
    return Icons.devices_outlined;
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
