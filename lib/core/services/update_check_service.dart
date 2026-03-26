import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';

class UpdateInfo {
  final bool isAvailable;
  final bool isRequired;
  final String downloadUrl;
  final String latestVersion;

  const UpdateInfo({
    required this.isAvailable,
    required this.isRequired,
    required this.downloadUrl,
    required this.latestVersion,
  });
}

class UpdateCheckService {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConfig.baseUrl}/app/version',
      );
      final data = response.data!;
      final platform = Platform.isIOS ? 'ios' : 'android';
      final platformData = data[platform] as Map<String, dynamic>? ?? {};
      final urls = data['updateUrl'] as Map<String, dynamic>? ?? {};

      final remoteBuild = platformData['build'] as int? ?? 0;
      final remoteVersion = platformData['version'] as String? ?? '';
      final required = platformData['required'] as bool? ?? false;
      final downloadUrl = urls[platform] as String? ?? '';

      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;

      return UpdateInfo(
        isAvailable: remoteBuild > localBuild,
        isRequired: required,
        downloadUrl: downloadUrl,
        latestVersion: remoteVersion,
      );
    } catch (_) {
      return null;
    }
  }
}
