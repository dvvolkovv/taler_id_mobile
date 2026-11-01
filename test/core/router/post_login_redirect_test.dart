import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/router/post_login_redirect.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:taler_id_mobile/features/interpreter/data/pending_interpreter_join.dart';
import 'package:taler_id_mobile/features/mail/domain/repositories/i_mail_repository.dart';
import 'package:taler_id_mobile/features/oauth/data/oauth_pending_request.dart';

class _MockOAuthPendingRequest extends Mock implements OAuthPendingRequest {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockMailRepository extends Mock implements IMailRepository {}

/// f3: `postLoginNavigate` consumed a pending face-to-face interpreter join
/// code regardless of platform, which on desktop would `context.go()` to
/// `/dashboard/interpreter/join/:code` — a route `app_router.dart` only
/// registers `if (PlatformUtils.instance.isMobile)`. `PlatformUtils.instance.
/// isMobile` has no fake/override hook in this codebase and is `false` under
/// `flutter test` on every host this repo builds on (same convention as
/// interpreter_entry_button_test.dart), so this test exercises exactly the
/// desktop path.
void main() {
  late _MockOAuthPendingRequest oauthPending;
  late PendingInterpreterJoin interpreterJoin;
  late _MockSecureStorageService storage;
  late _MockMailRepository mailRepo;

  setUp(() {
    oauthPending = _MockOAuthPendingRequest();
    interpreterJoin = PendingInterpreterJoin();
    storage = _MockSecureStorageService();
    mailRepo = _MockMailRepository();

    when(() => oauthPending.consume()).thenAnswer((_) async => null);
    when(() => storage.isOnboardingSeen).thenAnswer((_) async => true);
    when(() => storage.isMailSetupDismissed).thenAnswer((_) async => true);
    when(() => storage.isMailSetupConfirmed).thenAnswer((_) async => false);

    sl.registerSingleton<OAuthPendingRequest>(oauthPending);
    sl.registerSingleton<PendingInterpreterJoin>(interpreterJoin);
    sl.registerSingleton<SecureStorageService>(storage);
    sl.registerSingleton<IMailRepository>(mailRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
      'a pending interpreter join code is ignored on this (desktop) test '
      'host — falls through to the normal default route instead of the '
      'mobile-only join route', (tester) async {
    interpreterJoin.save('ABCD2345');

    String? landedOn;
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: RouteConstants.messenger,
          builder: (_, __) {
            landedOn = RouteConstants.messenger;
            return const SizedBox();
          },
        ),
        GoRoute(
          path: RouteConstants.interpreterJoin,
          builder: (_, state) {
            landedOn =
                '${RouteConstants.interpreter}/join/${state.pathParameters['code']}';
            return const SizedBox();
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final context = router.routerDelegate.navigatorKey.currentContext!;
    await postLoginNavigate(context);
    await tester.pumpAndSettle();

    expect(landedOn, RouteConstants.messenger);
  });
}
