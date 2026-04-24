import 'package:flutter/foundation.dart';

import 'billing_event_bus.dart';

/// Registers handlers for billing-related events on the existing messenger
/// Socket.IO connection, then fans them out via [BillingEventBus].
///
/// Does NOT own the socket. The messenger data source already has one and
/// handles (re)connects — we just piggyback on it. Attachment is idempotent
/// in the sense that the caller decides when to call [attach]; if the socket
/// is re-created (new auth), the caller should re-attach.
class BillingSocketListener {
  final BillingEventBus _bus;
  BillingSocketListener(this._bus);

  /// Call once when the messenger socket is ready. The caller provides an
  /// `on(event, handler)` function so this class stays independent of
  /// socket.io_client types — and easy to test.
  void attach(
    void Function(String event, void Function(dynamic data) handler) on,
  ) {
    on('billing_balance_changed', (data) {
      if (data is Map) {
        try {
          _bus.pushBalance(BalanceChangedEvent(
            balancePlanck: (data['balancePlanck'] as String?) ?? '0',
            reason: (data['reason'] as String?) ?? 'UNKNOWN',
            txId: data['txId'] as String?,
          ));
        } catch (e) {
          debugPrint('[BillingSocket] billing_balance_changed parse error: $e');
        }
      }
    });

    on('ai_session_started', (data) {
      if (data is Map) {
        try {
          _bus.pushSessionStarted(AiSessionStartedEvent(
            sessionId: (data['sessionId'] as String?) ?? '',
            featureKey: (data['featureKey'] as String?) ?? '',
          ));
        } catch (e) {
          debugPrint('[BillingSocket] ai_session_started parse error: $e');
        }
      }
    });

    on('ai_session_terminated', (data) {
      if (data is Map) {
        try {
          _bus.pushSessionTerminated(AiSessionTerminatedEvent(
            sessionId: (data['sessionId'] as String?) ?? '',
            reason: (data['reason'] as String?) ?? 'failed',
            featureKey: (data['featureKey'] as String?) ?? '',
            contextRef: data['contextRef'] as String?,
          ));
        } catch (e) {
          debugPrint('[BillingSocket] ai_session_terminated parse error: $e');
        }
      }
    });

    on('billing_low_balance_warning', (data) {
      if (data is Map) {
        try {
          _bus.pushLowBalance(LowBalanceWarningEvent(
            sessionId: (data['sessionId'] as String?) ?? '',
            balancePlanck: (data['balancePlanck'] as String?) ?? '0',
            minReservePlanck: (data['minReservePlanck'] as String?) ?? '0',
          ));
        } catch (e) {
          debugPrint(
              '[BillingSocket] billing_low_balance_warning parse error: $e');
        }
      }
    });
  }
}
