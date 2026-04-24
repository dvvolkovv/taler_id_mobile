import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/error_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/feature_toggle_entity.dart';
import '../bloc/toggles_bloc.dart';
import '../bloc/toggles_event.dart';
import '../bloc/toggles_state.dart';
import '_billing_formatters.dart';

/// Per-feature on/off switches for AI capabilities.
///
/// Optimistic UI: [TogglesBloc] flips the value immediately, then calls the
/// backend. On failure it rolls back and surfaces a `TogglesError` — we
/// show that via a SnackBar while the optimistic rollback re-emits the
/// prior `TogglesLoaded`.
class AiTogglesScreen extends StatelessWidget {
  const AiTogglesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TogglesBloc>(
      create: (_) => sl<TogglesBloc>()..add(LoadToggles()),
      child: const _AiTogglesView(),
    );
  }
}

/// Display labels (can differ slightly from the shared map, e.g. adding
/// a qualifier like "(AI Twin)" or "Outbound-бот обзвона" for clarity
/// on a settings screen).
const _displayLabels = <String, String>{
  'voice_assistant': 'Голосовой ассистент',
  'web_search': 'Веб-поиск ассистента',
  'ai_twin': 'Голосовой двойник (AI Twin)',
  'outbound_call': 'Outbound-бот обзвона',
  'whisper_transcribe': 'Транскрипция звонков',
  'meeting_summary': 'AI-резюме звонков',
};

class _AiTogglesView extends StatelessWidget {
  const _AiTogglesView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('AI-функции')),
      body: BlocConsumer<TogglesBloc, TogglesState>(
        listenWhen: (_, current) => current is TogglesError,
        listener: (context, state) {
          if (state is TogglesError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(resolveErrorMessage(l10n, state.message)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is TogglesInitial || state is TogglesLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          // After an error the BLoC re-emits the prior TogglesLoaded —
          // if we ever get stuck on a non-loaded state with no toggles,
          // offer a retry.
          List<FeatureToggleEntity> toggles = const [];
          if (state is TogglesLoaded) {
            toggles = state.toggles;
          }

          final byKey = {for (final t in toggles) t.featureKey: t};
          // Treat missing keys as enabled-by-default (backend returns all 6).
          bool enabledFor(String key) => byKey[key]?.enabled ?? true;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final key in orderedFeatureKeys)
                _ToggleTile(
                  featureKey: key,
                  label: _displayLabels[key] ?? key,
                  enabled: enabledFor(key),
                  onChanged: (v) => context
                      .read<TogglesBloc>()
                      .add(ToggleFeature(featureKey: key, enabled: v)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String featureKey;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.featureKey,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = _buildSubtitle(context, theme, colorScheme);

    return SwitchListTile(
      value: enabled,
      onChanged: onChanged,
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle,
    );
  }

  Widget? _buildSubtitle(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.65),
    );
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    switch (featureKey) {
      case 'web_search':
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('(при использовании ассистента)', style: subStyle),
        );
      case 'ai_twin':
        // Inline link to the detailed AI Twin settings screen (prompt,
        // timeout, voice). Task 9 will migrate it fully; for now the
        // existing screen at `/profile/ai-twin` handles all the config.
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/profile/ai-twin'),
            child: Text(
              'Настроить двойника',
              style: linkStyle,
            ),
          ),
        );
      default:
        return null;
    }
  }
}
