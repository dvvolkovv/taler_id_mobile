import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/billing/presentation/widgets/insufficient_funds_sheet.dart';
import '../../main.dart' show globalNavigatorKey;

/// Dio interceptor that converts HTTP 402 `insufficient_funds` responses into
/// a centrally-shown [InsufficientFundsSheet].
///
/// The backend returns:
/// ```json
/// {
///   "error": "insufficient_funds",
///   "featureKey": "voice_assistant",
///   "requiredPlanck": "26000000",
///   "availablePlanck": "1000000",
///   "suggestedPackage": "starter"
/// }
/// ```
///
/// Any call site hitting a paywalled endpoint gets the sheet automatically —
/// individual BLoCs don't need to know about 402 handling. The original
/// [DioException] still bubbles through `handler.next(err)` so feature-level
/// BLoCs can render their own failure state alongside the paywall if they wish.
class BillingPaywallInterceptor extends Interceptor {
  /// In-flight deduplication: guarantees only one sheet is visible at a time
  /// even when multiple requests hit 402 in rapid succession (e.g. a retry
  /// loop or several parallel metered calls racing for the same empty wallet).
  bool _sheetShowing = false;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 402 && !_sheetShowing) {
      final data = err.response?.data;
      if (data is Map && data['error'] == 'insufficient_funds') {
        final ctx = globalNavigatorKey.currentContext;
        if (ctx != null) {
          _sheetShowing = true;
          try {
            await InsufficientFundsSheet.show(
              ctx,
              featureKey: (data['featureKey'] as String?) ?? 'unknown',
              requiredPlanck: (data['requiredPlanck'] as String?) ?? '0',
              availablePlanck: (data['availablePlanck'] as String?) ?? '0',
              suggestedPackage: data['suggestedPackage'] as String?,
            );
          } catch (e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('BillingPaywallInterceptor show failed: $e');
            }
          } finally {
            _sheetShowing = false;
          }
        }
      }
    }
    // Always let the error bubble so BLoCs can still surface their own
    // error state (e.g., purchase screen shows "purchase failed" alongside
    // the paywall).
    handler.next(err);
  }
}
