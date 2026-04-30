import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taler_id_mobile/core/voice/mesh_prefs_service.dart';

void main() {
  late Directory tempDir;
  late MeshPrefsService prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_prefs_test_');
    Hive.init(tempDir.path);
    prefs = MeshPrefsService();
    await prefs.init();
  });

  tearDown(() async {
    await prefs.dispose();
    await Hive.deleteBoxFromDisk('mesh_prefs');
    await tempDir.delete(recursive: true);
  });

  group('MeshPrefsService', () {
    test('isOnboardingShown returns false initially', () async {
      expect(await prefs.isOnboardingShown(), isFalse);
    });

    test('markOnboardingShown then isOnboardingShown returns true', () async {
      await prefs.markOnboardingShown();
      expect(await prefs.isOnboardingShown(), isTrue);
    });

    test('flag persists across reopen', () async {
      await prefs.markOnboardingShown();
      await prefs.dispose();
      final prefs2 = MeshPrefsService();
      await prefs2.init();
      try {
        expect(await prefs2.isOnboardingShown(), isTrue);
      } finally {
        await prefs2.dispose();
      }
    });
  });
}
