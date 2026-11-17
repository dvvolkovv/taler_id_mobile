// Regression (2026-11-17): the "Account sign-in" notification was tapped the
// morning after the request was made. The request lives ten minutes, so both
// "Yes, allow" and "This wasn't me" got 404, and the screen printed the raw
// server text "Approval request not found" — no hint what happened, no way out
// but the back button.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/core/api/dio_client.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:taler_id_mobile/features/auth/presentation/screens/device_approval_request_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements DioClient {}

class _StubRemote extends AuthRemoteDataSource {
  _StubRemote({this.error}) : super(_MockDio());

  final ApiException? error;
  final calls = <String>[];

  @override
  Future<void> approveDevice(String approvalId) async {
    calls.add('approve $approvalId');
    if (error != null) throw error!;
  }

  @override
  Future<void> rejectDevice(String approvalId) async {
    calls.add('reject $approvalId');
    if (error != null) throw error!;
  }
}

const _notFound = ApiException(
  statusCode: 404,
  message: 'Approval request not found',
);

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

// The desktop scaffold (the test host is a Mac) animates its background
// forever, so pumpAndSettle never settles. The stubbed calls resolve in
// microtasks — two frames are enough for the answer to reach the screen.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

DeviceApprovalRequestScreen _screen({DateTime? expiresAt}) =>
    DeviceApprovalRequestScreen(
      approvalId: 'appr-1',
      deviceInfo: 'Pixel',
      ip: '1.2.3.4',
      location: '',
      expiresAt: expiresAt,
    );

void main() {
  late _StubRemote remote;

  Future<void> useRemote(_StubRemote r) async {
    remote = r;
    await sl.reset();
    sl.registerSingleton<AuthRemoteDataSource>(r);
  }

  tearDown(() => sl.reset());

  testWidgets('a request past its deadline says so instead of offering buttons',
      (tester) async {
    await useRemote(_StubRemote());
    await tester.pumpWidget(_wrap(_screen(
      expiresAt: DateTime.now().subtract(const Duration(hours: 10)),
    )));

    expect(find.text('This request is no longer valid'), findsOneWidget);
    expect(find.text('Yes, allow'), findsNothing);
    expect(find.text("This wasn't me"), findsNothing);
    expect(remote.calls, isEmpty);
  });

  for (final button in ['Yes, allow', "This wasn't me"]) {
    testWidgets('a 404 on "$button" reads as "no longer valid", not raw text',
        (tester) async {
      await useRemote(_StubRemote(error: _notFound));
      await tester.pumpWidget(_wrap(_screen()));

      await tester.tap(find.text(button));
      await _settle(tester);

      expect(find.text('This request is no longer valid'), findsOneWidget);
      expect(find.text('Approval request not found'), findsNothing);
    });
  }

  testWidgets('a live request still goes to the server', (tester) async {
    await useRemote(_StubRemote());
    await tester.pumpWidget(_wrap(_screen(
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    )));

    await tester.tap(find.text('Yes, allow'));
    await _settle(tester);

    expect(remote.calls, ['approve appr-1']);
    expect(find.text('Sign-in allowed'), findsOneWidget);
  });

  testWidgets('other server errors are still shown as they are',
      (tester) async {
    await useRemote(_StubRemote(
      error: const ApiException(statusCode: 400, message: 'Bad thing'),
    ));
    await tester.pumpWidget(_wrap(_screen()));

    await tester.tap(find.text('Yes, allow'));
    await _settle(tester);

    expect(find.text('Bad thing'), findsOneWidget);
    expect(find.text('This request is no longer valid'), findsNothing);
  });
}
