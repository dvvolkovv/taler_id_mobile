import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/theme/theme_mode_storage.dart';
import 'package:taler_id_mobile/core/platform/secure_storage.dart';

class _MemSecure implements SecureStorage {
  final _data = <String, String>{};
  @override Future<void> initialize() async {}
  @override Future<String?> read(String key) async => _data[key];
  @override Future<void> write(String key, String value) async => _data[key] = value;
  @override Future<void> delete(String key) async => _data.remove(key);
  @override Future<void> deleteAll() async => _data.clear();
}

void main() {
  test('default is system when nothing saved', () async {
    final s = ThemeModeStorage(storage: _MemSecure());
    expect(await s.load(), ThemeMode.system);
  });

  test('save then load round-trips dark', () async {
    final fake = _MemSecure();
    final s = ThemeModeStorage(storage: fake);
    await s.save(ThemeMode.dark);
    expect(await s.load(), ThemeMode.dark);
  });

  test('save then load round-trips light', () async {
    final fake = _MemSecure();
    final s = ThemeModeStorage(storage: fake);
    await s.save(ThemeMode.light);
    expect(await s.load(), ThemeMode.light);
  });

  test('unknown stored value falls back to system', () async {
    final fake = _MemSecure();
    await fake.write('theme_mode', 'unknown_value');
    final s = ThemeModeStorage(storage: fake);
    expect(await s.load(), ThemeMode.system);
  });
}
