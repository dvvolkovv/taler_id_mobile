import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:taler_id_mobile/features/notes/domain/entities/note_entity.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getApplicationSupportPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

NoteEntity note(String id) => NoteEntity(
      id: id,
      title: 'T-$id',
      content: 'C-$id',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      updatedAt: DateTime.parse('2026-05-13T10:00:00Z'),
    );

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_local_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(NotesLocalDataSource.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert + getAll returns notes in updatedAt-desc order', () async {
    final ds = NotesLocalDataSource();
    await ds.upsert(note('a').copyWith(updatedAt: DateTime.parse('2026-05-13T10:01:00Z')));
    await ds.upsert(note('b').copyWith(updatedAt: DateTime.parse('2026-05-13T10:02:00Z')));
    final list = await ds.getAll();
    expect(list.map((n) => n.id).toList(), ['b', 'a']);
  });

  test('remove drops the entry', () async {
    final ds = NotesLocalDataSource();
    await ds.upsert(note('a'));
    await ds.remove('a');
    expect((await ds.getAll()).isEmpty, true);
  });

  test('upsert replaces existing by id', () async {
    final ds = NotesLocalDataSource();
    await ds.upsert(note('a'));
    await ds.upsert(note('a').copyWith(title: 'updated'));
    final list = await ds.getAll();
    expect(list.length, 1);
    expect(list[0].title, 'updated');
  });

  test('watchAll emits on changes', () async {
    final ds = NotesLocalDataSource();
    final emissions = <int>[];
    final sub = ds.watchAll().listen((notes) => emissions.add(notes.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(note('a'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(note('b'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });
}
