import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'shortcut_intents.dart';

/// Wraps [child] with Shortcuts + Actions + Focus so that the MVP keyboard
/// shortcuts work anywhere inside DesktopShell. Phase 2A wires real handlers
/// for Cmd+1..6, Cmd+,, and Esc. Cmd+K, Cmd+I, and Cmd+W are registered with
/// no-op handlers and will be wired in Phase 2B/2C.
class ShortcutDispatcher extends StatelessWidget {
  final Widget child;
  const ShortcutDispatcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMacOS = Platform.isMacOS;
    final modifierKey =
        isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(modifierKey, LogicalKeyboardKey.digit1):
            const OpenSectionMessenger(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.digit2):
            const OpenSectionCalls(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.digit3):
            const OpenSectionAssistant(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.digit4):
            const OpenSectionCalendar(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.digit5):
            const OpenSectionWallet(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.digit6):
            const OpenSectionAiSettings(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.keyK):
            const OpenGlobalSearch(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.comma):
            const OpenSettings(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.keyI):
            const ToggleChatInfoPanel(),
        LogicalKeySet(modifierKey, LogicalKeyboardKey.keyW):
            const CloseWindowOrPopup(),
        LogicalKeySet(LogicalKeyboardKey.escape): const CloseTopmostModal(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenSectionMessenger:
              CallbackAction<OpenSectionMessenger>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.messenger);
            return null;
          }),
          OpenSectionCalls: CallbackAction<OpenSectionCalls>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.callHistory);
            return null;
          }),
          OpenSectionAssistant:
              CallbackAction<OpenSectionAssistant>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.assistant);
            return null;
          }),
          OpenSectionCalendar:
              CallbackAction<OpenSectionCalendar>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.calendar);
            return null;
          }),
          OpenSectionWallet: CallbackAction<OpenSectionWallet>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.wallet);
            return null;
          }),
          OpenSectionAiSettings:
              CallbackAction<OpenSectionAiSettings>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.aiToggles);
            return null;
          }),
          OpenSectionSettings:
              CallbackAction<OpenSectionSettings>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.settings);
            return null;
          }),
          OpenSettings: CallbackAction<OpenSettings>(onInvoke: (_) {
            GoRouter.of(context).go(RouteConstants.settings);
            return null;
          }),
          CloseTopmostModal: CallbackAction<CloseTopmostModal>(onInvoke: (_) {
            Navigator.of(context).maybePop();
            return null;
          }),
          // Phase 2B handlers — no-op for now
          OpenGlobalSearch:
              CallbackAction<OpenGlobalSearch>(onInvoke: (_) => null),
          ToggleChatInfoPanel:
              CallbackAction<ToggleChatInfoPanel>(onInvoke: (_) => null),
          // Phase 2C handler — no-op for now
          CloseWindowOrPopup:
              CallbackAction<CloseWindowOrPopup>(onInvoke: (_) => null),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
