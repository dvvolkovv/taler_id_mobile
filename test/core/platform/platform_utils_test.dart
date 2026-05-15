// test/core/platform/platform_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final p = PlatformUtils.instance;
  test('platform partition is exclusive', () {
    final flags = [p.isWeb, p.isMobile, p.isDesktop];
    expect(flags.where((f) => f).length, equals(1));
  });

  test('hostOs is non-empty and not unknown', () {
    expect(p.hostOs.isNotEmpty, isTrue);
    expect(p.hostOs, isNot('unknown'));
  });
}
