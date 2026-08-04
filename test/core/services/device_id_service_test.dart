import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/services/device_id_service.dart';

class _FakeStore implements DeviceIdStore {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String v) async {
    value = v;
    writes++;
  }
}

class _ThrowingStore implements DeviceIdStore {
  @override
  Future<String?> read() async => throw StateError('keychain locked');

  @override
  Future<void> write(String v) async => throw StateError('keychain locked');
}

void main() {
  test('generates once and keeps the same id across restarts', () async {
    final store = _FakeStore();

    final first = DeviceIdService(store);
    await first.init();
    final id = first.deviceId;

    expect(id, isNotEmpty);
    expect(store.writes, 1);

    final second = DeviceIdService(store);
    await second.init();

    expect(second.deviceId, id);
    expect(store.writes, 1);
  });

  test('treats a blank stored value as absent', () async {
    final store = _FakeStore()..value = '';

    final service = DeviceIdService(store);
    await service.init();

    expect(service.deviceId, isNotEmpty);
    expect(store.writes, 1);
  });

  // Идентификатор — удобство, а не условие работы. Если хранилище недоступно,
  // приложение должно логиниться как раньше, а не отказываться стартовать.
  test('stays empty rather than throwing when storage is unavailable',
      () async {
    final service = DeviceIdService(_ThrowingStore());

    await service.init();

    expect(service.deviceId, isEmpty);
  });
}
