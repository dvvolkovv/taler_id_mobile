import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/services/call_orientation_service.dart';
import 'package:taler_id_mobile/core/services/call_state_service.dart';
import 'package:taler_id_mobile/core/services/video_effects_service.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/theme/app_theme.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/voice/presentation/screens/voice_call_screen.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

// Returning to a call through the dashboard's "return to call" banner:
// the banner does context.go('/dashboard/voice?room=R&convId=C') for the
// line it shows, and /dashboard/voice is a top-level route, so the call
// screen opens as the only page on the stack.

class _MockRoom extends Mock implements lk.Room {
  final _emitter = lk.EventsEmitter<lk.RoomEvent>();

  @override
  lk.ConnectionState get connectionState => lk.ConnectionState.connected;

  @override
  UnmodifiableMapView<String, lk.RemoteParticipant> get remoteParticipants =>
      UnmodifiableMapView(<String, lk.RemoteParticipant>{});

  @override
  lk.EventsListener<lk.RoomEvent> createListener({bool synchronized = false}) =>
      lk.EventsListener<lk.RoomEvent>(_emitter, synchronized: synchronized);
}

class _MockMessenger extends Mock implements MessengerRemoteDataSource {}

class _MockStorage extends Mock implements SecureStorageService {}

const _room = 'room-x';
const _conv = 'conv-1';

GoRouter _router() => GoRouter(
      initialLocation: '/dashboard/messenger',
      routes: [
        GoRoute(
          path: '/dashboard/messenger',
          builder: (_, __) => const Scaffold(body: Text('messenger')),
        ),
        // Same shape as RouteConstants.voice in app_router.dart.
        GoRoute(
          path: '/dashboard/voice',
          builder: (_, state) => VoiceCallScreen(
            roomName: state.uri.queryParameters['room'],
            conversationId: state.uri.queryParameters['convId'],
          ),
        ),
      ],
    );

Future<void> _openFromBanner(WidgetTester tester, GoRouter router, String location) async {
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ru'),
  ));
  await tester.pump();
  router.go(location);
  // Several frames: _initCall runs after initState and schedules its own
  // post-frame work.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.allMessagesHandler =
        (String channel, MessageHandler? handler, ByteData? message) async {
      if (handler != null) return handler(message);
      // Framework channels (flutter/platform etc.) keep the test engine's
      // own answers; only plugin channels get a canned "ok".
      if (channel.startsWith('flutter/')) {
        return binding.defaultBinaryMessenger.delegate.send(channel, message);
      }
      if (channel.startsWith('dev.flutter.pigeon.')) {
        return const StandardMessageCodec().encodeMessage(<Object?>[null]);
      }
      return const StandardMethodCodec().encodeSuccessEnvelope(null);
    };

    final messenger = _MockMessenger();
    when(() => messenger.callEndedStream).thenAnswer((_) => const Stream.empty());
    when(() => messenger.callAiTwinOfferStream).thenAnswer((_) => const Stream.empty());
    when(() => messenger.callAiTwinJoinedStream).thenAnswer((_) => const Stream.empty());
    when(() => messenger.callAiTwinLeftStream).thenAnswer((_) => const Stream.empty());
    final storage = _MockStorage();
    when(() => storage.read(any())).thenAnswer((_) async => null);

    sl.registerSingleton<CallOrientationService>(
        CallOrientationService(isSupported: false, isIOS: false));
    sl.registerSingleton<MessengerRemoteDataSource>(messenger);
    sl.registerSingleton<SecureStorageService>(storage);
    sl.registerSingleton<VideoEffectsService>(VideoEffectsService());

    await CallStateService.instance.endCall();
    final room = _MockRoom();
    when(() => room.disconnect()).thenAnswer((_) async {});
    CallStateService.instance.setRoom(room, _room, _conv);
  });

  tearDown(() async {
    await CallStateService.instance.endCall();
    await sl.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.allMessagesHandler = null;
  });

  testWidgets('banner return without a conversation id resumes the call', (tester) async {
    final router = _router();
    await _openFromBanner(tester, router, '/dashboard/voice?room=$_room');

    expect(find.byType(VoiceCallScreen), findsOneWidget);
    expect(find.text('Подключение...'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('banner return to a 1:1 call resumes the call', (tester) async {
    final router = _router();
    await _openFromBanner(tester, router, '/dashboard/voice?room=$_room&convId=$_conv');

    expect(find.byType(VoiceCallScreen), findsOneWidget);
    expect(find.text('Подключение...'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
