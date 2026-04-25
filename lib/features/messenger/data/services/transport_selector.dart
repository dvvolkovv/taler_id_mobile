enum TransportChoice { server, mesh, offline }

/// Pure policy object for picking the delivery transport per outbound
/// message. All state is supplied by the three callbacks — the class has
/// no long-lived state of its own.
class TransportSelector {
  final bool Function() isSocketConnected;
  final bool Function(String contactUserId) isPeerVisibleFor;
  final bool Function() offlineFallbackEnabled;

  TransportSelector({
    required this.isSocketConnected,
    required this.isPeerVisibleFor,
    required this.offlineFallbackEnabled,
  });

  TransportChoice chooseFor(String contactUserId) {
    if (isSocketConnected()) return TransportChoice.server;
    if (!offlineFallbackEnabled()) return TransportChoice.offline;
    if (isPeerVisibleFor(contactUserId)) return TransportChoice.mesh;
    return TransportChoice.offline;
  }
}
