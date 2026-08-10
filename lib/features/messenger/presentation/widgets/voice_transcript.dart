import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/messenger_remote_datasource.dart';
import '../../domain/entities/message_entity.dart';
import '../../utils/voice_meta.dart';

/// Расшифровка голосового: кнопка, пока текста нет, и сам текст, когда есть.
///
/// Расшифровка стоит денег, поэтому запускается вручную, а не при получении
/// сообщения. Результат сервер запоминает на самом сообщении, так что второй
/// участник беседы увидит готовый текст, ничего не оплачивая.
class VoiceTranscript extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;
  const VoiceTranscript({super.key, required this.message, required this.isMe});

  @override
  State<VoiceTranscript> createState() => _VoiceTranscriptState();
}

class _VoiceTranscriptState extends State<VoiceTranscript> {
  String? _local;
  bool _loading = false;
  String? _error;

  Future<void> _run() async {
    setState(() { _loading = true; _error = null; });
    try {
      final text = await sl<MessengerRemoteDataSource>()
          .transcribeVoice(widget.message.id);
      if (mounted) setState(() => _local = text);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.chatTranscribeFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final onBubble = widget.isMe ? Colors.white : colors.textSecondary;

    // Пришедшее с сервера главнее локального: другое устройство могло
    // расшифровать это же сообщение, пока экран был открыт.
    final text = transcriptOf(widget.message) ?? _local;

    if (text != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text.trim().isEmpty ? l10n.chatTranscribeEmpty : text,
          style: TextStyle(
            color: onBubble,
            fontSize: 13,
            height: 1.3,
            fontStyle: text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
    }

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(l10n.chatTranscribing,
            style: TextStyle(color: onBubble, fontSize: 12, fontStyle: FontStyle.italic)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: GestureDetector(
        onTap: _run,
        child: Text(
          _error ?? l10n.chatTranscribeVoice,
          style: TextStyle(
            color: _error != null ? colors.error : (widget.isMe ? Colors.white70 : colors.primary),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
