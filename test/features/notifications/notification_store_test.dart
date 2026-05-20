import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/notifications/models/captured_notification.dart';
import 'package:taler_id_mobile/features/notifications/notification_filter.dart';
import 'package:taler_id_mobile/features/notifications/notification_platform.dart';
import 'package:taler_id_mobile/features/notifications/notification_store.dart';

/// Hand-rolled fake — simpler than Mocktail for this surface and easier to
/// read. Tracks the last reply args and lets each test pre-seed the
/// `getRecent` response and the `reply` outcome.
class FakeNotificationPlatform implements NotificationPlatform {
  final StreamController<CapturedNotification> _controller =
      StreamController<CapturedNotification>.broadcast();

  bool granted = true;
  bool openSettingsCalled = false;

  List<CapturedNotification> nextRecentResponse = const [];
  NotificationFilter? lastRecentFilter;

  Map<String, dynamic> nextReplyResponse = const {'ok': true};
  Map<String, String>? lastReplyArgs;

  @override
  Future<bool> isNotificationAccessGranted() async => granted;

  @override
  Future<void> openNotificationAccessSettings() async {
    openSettingsCalled = true;
  }

  @override
  Future<List<CapturedNotification>> getRecent(NotificationFilter filter) async {
    lastRecentFilter = filter;
    return nextRecentResponse;
  }

  @override
  Future<Map<String, dynamic>> reply({
    required String key,
    required String text,
  }) async {
    lastReplyArgs = {'key': key, 'text': text};
    return nextReplyResponse;
  }

  @override
  Stream<CapturedNotification> get notificationStream => _controller.stream;

  void emit(CapturedNotification n) => _controller.add(n);

  Future<void> close() => _controller.close();
}

CapturedNotification _make({
  required String key,
  String packageName = 'com.whatsapp',
  String title = 'Маша',
  String body = 'привет',
  String? conversationTitle,
  DateTime? postedAt,
  bool canReply = true,
}) {
  return CapturedNotification(
    packageName: packageName,
    key: key,
    title: title,
    body: body,
    conversationTitle: conversationTitle,
    postedAt: postedAt ?? DateTime.now(),
    canReply: canReply,
  );
}

void main() {
  late FakeNotificationPlatform platform;
  late NotificationStore store;

  setUp(() {
    platform = FakeNotificationPlatform();
    store = NotificationStore(platform);
  });

  tearDown(() async {
    await store.dispose();
    await platform.close();
  });

  test('constructor subscribes to event stream — emitted events enter cache', () async {
    final n = _make(key: 'k1');
    platform.emit(n);
    // Let the broadcast stream micro-task settle.
    await Future<void>.delayed(Duration.zero);

    expect(store.debugCache, hasLength(1));
    expect(store.debugCache.first.key, 'k1');
  });

  test('recent forwards the filter to the native platform', () async {
    const filter = NotificationFilter(app: 'whatsapp');
    platform.nextRecentResponse = [
      _make(key: 'a', packageName: 'com.whatsapp'),
    ];

    final result = await store.recent(filter);

    expect(platform.lastRecentFilter, filter);
    expect(result, hasLength(1));
    expect(result.first.packageName, 'com.whatsapp');
  });

  test('recent with sender filter forwards to native (native does matching)',
      () async {
    const filter = NotificationFilter(sender: 'Маша');
    platform.nextRecentResponse = [
      _make(key: 'a', title: 'Маша', body: 'hi'),
    ];

    final result = await store.recent(filter);

    expect(platform.lastRecentFilter?.sender, 'Маша');
    expect(result, hasLength(1));
  });

  test('recent with sinceMinutes forwards window — native excludes older', () async {
    const filter = NotificationFilter(sinceMinutes: 10);
    final fresh = _make(
      key: 'fresh',
      postedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );
    platform.nextRecentResponse = [fresh];

    final result = await store.recent(filter);

    expect(platform.lastRecentFilter?.sinceMinutes, 10);
    expect(result.map((n) => n.key), ['fresh']);
  });

  test('recent with limit forwards limit — native truncates', () async {
    const filter = NotificationFilter(limit: 5);
    platform.nextRecentResponse = List.generate(5, (i) => _make(key: 'k$i'));

    final result = await store.recent(filter);

    expect(platform.lastRecentFilter?.limit, 5);
    expect(result, hasLength(5));
  });

  test('replyOnKey forwards args to platform and returns normally on ok:true',
      () async {
    platform.emit(_make(key: 'k1'));
    await Future<void>.delayed(Duration.zero);

    await store.replyOnKey('k1', 'hi');

    expect(platform.lastReplyArgs, {'key': 'k1', 'text': 'hi'});
  });

  test('replyOnKey throws NotificationReplyException on {ok:false, error:x}',
      () async {
    platform.emit(_make(key: 'k1'));
    await Future<void>.delayed(Duration.zero);
    platform.nextReplyResponse = const {'ok': false, 'error': 'no_reply_action'};

    expect(
      () => store.replyOnKey('k1', 'hi'),
      throwsA(
        isA<NotificationReplyException>()
            .having((e) => e.error, 'error', 'no_reply_action'),
      ),
    );
  });

  test('replyOnKey error message is reflected in the exception text', () async {
    platform.nextReplyResponse = const {
      'ok': false,
      'error': 'pending_intent_failed',
      'message': 'CanceledException',
    };

    expect(
      () => store.replyOnKey('unknown', 'hi'),
      throwsA(
        isA<NotificationReplyException>()
            .having((e) => e.toString(), 'toString',
                contains('pending_intent_failed'))
            .having((e) => e.toString(), 'toString',
                contains('CanceledException')),
      ),
    );
  });

  test('replyOnKey on unknown key still forwards to native (defensive)', () async {
    // No emit — cache is empty, key is "unknown" from Dart's perspective.
    await store.replyOnKey('mystery-key', 'hi');

    expect(platform.lastReplyArgs, {'key': 'mystery-key', 'text': 'hi'});
  });

  test('cache is capped at 50 entries (oldest evicted first)', () async {
    for (var i = 0; i < 55; i++) {
      platform.emit(_make(key: 'k$i'));
    }
    await Future<void>.delayed(Duration.zero);

    expect(store.debugCache, hasLength(50));
    expect(store.debugCache.first.key, 'k5');
    expect(store.debugCache.last.key, 'k54');
  });

  test('stream getter re-publishes events to outside subscribers', () async {
    final received = <String>[];
    final sub = store.stream.listen((n) => received.add(n.key));

    platform.emit(_make(key: 'a'));
    platform.emit(_make(key: 'b'));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(received, ['a', 'b']);
  });
}
