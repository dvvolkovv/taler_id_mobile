import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/desktop/desktop_input_decoration.dart';
import '../../../../core/desktop/hover_lift.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/router/post_login_redirect.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_keys.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Single submit path shared by the Login button and the keyboard Enter/Done
  // action on the password field, so pressing Enter logs in like clicking.
  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          postLoginNavigate(context);
        } else if (state is AuthRequires2FA) {
          context.push(RouteConstants.twoFA, extra: {
            'email': state.email,
            'challengeToken': state.challengeToken,
          });
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resolveErrorMessage(l10n, state.message)),
              backgroundColor: AppColors.of(context).error,
            ),
          );
        }
      },
      builder: (context, state) {
        return DesktopAdaptiveScaffold(
          cardMaxWidth: kCardWidthForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo with colored glow
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.of(context).primary.withOpacity(0.55),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA855F7).withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('app_icon_1024.png', width: 40, height: 40),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                    ).createShader(rect),
                    child: const Text(
                      'Taler ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                l10n.login,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSubtitle,
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(color: AppColors.of(context).textPrimary),
                      decoration: desktopInputDecoration(
                        context,
                        label: l10n.email,
                        icon: Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.emailRequired;
                        if (!v.contains('@')) return l10n.emailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: TextStyle(color: AppColors.of(context).textPrimary),
                      decoration: desktopInputDecoration(
                        context,
                        label: l10n.password,
                        icon: Icons.lock_outlined,
                        suffix: Tooltip(
                          message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.of(context).textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.passwordRequired;
                        if (v.length < 8) return l10n.passwordMinLength;
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    HoverLift(
                      shadowBoost: AppColors.of(context).primary,
                      child: LoadingButton(
                        text: l10n.loginButton,
                        loading: state is AuthLoading,
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(RouteConstants.forgotPassword),
                        child: Text(
                          l10n.forgotPassword,
                          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push(RouteConstants.register),
                      child: Text(
                        '${l10n.noAccount} ${l10n.createOne}',
                        style: TextStyle(color: AppColors.of(context).primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
