// lib/core/platform/kyc_launcher_mobile.dart
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

import 'kyc_launcher.dart';

/// [KycLauncherPlatform] implementation for iOS and Android.
///
/// Delegates to the Sumsub `flutter_idensic_mobile_sdk_plugin`.
class KycLauncherMobile implements KycLauncherPlatform {
  @override
  Future<KycLaunchResult> launch({
    required String sdkToken,
    required Future<String?> Function() onTokenExpiration,
    Locale locale = const Locale('ru'),
    bool debug = true,
  }) async {
    final sdk = SNSMobileSDK.init(sdkToken, onTokenExpiration)
        .withLocale(locale)
        .withDebug(debug)
        .build();
    final result = await sdk.launch();
    return KycLaunchResult(
      success: result.success,
      errorMessage: result.errorMsg,
      errorType: result.errorType?.toString(),
    );
  }
}
