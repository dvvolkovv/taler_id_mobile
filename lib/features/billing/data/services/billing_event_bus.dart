import 'dart:async';

/// Backend-pushed events coming over the `/messenger` Socket.IO namespace.
///
/// These mirror the payloads the backend emits to `user:${userId}` rooms
/// (see billing spec §6.4):
///   - billing_balance_changed
///   - ai_session_started
///   - ai_session_terminated
///   - billing_low_balance_warning
///
/// The [BillingSocketListener] subscribes to the socket and pushes typed
/// events into [BillingEventBus]. BLoCs and widgets listen to the bus
/// streams without touching socket.io directly.

class BalanceChangedEvent {
  final String balancePlanck;
  final String reason;
  final String? txId;
  BalanceChangedEvent({
    required this.balancePlanck,
    required this.reason,
    this.txId,
  });
}

class AiSessionStartedEvent {
  final String sessionId;
  final String featureKey;
  AiSessionStartedEvent({
    required this.sessionId,
    required this.featureKey,
  });
}

class AiSessionTerminatedEvent {
  final String sessionId;
  final String reason; // 'no_funds' | 'failed'
  final String featureKey;
  final String? contextRef;
  AiSessionTerminatedEvent({
    required this.sessionId,
    required this.reason,
    required this.featureKey,
    this.contextRef,
  });
}

class LowBalanceWarningEvent {
  final String sessionId;
  final String balancePlanck;
  final String minReservePlanck;
  LowBalanceWarningEvent({
    required this.sessionId,
    required this.balancePlanck,
    required this.minReservePlanck,
  });
}

/// Singleton event bus for billing-related real-time events from the backend.
///
/// The socket listener pushes into it; BLoCs and screens subscribe.
/// Streams are broadcast so multiple listeners can coexist (e.g. the
/// dashboard [BalanceBloc], the voice call screen low-balance banner,
/// and the assistant screen all listen simultaneously).
class BillingEventBus {
  final _balance = StreamController<BalanceChangedEvent>.broadcast();
  final _sessionStarted = StreamController<AiSessionStartedEvent>.broadcast();
  final _sessionTerminated =
      StreamController<AiSessionTerminatedEvent>.broadcast();
  final _lowBalance = StreamController<LowBalanceWarningEvent>.broadcast();

  Stream<BalanceChangedEvent> get onBalanceChanged => _balance.stream;
  Stream<AiSessionStartedEvent> get onSessionStarted => _sessionStarted.stream;
  Stream<AiSessionTerminatedEvent> get onSessionTerminated =>
      _sessionTerminated.stream;
  Stream<LowBalanceWarningEvent> get onLowBalance => _lowBalance.stream;

  void pushBalance(BalanceChangedEvent e) => _balance.add(e);
  void pushSessionStarted(AiSessionStartedEvent e) => _sessionStarted.add(e);
  void pushSessionTerminated(AiSessionTerminatedEvent e) =>
      _sessionTerminated.add(e);
  void pushLowBalance(LowBalanceWarningEvent e) => _lowBalance.add(e);

  Future<void> dispose() async {
    await _balance.close();
    await _sessionStarted.close();
    await _sessionTerminated.close();
    await _lowBalance.close();
  }
}
