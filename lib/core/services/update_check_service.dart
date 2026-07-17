import 'dart:io';
import '../api/dio_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';

class ReleaseEntry {
  final String version;
  final int build;
  final String date;
  final String flavor; // 'dev' | 'prod' | 'both'
  final String notesRu;
  final String notesEn;

  const ReleaseEntry({
    required this.version,
    required this.build,
    required this.date,
    required this.flavor,
    required this.notesRu,
    required this.notesEn,
  });

  factory ReleaseEntry.fromJson(Map<String, dynamic> j) => ReleaseEntry(
        version: j['version'] as String? ?? '',
        build: j['build'] as int? ?? 0,
        date: j['date'] as String? ?? '',
        flavor: j['flavor'] as String? ?? 'both',
        notesRu: j['notes_ru'] as String? ?? '',
        notesEn: j['notes_en'] as String? ?? '',
      );

  String notesFor(String localeCode) => localeCode == 'ru' ? notesRu : notesEn;
}

class UpdateInfo {
  final bool isAvailable;
  final bool isRequired;
  final String downloadUrl;
  final String latestVersion;
  final String currentVersion;
  final List<ReleaseEntry> releases;

  const UpdateInfo({
    required this.isAvailable,
    required this.isRequired,
    required this.downloadUrl,
    required this.latestVersion,
    required this.currentVersion,
    required this.releases,
  });

  /// Notes shown in the update banner — the latest release matching current flavor.
  String? latestNotes(String localeCode) {
    for (final r in releases) {
      if (r.version == latestVersion) return r.notesFor(localeCode);
    }
    return null;
  }
}

class UpdateCheckService {
  // Goes through the shared DioClient so the version check follows the same
  // CIS failover (api.talerid.io → ru/ru2.talerid.io) as all other traffic.
  // The previous raw Dio hit AppConfig.baseUrl directly: on DPI-blocked
  // networks the whole app worked via the failover edge while this single
  // request silently timed out — users never saw the update banner
  // (reported 2026-07-17 on talerid 1.1.11).
  final DioClient _client;

  UpdateCheckService(this._client);

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final data = await _client.get<Map<String, dynamic>>(
        '/app/version',
        queryParameters: {'flavor': AppConfig.flavor},
      );
      final platform = Platform.isIOS ? 'ios' : 'android';
      final platformData = data[platform] as Map<String, dynamic>? ?? {};
      final urls = data['updateUrl'] as Map<String, dynamic>? ?? {};

      final remoteBuild = platformData['build'] as int? ?? 0;
      final remoteVersion = platformData['version'] as String? ?? '';
      final required = platformData['required'] as bool? ?? false;
      final downloadUrl = urls[platform] as String? ?? '';

      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;

      final releasesJson = (data['releases'] as List?) ?? const [];
      final releases = releasesJson
          .whereType<Map<String, dynamic>>()
          .map(ReleaseEntry.fromJson)
          .toList(growable: false);

      return UpdateInfo(
        isAvailable: remoteBuild > localBuild,
        isRequired: required,
        downloadUrl: downloadUrl,
        latestVersion: remoteVersion,
        currentVersion: info.version,
        releases: releases,
      );
    } catch (_) {
      return null;
    }
  }
}
