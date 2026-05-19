import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/secure_storage.dart';
import 'package:taler_id_mobile/features/auth/desktop/controllers/onboarding_progress.dart';

class _MemSecure implements SecureStorage {
  final _data = <String, String>{};
  @override Future<void> initialize() async {}
  @override Future<String?> read(String key) async => _data[key];
  @override Future<void> write(String key, String value) async => _data[key] = value;
  @override Future<void> delete(String key) async => _data.remove(key);
  @override Future<void> deleteAll() async => _data.clear();
}

void main() {
  setUp(() {
    SecureStorage.debugResetForTest();
    SecureStorage.debugInstance = _MemSecure();
  });

  tearDown(() => SecureStorage.debugResetForTest());

  test('getStep returns 0 when nothing saved', () async {
    expect(await OnboardingProgress.getStep(), 0);
  });

  test('saveStep(1) then getStep returns 1', () async {
    await OnboardingProgress.saveStep(1);
    expect(await OnboardingProgress.getStep(), 1);
  });

  test('saveStep(2) then getStep returns 2', () async {
    await OnboardingProgress.saveStep(2);
    expect(await OnboardingProgress.getStep(), 2);
  });

  test('clear() returns getStep to 0', () async {
    await OnboardingProgress.saveStep(2);
    await OnboardingProgress.clear();
    expect(await OnboardingProgress.getStep(), 0);
  });

  test('corrupt non-integer value returns 0', () async {
    await SecureStorage.instance.write('onboarding_step_desktop', 'not_a_number');
    expect(await OnboardingProgress.getStep(), 0);
  });
}
