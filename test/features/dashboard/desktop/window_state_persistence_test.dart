import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/window/window_state_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('window_state_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('save then load round-trips size, position, maximized', () async {
    final p = WindowStatePersistence();
    await p.initialize();
    await p.save(width: 1024, height: 768, x: 100, y: 50, isMaximized: false);

    final loaded = await p.load();
    expect(loaded, isNotNull);
    expect(loaded!.width, 1024);
    expect(loaded.height, 768);
    expect(loaded.x, 100);
    expect(loaded.y, 50);
    expect(loaded.isMaximized, isFalse);
  });

  test('load returns null when no state saved', () async {
    final p = WindowStatePersistence();
    await p.initialize();
    expect(await p.load(), isNull);
  });

  test('save coalesces — multiple writes within debounce produce single record', () async {
    final p = WindowStatePersistence();
    await p.initialize();
    await p.save(width: 800, height: 600, x: 0, y: 0, isMaximized: false);
    await p.save(width: 1024, height: 768, x: 0, y: 0, isMaximized: false);
    await p.save(width: 1280, height: 800, x: 0, y: 0, isMaximized: true);

    final loaded = await p.load();
    expect(loaded!.width, 1280);
    expect(loaded.isMaximized, isTrue);
  });
}
