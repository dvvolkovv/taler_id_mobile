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
import '../../../../core/utils/error_keys.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          postLoginNavigate(context);
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
              Row(
                children: [
                  Tooltip(
                    message: MaterialLocalizations.of(context).backButtonTooltip,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: AppColors.of(context).textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.register,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.registerSubtitle,
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            style: TextStyle(color: AppColors.of(context).textPrimary),
                            decoration: desktopInputDecoration(
                              context,
                              label: l10n.firstName,
                              icon: Icons.person_outline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            style: TextStyle(color: AppColors.of(context).textPrimary),
                            decoration: desktopInputDecoration(
                              context,
                              label: l10n.lastName,
                              icon: Icons.person_outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(color: AppColors.of(context).textPrimary),
                      decoration: desktopInputDecoration(
                        context,
                        label: l10n.usernameOptional,
                        hint: 'username',
                        icon: Icons.alternate_email,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null; // optional
                        if (v.length < 3) return l10n.usernameMinLength;
                        if (v.length > 30) return l10n.usernameMaxLength;
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                          return l10n.usernameInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                      style: TextStyle(color: AppColors.of(context).textPrimary),
                      decoration: desktopInputDecoration(
                        context,
                        label: l10n.password,
                        icon: Icons.lock_outlined,
                        suffix: Tooltip(
                          message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.of(context).textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        text: l10n.registerButton,
                        loading: state is AuthLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(RegisterSubmitted(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                              firstName: _firstNameController.text.trim().isEmpty
                                  ? null
                                  : _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim().isEmpty
                                  ? null
                                  : _lastNameController.text.trim(),
                              username: _usernameController.text.trim().isEmpty
                                  ? null
                                  : _usernameController.text.trim(),
                            ));
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('${l10n.haveAccount} ${l10n.signIn}', style: TextStyle(color: AppColors.of(context).primary)),
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
