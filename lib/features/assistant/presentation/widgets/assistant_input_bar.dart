import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/assistant_draft_storage.dart';

/// Assistant text input bar: multiline field with draft persistence
/// (restored on init, debounce-saved on edit, cleared on send), attach
/// button and send button. The mic shortcut is shown only when [showMic]
/// (the voice session screen has its own controls).
class AssistantInputBar extends StatefulWidget {
  const AssistantInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
    required this.onAttach,
    this.attaching = false,
    this.showMic = false,
    this.onMic,
  });

  /// False while a turn is being sent — send is disabled.
  final bool enabled;
  final void Function(String text) onSend;
  final VoidCallback onAttach;

  /// Shows a spinner in place of the attach button during file upload.
  final bool attaching;
  final bool showMic;
  final VoidCallback? onMic;

  @override
  State<AssistantInputBar> createState() => _AssistantInputBarState();
}

class _AssistantInputBarState extends State<AssistantInputBar> {
  late final TextEditingController _ctrl;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: sl<AssistantDraftStorage>().read() ?? '');
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500),
        () => sl<AssistantDraftStorage>().save(text));
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _ctrl.clear();
    _draftTimer?.cancel();
    sl<AssistantDraftStorage>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          widget.attaching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: widget.onAttach,
                  icon: const Icon(Icons.attach_file),
                  tooltip: l10n.assistantAttachFile,
                ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.assistantChatHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          if (widget.showMic)
            IconButton(
              onPressed: widget.onMic,
              icon: const Icon(Icons.mic_none),
            ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (context, value, _) {
              final enabled = value.text.trim().isNotEmpty && widget.enabled;
              return IconButton(
                onPressed: enabled ? _send : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: enabled
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
