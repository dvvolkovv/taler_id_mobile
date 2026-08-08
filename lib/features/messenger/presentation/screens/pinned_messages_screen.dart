import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/i_messenger_repository.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';

/// Client-side mirror of the backend's `_assertCanPin` permission check
/// (`messenger.service.ts`): any participant may unpin in DIRECT/SAVED/AI_*
/// conversations, but only OWNER/ADMIN in GROUP/CHANNEL. An unresolved
/// conversation ([conv] null) fails closed rather than let the user attempt
/// an action the server would reject anyway.
///
/// Extracted as a top-level pure function (rather than inlined at the call
/// site in `chat_room_screen.dart`) so this permission rule — a client-side
/// duplicate of a server-side check — is independently unit-testable; see
/// the `canUnpinIn` group in `pinned_messages_screen_test.dart`.
bool canUnpinIn(ConversationEntity? conv) {
  if (conv == null) return false;
  if (conv.type != 'CHANNEL' && conv.type != 'GROUP') return true;
  return conv.myRole == 'OWNER' || conv.myRole == 'ADMIN';
}

/// Full list of a conversation's pinned messages (Task 13), opened from the
/// pinned banner's list icon ([PinnedBanner.onOpenList] in
/// `pinned_banner.dart`).
///
/// Tapping a row pops this screen with that message's id so the caller
/// (`ChatRoomScreen`) can jump to/highlight it, reusing `_onPinJump`.
///
/// [canUnpin] (see [canUnpinIn]) controls whether each row gets an unpin
/// control and the AppBar gets an "Unpin all" action. Both go through
/// MessengerBloc events (`UnpinMessage`/`UnpinAllMessages`) rather than the
/// repository directly, so the chat's banner and the conversation's
/// `pinnedCount` stay in sync (see `MessengerBloc._withPinnedCount`).
class PinnedMessagesScreen extends StatefulWidget {
  final String conversationId;
  final bool canUnpin;

  const PinnedMessagesScreen({
    super.key,
    required this.conversationId,
    required this.canUnpin,
  });

  @override
  State<PinnedMessagesScreen> createState() => _PinnedMessagesScreenState();
}

class _PinnedMessagesScreenState extends State<PinnedMessagesScreen> {
  bool _loading = true;
  List<MessageEntity> _pins = const [];

  // Re-entrancy guard for "Unpin all" — a frame-perfect double tap must not
  // stack two confirmation dialogs. Mirrors the `_saving` flag in
  // channel_settings_screen.dart's analogous confirm-then-mutate flow.
  bool _confirmingUnpinAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pins =
          await sl<IMessengerRepository>().getPinnedMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _pins = pins;
        _loading = false;
      });
    } catch (_) {
      // No dedicated error UI (out of scope for this task) — treat like an
      // empty list so the screen still resolves out of the spinner state.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Re-reads the pin list from the server after a write dispatched through
  /// the bloc, so a rejected unpin restores the row instead of leaving it
  /// silently gone.
  ///
  /// `MessengerBloc`'s `UnpinMessage`/`UnpinAllMessages` handlers swallow
  /// repository failures silently (`catch (_) {}` in
  /// `_onUnpinMessage`/`_onUnpinAllMessages`) — by design, since inventing
  /// an error channel on the BLoC just for this screen isn't worth it. That
  /// means nothing tells this screen when a dispatch was rejected (e.g. a
  /// 403 because the cached `myRole` this screen's `canUnpin` was built
  /// from has gone stale since the conversation was last loaded). Without
  /// this, a rejected unpin would still make the row vanish here and look
  /// like it worked. Reconciling with a plain read — rather than writing
  /// through the repository directly — keeps `MessengerBloc` the only path
  /// that mutates pin state, so `pinnedCount`/the chat banner stay correct.
  ///
  /// `Bloc.add()` returns before its own HTTP call has landed (the dispatch
  /// a moment before this runs is fire-and-forget from this screen's point
  /// of view), so a single immediate GET can read a not-yet-written state.
  /// A fixed sleep-then-check can't tell "still in flight" from "rejected"
  /// apart, and picking a sleep long enough for one turns it into wasted
  /// time for the other — worse, too short and it reads mid-flight, taking
  /// that stale answer at face value and putting a *successfully* unpinned
  /// row back, which is the exact lie this method exists to prevent, just
  /// inverted. Retrying — keyed on the expected outcome — instead of
  /// guessing at timing avoids both: keep checking until the server's
  /// answer matches what was asked for ([expectGone]'s id absent, or the
  /// list empty for [expectEmpty]), and only accept a contradicting answer
  /// once attempts run out, at which point a genuine rejection correctly
  /// wins and restores the row.
  Future<void> _reconcile({String? expectGone, bool expectEmpty = false}) async {
    const maxAttempts = 3;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // Linear backoff (250ms, 500ms, 750ms — 1.5s total worst case) gives
      // a slow write progressively more room without ever guessing a
      // single fixed wait.
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      if (!mounted) return;
      try {
        final pins =
            await sl<IMessengerRepository>().getPinnedMessages(widget.conversationId);
        if (!mounted) return;
        final settled = expectEmpty
            ? pins.isEmpty
            : expectGone == null || !pins.any((p) => p.id == expectGone);
        if (settled || attempt == maxAttempts - 1) {
          setState(() => _pins = pins);
          return;
        }
      } catch (_) {
        // Reconciliation itself failing is no worse than not reconciling —
        // keep whatever the optimistic local state already shows.
        return;
      }
    }
  }

  Future<void> _unpin(MessageEntity message) async {
    context.read<MessengerBloc>().add(
          UnpinMessage(conversationId: widget.conversationId, messageId: message.id),
        );
    // Optimistic removal so the UI stays responsive; _reconcile() below
    // corrects it against the server a moment later.
    setState(() => _pins = _pins.where((p) => p.id != message.id).toList());
    await _reconcile(expectGone: message.id);
  }

  Future<void> _confirmUnpinAll() async {
    if (_confirmingUnpinAll) return;
    setState(() => _confirmingUnpinAll = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.unpinAllAction),
          content: Text(l10n.unpinAllConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.unpinAllAction,
                style: TextStyle(color: AppColors.of(context).error),
              ),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      context.read<MessengerBloc>().add(UnpinAllMessages(widget.conversationId));
      // Optimistic empty so the UI stays responsive; _reconcile() below
      // corrects it against the server a moment later.
      setState(() => _pins = const []);
      await _reconcile(expectEmpty: true);
    } finally {
      if (mounted) setState(() => _confirmingUnpinAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(l10n.pinnedMessagesTitle),
        actions: [
          if (widget.canUnpin)
            TextButton(
              onPressed: _confirmUnpinAll,
              child: Text(l10n.unpinAllAction),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pins.isEmpty
              ? Center(
                  child: Text(
                    l10n.noPinnedMessages,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              : ListView.separated(
                  itemCount: _pins.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: colors.border),
                  itemBuilder: (context, index) {
                    final message = _pins[index];
                    // Telegram-style one-line preview: collapse newlines,
                    // let the Text widget ellipsize the rest — same
                    // transform PinnedBanner applies to its own preview.
                    final preview = message.content.replaceAll('\n', ' ');
                    return ListTile(
                      tileColor: colors.card,
                      onTap: () => Navigator.pop(context, message.id),
                      title: Text(
                        message.senderName ?? '',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      trailing: widget.canUnpin
                          ? IconButton(
                              tooltip: l10n.unpinAction,
                              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                              onPressed: () => _unpin(message),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
