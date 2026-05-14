import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/saved_conversation_id_cache.dart';

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
    tempDir = await Directory.systemTemp.createTemp('saved_conv_id_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(SavedConversationIdCache.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('read returns null when no id stored', () async {
    final cache = SavedConversationIdCache();
    expect(await cache.read(), isNull);
  });

  test('write then read returns the same value', () async {
    final cache = SavedConversationIdCache();
    await cache.write('conv-xyz');
    expect(await cache.read(), 'conv-xyz');
  });

  test('clear removes the value', () async {
    final cache = SavedConversationIdCache();
    await cache.write('conv-xyz');
    await cache.clear();
    expect(await cache.read(), isNull);
  });
}
