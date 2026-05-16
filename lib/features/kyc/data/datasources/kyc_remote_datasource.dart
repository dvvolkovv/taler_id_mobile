import '../../../../core/api/dio_client.dart';
import '../../../../core/platform/platform_utils.dart';

/// Unified response from POST /kyc/start.
///
/// Shape differs by platform:
///   mobile  → { platform: 'mobile', sdkToken, sumsubApplicantId, status }
///   desktop → { platform: 'desktop', webSdkUrl, sumsubApplicantId, status }
class KycStartResponse {
  final String platform;
  final String sumsubApplicantId;

  /// Sumsub Mobile SDK token — present on mobile only.
  final String? sdkToken;

  /// Sumsub Web SDK URL — present on desktop only.
  final String? webSdkUrl;

  final String status;

  const KycStartResponse({
    required this.platform,
    required this.sumsubApplicantId,
    this.sdkToken,
    this.webSdkUrl,
    required this.status,
  });

  factory KycStartResponse.fromJson(Map<String, dynamic> json) => KycStartResponse(
        platform: json['platform'] as String? ?? 'mobile',
        sumsubApplicantId: json['sumsubApplicantId'] as String? ?? '',
        sdkToken: json['sdkToken'] as String?,
        webSdkUrl: json['webSdkUrl'] as String?,
        status: json['status'] as String? ?? 'PENDING',
      );
}

class KycRemoteDataSource {
  final DioClient client;
  KycRemoteDataSource(this.client);

  Future<KycStartResponse> startKyc() async {
    final platform = PlatformUtils.instance.isDesktop ? 'desktop' : 'mobile';
    final data = await client.post<Map<String, dynamic>>(
      '/kyc/start?platform=$platform',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d),
    );
    return KycStartResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> getKycStatus() =>
      client.get('/kyc/status', fromJson: (d) => Map<String, dynamic>.from(d));

  Future<Map<String, dynamic>> getApplicantData() =>
      client.get('/kyc/applicant-data', fromJson: (d) => Map<String, dynamic>.from(d));
}
