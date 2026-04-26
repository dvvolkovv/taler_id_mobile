import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/messenger/presentation/widgets/chat_transport_badge.dart';

void main() {
  group('ChatTransportBadge', () {
    testWidgets('renders server icon when connected', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.server,
          ),
        ),
      ));
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('renders mesh icon when offline fallback active', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.mesh,
          ),
        ),
      ));
      expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
    });

    testWidgets('renders warning icon when queued', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.queued,
          ),
        ),
      ));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });

  group('ChatTransportBadge group state (Phase 2)', () {
    testWidgets('renders "3/5" when state is meshGroup with counts',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(
            state: TransportBadgeState.meshGroup,
            visibleCount: 3,
            totalCount: 5,
          ),
        ),
      ));
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('1:1 mesh state does not show counts',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChatTransportBadge(state: TransportBadgeState.mesh),
        ),
      ));
      expect(find.textContaining('/'), findsNothing);
    });
  });
}
