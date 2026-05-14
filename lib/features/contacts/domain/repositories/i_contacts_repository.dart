// lib/features/contacts/domain/repositories/i_contacts_repository.dart
import '../entities/contact_item_entity.dart';

abstract class IContactsRepository {
  Stream<List<ContactItemEntity>> watchAll();
  Future<void> refresh();
  /// Online-only. Throws on network error.
  Future<Map<String, dynamic>> sendContactRequest(String receiverId);
  Future<void> acceptContactRequest(String requestId, String userId);
  Future<void> rejectContactRequest(String requestId, String userId);
  Stream<int> watchPendingCount();
}
