import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/desktop/desktop_adaptive_scaffold.dart';
import '../../../../core/desktop/desktop_breakpoints.dart';
import '../../../../core/desktop/hover_lift.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/router/post_login_redirect.dart';
import '../../../../core/utils/error_keys.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class TwoFAScreen extends StatefulWidget {
  final String email;
  final String tempToken;
  const TwoFAScreen({super.key, required this.email, required this.tempToken});

  @override
  State<TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends State<TwoFAScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_codeController.text.length == 6) {
      context.read<AuthBloc>().add(TwoFASubmitted(
        email: widget.email,
        code: _codeController.text,
        tempToken: widget.tempToken,
      ));
    }
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
          _codeController.clear();
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
              Icon(Icons.security, color: AppColors.of(context).primary, size: 48),
              const SizedBox(height: 24),
              Text(
                l10n.twoFATitle,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.twoFASubtitle,
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(color: AppColors.of(context).border, letterSpacing: 8, fontSize: 28),
                ),
                onChanged: (v) {
                  if (v.length == 6) _submit(context);
                },
              ),
              const SizedBox(height: 32),
              HoverLift(
                shadowBoost: AppColors.of(context).primary,
                child: LoadingButton(
                  text: l10n.verify,
                  loading: state is AuthLoading,
                  onPressed: () => _submit(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
