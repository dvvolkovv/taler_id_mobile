import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/desktop/animated_blob_background.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            postLoginNavigate(context);
          } else if (state is AuthRequires2FA) {
            context.push(RouteConstants.twoFA, extra: {
              'email': state.email,
              'tempToken': state.tempToken,
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
          return Stack(
            children: [
              // Animated background blobs
              const Positioned.fill(child: AnimatedBlobBackground()),
              SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
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
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            filled: true,
                            fillColor: AppColors.of(context).card,
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.of(context).textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).error, width: 2),
                            ),
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
                          style: TextStyle(color: AppColors.of(context).textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            filled: true,
                            fillColor: AppColors.of(context).card,
                            prefixIcon: Icon(Icons.lock_outlined, color: AppColors.of(context).textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.of(context).textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.of(context).error, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return l10n.passwordRequired;
                            if (v.length < 8) return l10n.passwordMinLength;
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        LoadingButton(
                          text: l10n.loginButton,
                          loading: state is AuthLoading,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(
                                LoginSubmitted(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                ),
                              );
                            }
                          },
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
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}
