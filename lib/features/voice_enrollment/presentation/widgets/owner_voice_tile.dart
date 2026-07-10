import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/voice_enrollment_bloc.dart';
import '../bloc/voice_enrollment_event.dart';
import '../bloc/voice_enrollment_state.dart';
import 'owner_enrollment_sheet.dart';

/// Settings tile for the owner-voice enrollment: shows whether a voice
/// sample is enrolled, lets the user record one, re-record, or delete it.
class OwnerVoiceTile extends StatelessWidget {
  final String lang;
  const OwnerVoiceTile({super.key, required this.lang});

  bool get _ru => lang == 'ru';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VoiceEnrollmentBloc>()..add(const Check()),
      child: BlocBuilder<VoiceEnrollmentBloc, VoiceEnrollmentState>(
        builder: (context, state) {
          final colors = AppColors.of(context);
          final enrolled = state is Enrolled;
          final busy = state is Idle && state.busy;

          String subtitle;
          if (busy) {
            subtitle = _ru ? 'Проверка…' : 'Checking…';
          } else if (enrolled) {
            subtitle = _ru
                ? 'Записан — ассистент реагирует только на ваш голос'
                : 'Enrolled — the assistant reacts to your voice only';
          } else if (state is Failed) {
            subtitle = _ru ? 'Ошибка проверки статуса' : 'Status check failed';
          } else {
            subtitle = _ru
                ? 'Не записан — ассистент отвечает любому голосу'
                : 'Not enrolled — the assistant answers any voice';
          }

          return ListTile(
            leading: Icon(Icons.record_voice_over_outlined, color: colors.primary),
            title: Text(
              _ru ? 'Голос владельца' : 'Owner voice',
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            trailing: enrolled
                ? IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error),
                    onPressed: () => _confirmDelete(context),
                  )
                : const Icon(Icons.chevron_right),
            onTap: busy
                ? null
                : () async {
                    if (enrolled) {
                      _confirmDelete(context);
                    } else {
                      final bloc = context.read<VoiceEnrollmentBloc>();
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: const OwnerEnrollmentSheet(),
                        ),
                      );
                      bloc.add(const Check());
                    }
                  },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<VoiceEnrollmentBloc>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(_ru ? 'Удалить запись голоса?' : 'Delete voice sample?'),
        content: Text(
          _ru
              ? 'Ассистент перестанет различать ваш голос и будет отвечать любому. Запись можно сделать заново в любой момент.'
              : 'The assistant will stop recognising your voice and answer anyone. You can re-record at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(_ru ? 'Отмена' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              bloc.add(const Delete());
            },
            child: Text(
              _ru ? 'Удалить' : 'Delete',
              style: TextStyle(color: AppColors.of(context).error),
            ),
          ),
        ],
      ),
    );
  }
}
