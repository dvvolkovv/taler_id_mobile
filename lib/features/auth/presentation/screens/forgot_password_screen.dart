import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/desktop/desktop_input_decoration.dart';
import '../../../../core/desktop/hover_lift.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 0; // 0=email, 1=code, 2=new password
  String _email = '';
  String _resetToken = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
        if (state is PasswordResetCodeSent) {
          _email = state.email;
          setState(() => _step = 1);
        } else if (state is PasswordResetCodeVerified) {
          _resetToken = state.resetToken;
          setState(() => _step = 2);
        } else if (state is PasswordResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passwordResetSuccess),
              backgroundColor: colors.primary,
            ),
          );
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
                      l10n.forgotPasswordTitle,
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
                      ? _buildEmailStep(l10n, colors, isLoading)
                      : _step == 1
                          ? _buildCodeStep(l10n, colors, isLoading)
                          : _buildPasswordStep(l10n, colors, isLoading),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailStep(AppLocalizations l10n, AppColorsExtension colors, bool isLoading) {
    return Column(
      key: const ValueKey('step0'),
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
          child: Icon(Icons.email_outlined, color: colors.primary, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.forgotPasswordSubtitle,
          style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [],
            style: TextStyle(color: colors.textPrimary),
            decoration: desktopInputDecoration(
              context,
              label: l10n.email,
              icon: Icons.email_outlined,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.fieldRequired;
              if (!v.contains('@')) return l10n.invalidEmail;
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),
        HoverLift(
          shadowBoost: colors.primary,
          child: LoadingButton(
            text: l10n.sendCode,
            loading: isLoading,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                  ForgotPasswordRequested(email: _emailController.text.trim()),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep(AppLocalizations l10n, AppColorsExtension colors, bool isLoading) {
    return Column(
      key: const ValueKey('step1'),
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
          l10n.resetCodeSent(_email),
          style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            labelText: l10n.enterResetCode,
            filled: true,
            fillColor: colors.card,
            counterText: '',
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
          onChanged: (v) {
            if (v.length == 6) {
              context.read<AuthBloc>().add(
                ForgotPasswordCodeVerified(email: _email, code: v),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        HoverLift(
          shadowBoost: colors.primary,
          child: LoadingButton(
            text: l10n.verify,
            loading: isLoading,
            onPressed: () {
              if (_codeController.text.length == 6) {
                context.read<AuthBloc>().add(
                  ForgotPasswordCodeVerified(
                    email: _email,
                    code: _codeController.text,
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    _codeController.clear();
                    context.read<AuthBloc>().add(
                      ForgotPasswordRequested(email: _email),
                    );
                  },
            child: Text(
              l10n.resendCode,
              style: TextStyle(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(AppLocalizations l10n, AppColorsExtension colors, bool isLoading) {
    return Column(
      key: const ValueKey('step2'),
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
          child: Icon(Icons.lock_reset, color: colors.primary, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.resetPasswordButton,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: colors.textPrimary),
          decoration: desktopInputDecoration(
            context,
            label: l10n.newPassword,
            icon: Icons.lock_outlined,
            suffix: Tooltip(
              message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
              child: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: colors.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          style: TextStyle(color: colors.textPrimary),
          decoration: desktopInputDecoration(
            context,
            label: l10n.confirmNewPassword,
            icon: Icons.lock_outlined,
            suffix: Tooltip(
              message: _obscureConfirm ? l10n.showPassword : l10n.hidePassword,
              child: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: colors.textSecondary,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.passwordMinLength,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        HoverLift(
          shadowBoost: colors.primary,
          child: LoadingButton(
            text: l10n.resetPasswordButton,
            loading: isLoading,
            onPressed: () {
              final pwd = _passwordController.text;
              final confirm = _confirmController.text;
              if (pwd.isEmpty || confirm.isEmpty) return;
              if (pwd.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.passwordMinLength),
                    backgroundColor: AppColors.of(context).error,
                  ),
                );
                return;
              }
              if (pwd != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.passwordMismatch),
                    backgroundColor: AppColors.of(context).error,
                  ),
                );
                return;
              }
              context.read<AuthBloc>().add(
                ForgotPasswordNewPassword(
                  resetToken: _resetToken,
                  newPassword: pwd,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
