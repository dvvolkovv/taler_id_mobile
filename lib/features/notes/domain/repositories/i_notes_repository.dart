import '../entities/note_entity.dart';

abstract class INotesRepository {
  Stream<List<NoteEntity>> watchAll();
  Future<void> refresh();
  Future<NoteEntity> create(String title, String content, {NoteSource source});
  Future<NoteEntity> update(String id, {String? title, String? content});
  Future<void> delete(String id);
  Future<void> resolveConflict(String id, ConflictResolution choice);
  Stream<int> watchPendingCount();
  Stream<int> watchConflictCount();
}
