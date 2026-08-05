import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/di/service_locator.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/desktop_shell.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';

class _MockMessengerBloc extends MockBloc<MessengerEvent, MessengerState>
    implements MessengerBloc {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockMessengerRemoteDataSource extends Mock
    implements MessengerRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConnectMessenger('fallback'));
  });

  late _MockMessengerBloc bloc;
  late _MockSecureStorageService storage;
  late _MockMessengerRemoteDataSource remote;
  late StreamController<String> disconnectCtrl;

  setUp(() async {
    await sl.reset();
    bloc = _MockMessengerBloc();
    storage = _MockSecureStorageService();
    remote = _MockMessengerRemoteDataSource();
    disconnectCtrl = StreamController<String>.broadcast();

    when(() => bloc.state).thenReturn(const MessengerState());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => storage.getAccessToken()).thenAnswer((_) async => 'token');
    when(() => storage.getUserId()).thenAnswer((_) async => 'user-1');
    when(() => remote.disconnectStream)
        .thenAnswer((_) => disconnectCtrl.stream);
    when(() => remote.isSocketConnected).thenReturn(false);

    sl.registerSingleton<SecureStorageService>(storage);
    sl.registerSingleton<MessengerRemoteDataSource>(remote);
  });

  tearDown(() async {
    await disconnectCtrl.close();
    await sl.reset();
  });

  testWidgets('DesktopShell reconnects messenger after socket disconnect',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<MessengerBloc>.value(
          value: bloc,
          child: const DesktopShell(
            currentRoute: RouteConstants.messenger,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    await tester.pump();
    verify(() => bloc.add(const ConnectMessenger('token', userId: 'user-1')))
        .called(1);

    disconnectCtrl.add('transport close');
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    verify(() => bloc.add(const ConnectMessenger('token', userId: 'user-1')))
        .called(1);
  });
}
