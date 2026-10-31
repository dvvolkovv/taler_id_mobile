import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../voice/presentation/widgets/pulsing_avatar.dart'
    show rainbowColorFor;
import '../../domain/entities/conversation_entity.dart';
import '../../utils/recipient_filters.dart';

/// Имя, которое показывает строка получателя и по которому ищет поиск:
/// название беседы, а если его нет — имя собеседника.
String recipientDisplayName(ConversationEntity c) =>
    c.name ?? c.otherUserName ?? '';

/// Беседы, которые предлагаются получателями: те, куда можно писать, кроме
/// «Избранного». У него своя строка сверху, а созданная беседа SAVED в
/// общем списке показывалась второй раз.
List<ConversationEntity> recipientCandidates(List<ConversationEntity> all) =>
    filterRecipients(all)
        .where((c) => c.type != 'SAVED')
        .toList(growable: false);

/// Поиск, «Избранное» и чаты, куда можно писать.
///
/// Общий для «Переслать» и «Поделиться», чтобы два выбора не расходились.
/// Обёртку (лист или полный экран, заголовок) и действие по нажатию задаёт
/// вызывающий.
class RecipientPickerList extends StatefulWidget {
  final List<ConversationEntity> conversations;
  final ValueChanged<ConversationEntity> onSelected;

  /// Строка «Избранное» сверху; нет обработчика — нет строки.
  final VoidCallback? onSelectSaved;

  /// Для листа на `DraggableScrollableSheet`.
  final ScrollController? scrollController;

  /// Беседы ещё грузятся: вместо «Нет чатов» — индикатор.
  final bool loading;

  const RecipientPickerList({
    super.key,
    required this.conversations,
    required this.onSelected,
    this.onSelectSaved,
    this.scrollController,
    this.loading = false,
  });

  @override
  State<RecipientPickerList> createState() => _RecipientPickerListState();
}

class _RecipientPickerListState extends State<RecipientPickerList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final query = _query.toLowerCase();
    final candidates = recipientCandidates(widget.conversations)
        .where((c) => recipientDisplayName(c).toLowerCase().contains(query))
        .toList();
    // Пока идёт поиск, «Избранное» прячется, а пустой результат — просто
    // пустой список: «Нет чатов» там было бы неправдой.
    final showSaved = widget.onSelectSaved != null && _query.isEmpty;
    final showEmptyRow = candidates.isEmpty && _query.isEmpty;
    final itemCount =
        (showSaved ? 1 : 0) + (showEmptyRow ? 1 : candidates.length);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: false,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.chatSearchHint,
              hintStyle: TextStyle(color: colors.textSecondary),
              prefixIcon:
                  Icon(Icons.search_rounded, color: colors.textSecondary),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (showSaved && i == 0) {
                return _SavedTile(onTap: widget.onSelectSaved!);
              }
              if (showEmptyRow) return _EmptyRow(loading: widget.loading);
              final conv = candidates[showSaved ? i - 1 : i];
              return _RecipientTile(
                conversation: conv,
                onTap: () => widget.onSelected(conv),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SavedTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SavedTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFA855F7), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
            ),
          ),
          child: const Icon(Icons.cloud_done_rounded,
              color: Colors.white, size: 22),
        ),
      ),
      title: Text(l10n.messengerSavedSection,
          style: TextStyle(
              color: colors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(l10n.messengerSavedSubtitle,
          style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      onTap: onTap,
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;
  const _RecipientTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final conv = conversation;
    final shown = recipientDisplayName(conv);
    final name =
        shown.isNotEmpty ? shown : AppLocalizations.of(context)!.chatDialog;
    final avatarUrl =
        conv.type == 'DIRECT' ? conv.otherUserAvatar : conv.avatarUrl;
    final ringColor = rainbowColorFor(name.isNotEmpty ? name : conv.id);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: ringColor.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: avatarUrl != null
                ? null
                : RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    radius: 1.1,
                    colors: [
                      Color.lerp(ringColor, Colors.white, 0.28)!,
                      ringColor,
                      Color.lerp(ringColor, Colors.black, 0.38)!,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
          ),
          child: avatarUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
        ),
      ),
      title: Text(name, style: TextStyle(color: colors.textPrimary)),
      onTap: onTap,
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final bool loading;
  const _EmptyRow({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text(
                AppLocalizations.of(context)!.shareNoChats,
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
      ),
    );
  }
}
