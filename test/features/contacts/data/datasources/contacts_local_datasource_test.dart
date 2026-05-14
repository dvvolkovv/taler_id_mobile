import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/features/contacts/data/datasources/contacts_local_datasource.dart';
import 'package:taler_id_mobile/features/contacts/domain/entities/contact_item_entity.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

ContactItemEntity ci(String userId, ContactStatus status, {String? name}) =>
    ContactItemEntity(
      userId: userId,
      name: name ?? 'name-$userId',
      status: status,
    );

void main() {
  late Directory tempDir;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contacts_local_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(ContactsLocalDataSource.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert + getAll returns items sorted incoming → accepted → pending', () async {
    final ds = ContactsLocalDataSource();
    await ds.upsert(ci('u1', ContactStatus.pending, name: 'Zed'));
    await ds.upsert(ci('u2', ContactStatus.accepted, name: 'Bob'));
    await ds.upsert(ci('u3', ContactStatus.incoming, name: 'Alice'));
    await ds.upsert(ci('u4', ContactStatus.accepted, name: 'alice2'));
    final list = await ds.getAll();
    expect(list.map((c) => c.userId).toList(), ['u3', 'u4', 'u2', 'u1']);
  });

  test('remove drops the entry', () async {
    final ds = ContactsLocalDataSource();
    await ds.upsert(ci('u1', ContactStatus.accepted));
    await ds.remove('u1');
    expect((await ds.getAll()).isEmpty, true);
  });

  test('upsert replaces existing by userId', () async {
    final ds = ContactsLocalDataSource();
    await ds.upsert(ci('u1', ContactStatus.incoming));
    await ds.upsert(ci('u1', ContactStatus.accepted, name: 'updated'));
    final list = await ds.getAll();
    expect(list.length, 1);
    expect(list[0].status, ContactStatus.accepted);
    expect(list[0].name, 'updated');
  });

  test('watchAll emits on changes', () async {
    final ds = ContactsLocalDataSource();
    final emissions = <int>[];
    final sub = ds.watchAll().listen((items) => emissions.add(items.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ci('u1', ContactStatus.accepted));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ci('u2', ContactStatus.incoming));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });
}
