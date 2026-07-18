import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/presentation/widgets/assistant_nav_bar.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

class _MockMessengerBloc extends MockBloc<MessengerEvent, MessengerState>
    implements MessengerBloc {}

Widget _wrap(MessengerBloc bloc) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<MessengerBloc>.value(
      value: bloc,
      child: const Scaffold(body: AssistantNavBar()),
    ),
  );
}

void main() {
  const sectionIcons = [
    Icons.chat_bubble_outline_rounded, // Messenger
    Icons.call_outlined, // Calls
    Icons.calendar_month_outlined, // Calendar
    Icons.sticky_note_2_outlined, // Notes
    Icons.people_outline, // Contacts
    Icons.person_outline, // Profile
    Icons.settings_outlined, // Settings
  ];

  testWidgets('renders 7 section icons without badges when counts are zero',
      (tester) async {
    final bloc = _MockMessengerBloc();
    whenListen(
      bloc,
      const Stream<MessengerState>.empty(),
      initialState: const MessengerState(),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    for (final icon in sectionIcons) {
      expect(find.byIcon(icon), findsOneWidget);
    }
    expect(find.byType(Tooltip), findsNWidgets(7));
    // No badge numbers when everything is zero.
    expect(find.text('1'), findsNothing);
  });

  testWidgets('shows badge counts when missed calls / pending items > 0',
      (tester) async {
    final bloc = _MockMessengerBloc();
    whenListen(
      bloc,
      const Stream<MessengerState>.empty(),
      initialState: const MessengerState(
        missedCallsCount: 3,
        pendingCalendarInvites: 1,
        pendingContactRequests: 2,
      ),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    // Calls badge.
    expect(find.text('3'), findsOneWidget);
    // Calendar badge.
    expect(find.text('1'), findsOneWidget);
    // Contacts badge (2) — pendingContacts also feeds the Messenger badge
    // (unread 0 + pending 2), so "2" appears twice.
    expect(find.text('2'), findsNWidgets(2));
  });
}
