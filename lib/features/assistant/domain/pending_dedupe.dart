import '../../messenger/domain/entities/message_entity.dart';

/// True when a live voice replica [text] is already persisted in the
/// assistant thread: any message logged from the voice session
/// (metadata.source == 'voice') with identical content.
bool replicaAlreadyPersisted(String text, List<MessageEntity> messages) =>
    messages.any((m) => (m.metadata?['source'] == 'voice') && m.content == text);
