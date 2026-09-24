// test/core/platform/callkit_support_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/platform/callkit_support.dart';

void main() {
  test('a UUID-shaped room name is used as is', () {
    expect(toCallkitId('550e8400-e29b-41d4-a716-446655440000'),
        '550e8400-e29b-41d4-a716-446655440000');
  });

  test('call-<uuid> loses the prefix — the id the VoIP push path derives too', () {
    expect(toCallkitId('call-550e8400-e29b-41d4-a716-446655440000'),
        '550e8400-e29b-41d4-a716-446655440000');
  });

  test('fallback id is fixed — the FCM background isolate derives the same one', () {
    // VM String.hashCode is unseeded: same in every isolate, run, JIT and AOT.
    // A seeded hash (Object.hash/hashAll) would fail here, yet pass a
    // same-isolate or Isolate.run comparison.
    expect(toCallkitId('group-550e8400-e29b-41d4-a716-446655440000'),
        '00000000-0000-4000-8000-00003fd2cc79');
  });

  test('case is kept as given — callers lowercase for comparisons', () {
    expect(toCallkitId('550E8400-E29B-41D4-A716-446655440000'),
        '550E8400-E29B-41D4-A716-446655440000');
  });
}
