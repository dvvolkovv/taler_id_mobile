import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/sdk_reconnect_grace.dart';

/// Звонок 18.11.2026 на PROD: телефон собеседника перескакивал между Wi-Fi и
/// сотовой сетью, LiveKit каждый раз восстанавливал соединение за секунду, а
/// экран звонка через две секунды выходил из комнаты и входил заново — каждое
/// мигание сети превращалось в обрыв на несколько секунд со звуковым сигналом.
/// Экран читал `disconnected`, через которое LiveKit проходит, восстанавливая
/// соединение, как «LiveKit сдался».
///
/// Экран звонка в тесте не поднять, поэтому здесь закреплено само правило:
/// когда экрану пора браться за своё переподключение.
void main() {
  late int fired;
  late SdkReconnectGrace grace;

  void setUpGrace() {
    fired = 0;
    grace = SdkReconnectGrace(
      onExpired: () => fired++,
      grace: const Duration(seconds: 30),
    );
  }

  test('a resume that comes back in time never starts our own reconnect', () {
    fakeAsync((async) {
      setUpGrace();
      grace.disconnected();
      async.elapse(const Duration(seconds: 2));
      grace.cancel(); // снова connected

      async.elapse(const Duration(minutes: 1));
      expect(fired, 0);
    });
  });

  test('repeated disconnected reports do not restart the wait', () {
    fakeAsync((async) {
      setUpGrace();
      grace.disconnected();
      async.elapse(const Duration(seconds: 20));
      grace.disconnected(); // слушатель комнаты зовётся на каждое изменение
      async.elapse(const Duration(seconds: 11));

      expect(fired, 1);
    });
  });

  test('LiveKit gone quiet: our reconnect starts once the wait is over', () {
    fakeAsync((async) {
      setUpGrace();
      grace.disconnected();
      async.elapse(const Duration(seconds: 29));
      expect(fired, 0);

      async.elapse(const Duration(seconds: 2));
      expect(fired, 1);
      expect(grace.isArmed, isFalse);
    });
  });

  test('each new LiveKit attempt gives it a full wait again', () {
    fakeAsync((async) {
      setUpGrace();
      grace.disconnected();
      async.elapse(const Duration(seconds: 25));
      grace.attempt();
      async.elapse(const Duration(seconds: 25));
      grace.attempt();
      async.elapse(const Duration(seconds: 25));
      expect(fired, 0);

      async.elapse(const Duration(seconds: 6));
      expect(fired, 1);
    });
  });

  test('an attempt arms the wait even before the room reports disconnected',
      () {
    fakeAsync((async) {
      setUpGrace();
      grace.attempt();
      expect(grace.isArmed, isTrue);

      async.elapse(const Duration(seconds: 31));
      expect(fired, 1);
    });
  });

  test('cancel after expiry is harmless', () {
    fakeAsync((async) {
      setUpGrace();
      grace.disconnected();
      async.elapse(const Duration(seconds: 31));
      grace.cancel();

      expect(fired, 1);
      expect(grace.isArmed, isFalse);
    });
  });
}
