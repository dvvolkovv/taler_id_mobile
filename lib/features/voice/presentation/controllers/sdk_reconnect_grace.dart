import 'dart:async';

/// Сколько экран звонка ждёт, пока LiveKit восстановит соединение сам, прежде
/// чем браться за своё переподключение.
///
/// Восстанавливая соединение после мигания сети (Wi-Fi ↔ сотовая), LiveKit
/// проводит `Room.connectionState` через `disconnected`, пока заново открывает
/// сигнальный сокет, и `RoomReconnectingEvent` для этого не шлёт (livekit_client
/// 2.4.1: `SignalClient._onSocketDispose` и `cleanUp`). Экран принимал такое
/// `disconnected` за «LiveKit сдался» и через две секунды выходил из комнаты и
/// входил заново, обрывая уже удавшееся восстановление. Каждое мигание сети
/// становилось обрывом на несколько секунд со звуковым сигналом у обоих —
/// 18.11.2026 на PROD так рвался звонок с iPhone, а в журнале LiveKit за неделю
/// так кончалось почти каждое восстановление у мобильных клиентов.
///
/// Теперь `disconnected` лишь заводит ожидание. Оно снимается, когда комната
/// снова на связи, начинается заново с каждой новой попыткой LiveKit и
/// срабатывает, только если LiveKit замолчал. Когда LiveKit действительно
/// сдаётся, он говорит об этом `RoomDisconnectedEvent`, и на него экран
/// отвечает своим переподключением сразу, как и раньше.
///
/// Вынесено из экрана звонка, потому что экран в тесте не поднять.
class SdkReconnectGrace {
  SdkReconnectGrace({required this.onExpired, this.grace = defaultGrace});

  /// Дольше одной попытки LiveKit: та открывает сокет и ждёт ответа сервера,
  /// каждое — до 10 секунд.
  static const Duration defaultGrace = Duration(seconds: 30);

  final void Function() onExpired;
  final Duration grace;

  Timer? _timer;

  bool get isArmed => _timer != null;

  /// Комната сообщила `disconnected`. Слушатель комнаты зовётся на каждое
  /// изменение, поэтому уже идущее ожидание не перезапускается.
  void disconnected() => _timer ??= Timer(grace, _fire);

  /// LiveKit начинает очередную попытку — у неё полное ожидание заново.
  void attempt() {
    _timer?.cancel();
    _timer = Timer(grace, _fire);
  }

  /// Комната снова на связи, или переподключение уже взял на себя экран.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _fire() {
    _timer = null;
    onExpired();
  }
}
