import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/room_chat_controller.dart';

/// Панель чата комнаты. Раскладку выбирает вызывающая сторона: на узком
/// экране панель кладут поверх звонка, на широком окне — сбоку. Сама панель
/// просто заполняет отведённое место.
class RoomChatPanel extends StatefulWidget {
  final RoomChatController controller;
  final ValueChanged<String> onSend;
  final VoidCallback onClose;

  const RoomChatPanel({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onClose,
  });

  @override
  State<RoomChatPanel> createState() => _RoomChatPanelState();
}

class _RoomChatPanelState extends State<RoomChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Прокручиваем только когда лента реально выросла: контроллер уведомляет
  /// и о `setOpen`, на которое двигать ничего не надо.
  int _seen = 0;

  @override
  void initState() {
    super.initState();
    _seen = widget.controller.messages.length;
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(RoomChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _seen = widget.controller.messages.length;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final count = widget.controller.messages.length;
    if (count == _seen) return;
    _seen = count;
    // Ленту перерисовывает ListenableBuilder — здесь только доводим её до низа
    // после того, как новый элемент уже отрисован и размеры пересчитаны.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      if (!position.hasContentDimensions) return;
      _scroll.jumpTo(position.maxScrollExtent);
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = _Palette.of(context);

    return Material(
      color: palette.background,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.voiceChat,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                color: palette.textSecondary,
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onClose,
              ),
            ],
          ),
          Divider(height: 1, color: palette.divider),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final messages = widget.controller.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l10n.voiceChatEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: palette.textSecondary),
                      ),
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // На узком телефоне фиксированные 280 пикселей оказались бы
                    // шире доступного места, поэтому берём долю от ширины.
                    final bubbleMaxWidth =
                        math.min(280.0, constraints.maxWidth * 0.78);
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _bubble(
                        context,
                        messages[i],
                        palette,
                        bubbleMaxWidth,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: palette.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: TextStyle(color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.voiceChatHint,
                      hintStyle: TextStyle(color: palette.textSecondary),
                      counterText: '',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: l10n.voiceChatSend,
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(
    BuildContext context,
    RoomChatMessage m,
    _Palette palette,
    double maxWidth,
  ) {
    final theme = Theme.of(context);
    final time = '${m.sentAt.hour.toString().padLeft(2, '0')}:'
        '${m.sentAt.minute.toString().padLeft(2, '0')}';
    final textColor = m.own ? palette.onOwnBubble : palette.textPrimary;
    final metaColor =
        m.own ? palette.onOwnBubbleMuted : palette.textSecondary;

    return Align(
      alignment: m.own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: m.own ? palette.ownBubble : palette.otherBubble,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!m.own)
              Text(
                m.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(m.text, style: TextStyle(color: textColor, fontSize: 15)),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(color: metaColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Цвета панели.
///
/// В приложении тема одна — тёмная, и цвета в ней принято брать из
/// `AppColorsExtension`. Но `AppColors.of(context)` падает, если расширение
/// не установлено (например, в виджет-тесте с голым `MaterialApp`), поэтому
/// читаем расширение мягко и в его отсутствие раскладываемся на `ColorScheme`.
class _Palette {
  final Color background;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color ownBubble;
  final Color onOwnBubble;
  final Color onOwnBubbleMuted;
  final Color otherBubble;

  const _Palette({
    required this.background,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.ownBubble,
    required this.onOwnBubble,
    required this.onOwnBubbleMuted,
    required this.otherBubble,
  });

  factory _Palette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppColorsExtension>();

    if (colors == null) {
      return _Palette(
        background: scheme.surface,
        divider: theme.dividerColor,
        textPrimary: scheme.onSurface,
        textSecondary: scheme.onSurfaceVariant,
        accent: scheme.primary,
        ownBubble: scheme.primary,
        onOwnBubble: scheme.onPrimary,
        onOwnBubbleMuted: scheme.onPrimary.withValues(alpha: 0.75),
        otherBubble: scheme.surfaceContainerHighest,
      );
    }

    return _Palette(
      background: colors.card,
      divider: colors.border,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
      accent: colors.accent,
      ownBubble: colors.primary,
      onOwnBubble: Colors.white,
      onOwnBubbleMuted: Colors.white.withValues(alpha: 0.75),
      // `surfaceContainerHighest` в нашей теме сваливается в `surface`, то есть
      // в цвет самой панели, и чужой пузырь стал бы невидимым — берём border.
      otherBubble: colors.border,
    );
  }
}
