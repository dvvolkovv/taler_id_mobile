import '../../../../core/api/dio_client.dart';

/// Response from POST /kyc/start.
///
/// Backend now serves the same shape to all platforms — KYC runs through the
/// SumSub-compatible mock WebSDK over an in-app WebView (no native SDK token).
class KycStartResponse {
  final String applicantId;
  final String webSdkUrl;
  final String sdkBaseUrl;
  final String status;
  final String? expiresAt;

  const KycStartResponse({
    required this.applicantId,
    required this.webSdkUrl,
    required this.sdkBaseUrl,
    required this.status,
    this.expiresAt,
  });

  factory KycStartResponse.fromJson(Map<String, dynamic> json) {
    final applicantId =
        (json['applicantId'] ?? json['sumsubApplicantId']) as String? ?? '';
    return KycStartResponse(
      applicantId: applicantId,
      webSdkUrl: json['webSdkUrl'] as String? ?? '',
      sdkBaseUrl: json['sdkBaseUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      expiresAt: json['expiresAt'] as String?,
    );
  }
}

class KycRemoteDataSource {
  final DioClient client;
  KycRemoteDataSource(this.client);

  Future<KycStartResponse> startKyc() async {
    final data = await client.post<Map<String, dynamic>>(
      '/kyc/start',
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
