import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Dedicated settings screen for the AI voice twin feature.
///
/// Shown as its own menu entry from [ProfileScreen] so the feature is
/// discoverable — it used to live buried inside Edit Profile.
class AiTwinScreen extends StatefulWidget {
  const AiTwinScreen({super.key});

  @override
  State<AiTwinScreen> createState() => _AiTwinScreenState();
}

class _AiTwinScreenState extends State<AiTwinScreen> {
  final _promptCtrl = TextEditingController();
  bool _enabled = false;
  int _timeoutSeconds = 30;
  bool _initialized = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _initFromUser(UserEntity user) {
    if (_initialized) return;
    _enabled = user.aiTwinEnabled;
    _timeoutSeconds = user.aiTwinTimeoutSeconds;
    _promptCtrl.text = user.aiTwinPrompt ?? '';
    _initialized = true;
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  /// Best-effort user-facing name used in default hints and info copy.
  /// Prefers firstName, falls back to username, then to a generic word.
  String _displayName(UserEntity? user, AppLocalizations l10n) {
    if (user == null) return l10n.aiTwinDefaultName;
    final first = user.firstName?.trim() ?? '';
    if (first.isNotEmpty) return first;
    final uname = user.username?.trim() ?? '';
    if (uname.isNotEmpty) return uname;
    return l10n.aiTwinDefaultName;
  }

  void _save() {
    setState(() => _saving = true);
    context.read<ProfileBloc>().add(ProfileUpdateSubmitted({
          'aiTwinEnabled': _enabled,
          'aiTwinTimeoutSeconds': _timeoutSeconds,
          'aiTwinPrompt':
              _promptCtrl.text.trim().isEmpty ? null : _promptCtrl.text.trim(),
        }));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.aiTwinSection),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && _saving) {
            setState(() {
              _saving = false;
              _dirty = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileUpdated),
                backgroundColor: colors.primary,
              ),
            );
          } else if (state is ProfileError && _saving) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileUpdating
                  ? state.user
                  : null;
          if (user != null) _initFromUser(user);

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(colors, l10n),
                const SizedBox(height: 20),
                _buildMainToggle(colors, l10n),
                if (_enabled) ...[
                  const SizedBox(height: 16),
                  _buildTimeoutCard(colors, l10n),
                ],
                // Prompt is editable even when the twin is disabled — so the
                // user can prepare their instructions in advance.
                const SizedBox(height: 16),
                _buildPromptCard(colors, l10n, user),
                const SizedBox(height: 16),
                _buildVoiceInfoCard(colors, l10n, user),
                const SizedBox(height: 32),
                _buildSaveButton(colors, l10n),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildHero(AppColorsExtension colors, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.22),
            colors.primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.4),
                      colors.primary.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: colors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiTwinHeroTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.aiTwinHeroSubtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle(AppColorsExtension colors, AppLocalizations l10n) {
    return AppCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.aiTwinEnabled,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.aiTwinEnabledDesc,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        value: _enabled,
        activeThumbColor: colors.primary,
        onChanged: (v) {
          setState(() => _enabled = v);
          _markDirty();
        },
      ),
    );
  }

  Widget _buildTimeoutCard(AppColorsExtension colors, AppLocalizations l10n) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                l10n.aiTwinTimeout,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.aiTwinTimeoutValue(_timeoutSeconds),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.border,
              thumbColor: colors.primary,
              overlayColor: colors.primary.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: _timeoutSeconds.toDouble(),
              min: 15,
              max: 60,
              divisions: 9,
              onChanged: (v) {
                setState(() => _timeoutSeconds = v.round());
                _markDirty();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(
      AppColorsExtension colors, AppLocalizations l10n, UserEntity? user) {
    final name = _displayName(user, l10n);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiTwinPrompt,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aiTwinPromptSubtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _promptCtrl,
            maxLines: 5,
            minLines: 3,
            maxLength: 2000,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
            onChanged: (_) => _markDirty(),
            decoration: InputDecoration(
              hintText: l10n.aiTwinPromptHint(name),
              hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              counterStyle: TextStyle(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInfoCard(
      AppColorsExtension colors, AppLocalizations l10n, UserEntity? user) {
    final name = _displayName(user, l10n);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.graphic_eq, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.aiTwinComingSoon(name),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppColorsExtension colors, AppLocalizations l10n) {
    final canSave = _dirty && !_saving;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: canSave
                ? [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.8),
                  ]
                : [
                    colors.border,
                    colors.border.withValues(alpha: 0.6),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: canSave
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: canSave ? _save : null,
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: TextStyle(
                        color: canSave
                            ? Colors.white
                            : colors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
