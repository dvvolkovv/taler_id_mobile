import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/notifications/models/captured_notification.dart';
import 'package:taler_id_mobile/features/notifications/notification_filter.dart';
import 'package:taler_id_mobile/features/notifications/notification_permission_service.dart';
import 'package:taler_id_mobile/features/notifications/notification_platform.dart';

class FakeNotificationPlatform implements NotificationPlatform {
  final List<bool> isGrantedQueue = [];
  bool fallbackGranted = false;
  int isGrantedCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<bool> isNotificationAccessGranted() async {
    isGrantedCalls++;
    if (isGrantedQueue.isNotEmpty) return isGrantedQueue.removeAt(0);
    return fallbackGranted;
  }

  @override
  Future<void> openNotificationAccessSettings() async {
    openSettingsCalls++;
  }

  @override
  Future<List<CapturedNotification>> getRecent(NotificationFilter filter) async =>
      const [];

  @override
  Future<Map<String, dynamic>> reply({
    required String key,
    required String text,
  }) async =>
      const {'ok': true};

  @override
  Stream<CapturedNotification> get notificationStream =>
      const Stream<CapturedNotification>.empty();
}

void main() {
  late FakeNotificationPlatform platform;
  late NotificationPermissionService service;

  setUp(() {
    platform = FakeNotificationPlatform();
    service = NotificationPermissionService(platform);
  });

  tearDown(() async {
    await service.dispose();
  });

  test('isGranted forwards to the platform', () async {
    platform.fallbackGranted = true;
    expect(await service.isGranted(), isTrue);

    platform.fallbackGranted = false;
    expect(await service.isGranted(), isFalse);

    expect(platform.isGrantedCalls, 2);
  });

  test('openSettings forwards to the platform', () async {
    await service.openSettings();
    expect(platform.openSettingsCalls, 1);
  });

  test('refresh re-polls the platform and emits the new value on watch()',
      () async {
    platform.fallbackGranted = false;

    final received = <bool>[];
    final sub = service.watch().listen(received.add);

    // First refresh — false.
    await service.refresh();
    // Flip and refresh again — true.
    platform.fallbackGranted = true;
    await service.refresh();

    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(received, [false, true]);
    expect(platform.isGrantedCalls, greaterThanOrEqualTo(2));
  });

  test('watch() de-duplicates consecutive identical values', () async {
    platform.fallbackGranted = false;
    final received = <bool>[];
    final sub = service.watch().listen(received.add);

    await service.refresh();
    await service.refresh();
    await service.refresh();

    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(received, [false]); // identical -> emitted once
  });

  test('current returns last polled value, null before first poll', () async {
    expect(service.current, isNull);

    platform.fallbackGranted = true;
    await service.refresh();
    expect(service.current, isTrue);
  });
}
