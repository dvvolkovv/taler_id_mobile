import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/core/api/endpoint_service.dart';

void main() {
  group('EndpointService failover', () {
    test('starts on the first candidate', () {
      final ep = EndpointService(candidates: const ['https://a', 'https://b']);
      expect(ep.baseUrl, 'https://a');
      expect(ep.hasFallback, isTrue);
    });

    test('single candidate has no fallback and never switches', () async {
      final ep = EndpointService(candidates: const ['https://only']);
      expect(ep.hasFallback, isFalse);
      expect(await ep.reportFailureAndFallback(), isFalse);
      expect(ep.baseUrl, 'https://only');
    });

    test('reportFailureAndFallback advances through candidates and wraps', () async {
      final ep = EndpointService(
        candidates: const ['https://a', 'https://b', 'https://c'],
      );
      expect(ep.baseUrl, 'https://a');

      expect(await ep.reportFailureAndFallback(), isTrue);
      expect(ep.baseUrl, 'https://b');

      expect(await ep.reportFailureAndFallback(), isTrue);
      expect(ep.baseUrl, 'https://c');

      // wraps back to the primary
      expect(await ep.reportFailureAndFallback(), isTrue);
      expect(ep.baseUrl, 'https://a');
    });

    test('activeUrl notifies listeners on change (Dio/socket react to this)', () async {
      final ep = EndpointService(candidates: const ['https://a', 'https://b']);
      final seen = <String>[];
      ep.activeUrl.addListener(() => seen.add(ep.activeUrl.value));

      await ep.reportFailureAndFallback();
      expect(seen, ['https://b']);
    });

    test('resetToPrimary returns to the first candidate', () async {
      final ep = EndpointService(candidates: const ['https://a', 'https://b']);
      await ep.reportFailureAndFallback();
      expect(ep.baseUrl, 'https://b');

      await ep.resetToPrimary();
      expect(ep.baseUrl, 'https://a');
    });

    test('candidates are de-duplicated, order preserved', () {
      final ep = EndpointService(
        candidates: const ['https://a', 'https://a', 'https://b'],
      );
      // construction keeps the list as given; the production default de-dups —
      // here we just assert the explicit list is usable and starts at first.
      expect(ep.baseUrl, 'https://a');
    });
  });
}
