// Regression cover for the 2026-07-27 audit finding: the PIN retry counter
// lived in widget State, so killing and reopening the app handed the next five
// guesses back — against a 4-digit PIN, i.e. 10 000 values.

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/secure_storage.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';

class _MemStorage implements SecureStorage {
  final Map<String, String> data = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<void> deleteAll() async => data.clear();
}

void main() {
  late _MemStorage mem;
  late SecureStorageService service;

  setUp(() {
    mem = _MemStorage();
    SecureStorage.debugInstance = mem;
    service = SecureStorageService();
  });

  tearDown(SecureStorage.debugResetForTest);

  test('starts at zero', () async {
    expect(await service.getPinAttempts(), 0);
  });

  test('counts each failure and persists it', () async {
    expect(await service.incrementPinAttempts(), 1);
    expect(await service.incrementPinAttempts(), 2);

    // Survives a "restart": a fresh service over the same storage.
    expect(await SecureStorageService().getPinAttempts(), 2);
    expect(mem.data[ApiConstants.pinAttemptsKey], '2');
  });

  test('a correct PIN clears the counter', () async {
    await service.incrementPinAttempts();
    await service.incrementPinAttempts();

    await service.resetPinAttempts();

    expect(await service.getPinAttempts(), 0);
    expect(mem.data.containsKey(ApiConstants.pinAttemptsKey), isFalse);
  });

  test('clearPin drops the counter along with the PIN', () async {
    await service.savePinHash('hash');
    await service.setPinEnabled(true);
    await service.incrementPinAttempts();

    await service.clearPin();

    expect(await service.getPinAttempts(), 0);
    expect(await service.getPinHash(), isNull);
    expect(await service.isPinEnabled, isFalse);
  });

  test('a corrupt stored value is treated as zero, not as a crash', () async {
    mem.data[ApiConstants.pinAttemptsKey] = 'not-a-number';

    expect(await service.getPinAttempts(), 0);
    expect(await service.incrementPinAttempts(), 1);
  });
}
