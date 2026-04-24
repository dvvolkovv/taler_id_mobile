import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Non-dismissible warning banner shown during an active AI session when
/// the balance drops into a warning range. Caller decides when to render it
/// (e.g. in response to a `billing_low_balance_warning` socket event) and
/// passes the current micro-TAL amount.
///
/// Provide [onTopUp] to override the default navigation to `/billing/wallet`.
class LowBalanceBanner extends StatelessWidget {
  final String balanceMicroTal;
  final VoidCallback? onTopUp;

  const LowBalanceBanner({
    super.key,
    required this.balanceMicroTal,
    this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    // Deliberately hard-coded warning palette — banner should stand out
    // against both dark and light surfaces.
    const bg = Color(0xFFFFF3CD); // warm amber tint
    const fg = Color(0xFF7A4F01);

    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: fg, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Баланс на исходе: $balanceMicroTal μTAL',
                  style: const TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onTopUp ?? () => context.push('/billing/wallet'),
                style: TextButton.styleFrom(
                  foregroundColor: fg,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Пополнить',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
