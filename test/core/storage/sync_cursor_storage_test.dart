import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/sync_cursor_storage.dart';

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
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_cursor_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(SyncCursorStorage.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('read returns null when no cursor stored', () async {
    final storage = SyncCursorStorage();
    expect(await storage.read(), isNull);
  });

  test('write then read returns the same value', () async {
    final storage = SyncCursorStorage();
    await storage.write('2026-05-13T10:00:00.000Z|abc-uuid');
    expect(await storage.read(), '2026-05-13T10:00:00.000Z|abc-uuid');
  });

  test('overwrite replaces the previous cursor', () async {
    final storage = SyncCursorStorage();
    await storage.write('A');
    await storage.write('B');
    expect(await storage.read(), 'B');
  });
}
