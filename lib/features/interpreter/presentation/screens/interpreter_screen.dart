import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../voice_enrollment/presentation/bloc/voice_enrollment_bloc.dart';
import '../../../voice_enrollment/presentation/widgets/owner_enrollment_sheet.dart';
import '../../domain/interpreter_error.dart';
import '../../domain/interpreter_models.dart';
import '../bloc/interpreter_bloc.dart';
import '../bloc/interpreter_event.dart';
import '../bloc/interpreter_state.dart';
import '../widgets/ended_view.dart';
import '../widgets/interpreter_texts.dart';
import '../widgets/qr_view.dart';
import '../widgets/scanner_screen.dart';
import '../widgets/session_view.dart';
import '../widgets/start_view.dart';

/// Single route for the whole "Разговор с переводом" feature — a
/// `BlocConsumer` over [InterpreterBloc] swaps the body between views as the
/// bloc's state machine advances. [joinCode] carries a scanned/deep-linked
/// code straight into the flow; [scanFirst] opens the QR scanner once the
/// language-choosing screen is reached (used by the assistant's
/// `open_interpreter({action: 'join'})` and by `?scan=1`).
class InterpreterScreen extends StatelessWidget {
  final String? joinCode;
  final bool scanFirst;

  const InterpreterScreen({super.key, this.joinCode, this.scanFirst = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InterpreterBloc>(
      create: (ctx) => sl<InterpreterBloc>(
        param1: Localizations.localeOf(ctx).languageCode,
      )..add(Started(joinCode: joinCode)),
      child: _InterpreterView(scanFirst: scanFirst),
    );
  }
}

class _InterpreterView extends StatefulWidget {
  final bool scanFirst;
  const _InterpreterView({required this.scanFirst});

  @override
  State<_InterpreterView> createState() => _InterpreterViewState();
}

class _InterpreterViewState extends State<_InterpreterView> {
  bool _scanFirstPending = false;

  /// The catalog only ever arrives on [InterpreterChoosing] — remembered
  /// here so [InterpreterSessionView] (reached from [InterpreterActive], which carries
  /// no catalog of its own) can still resolve the partner's language name.
  InterpreterCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _scanFirstPending = widget.scanFirst;
  }

  Future<void> _openScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const InterpreterScannerScreen()),
    );
    if (code != null && mounted) {
      context.read<InterpreterBloc>().add(JoinPressed(code));
    }
  }

  Future<void> _handleNeedVoicePrint() async {
    final bloc = sl<VoiceEnrollmentBloc>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: const OwnerEnrollmentSheet(),
      ),
    );
    if (mounted) {
      context.read<InterpreterBloc>().add(VoicePrintResult(result == true));
    }
  }

  Future<bool> _confirmLeave() async {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(l10n.interpreterLeaveConfirmTitle),
        content: Text(l10n.interpreterLeaveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.interpreterEndButton),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return BlocConsumer<InterpreterBloc, InterpreterState>(
      listener: (context, state) {
        if (state is InterpreterChoosing) _catalog = state.catalog;
        if (state is InterpreterNeedVoicePrint) {
          _handleNeedVoicePrint();
        } else if (state is InterpreterChoosing && _scanFirstPending) {
          _scanFirstPending = false;
          _openScanner();
        }
      },
      builder: (context, state) {
        final blockPop =
            state is InterpreterHosting || state is InterpreterActive;
        return PopScope(
          canPop: !blockPop,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final confirmed = await _confirmLeave();
            if (confirmed && context.mounted) {
              context.read<InterpreterBloc>().add(const EndPressed());
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(title: Text(l10n.interpreterTitle)),
            body: _buildBody(context, state, l10n, colors),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    InterpreterState state,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final bloc = context.read<InterpreterBloc>();
    switch (state) {
      case InterpreterLoading():
        return Center(child: CircularProgressIndicator(color: colors.primary));

      case InterpreterUnavailable():
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.interpreterUnavailableTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
          ),
        );

      case InterpreterNeedVoicePrint():
        // The enrollment sheet is already open (triggered from the
        // listener) — this is just what shows behind/after it.
        return Center(child: CircularProgressIndicator(color: colors.primary));

      case InterpreterChoosing(catalog: final catalog, myLang: final myLang):
        return StartView(
          catalog: catalog,
          myLang: myLang,
          onLanguageChosen: (code) => bloc.add(LanguageChosen(code)),
          onStart: () => bloc.add(const HostPressed()),
          onScan: _openScanner,
        );

      case InterpreterWorking(kind: final kind):
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                kind == InterpreterWorkKind.creating
                    ? l10n.interpreterCreatingLabel
                    : l10n.interpreterJoiningLabel,
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        );

      case InterpreterHosting(code: final code, expiresAt: final expiresAt):
        return QrView(
          code: code,
          expiresAt: expiresAt,
          onNewCode: () => bloc.add(const NewCodePressed()),
        );

      case InterpreterActive(
          isHost: final isHost,
          partner: final partner,
          directions: final directions,
          captions: final captions,
          partnerSpeaking: final partnerSpeaking,
          meSpeaking: final meSpeaking,
          agentPresent: final agentPresent,
          connection: final connection,
          micOn: final micOn,
          startedAt: final startedAt,
          spentPlanck: final spentPlanck,
        ):
        return InterpreterSessionView(
          isHost: isHost,
          partner: partner,
          directions: directions,
          captions: captions,
          partnerSpeaking: partnerSpeaking,
          meSpeaking: meSpeaking,
          agentPresent: agentPresent,
          connection: connection,
          micOn: micOn,
          startedAt: startedAt,
          spentPlanck: spentPlanck,
          languages: _catalog?.languages ?? const [],
          onMicToggle: (on) => bloc.add(MicToggled(on)),
          onEnd: () => bloc.add(const EndPressed()),
        );

      case InterpreterEnded(
          reason: final reason,
          duration: final duration,
          spentPlanck: final spentPlanck,
          isHost: final isHost,
        ):
        return EndedView(
          reason: reason,
          duration: duration,
          spentPlanck: spentPlanck,
          isHost: isHost,
          onDone: () => Navigator.of(context).maybePop(),
          onAgain: () => bloc.add(const BackToStart()),
        );

      case InterpreterFailure(kind: final kind, back: final back):
        return _buildFailureView(context, kind, back, l10n, colors, bloc);
    }
  }

  Widget _buildFailureView(
    BuildContext context,
    InterpreterErrorKind kind,
    InterpreterChoosing? back,
    AppLocalizations l10n,
    AppColorsExtension colors,
    InterpreterBloc bloc,
  ) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 40),
              const SizedBox(height: 16),
              Text(
                interpreterErrorText(l10n, kind),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
              ),
              if (kind == InterpreterErrorKind.codeExpired) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.interpreterAskNewCodeHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              if (kind == InterpreterErrorKind.insufficientFunds) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.push(RouteConstants.wallet),
                    child: Text(l10n.billingTopUp),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => bloc.add(const BackToStart()),
                  child: Text(
                    back == null
                        ? l10n.retry
                        : l10n.interpreterBackToStartButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
