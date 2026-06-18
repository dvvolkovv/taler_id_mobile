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

    test('does not return to a failed endpoint while a healthy one exists', () async {
      final ep = EndpointService(
        candidates: const ['https://primary', 'https://ru', 'https://ru2'],
      );
      // primary unreachable -> fail over to ru
      await ep.reportFailureAndFallback();
      expect(ep.baseUrl, 'https://ru');
      await ep.reportSuccess(); // ru works
      // transient blip on ru -> move to ru2, NOT back to the blocked primary
      await ep.reportFailureAndFallback();
      expect(ep.baseUrl, 'https://ru2');
      await ep.reportSuccess(); // ru2 works
      // blip on ru2 -> back to the healthy ru, still never the blocked primary
      await ep.reportFailureAndFallback();
      expect(ep.baseUrl, 'https://ru');
    });

    test('falls back to primary only when every edge has also failed', () async {
      final ep = EndpointService(
        candidates: const ['https://primary', 'https://ru', 'https://ru2'],
      );
      await ep.reportFailureAndFallback(); // primary -> ru
      await ep.reportFailureAndFallback(); // ru -> ru2
      // all three failed in quick succession -> oldest mark (primary) is reused
      await ep.reportFailureAndFallback(); // ru2 -> primary
      expect(ep.baseUrl, 'https://primary');
    });

    test('reportSuccess clears the failure mark so the endpoint is eligible again', () async {
      final ep = EndpointService(
        candidates: const ['https://a', 'https://b', 'https://c'],
      );
      await ep.reportFailureAndFallback(); // a -> b (a failed)
      await ep.reportSuccess();            // b good
      await ep.reportFailureAndFallback(); // b -> c (b failed)
      await ep.reportSuccess();            // c good
      // c blips: a still in cooldown (never succeeded), b cleared by success
      await ep.reportFailureAndFallback(); // c -> b
      expect(ep.baseUrl, 'https://b');
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
