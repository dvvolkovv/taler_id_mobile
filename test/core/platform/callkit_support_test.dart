import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/callkit_support.dart';

void main() {
  final uuidShape = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  test('a UUID-shaped room name is used as is', () {
    expect(toCallkitId('550e8400-e29b-41d4-a716-446655440000'),
        '550e8400-e29b-41d4-a716-446655440000');
  });

  test('call-<uuid> loses the prefix — the id the VoIP push path derives too', () {
    expect(toCallkitId('call-550e8400-e29b-41d4-a716-446655440000'),
        '550e8400-e29b-41d4-a716-446655440000');
  });

  test('any other name maps to a stable valid UUID', () {
    final a = toCallkitId('personal-c79530ed-36fc367a');
    expect(a, matches(uuidShape));
    expect(toCallkitId('personal-c79530ed-36fc367a'), a);
  });
}
