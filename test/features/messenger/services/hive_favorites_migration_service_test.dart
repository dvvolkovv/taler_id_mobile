import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:taler_id_mobile/features/messenger/services/hive_favorites_migration_service.dart';

class _FakeStorage implements SecureStorageService {
  final Map<String, String> _kv = {};

  @override
  Future<String?> read(String key) async => _kv[key];

  @override
  Future<void> write(String key, String value) async {
    _kv[key] = value;
  }

  // Stubs for other abstract methods — not used in tests
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRepo extends Mock implements IMessengerRepository {}

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

void main() {
  late _FakeStorage storage;
  late _MockRepo repo;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    storage = _FakeStorage();
    repo = _MockRepo();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('skips if flag already set', () async {
    await storage.write('saved_migrated_v1', 'true');
    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();
    verifyNever(() => repo.getOrCreateSavedConversation());
  });

  test('no Hive box → marks flag, no sends', () async {
    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();
    expect(await storage.read('saved_migrated_v1'), 'true');
    verifyNever(() => repo.getOrCreateSavedConversation());
  });

  test('empty Hive box → deletes box, marks flag, no sends', () async {
    final box = await Hive.openBox<Map>('saved_messages');
    await box.close();
    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();
    expect(await storage.read('saved_migrated_v1'), 'true');
    verifyNever(() => repo.getOrCreateSavedConversation());
    expect(await Hive.boxExists('saved_messages'), false);
  });

  test('non-empty box → migrates in chronological order, deletes box, sets flag',
      () async {
    final box = await Hive.openBox<Map>('saved_messages');
    await box.add({'content': 'B', 'savedAt': '2025-01-02T00:00:00Z'});
    await box.add({'content': 'A', 'savedAt': '2025-01-01T00:00:00Z'});
    await box.add({
      'content': 'C',
      'savedAt': '2025-01-03T00:00:00Z',
      'fileUrl': 'http://x',
      'fileName': 'f.png',
      'fileType': 'image',
      'fileSize': 100,
    });
    await box.close();

    when(() => repo.getOrCreateSavedConversation())
        .thenAnswer((_) async => 'saved-id');
    when(() => repo.sendMessage(
          any(),
          any(),
          fileUrl: any(named: 'fileUrl'),
          fileName: any(named: 'fileName'),
          fileType: any(named: 'fileType'),
          fileSize: any(named: 'fileSize'),
        )).thenReturn(null);

    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce();

    expect(await storage.read('saved_migrated_v1'), 'true');
    expect(await Hive.boxExists('saved_messages'), false);

    final captured = verify(() => repo.sendMessage(
          'saved-id',
          captureAny(),
          fileUrl: any(named: 'fileUrl'),
          fileName: any(named: 'fileName'),
          fileType: any(named: 'fileType'),
          fileSize: any(named: 'fileSize'),
        )).captured;
    expect(captured, ['A', 'B', 'C']);
  });

  test('sendMessage throws → flag NOT set, box NOT deleted', () async {
    final box = await Hive.openBox<Map>('saved_messages');
    await box.add({'content': 'test', 'savedAt': '2025-01-01T00:00:00Z'});
    await box.close();

    when(() => repo.getOrCreateSavedConversation())
        .thenAnswer((_) async => 'saved-id');
    when(() => repo.sendMessage(
          any(),
          any(),
          fileUrl: any(named: 'fileUrl'),
          fileName: any(named: 'fileName'),
          fileType: any(named: 'fileType'),
          fileSize: any(named: 'fileSize'),
        )).thenThrow(Exception('network'));

    final svc = HiveFavoritesMigrationService(repo: repo, storage: storage);
    await svc.runOnce(); // must not throw

    expect(await storage.read('saved_migrated_v1'), isNull);
    expect(await Hive.boxExists('saved_messages'), true);
  });
}
