import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_code.dart';

void main() {
  group('codeFromScan', () {
    test('accepts a valid link', () {
      expect(codeFromScan('talerid://interp/ABC123'), 'ABC123');
    });

    test('tolerates a trailing slash', () {
      expect(codeFromScan('talerid://interp/ABC123/'), 'ABC123');
    });

    test('accepts an uppercase scheme/host, preserving the code case', () {
      expect(codeFromScan('TALERID://INTERP/AbC123'), 'AbC123');
    });

    test('mixed-case scheme/host also accepted', () {
      expect(codeFromScan('TalerId://Interp/code1'), 'code1');
    });

    test('rejects a different talerid:// path', () {
      expect(codeFromScan('talerid://user/x'), isNull);
    });

    test('rejects an https URL', () {
      expect(codeFromScan('https://talerid.io/interp/ABC123'), isNull);
    });

    test('rejects an empty string', () {
      expect(codeFromScan(''), isNull);
    });

    test('rejects a non-URI string', () {
      expect(codeFromScan('not a uri at all'), isNull);
    });

    test('rejects a link with no code segment', () {
      expect(codeFromScan('talerid://interp/'), isNull);
    });

    test('rejects a link with extra path segments', () {
      expect(codeFromScan('talerid://interp/ABC123/extra'), isNull);
    });
  });

  group('interpreterLink', () {
    test('builds the deep link for a code', () {
      expect(interpreterLink('ABC123'), 'talerid://interp/ABC123');
    });
  });
}
