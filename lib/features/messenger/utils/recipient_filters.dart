import '../domain/entities/conversation_entity.dart';

/// Roles allowed to post in a CHANNEL (mirrors backend assertCanPostInChannel).
const _channelPostingRoles = {'OWNER', 'ADMIN'};

/// Returns conversations where the current user can SEND a message.
///
/// Inclusions:
///   - DIRECT, GROUP — always
///   - CHANNEL — only when user role is OWNER or ADMIN
///   - SAVED, AI_ANALYST — always (single-participant or bot chats)
///
/// Exclusions:
///   - CHANNEL with SUBSCRIBER role (read-only)
///   - Unknown ConvType (defensive)
List<ConversationEntity> filterRecipients(List<ConversationEntity> all) {
  return all.where(_canPost).toList(growable: false);
}

bool _canPost(ConversationEntity c) {
  switch (c.type) {
    case 'DIRECT':
    case 'GROUP':
    case 'SAVED':
    case 'AI_ANALYST':
      return true;
    case 'CHANNEL':
      return _channelPostingRoles.contains(c.myRole);
    default:
      return false;
  }
}
