import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/desktop/hover_lift.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Verify the user's registered email address via a 6-digit OTP.
///
/// Two stages, controlled by `_step`:
///  - 0: "We'll send a code to your address" + [Send code]
///  - 1: 6-digit input + [Verify] + [Resend]
///
/// The screen accepts the current email as a constructor argument because the
/// user might land here from Settings, Profile banner, or a deep link — and we
/// don't want to wait for ProfileBloc to load just to show a label.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  int _step = 0; // 0=send invite, 1=enter code

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onBack(BuildContext context) {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailVerifyCodeSent) {
          if (state.alreadyVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.verifyEmailAlreadyVerified),
                backgroundColor: colors.primary,
              ),
            );
            // Refresh profile so any banner disappears, then pop.
            context.read<ProfileBloc>().add(ProfileLoadRequested());
            context.pop();
            return;
          }
          setState(() => _step = 1);
        } else if (state is EmailVerifySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.verifyEmailSuccess),
              backgroundColor: colors.primary,
            ),
          );
          context.read<ProfileBloc>().add(ProfileLoadRequested());
          context.pop();
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colors.error,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return DesktopAdaptiveScaffold(
            cardMaxWidth: kCardWidthForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: MaterialLocalizations.of(context).backButtonTooltip,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                        onPressed: () => _onBack(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.verifyEmailTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _step == 0
                      ? _buildSendStep(l10n, colors, isLoading)
                      : _buildCodeStep(l10n, colors, isLoading),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSendStep(AppLocalizations l10n, AppColorsExtension colors, bool isLoading) {
    return Column(
      key: const ValueKey('verify-step-send'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.mark_email_unread_outlined, color: colors.primary, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.verifyEmailSubtitle(widget.email),
          style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        HoverLift(
          shadowBoost: colors.primary,
          child: LoadingButton(
            text: l10n.verifyEmailSendCode,
            loading: isLoading,
            onPressed: () => context.read<AuthBloc>().add(EmailVerifySendRequested()),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep(AppLocalizations l10n, AppColorsExtension colors, bool isLoading) {
    return Column(
      key: const ValueKey('verify-step-code'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.pin_outlined, color: colors.primary, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.verifyEmailCodeSent(widget.email),
          style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5), letterSpacing: 8),
            filled: true,
            fillColor: colors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          onSubmitted: (v) => _submit(v),
        ),
        const SizedBox(height: 24),
        HoverLift(
          shadowBoost: colors.primary,
          child: LoadingButton(
            text: l10n.verifyEmailConfirm,
            loading: isLoading,
            onPressed: () => _submit(_codeController.text),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: isLoading
                ? null
                : () => context.read<AuthBloc>().add(EmailVerifySendRequested()),
            child: Text(
              l10n.verifyEmailResend,
              style: TextStyle(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _submit(String raw) {
    final code = raw.trim();
    if (code.length < 4) return;
    context.read<AuthBloc>().add(EmailVerifySubmitted(code: code));
  }
}
