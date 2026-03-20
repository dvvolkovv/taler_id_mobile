import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../di/service_locator.dart';

class ChunkedUploadResult {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String s3Key;
  final String? thumbnailSmallUrl;
  final String? thumbnailMediumUrl;
  final String? thumbnailLargeUrl;
  final String? fileRecordId;

  ChunkedUploadResult({
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.s3Key,
    this.thumbnailSmallUrl,
    this.thumbnailMediumUrl,
    this.thumbnailLargeUrl,
    this.fileRecordId,
  });
}

class ChunkedUploadService {
  static const int chunkSize = 5 * 1024 * 1024; // 5MB (S3 minimum)
  static const int maxRetries = 3;

  static const _mimeMap = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mp3': 'audio/mpeg',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  /// Detect MIME type from file name extension.
  static String detectMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return _mimeMap[ext] ?? 'application/octet-stream';
  }

  /// Compute SHA-256 hash of a file by reading it in chunks.
  static Future<String> _computeSha256(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Check if a file with the given hash already exists on the server.
  /// Returns the existing file record data if found, or null otherwise.
  static Future<ChunkedUploadResult?> _checkDedup({
    required String sha256Hash,
    required int fileSize,
    required String mimeType,
    CancelToken? cancelToken,
  }) async {
    final client = sl<DioClient>();
    try {
      final res = await client.dio.post<Map<String, dynamic>>(
        '/messenger/files/check',
        data: {
          'sha256': sha256Hash,
          'fileSize': fileSize,
          'mimeType': mimeType,
        },
        cancelToken: cancelToken,
      );
      final data = res.data!;
      if (data['exists'] == true && data['fileRecord'] != null) {
        final record = Map<String, dynamic>.from(data['fileRecord'] as Map);
        return ChunkedUploadResult(
          fileUrl: record['fileUrl'] as String,
          fileName: record['fileName'] as String,
          fileSize: record['fileSize'] as int,
          fileType: record['fileType'] as String? ?? 'document',
          s3Key: record['s3Key'] as String? ?? '',
          thumbnailSmallUrl: record['thumbnailSmallUrl'] as String?,
          thumbnailMediumUrl: record['thumbnailMediumUrl'] as String?,
          thumbnailLargeUrl: record['thumbnailLargeUrl'] as String?,
          fileRecordId: record['id'] as String?,
        );
      }
    } catch (_) {
      // If dedup check fails, proceed with normal upload
    }
    return null;
  }

  /// Upload a file, using chunked upload for files >= 5MB, single POST otherwise.
  /// [onProgress] receives 0.0 to 1.0
  static Future<ChunkedUploadResult> upload({
    required String filePath,
    required String fileName,
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();

    // Phase 1: Compute SHA-256 (progress 0.0 -> 0.05)
    onProgress?.call(0.0);
    final sha256Hash = await _computeSha256(filePath);
    onProgress?.call(0.05);

    // Phase 2: Check dedup
    final mimeType = detectMimeType(fileName);
    final existing = await _checkDedup(
      sha256Hash: sha256Hash,
      fileSize: fileSize,
      mimeType: mimeType,
      cancelToken: cancelToken,
    );
    if (existing != null) {
      onProgress?.call(1.0);
      return existing;
    }

    // Phase 3: Upload (progress 0.05 -> 1.0)
    // Small files: use existing single POST
    if (fileSize < chunkSize) {
      return _singleUpload(filePath, fileName,
          cancelToken: cancelToken,
          onProgress: onProgress != null
              ? (p) => onProgress(0.05 + p * 0.95)
              : null);
    }

    // Large files: chunked upload
    return _chunkedUpload(filePath, fileName, fileSize,
        cancelToken: cancelToken,
        onProgress: onProgress != null
            ? (p) => onProgress(0.05 + p * 0.95)
            : null);
  }

  static Future<ChunkedUploadResult> _singleUpload(
    String filePath,
    String fileName, {
    CancelToken? cancelToken,
    void Function(double)? onProgress,
  }) async {
    final client = sl<DioClient>();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await client.dio.post<Map<String, dynamic>>(
      '/messenger/files',
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    final data = res.data!;
    return ChunkedUploadResult(
      fileUrl: data['fileUrl'] as String,
      fileName: data['fileName'] as String,
      fileSize: data['fileSize'] as int,
      fileType: data['fileType'] as String? ?? 'document',
      s3Key: data['s3Key'] as String? ?? '',
      thumbnailSmallUrl: data['thumbnailSmallUrl'] as String?,
      thumbnailMediumUrl: data['thumbnailMediumUrl'] as String?,
      thumbnailLargeUrl: data['thumbnailLargeUrl'] as String?,
      fileRecordId: data['id'] as String?,
    );
  }

  static Future<ChunkedUploadResult> _chunkedUpload(
    String filePath,
    String fileName,
    int fileSize, {
    CancelToken? cancelToken,
    void Function(double)? onProgress,
  }) async {
    final client = sl<DioClient>();
    final file = File(filePath);

    // Determine MIME type
    final mimeType = detectMimeType(fileName);

    // 1. Init
    final initRes = await client.dio.post<Map<String, dynamic>>(
      '/messenger/files/init',
      data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
      },
      cancelToken: cancelToken,
    );
    final uploadId = initRes.data!['uploadId'] as String;
    final totalParts = initRes.data!['totalParts'] as int;

    // 2. Upload chunks
    final raf = await file.open();
    try {
      for (int i = 1; i <= totalParts; i++) {
        if (cancelToken?.isCancelled == true) {
          // Abort on server
          try {
            await client.dio.delete('/messenger/files/$uploadId');
          } catch (_) {}
          throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.cancel,
          );
        }

        final offset = (i - 1) * chunkSize;
        final length = (i == totalParts) ? fileSize - offset : chunkSize;

        await raf.setPosition(offset);
        final chunkData = await raf.read(length);

        // Retry logic
        for (int attempt = 0; attempt < maxRetries; attempt++) {
          try {
            final formData = FormData.fromMap({
              'uploadId': uploadId,
              'partNumber': i.toString(),
              'chunk':
                  MultipartFile.fromBytes(chunkData, filename: 'chunk_$i'),
            });
            await client.dio.post(
              '/messenger/files/chunk',
              data: formData,
              cancelToken: cancelToken,
            );
            break; // success
          } catch (e) {
            if (attempt == maxRetries - 1) rethrow;
            if (cancelToken?.isCancelled == true) rethrow;
            await Future.delayed(
                Duration(seconds: (attempt + 1) * 2)); // exponential backoff
          }
        }

        // Progress: chunk completion
        onProgress?.call(i / totalParts);
      }
    } finally {
      await raf.close();
    }

    // 3. Complete
    final completeRes = await client.dio.post<Map<String, dynamic>>(
      '/messenger/files/complete',
      data: {'uploadId': uploadId},
      cancelToken: cancelToken,
    );
    final data = completeRes.data!;
    return ChunkedUploadResult(
      fileUrl: data['fileUrl'] as String,
      fileName: data['fileName'] as String,
      fileSize: data['fileSize'] as int,
      fileType: data['fileType'] as String? ?? 'document',
      s3Key: data['s3Key'] as String? ?? '',
      thumbnailSmallUrl: data['thumbnailSmallUrl'] as String?,
      thumbnailMediumUrl: data['thumbnailMediumUrl'] as String?,
      thumbnailLargeUrl: data['thumbnailLargeUrl'] as String?,
      fileRecordId: data['id'] as String?,
    );
  }
}
