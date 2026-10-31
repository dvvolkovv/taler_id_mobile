import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/domain/rotation_lock_arg.dart';

void main() {
  test('booleans pass through', () {
    expect(parseRotationLockArg(true), isTrue);
    expect(parseRotationLockArg(false), isFalse);
  });

  test('their string forms are accepted', () {
    expect(parseRotationLockArg('true'), isTrue);
    expect(parseRotationLockArg('false'), isFalse);
  });

  test('anything else is refused, never read as unlock', () {
    for (final raw in <Object?>[null, 1, 0, 'yes', 'TRUE', '', <String>[]]) {
      expect(parseRotationLockArg(raw), isNull, reason: '$raw');
    }
  });
}
